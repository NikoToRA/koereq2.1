//
//  STTService.swift
//  Koereq
//
//  Created by Koereq Team on 2025/05/23.
//

import Foundation
import Speech
import AVFoundation

// MARK: - 相対時間解析関連の型定義

struct RelativeTimeResult {
    let originalText: String
    let processedText: String
    let detectedDates: [DetectedDate]
    let deviceCurrentTime: Date
}

struct DetectedDate {
    let originalText: String
    let calculatedDate: Date
    let range: Range<String.Index>
    let isTimeUnit: Bool // 時間単位かどうか
}

struct DeviceTimeInfo {
    let currentDate: Date
    let timeZone: TimeZone
    let calendar: Calendar
    let formattedString: String
    
    var timeZoneIdentifier: String {
        return timeZone.identifier
    }
    
    var timeZoneOffset: String {
        let seconds = timeZone.secondsFromGMT()
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        return String(format: "UTC%+03d:%02d", hours, minutes)
    }
}

// MARK: - RelativeTimeParser クラス

class RelativeTimeParser {
    
    static let shared = RelativeTimeParser()
    
    private init() {}
    
    // 日本語の相対時間表現パターン
    private struct TimePattern {
        let pattern: String
        let unit: Calendar.Component
        let multiplier: Int
        let isTimeUnit: Bool // 時間単位かどうか（分・時間）
        
        init(pattern: String, unit: Calendar.Component, multiplier: Int) {
            self.pattern = pattern
            self.unit = unit
            self.multiplier = multiplier
            // 分・時間単位の場合はtrue、日・週・月・年の場合はfalse
            self.isTimeUnit = (unit == .minute || unit == .hour)
        }
    }
    
