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
    @State private var showingHelp = false
    @State private var showingMedicalGuide = false
    @State private var selectedPromptType: PromptType?
    @State private var currentAudioURL: URL?
    @State private var chatMessages: [ChatMessage] = []
    @State private var isProcessing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var lastAIResponse = ""
    
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
            
            // 医療記録ガイドオーバーレイ（フッターを除外）
            if showingMedicalGuide {
                VStack(spacing: 0) {
                    MedicalGuideOverlay(isShowing: $showingMedicalGuide)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .animation(.easeInOut(duration: 0.3), value: showingMedicalGuide)
                    
                    Spacer()
                        .frame(height: 120) // フッター分のスペースを確保
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            setupSession()
        }
        .onChange(of: activeSession?.id) {
            // セッションが変更された際にチャットメッセージを再読み込み
            loadChatMessages()
        }
        .onDisappear {
            endSession()
        }
        .sheet(isPresented: $showingQRCode) {
            QRCodeView(content: lastAIResponse)
        }
        .sheet(isPresented: $showingHelp) {
            HelpView()
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
            
            HStack(spacing: 12) {
                Button(action: { showingMedicalGuide = true }) {
                    Image(systemName: "list.clipboard")
                        .font(.title3)
                        .foregroundColor(.green)
                }
                
                Button(action: { showingHelp = true }) {
                    Image(systemName: "questionmark.circle")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                
                Button(action: endSession) {
                    Text("終了")
                        .foregroundColor(.red)
                }
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
            .onChange(of: chatMessages.count) {
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
                let rawTranscription = try await sttService.transcribe(audioURL: audioURL)
                
                // ユーザー辞書による変換を適用
                let processedTranscription = promptManager.processTextWithDictionary(rawTranscription)
                
                await MainActor.run {
                    // チャットに変換後のトランスクリプトを追加
                    let message = ChatMessage(content: processedTranscription, isUser: true, timestamp: Date())
                    chatMessages.append(message)
                    
                    // セッションに変換後のトランスクリプトを保存
                    if let currentSession = activeSession {
                        sessionStore.addTranscript(processedTranscription, to: currentSession)
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
        sessionStore.endCurrentSession()
        
        // Azure Blob Storageアップロード（現在は無効化済み - 24時間ローカルキャッシュを使用）
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

// MARK: - Help View

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // タイトル
                    VStack(alignment: .leading, spacing: 8) {
                        Text("音声入力ガイド")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("患者情報収集ガイド")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    // セクション1: 基本的な使い方
                    HelpSectionView(
                        icon: "mic.circle.fill",
                        iconColor: .blue,
                        title: "基本的な使い方",
                        content: """
                        1. 📱 マイクボタンをタップして録音開始
                        2. 🗣️ はっきりと話しかけてください、録音されています。
                        3. 🛑 マイクボタンを再度タップして録音終了
                        4. 🤖 AI生成ボタンで回答を生成できます
                        """
                    )
                    
                    // セクション2: 音声入力のコツ
                    HelpSectionView(
                        icon: "lightbulb.fill",
                        iconColor: .orange,
                        title: "音声入力のコツ",
                        content: """
                        🎯 はっきりと、ゆっくり話す
                        🔇 静かな環境で録音する
                        📱 デバイスを口から20-30cm離す
                        ⏸️ 句読点の位置で少し間を置く
                        🔤 専門用語は特にゆっくりと
                        """
                    )
                    
                    // セクション3: AI生成について
                    HelpSectionView(
                        icon: "brain",
                        iconColor: .purple,
                        title: "AI生成機能",
                        content: """
                        💬 録音した内容を基にAIが回答を生成
                        📝 要約、翻訳、文章作成など様々な用途
                        🎯 プロンプトを選択して用途を指定
                        📋 生成された内容はQRコードで共有可能
                        """
                    )
                    
                    // セクション4: 録音時の注意点
                    HelpSectionView(
                        icon: "exclamationmark.triangle.fill",
                        iconColor: .red,
                        title: "録音時の注意",
                        content: """
                        🔊 録音レベルが適切か確認してください
                        🎤 マイクが塞がれていないか確認
                        🔋 バッテリー残量にご注意ください
                        📶 安定したネットワーク環境で使用
                        ⏱️ 長時間の録音は分割することをお勧めします
                        """
                    )
                    
                    // セクション5: トラブルシューティング
                    HelpSectionView(
                        icon: "gear",
                        iconColor: .gray,
                        title: "よくある問題",
                        content: """
                        ❌ 音声が認識されない
                        → マイク権限を確認してください
                        
                        🌐 AI生成が失敗する
                        → ネットワーク接続を確認してください
                        
                        🔇 音が小さい
                        → デバイスに近づいて話してください
                        
                        ⚡ 処理が遅い
                        → しばらくお待ちください
                        """
                    )
                }
                .padding(20)
            }
            .navigationTitle("ヘルプ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Help Section View

struct HelpSectionView: View {
    let icon: String
    let iconColor: Color
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(iconColor)
                    .frame(width: 30)
                
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            
            Text(content)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 42)
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Medical Guide Overlay

struct MedicalGuideOverlay: View {
    @Binding var isShowing: Bool
    @State private var selectedCategory: MedicalCategory?
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 全画面の半透明背景（タップ＆スワイプ対応）
                Color.black.opacity(0.3)
                    .ignoresSafeArea(.all)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isShowing = false
                        }
                    }
                    .gesture(
                        // 背景での左右スワイプジェスチャー
                        DragGesture()
                            .onChanged { value in
                                // 左右スワイプの場合のみ反応
                                if abs(value.translation.width) > abs(value.translation.height) {
                                    dragOffset = value.translation.width
                                }
                            }
                            .onEnded { value in
                                let horizontalDistance = value.translation.width
                                let horizontalVelocity = abs(value.velocity.width)
                                
                                // 左右スワイプで消える（背景でも反応）
                                if abs(horizontalDistance) > 80 || horizontalVelocity > 400 {
                                    // ハプティクフィードバック
                                    let impact = UIImpactFeedbackGenerator(style: .medium)
                                    impact.impactOccurred()
                                    
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        isShowing = false
                                        dragOffset = 0
                                    }
                                } else {
                                    // 元の位置に戻る
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        dragOffset = 0
                                    }
                                }
                            }
                    )
                
                // メインオーバーレイ
                VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        // ドラッグハンドル
                        dragHandle
                        
                        // ヘッダー
                        overlayHeaderView
                        
                        // メインコンテンツ
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(MedicalCategory.allCases, id: \.self) { category in
                                    MedicalCategoryCard(
                                        category: category,
                                        isSelected: selectedCategory == category
                                    ) {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            selectedCategory = selectedCategory == category ? nil : category
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                        }
                    }
                    .frame(height: max(200, geometry.size.height * 0.7))
                    .background(Color(.systemBackground))
                    .medicalCornerRadius(20, corners: [.bottomLeft, .bottomRight])
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                    .offset(x: dragOffset, y: 0)
                    .gesture(
                        // メインコンテンツでの左右スワイプジェスチャー（優先度高）
                        DragGesture()
                            .onChanged { value in
                                // 左右スワイプの場合は横方向の移動を追跡
                                if abs(value.translation.width) > abs(value.translation.height) {
                                    dragOffset = value.translation.width
                                } else {
                                    // 上下方向は従来通り（下スワイプで閉じる）
                                    if value.translation.height > 50 {
                                        dragOffset = value.translation.height * 0.3 // 抵抗感を追加
                                    }
                                }
                            }
                            .onEnded { value in
                                let horizontalDistance = value.translation.width
                                let verticalDistance = value.translation.height
                                let horizontalVelocity = abs(value.velocity.width)
                                let verticalVelocity = abs(value.velocity.height)
                                
                                // 左右スワイプで消える（メイン機能）
                                if abs(horizontalDistance) > abs(verticalDistance) {
                                    if abs(horizontalDistance) > 80 || horizontalVelocity > 400 {
                                        // ハプティクフィードバック
                                        let impact = UIImpactFeedbackGenerator(style: .medium)
                                        impact.impactOccurred()
                                        
                                        // スワイプした方向に消える演出
                                        let exitDirection: CGFloat = horizontalDistance > 0 ? geometry.size.width + 100 : -geometry.size.width - 100
                                        
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            dragOffset = exitDirection
                                        }
                                        
                                        // 少し遅れてオーバーレイを閉じる
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                            isShowing = false
                                            dragOffset = 0
                                        }
                                    } else {
                                        // 元の位置に戻る
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            dragOffset = 0
                                        }
                                    }
                                }
                                // 下方向ドラッグで閉じる（補助機能）
                                else if verticalDistance > 120 || (verticalDistance > 60 && verticalVelocity > 500) {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        isShowing = false
                                        dragOffset = 0
                                    }
                                }
                                // 元の位置に戻る
                                else {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        dragOffset = 0
                                    }
                                }
                            }
                    )
                    
                    Spacer()
                        .frame(height: 120) // フッター分のスペースを確保
                }
            }
        }
    }
    
    private var dragHandle: some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.secondary.opacity(0.5))
                .frame(width: 36, height: 4)
            
            // ドラッグヒント（左右スワイプ用）
            Text("← 左右スワイプで閉じる →")
                .font(.caption2)
                .foregroundColor(.secondary.opacity(0.7))
                .padding(.top, 2)
        }
        .padding(.top, 8)
        .padding(.bottom, 6)
    }
    
    private var overlayHeaderView: some View {
        HStack {
            Button("✕ 閉じる") {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isShowing = false
                }
            }
            .foregroundColor(.blue)
            .font(.subheadline)
            .fontWeight(.medium)
            
            Spacer()
            
            Text("医療記録入力ガイド")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Spacer()
            
            // 操作ヒント
            Text("背景タップで閉じる")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
}

