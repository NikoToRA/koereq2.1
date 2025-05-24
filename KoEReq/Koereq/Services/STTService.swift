//
//  STTService.swift
//  Koereq
//
//  Created by Koereq Team on 2025/05/23.
//

import Foundation
import Speech
import AVFoundation

@MainActor
class STTService: ObservableObject {
    @Published var isTranscribing = false
    @Published var transcriptionResult = ""
    @Published var error: Error?
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    init() {
        requestSpeechAuthorization()
    }
    
    private func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    print("Speech recognition authorized")
                case .denied:
                    print("Speech recognition authorization denied")
                    self?.error = STTError.authorizationDenied
                case .restricted:
                    print("Speech recognition restricted")
                    self?.error = STTError.authorizationRestricted
                case .notDetermined:
                    print("Speech recognition not determined")
                    self?.error = STTError.authorizationNotDetermined
                @unknown default:
                    print("Unknown speech recognition authorization status")
                }
            }
        }
    }
    
    func transcribe(audioURL: URL) async throws -> String {
        print("[STTService] Starting transcription for URL: \(audioURL.path)")
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            print("[STTService] Speech recognizer not available.")
            throw STTError.recognizerNotAvailable
        }
        
        do {
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: audioURL.path)
            if let fileSize = fileAttributes[FileAttributeKey.size] as? NSNumber {
                print("[STTService] Audio file size: \(fileSize.uint64Value) bytes")
                if fileSize.uint64Value == 0 {
                    print("[STTService] Audio file is empty!")
                    throw STTError.audioFileEmpty
                }
            }
        } catch {
            print("[STTService] Could not get audio file attributes: \(error)")
            throw STTError.audioFileNotReadable
        }

        self.isTranscribing = true
        self.transcriptionResult = "" // Reset previous result
        self.error = nil // Reset previous error
        
        return try await withCheckedThrowingContinuation { continuation in
            
            do {
                print("[STTService] Initializing AVAudioFile...")
                let audioFile = try AVAudioFile(forReading: audioURL)
                print("[STTService] AVAudioFile initialized. Format: \(audioFile.processingFormat), Length: \(audioFile.length) frames.")

                let request = SFSpeechAudioBufferRecognitionRequest()
                request.shouldReportPartialResults = true
                request.taskHint = .dictation 
                // request.requiresOnDeviceRecognition = false // Consider for specific needs
                print("[STTService] SFSpeechAudioBufferRecognitionRequest created.")
                
                self.recognitionRequest = request

                recognitionTask = speechRecognizer.recognitionTask(with: request) { result, error in
                    
                    var isFinal = false
                    var recognizedText: String? = nil
                    
                    if let result = result {
                        recognizedText = result.bestTranscription.formattedString
                        print("[STTService] Recognition result (isFinal: \(result.isFinal)): \(recognizedText ?? "N/A")")
                        if result.isFinal {
                            isFinal = true
                        }
                    }
                    
                    if let error = error {
                        print("[STTService] Recognition task error: \(error.localizedDescription)")
                        let nsError = error as NSError
                        print("[STTService] Error Domain: \(nsError.domain), Code: \(nsError.code), UserInfo: \(nsError.userInfo)")
                    }
                    
                    if error != nil || isFinal {
                        Task { @MainActor in
                            self.isTranscribing = false
                        }
                        self.recognitionRequest?.endAudio()
                        
                        if let currentTask = self.recognitionTask, currentTask.state != .canceling && currentTask.state != .completed {
                             if isFinal && error == nil {
                                currentTask.finish()
                             } else {
                                currentTask.cancel()
                             }
                        }
                        self.recognitionRequest = nil
                        self.recognitionTask = nil
                        
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else if isFinal, let finalText = recognizedText {
                            continuation.resume(returning: finalText)
                        } else if isFinal { // Should have text if final and no error
                            print("[STTService] Final result without text and no error, resuming with empty string or handling as error.")
                            continuation.resume(returning: "") // Or throw an error
                        }
                        // If not final and no error, the callback will be called again.
                    }
                }
                
                guard self.recognitionTask != nil else {
                    print("[STTService] Failed to create recognition task.")
                    throw STTError.recognizerNotAvailable // Or a more specific error
                }
                print("[STTService] Recognition task created successfully.")
                
                let bufferSize = AVAudioFrameCount(4096)
                let audioFormat = audioFile.processingFormat
                print("[STTService] Buffer size: \(bufferSize), Audio format for buffer: \(audioFormat)")
                
                guard self.recognitionRequest != nil else {
                    print("[STTService] recognitionRequest is nil before appending buffers. This should not happen.")
                    throw STTError.recognizerNotAvailable 
                }

                var totalFramesRead: AVAudioFramePosition = 0
                while audioFile.framePosition < audioFile.length {
                    let framesToRead = min(bufferSize, AVAudioFrameCount(audioFile.length - audioFile.framePosition))
                    if framesToRead <= 0 {
                        print("[STTService] No more frames to read or invalid frame count: \(framesToRead). Current position: \(audioFile.framePosition), File length: \(audioFile.length). Breaking loop.")
                        break
                    }
                    
                    guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: framesToRead) else {
                        print("[STTService] Failed to create AVAudioPCMBuffer for \(framesToRead) frames.")
                        throw STTError.audioBufferCreationFailed
                    }
                    try audioFile.read(into: buffer, frameCount: framesToRead)
                    
                    if buffer.frameLength > 0 {
                        self.recognitionRequest?.append(buffer)
                        totalFramesRead += AVAudioFramePosition(buffer.frameLength)
                        // print("[STTService] Appended buffer with \(buffer.frameLength) frames. Total frames read: \(totalFramesRead)")
                    } else {
                        print("[STTService] Buffer frameLength is 0 after read (expected \(framesToRead)), not appending. Current position: \(audioFile.framePosition)")
                    }
                }
                print("[STTService] Finished appending audio buffers. Total frames read: \(totalFramesRead). Audio file length: \(audioFile.length). Current position: \(audioFile.framePosition)")
                
                if totalFramesRead == 0 && audioFile.length > 0 {
                    print("[STTService] Warning: No frames were read from a non-empty audio file (length: \(audioFile.length)).")
                }
                
                self.recognitionRequest?.endAudio()
                print("[STTService] Called endAudio() on recognitionRequest.")
                
            } catch let processingError {
                print("[STTService] Error during audio processing or request setup: \(processingError.localizedDescription)")
                Task { @MainActor in
                    self.isTranscribing = false
                    self.error = processingError
                }
                self.recognitionRequest?.endAudio() 
                self.recognitionTask?.cancel()
                self.recognitionRequest = nil
                self.recognitionTask = nil
                continuation.resume(throwing: processingError)
            }
        }
    }
    
    func transcribeRealTime(audioBuffer: AVAudioPCMBuffer) {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            self.error = STTError.recognizerNotAvailable
            return
        }
        
        if recognitionRequest == nil {
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            recognitionRequest?.shouldReportPartialResults = true
            
            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest!) { result, error in
                Task { @MainActor in
                    if let error = error {
                        self.error = error
                        self.stopRealTimeTranscription()
                        return
                    }
                    
                    if let result = result {
                        self.transcriptionResult = result.bestTranscription.formattedString
                    }
                }
            }
        }
        
        recognitionRequest?.append(audioBuffer)
    }
    
    func stopRealTimeTranscription() {
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        isTranscribing = false
    }
}

enum STTError: Error, LocalizedError {
    case authorizationDenied
    case authorizationRestricted
    case authorizationNotDetermined
    case recognizerNotAvailable
    case audioBufferCreationFailed
    case audioFileEmpty
    case audioFileNotReadable
    
    var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            return "音声認識の許可が拒否されました"
        case .authorizationRestricted:
            return "音声認識が制限されています"
        case .authorizationNotDetermined:
            return "音声認識の許可が未確定です"
        case .recognizerNotAvailable:
            return "音声認識が利用できません"
        case .audioBufferCreationFailed:
            return "オーディオバッファの作成に失敗しました"
        case .audioFileEmpty:
            return "音声ファイルが空です。"
        case .audioFileNotReadable:
            return "音声ファイルの読み込みに失敗しました。"
        }
    }
}