    private let timePatterns: [TimePattern] = [
        // 分単位
        TimePattern(pattern: #"(\d+)分前"#, unit: .minute, multiplier: -1),
        TimePattern(pattern: #"(\d+)分後"#, unit: .minute, multiplier: 1),
        TimePattern(pattern: #"今から(\d+)分後"#, unit: .minute, multiplier: 1),
        TimePattern(pattern: #"今から(\d+)分前"#, unit: .minute, multiplier: -1),
        
        // 時間単位
        TimePattern(pattern: #"(\d+)時間前"#, unit: .hour, multiplier: -1),
        TimePattern(pattern: #"(\d+)時間後"#, unit: .hour, multiplier: 1),
        TimePattern(pattern: #"今から(\d+)時間後"#, unit: .hour, multiplier: 1),
        TimePattern(pattern: #"今から(\d+)時間前"#, unit: .hour, multiplier: -1),
        
        // 日単位
        TimePattern(pattern: #"(\d+)日前"#, unit: .day, multiplier: -1),
        TimePattern(pattern: #"(\d+)日後"#, unit: .day, multiplier: 1),
        TimePattern(pattern: #"今から(\d+)日後"#, unit: .day, multiplier: 1),
        TimePattern(pattern: #"今から(\d+)日前"#, unit: .day, multiplier: -1),
        
        // 週単位
        TimePattern(pattern: #"(\d+)週間前"#, unit: .weekOfYear, multiplier: -1),
        TimePattern(pattern: #"(\d+)週間後"#, unit: .weekOfYear, multiplier: 1),
        TimePattern(pattern: #"今から(\d+)週間後"#, unit: .weekOfYear, multiplier: 1),
        TimePattern(pattern: #"今から(\d+)週間前"#, unit: .weekOfYear, multiplier: -1),
        
        // 月単位
        TimePattern(pattern: #"(\d+)ヶ月前"#, unit: .month, multiplier: -1),
        TimePattern(pattern: #"(\d+)ヶ月後"#, unit: .month, multiplier: 1),
        TimePattern(pattern: #"(\d+)か月前"#, unit: .month, multiplier: -1),
        TimePattern(pattern: #"(\d+)か月後"#, unit: .month, multiplier: 1),
        TimePattern(pattern: #"今から(\d+)ヶ月後"#, unit: .month, multiplier: 1),
        TimePattern(pattern: #"今から(\d+)ヶ月前"#, unit: .month, multiplier: -1),
        TimePattern(pattern: #"今から(\d+)か月後"#, unit: .month, multiplier: 1),
        TimePattern(pattern: #"今から(\d+)か月前"#, unit: .month, multiplier: -1),
        
        // 年単位
        TimePattern(pattern: #"(\d+)年前"#, unit: .year, multiplier: -1),
        TimePattern(pattern: #"(\d+)年後"#, unit: .year, multiplier: 1),
        TimePattern(pattern: #"今から(\d+)年後"#, unit: .year, multiplier: 1),
        TimePattern(pattern: #"今から(\d+)年前"#, unit: .year, multiplier: -1),
        
        // 特殊表現
        TimePattern(pattern: "昨日", unit: .day, multiplier: -1),
        TimePattern(pattern: "明日", unit: .day, multiplier: 1),
        TimePattern(pattern: "今日", unit: .day, multiplier: 0),
        TimePattern(pattern: "先週", unit: .weekOfYear, multiplier: -1),
        TimePattern(pattern: "来週", unit: .weekOfYear, multiplier: 1),
        TimePattern(pattern: "今週", unit: .weekOfYear, multiplier: 0),
        TimePattern(pattern: "先月", unit: .month, multiplier: -1),
        TimePattern(pattern: "来月", unit: .month, multiplier: 1),
        TimePattern(pattern: "今月", unit: .month, multiplier: 0),
        TimePattern(pattern: "去年", unit: .year, multiplier: -1),
        TimePattern(pattern: "来年", unit: .year, multiplier: 1),
        TimePattern(pattern: "今年", unit: .year, multiplier: 0)
    ]
    
    /// テキストから相対時間表現を解析してDateオブジェクトを生成
    /// - Parameters:
    ///   - text: 解析対象のテキスト
    ///   - baseDate: 基準となる日時（省略時は現在時刻）
    /// - Returns: 解析結果のDate配列とテキスト化された結果
    func parseRelativeTime(from text: String, baseDate: Date = Date()) -> RelativeTimeResult {
        var detectedDates: [DetectedDate] = []
        var processedText = text
        
        for pattern in timePatterns {
            let regex = try! NSRegularExpression(pattern: pattern.pattern)
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            
            for match in matches {
                if let matchedRange = Range(match.range, in: text) {
                    let matchedText = String(text[matchedRange])
                    
                    var value = 1
                    // 数値を含むパターンの場合
                    if match.numberOfRanges > 1 {
                        let numberRange = Range(match.range(at: 1), in: text)!
                        value = Int(String(text[numberRange])) ?? 1
                    }
                    
                    let calculatedDate = calculateDate(
                        baseDate: baseDate,
                        value: value * pattern.multiplier,
                        unit: pattern.unit
                    )
                    
                    let detectedDate = DetectedDate(
                        originalText: matchedText,
                        calculatedDate: calculatedDate,
                        range: matchedRange,
                        isTimeUnit: pattern.isTimeUnit
                    )
                    
                    detectedDates.append(detectedDate)
                    
                    // テキストを日時表現に置換（時間単位か日付単位かで異なるフォーマット）
                    let formattedDate = formatDate(calculatedDate, isTimeUnit: pattern.isTimeUnit)
                    processedText = processedText.replacingOccurrences(
                        of: matchedText,
                        with: formattedDate
                    )
                }
            }
        }
        
        return RelativeTimeResult(
            originalText: text,
            processedText: processedText,
            detectedDates: detectedDates,
            deviceCurrentTime: baseDate
        )
    }
    
    /// 基準日時から指定した値・単位で日時を計算
    private func calculateDate(baseDate: Date, value: Int, unit: Calendar.Component) -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: unit, value: value, to: baseDate) ?? baseDate
    }
    
    /// 日時を読みやすい形式でフォーマット
    /// - Parameters:
    ///   - date: フォーマット対象の日時
    ///   - isTimeUnit: true=時刻のみ表示（分・時間単位）、false=日付のみ表示（日・週・月・年単位）
    private func formatDate(_ date: Date, isTimeUnit: Bool = false) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        
        if isTimeUnit {
            // 時間単位（分・時間）の場合：時刻のみ表示
            formatter.dateStyle = .none
            formatter.timeStyle = .short
        } else {
            // 日付単位（日・週・月・年）の場合：日付のみ表示
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
        }
        
        return formatter.string(from: date)
    }
    
    /// 現在のデバイス時刻を取得
    func getCurrentDeviceTime() -> DeviceTimeInfo {
        let now = Date()
        let calendar = Calendar.current
        let timeZone = TimeZone.current
        
        // デバイス時刻表示用の専用フォーマット（日付+時刻）
        let deviceFormatter = DateFormatter()
        deviceFormatter.locale = Locale(identifier: "ja_JP")
        deviceFormatter.dateStyle = .medium
        deviceFormatter.timeStyle = .short
        
        return DeviceTimeInfo(
            currentDate: now,
            timeZone: timeZone,
            calendar: calendar,
            formattedString: deviceFormatter.string(from: now)
        )
    }
}

@MainActor
class STTService: ObservableObject {
    @Published var isTranscribing = false
    @Published var transcriptionResult = ""
    @Published var processedTranscriptionResult = ""
    @Published var detectedRelativeTimeExpressions: [DetectedDate] = []
    @Published var error: Error?
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let relativeTimeParser = RelativeTimeParser.shared
    
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
                            // 相対時間表現を解析してテキスト化
                            let relativeTimeResult = self.relativeTimeParser.parseRelativeTime(from: finalText)
                            Task { @MainActor in
                                self.transcriptionResult = finalText
                                self.processedTranscriptionResult = relativeTimeResult.processedText
                                self.detectedRelativeTimeExpressions = relativeTimeResult.detectedDates
                            }
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
                        let originalText = result.bestTranscription.formattedString
                        self.transcriptionResult = originalText
                        
                        // リアルタイム音声認識でも相対時間解析を実行
                        let relativeTimeResult = self.relativeTimeParser.parseRelativeTime(from: originalText)
                        self.processedTranscriptionResult = relativeTimeResult.processedText
                        self.detectedRelativeTimeExpressions = relativeTimeResult.detectedDates
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
    
    /// 現在のデバイス時刻を取得
    func getCurrentDeviceTime() -> DeviceTimeInfo {
        return relativeTimeParser.getCurrentDeviceTime()
    }
    
    /// 指定されたテキストから相対時間表現を解析
    func parseRelativeTimeFromText(_ text: String, baseDate: Date = Date()) -> RelativeTimeResult {
        return relativeTimeParser.parseRelativeTime(from: text, baseDate: baseDate)
    }
    
    /// 音声認識結果の相対時間表現を手動で再解析
    func reprocessRelativeTime(baseDate: Date = Date()) {
        guard !transcriptionResult.isEmpty else { return }
        
        let result = relativeTimeParser.parseRelativeTime(from: transcriptionResult, baseDate: baseDate)
        self.processedTranscriptionResult = result.processedText
        self.detectedRelativeTimeExpressions = result.detectedDates
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
