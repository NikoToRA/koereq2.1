//
//  RecordingService.swift
//  Koereq
//
//  Created by Koereq Team on 2025/05/23.
//

import Foundation
import AVFoundation

class RecordingService: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordingLevel: Float = 0.0
    
    private var audioRecorder: AVAudioRecorder?
    private var recordingSession: AVAudioSession = AVAudioSession.sharedInstance()
    private var levelTimer: Timer?
    
    override init() {
        super.init()


        setupRecordingSession()
    }
    
    private func setupRecordingSession() {
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            
            if #available(iOS 17.0, *) {
                AVAudioApplication.requestRecordPermission {
                    [weak self] allowed in
                    DispatchQueue.main.async {
                        if !allowed {
                            print("Recording permission denied")
                        }
                    }
                }
            } else {
                recordingSession.requestRecordPermission { [weak self] allowed in
                    DispatchQueue.main.async {
                        if !allowed {
                            print("Recording permission denied")
                        }
                    }
                }
            }
        } catch {
            print("Failed to setup recording session: \(error)")
        }
    }
    
    func startRecording() -> URL? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documentsPath.appendingPathComponent("voice_\(Date().timeIntervalSince1970).m4a")
        print("[RecordingService] Attempting to record to: \(audioFilename.path)")

        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            
            isRecording = true
            startLevelMonitoring()
            print("[RecordingService] Recording started successfully.")
            return audioFilename
        } catch {
            print("[RecordingService] Could not start recording: \(error)")
            DispatchQueue.main.async { // Ensure UI updates on main thread
                self.isRecording = false
                self.stopLevelMonitoring() // Stop monitoring if start fails
            }
            return nil
        }
    }
    
    func stopRecording() -> URL? {
        guard let recorder = audioRecorder else {
            print("[RecordingService] Stop recording called but recorder is nil.")
            return nil
        }
        
        // Check if already stopped to prevent issues, though delegate should handle state
        if !recorder.isRecording && !self.isRecording {
             print("[RecordingService] Stop recording called but recorder was not recording or already stopped.")
             return recorder.url
        }

        // Actual stop call should ideally be synchronous with state updates
        // However, the delegate handles the final state update.
        // If isRecording is true here, we expect the delegate to be called.
        recorder.stop()
        
        // Log immediately, but final state is set by delegate
        print("[RecordingService] recorder.stop() called. File URL: \(recorder.url.path). Waiting for delegate.")
        
        // File size check can be done here or in delegate
        // For immediate feedback:
        do {
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: recorder.url.path)
            if let fileSize = fileAttributes[FileAttributeKey.size] as? NSNumber {
                print("[RecordingService] Tentative recorded file size: \(fileSize.uint64Value) bytes (final size may vary until delegate confirms)")
            }
        } catch {
            print("[RecordingService] Could not get file attributes immediately after stop: \(error)")
        }
        
        return recorder.url
    }
    
    private func startLevelMonitoring() {
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let recorder = self.audioRecorder else { return }
            
            recorder.updateMeters()
            let level = recorder.averagePower(forChannel: 0)
            let normalizedLevel = max(0, (level + 80) / 80) // Normalize -80 to 0 dB to 0-1
            
            DispatchQueue.main.async {
                self.recordingLevel = normalizedLevel
            }
        }
    }
    
    private func stopLevelMonitoring() {
        levelTimer?.invalidate()
        levelTimer = nil
        recordingLevel = 0.0
    }
}

extension RecordingService: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isRecording = false // Update published property
            self.stopLevelMonitoring() // Stop UI updates for level
            if flag {
                print("[RecordingService] audioRecorderDidFinishRecording: Successfully. Final file URL: \(recorder.url.path)")
                do {
                    let fileAttributes = try FileManager.default.attributesOfItem(atPath: recorder.url.path)
                    if let fileSize = fileAttributes[FileAttributeKey.size] as? NSNumber {
                        print("[RecordingService] Final recorded file size: \(fileSize.uint64Value) bytes")
                    }
                } catch {
                    print("[RecordingService] Could not get final file attributes: \(error)")
                }
            } else {
                print("[RecordingService] audioRecorderDidFinishRecording: Failed. File URL: \(recorder.url.path)")
            }
        }
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        DispatchQueue.main.async {
            self.isRecording = false // Update published property
            self.stopLevelMonitoring() // Stop UI updates for level
            if let error = error {
                print("[RecordingService] audioRecorderEncodeErrorDidOccur: \(error.localizedDescription). File URL: \(recorder.url.path)")
            } else {
                print("[RecordingService] audioRecorderEncodeErrorDidOccur: Unknown error. File URL: \(recorder.url.path)")
            }
        }
    }
}