// MARK: - Medical Category Card

struct MedicalCategoryCard: View {
    let category: MedicalCategory
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // カテゴリヘッダー
            Button(action: onTap) {
                HStack {
                    HStack(spacing: 12) {
                        Image(systemName: category.icon)
                            .font(.title2)
                            .foregroundColor(category.color)
                            .frame(width: 30)
                        
                        Text(category.title)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isSelected ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .background(category.color.opacity(0.1))
                .medicalCornerRadius(12, corners: isSelected ? [.topLeft, .topRight] : .allCorners)
            }
            
            // 展開されたコンテンツ
            if isSelected {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(category.items, id: \.self) { item in
                        HStack(alignment: .top, spacing: 12) {
                            Circle()
                                .fill(category.color)
                                .frame(width: 6, height: 6)
                                .padding(.top, 8)
                            
                            Text(item)
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Spacer()
                        }
                    }
                }
                .padding(16)
                .background(Color(.systemGray6))
                .medicalCornerRadius(12, corners: [.bottomLeft, .bottomRight])
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Medical Category Model

enum MedicalCategory: CaseIterable {
    case basicInfo
    case medicalHistory
    case vitalSigns
    case physicalExam
    case diagnostics
    case treatment
    
    var title: String {
        switch self {
        case .basicInfo:
            return "基本情報"
        case .medicalHistory:
            return "病歴・既往歴"
        case .vitalSigns:
            return "バイタルサイン"
        case .physicalExam:
            return "身体所見"
        case .diagnostics:
            return "検査・診断"
        case .treatment:
            return "治療・方針"
        }
    }
    
    var icon: String {
        switch self {
        case .basicInfo:
            return "person.fill"
        case .medicalHistory:
            return "clock.fill"
        case .vitalSigns:
            return "waveform.path.ecg"
        case .physicalExam:
            return "stethoscope"
        case .diagnostics:
            return "doc.text.magnifyingglass"
        case .treatment:
            return "cross.case.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .basicInfo:
            return .blue
        case .medicalHistory:
            return .orange
        case .vitalSigns:
            return .green
        case .physicalExam:
            return .purple
        case .diagnostics:
            return .indigo
        case .treatment:
            return .pink
        }
    }
    
    var items: [String] {
        switch self {
        case .basicInfo:
            return [
                "年齢",
                "性別",
                "居住形態（独居・家族同居など）",
                "介護度（要支援・要介護など）",
                "ADL（日常生活動作の自立度）"
            ]
        case .medicalHistory:
            return [
                "主訴（今回の主な症状・問題）",
                "現病歴（症状の経過・変化）",
                "既往歴（過去の病気・手術歴）",
                "内服薬（現在服用中の薬剤名）",
                "生活歴（居住形態（施設など）、ADL、喫煙・飲酒）"
            ]
        case .vitalSigns:
            return [
                "意識レベルGCS（E, V, M）、瞳孔所見など",
                "血圧（収縮期/拡張期 mmHg）",
                "脈拍（回/分、リズム）",
                "SpO2（%、室内気または酸素下）",
                "酸素投与量（L/分、投与方法）",
                "呼吸数（回/分）",
                "体温（℃）"
            ]
        case .physicalExam:
            return [
                "外観・全身状態",
                "頭頸部所見",
                "胸部所見（心音・呼吸音）",
                "腹部所見",
                "四肢所見",
                "皮膚所見",
                "神経学的所見"
            ]
        case .diagnostics:
            return [
                "血液検査結果",
                "画像検査結果（X線・CT・MRIなど）",
                "心電図所見",
                "その他の検査結果",
                "診断名・病名",
                "病期・重症度"
            ]
        case .treatment:
            return [
                "治療方針・計画",
                "処方薬剤の変更",
                "処置・手技の実施",
                "患者・家族への説明内容",
                "今後の予定・フォローアップ",
                "注意事項・指導内容"
            ]
        }
    }
}

// MARK: - Extensions for Medical Guide

extension View {
    func medicalCornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(MedicalRoundedCorner(radius: radius, corners: corners))
    }
}

struct MedicalRoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    let dummySession = Session()
    
    SessionView()
        .environmentObject({
            let store = SessionStore()
            store.currentSession = dummySession
            return store
        }())
        .environmentObject(RecordingService())
        .environmentObject(STTService())
        .environmentObject(OpenAIService())
        .environmentObject(StorageService())
        .environmentObject(QRService())
        .environmentObject(PromptManager())
}
