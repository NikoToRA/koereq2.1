//
//  SessionView.swift
//  Koereq
//
//  Created by Koereq Team on 2025/05/23.
//

import SwiftUI

struct SessionView: View {
    @EnvironmentObject var sessionStore: SessionStore
    @EnvironmentObject var recordingService: RecordingService
    @EnvironmentObject var sttService: STTService
    @EnvironmentObject var openAIService: OpenAIService
    @EnvironmentObject var storageService: StorageService
    @EnvironmentObject var qrService: QRService
    @EnvironmentObject var promptManager: PromptManager
    
    @State private var showingPromptSelector = false
    @State private var showingQRCode = false
    @State private var selectedPromptType: PromptType?
    @State private var currentAudioURL: URL?
    @State private var chatMessages: [ChatMessage] = []
    @State private var isProcessing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var lastAIResponse = ""
    @State private var inactivityTimer: Timer?
    
    @Environment(\.dismiss) private var dismiss
    
    private var activeSession: Session? {
        sessionStore.currentSession
    }
    
    var body: some View {
        ZStack {
            // メインコンテンツ
            VStack(spacing: 0) {
                // ヘッダー
                headerView
                
                // チャット画面
                chatView
                
                // 録音中のオーバーレイ (横帯)
                if recordingService.isRecording {
                    recordingOverlayContent
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // フッター（コントロール）
                footerView
            }
            
            // 処理中のオーバーレイ
            if isProcessing {
                processingOverlay
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            setupSession()
            startInactivityTimer()
        }
        .onDisappear {
            endSession()
        }
        .sheet(isPresented: $showingQRCode) {
            QRCodeView(content: lastAIResponse)
        }
        .alert("エラー", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("戻る")
                }
                .foregroundColor(.blue)
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text("セッション")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(formatSessionTime())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: endSession) {
                Text("終了")
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
    }
    
    private var chatView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(chatMessages) { message in
                        ChatBubbleView(message: message)
                            .id(message.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .onChange(of: chatMessages.count) { _ in
                if let lastMessage = chatMessages.last {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    private var footerView: some View {
        VStack(spacing: 0) {
            // プロンプト選択（アコーディオン）
            if showingPromptSelector {
                promptSelectorView
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // メインコントロール
            HStack(spacing: 16) {
                // AI生成ボタン
                Button(action: togglePromptSelector) {
                    HStack(spacing: 8) {
                        Image(systemName: "brain")
                        Text("AI生成")
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.purple)
                    .cornerRadius(25)
                }
                
                Spacer()
                
                // QRコード生成ボタン（AI応答後のみ表示）
                if !lastAIResponse.isEmpty {
                    Button(action: { showingQRCode = true }) {
                        Image(systemName: "qrcode")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.green)
                            .cornerRadius(22)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                
                // 録音ボタン
                Button(action: toggleRecording) {
                    Image(systemName: recordingService.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(recordingService.isRecording ? .red : .blue)
                        .scaleEffect(recordingService.isRecording ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: recordingService.isRecording)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
        }
    }
    
    private var promptSelectorView: some View {
        VStack(spacing: 8) {
            ForEach(promptManager.allPrompts, id: \.displayName) { promptType in
                Button(action: { selectPrompt(promptType) }) {
                    HStack {
                        Text(promptType.displayName)
                            .fontWeight(.medium)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: -1)
    }
    
    // 新しい録音オーバーレイの定義
    private var recordingOverlayContent: some View {
        HStack(spacing: 16) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 10, height: 10)
                    .scaleEffect(recordingService.isRecording ? 1.2 : 0.8)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: recordingService.isRecording)
                
                Text("REC")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            ProgressView(value: recordingService.recordingLevel, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: .green))
                .frame(height: 8) // ゲージの太さを調整
            
            Text(String(format: "%.0f%%", recordingService.recordingLevel * 100))
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 40, alignment: .trailing) // 幅と寄せを指定してレイアウト崩れを防ぐ
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10) // 上下のpaddingを少し増やす
        .background(Color.black.opacity(0.75)) // 背景を少し濃く
        // .cornerRadius(10) // VStackの一部なので角丸は不要と判断
        .frame(maxWidth: .infinity) // 横幅いっぱい
        // .padding(.horizontal) // frame(maxWidth: .infinity) と併用する場合、外側のVStackのpaddingと競合する可能性があるので削除
    }
    
    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                
                Text(sttService.isTranscribing ? "認識中..." : "AI生成中...")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Actions
    
    private func setupSession() {
        loadChatMessages()
    }
    
    private func loadChatMessages() {
        chatMessages.removeAll()
        
        guard let currentActiveSession = activeSession else {
            return
        }
        
        // トランスクリプトとAI応答を時系列で統合
        var allMessages: [(Date, ChatMessage)] = []
        
        for transcript in currentActiveSession.transcripts {
            let message = ChatMessage(
                content: transcript.text,
                isUser: true,
                timestamp: transcript.createdAt
            )
            allMessages.append((transcript.createdAt, message))
        }
        
        for response in currentActiveSession.aiResponses {
            let message = ChatMessage(
                content: response.content,
                isUser: false,
                timestamp: response.createdAt
            )
            allMessages.append((response.createdAt, message))
        }
        
        // 時系列でソート
        allMessages.sort { $0.0 < $1.0 }
        chatMessages = allMessages.map { $0.1 }
        
        if let lastAI = currentActiveSession.aiResponses.last {
            lastAIResponse = lastAI.content
        }
    }
    
    private func toggleRecording() {
        resetInactivityTimer()
        
        if recordingService.isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        currentAudioURL = recordingService.startRecording()
    }
    
    private func stopRecording() {
        guard let audioURL = recordingService.stopRecording() else { return }
        
        isProcessing = true
        
        Task {
            do {
                let transcription = try await sttService.transcribe(audioURL: audioURL)
                
                await MainActor.run {
                    // チャットにトランスクリプトを追加
                    let message = ChatMessage(content: transcription, isUser: true, timestamp: Date())
                    chatMessages.append(message)
                    
                    // セッションにトランスクリプトを保存
                    if let currentSession = activeSession {
                        sessionStore.addTranscript(transcription, to: currentSession)
                        print("[SessionView] stopRecording: activeSession.transcripts.count after addTranscript = \(currentSession.transcripts.count)")
                        if let lastTranscript = currentSession.transcripts.last {
                            print("[SessionView] stopRecording: last transcript added = \(lastTranscript.text)")
                        }
                    }
                    
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    showError(error.localizedDescription)
                    isProcessing = false
                }
            }
        }
    }
    
    private func togglePromptSelector() {
        resetInactivityTimer()
        withAnimation(.easeInOut(duration: 0.3)) {
            showingPromptSelector.toggle()
        }
    }
    
    private func selectPrompt(_ promptType: PromptType) {
        selectedPromptType = promptType
        showingPromptSelector = false
        generateAIResponse(promptType)
    }
    
    private func generateAIResponse(_ promptType: PromptType) {
        guard let currentActiveSession = activeSession else {
            showError("現在のセッションがアクティブではありません。")
            isProcessing = false
            return
        }

        print("[SessionView] generateAIResponse: Called with promptType = \(promptType.displayName)")
        print("[SessionView] generateAIResponse: session.transcripts.count before guard = \(currentActiveSession.transcripts.count)")
        if let firstTranscript = currentActiveSession.transcripts.first {
            print("[SessionView] generateAIResponse: first transcript in session = \(firstTranscript.text)")
        }

        guard !currentActiveSession.transcripts.isEmpty else {
            showError("音声記録がありません。まず音声を録音してください。")
            return
        }
        
        isProcessing = true
        
        Task {
            do {
                let response = try await openAIService.generateResponse(
                    prompt: promptType,
                    transcripts: currentActiveSession.transcripts
                )
                
                await MainActor.run {
                    // チャットにAI応答を追加
                    let message = ChatMessage(content: response, isUser: false, timestamp: Date())
                    chatMessages.append(message)
                    
                    // セッションにAI応答を保存
                    sessionStore.addAIResponse(response, promptType: promptType, to: currentActiveSession)
                    
                    lastAIResponse = response
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    showError(error.localizedDescription)
                    isProcessing = false
                }
            }
        }
    }
    
    private func endSession() {
        inactivityTimer?.invalidate()
        sessionStore.endCurrentSession()
        
        // Azure Blob Storageにアップロード
        if let currentSession = activeSession {
            Task {
                do {
                    let audioFiles = [currentAudioURL].compactMap { $0 }
                    try await storageService.uploadSession(currentSession, audioFiles: audioFiles)
                } catch {
                    print("Upload failed: \(error)")
                }
            }
        }
    }
    
    private func startInactivityTimer() {
        inactivityTimer = Timer.scheduledTimer(withTimeInterval: 1800, repeats: false) { _ in
            // 30分無操作で自動終了
            endSession()
            dismiss()
        }
    }
    
    private func resetInactivityTimer() {
        inactivityTimer?.invalidate()
        startInactivityTimer()
    }
    
    private func formatSessionTime() -> String {
        guard let currentActiveSession = activeSession else { return "N/A" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: currentActiveSession.startedAt)
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}

// MARK: - Chat Message Model

struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
}

// MARK: - Chat Bubble View

struct ChatBubbleView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer(minLength: 50)
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(message.isUser ? Color.blue : Color(.systemGray5))
                    .foregroundColor(message.isUser ? .white : .primary)
                    .cornerRadius(18)
                
                Text(formatTime(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
            
            if !message.isUser {
                Spacer(minLength: 50)
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    let previewSessionStore = SessionStore()
    let dummySession = Session()
    previewSessionStore.currentSession = dummySession
    
    return SessionView()
        .environmentObject(previewSessionStore)
        .environmentObject(RecordingService())
        .environmentObject(STTService())
        .environmentObject(OpenAIService())
        .environmentObject(StorageService())
        .environmentObject(QRService())
        .environmentObject(PromptManager())
}
