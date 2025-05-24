//
//  SpeechRecognitionManager.swift
//  Talk_AI_Medicalassitant_3
//

import Speech
import AVFoundation
import Combine
import AudioToolbox

class SpeechRecognitionManager: ObservableObject {
    // MARK: - Published Properties
    @Published var transcribedText: String = ""
    @Published var isRecording: Bool = false
    @Published var error: Error? = nil
    @Published var displayError: DisplayError? = nil
    
    // MARK: - Public Properties
    let autoSendTrigger = PassthroughSubject<String, Never>()
    
    // MARK: - Private Properties
    private let audioEngine = AVAudioEngine()
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    // 音声認識の安定性を高めるためのプロパティ
    private let bufferSize: AVAudioFrameCount = 1024 * 4
    var currentText: String = ""
    
    // タイマー関連
    private var silenceTimer: Timer?
    private let silenceInterval: TimeInterval = 2.5
    private var lastTranscriptionTime: Date?
    
    // 状態管理
    var hasAutoSent: Bool = false
    
    // MARK: - Initialization
    init(locale: Locale = Locale(identifier: "ja-JP")) {
        self.speechRecognizer = SFSpeechRecognizer(locale: locale)
    }
    
    // Viewモジュール構築時に初期化して生成される対策
    func prepare() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    self?.speechRecognizer?.delegate = self as? SFSpeechRecognizerDelegate
                case .denied:
                    self?.displayError = DisplayError(message: "音声認識の権限が拒否されています", isCancelable: true, isMaintenance: true)

                case .restricted:
                    self?.displayError = DisplayError(message: "この端末では音声認識が制限されています", isCancelable: true)

                case .notDetermined:
                    self?.displayError = DisplayError(message: "音声認識の権限が未設定です", isCancelable: true, isMaintenance: true)

                @unknown default:
                    break
                }
            }
        }
    }
    
    // MARK: - Public Methods
    func startRecording() {
        debugLog("録音開始処理を開始")
        hasAutoSent = false
        resetSilenceTimer()
        resetRecognition()
        currentText = ""
        
        // 音を鳴らす
        playSound(id: 1256)
        
        do {
            try configureAudioSession()
        } catch {
            self.displayError = DisplayError(message: R.string.errorMessageSpeechRecognition, isCancelable: false)
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            self.displayError = DisplayError(message: "音声認識リクエストの作成に失敗しました", isCancelable: false)
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.taskHint = .dictation
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let errorDetail: NSError = error as NSError? {
                // 一部のエラーはスルー
                if !(errorDetail.code == 301 || errorDetail.code == 216 || errorDetail.code == 1110) {
                    self.displayError = DisplayError(message: R.string.errorMessageSpeechRecognition, isCancelable: false)
                    return
                }
                
            }
            
            if let result = result {
                DispatchQueue.main.async {
                    let newText = result.bestTranscription.formattedString
                    self.transcribedText = newText
                    /*
                    // 既存のテキストと新しい認識結果を結合
                    if !self.currentText.isEmpty {
                        self.transcribedText = "\(self.currentText) \(newText)"
                    } else {
                        self.transcribedText = newText
                    }
                    */
                    self.debugLog("新しいテキスト認識: \(newText)")
                    self.handleNewTranscription()
                }
            }
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            self.displayError = DisplayError(message: R.string.errorMessageSpeechRecognition, isCancelable: false)
            return
        }
        
        isRecording = true
        debugLog("録音開始完了")
    }
    
    func stopRecording() -> String {
        if (!isRecording) {
            return ""
        }
        debugLog("録音停止処理を開始")
        resetSilenceTimer()
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        playSound(id: 1255)
        isRecording = false
        let finalText = transcribedText
        
        // 自動送信されていない場合のみ、最終テキストを返す
        if !hasAutoSent && !finalText.isEmpty {
            debugLog("手動停止による送信テキスト: \(finalText)")
            return finalText
        }
        debugLog("送信テキストなし（自動送信済みまたは空）")
        return ""
    }
    
    func clearText() {
        transcribedText = ""
        hasAutoSent = false
        debugLog("テキストとフラグをクリア")
    }
    
    func acceptError() {
        self.displayError = nil
    }
    
    // MARK: - Private Methods
    private func handleNewTranscription() {
        lastTranscriptionTime = Date()
        resetSilenceTimer()
        
        // 新しいテキストがある場合のみタイマーを設定
        if !transcribedText.isEmpty {
            silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceInterval, repeats: false) { [weak self] _ in
                self?.handleSilenceTimeout()
            }
            debugLog("無音検出タイマーを設定: \(silenceInterval)秒")
        }
    }
    
    private func handleSilenceTimeout() {
        guard !hasAutoSent && !transcribedText.isEmpty else {
            debugLog("自動送信をスキップ（既に送信済みまたは空テキスト）")
            return
        }
        
        hasAutoSent = true
        debugLog("無音検出による自動送信: \(transcribedText)")
        playSound(id: 1004) // 自動送信時に音を鳴らす
        autoSendTrigger.send(transcribedText)
        
        resetSilenceTimer()
    }
    
    private func resetSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = nil
        debugLog("無音検出タイマーをリセット")
    }
    
    private func configureAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.mixWithOthers, .defaultToSpeaker])
            try audioSession.setActive(true)
        } catch {
            debugLog("Audio session setup error: \(error)")
        }
        debugLog("オーディオセッションを設定")
    }
    
    private func resetRecognition() {
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
    }
    
    private func playSound(id: SystemSoundID) {
        AudioServicesPlaySystemSound(id)
    }
    
    private func debugLog(_ message: String) {
        if Constants.devMode {
            print("🎤 [SpeechRecognition] \(message)")
        }
    }
}

