//
//  SessionView.swift
//  Koereq
//
//  Created by Koereq Team on 2025/05/23.
//

import SwiftUI

// MARK: - 一時的なMedicalGuideManager実装
struct SimpleGuideSet: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var categories: [MedicalGuideCategory]
    var isDefault: Bool
    
    init(id: UUID = UUID(), name: String, description: String, categories: [MedicalGuideCategory], isDefault: Bool = false) {
        self.id = id
        self.name = name
        self.description = description
        self.categories = categories
        self.isDefault = isDefault
    }
}

class SimpleMedicalGuideManager: ObservableObject {
    @Published var guideSets: [SimpleGuideSet] = []
    @Published var selectedGuideSetId: UUID?
    
    private let userDefaults = UserDefaults.standard
    private let guideSetsKey = "simpleGuideSets"
    private let selectedGuideKey = "selectedSimpleGuideId"
    
    var selectedGuideSet: SimpleGuideSet? {
        guideSets.first { $0.id == selectedGuideSetId }
    }
    
    var currentCategories: [MedicalGuideCategory] {
        selectedGuideSet?.categories.filter { $0.isEnabled } ?? MedicalGuideCategory.defaultCategories
    }
    
    init() {
        // UserDefaultsをクリア（一時的）
        userDefaults.removeObject(forKey: guideSetsKey)
        userDefaults.removeObject(forKey: selectedGuideKey)
        
        loadGuideSets()
        loadSelectedGuide()
    }
    
    private func loadGuideSets() {
        // 一時的に強制的に新しいガイドセットを作成
        createDefaultGuideSets()
        
        // 以下は後で有効にする（今はコメントアウト）
        /*
        if let data = userDefaults.data(forKey: guideSetsKey),
           let decodedSets = try? JSONDecoder().decode([SimpleGuideSet].self, from: data) {
            guideSets = decodedSets
        } else {
            // 初回起動時はデフォルトを作成
            createDefaultGuideSets()
        }
        */
    }
    
    private func createDefaultGuideSets() {
        let emergencyNursingCategories = [
            MedicalGuideCategory(
                title: "ER経過観察記録",
                icon: "cross.case.fill",
                colorHex: "#FF2D55",
                items: [
                    "搬送（救急車）",
                    "妊娠",
                    "付き添い",
                    "持ち物",
                    "確認者",
                    "受け取り者",
                    "症候",
                    "経過",
                    "既往歴",
                    "アレルギー"
                ],
                order: 0
            ),
            MedicalGuideCategory(
                title: "入退院支援チェックリスト",
                icon: "house.fill",
                colorHex: "#007AFF",
                items: [
                    "キーパーソン",
                    "同居人の有無（あり／なし／記載なし）",
                    "住宅（自宅／施設）",
                    "生活環境（戸建て／集合住宅・段差利用）",
                    "ADL",
                    "各種手帳（身体障害／精神障害）",
                    "介護認定（あり／なし／申請中）",
                    "利用中のサービス",
                    "生活保護受給",
                    "職業",
                    "障害高齢者の日常生活自立度：\n• J1: 交通機関などを利用して外出\n• J2: 隣近所へなら外出\n• A1: 介助により外出し、日中はほとんどベッドから離れて生活\n• A2: 外出の頻度が少なく、日中寝たり起きたりの生活\n• B1: 車椅子に移乗し、食事、排泄はベッドから離れて行う\n• B2: 介助により車椅子に移乗\n• C1: 自力で寝返りをうつ\n• C2: 自力で寝返りがうてない",
                    "認知症高齢者の日常生活自立度：\n• Ⅰ: 自立\n• Ⅰa: 見守りが必要（家庭外）\n• Ⅰb: 見守りが必要（家庭内）\n• Ⅱa: 日中中心に日常生活に支障を来たすような行動・意思疎通の困難さ、介助が必要\n• Ⅱb: 夜間中心に日常生活に支障を来たすような行動・意思疎通の困難さ、介助が必要\n• Ⅲ: 日常生活に支障を来たすような行動・意思疎通の困難さが頻繁で、常に介助が必要\n• Ⅳ: 著しい精神症状や問題行動などがみられ、専門医療が必要"
                ],
                order: 1
            ),
            MedicalGuideCategory(
                title: "来院時評価",
                icon: "clock.fill",
                colorHex: "#FF9500",
                items: [
                    "来院時間",
                    "感染対策",
                    "第一印象（ショック兆候の有無）",
                    "蒼白、冷感、虚脱",
                    "脈拍触知不能、呼吸不全"
                ],
                order: 2
            ),
            MedicalGuideCategory(
                title: "一次評価（ABCDE）",
                icon: "waveform.path.ecg",
                colorHex: "#34C759",
                items: [
                    "A（気道）",
                    "B（呼吸）：呼吸数・SpO2・呼吸異常・補助筋使用",
                    "気管偏位・頸静脈怒張・呼吸音減弱",
                    "肺副雑音・皮下気腫",
                    "C（循環）：HR・BP・チアノーゼ・CRT",
                    "皮膚の湿潤・顔面蒼白",
                    "D（意識）：GCS E-V-M",
                    "E（体温）・四肢冷感・皮膚湿潤",
                    "QSOFA：スコア（0〜3）"
                ],
                order: 3
            ),
            MedicalGuideCategory(
                title: "感染スクリーニング",
                icon: "shield.fill",
                colorHex: "#AF52DE",
                items: [
                    "過去1ヶ月以内の感染歴（あり／なし）",
                    "過去3日以内の陽性者との接触（あり／なし）"
                ],
                order: 4
            ),
            MedicalGuideCategory(
                title: "初療確認事項",
                icon: "stethoscope",
                colorHex: "#5856D6",
                items: [
                    "移動方法",
                    "名前・生年月日確認",
                    "最終飲食",
                    "飲酒",
                    "喫煙",
                    "最終排泄"
                ],
                order: 5
            ),
            MedicalGuideCategory(
                title: "入院・帰宅前チェック",
                icon: "checklist",
                colorHex: "#FF9500",
                items: [
                    "入院・帰宅前チェックリスト確認",
                    "時系列記録まとめ",
                    "HH:MM 出来事（簡潔に記録）"
                ],
                order: 6
            )
        ]
        
        guideSets = [
            SimpleGuideSet(
                name: "一般医療",
                description: "一般的な医療記録に適用される標準的なガイド",
                categories: MedicalGuideCategory.defaultCategories,
                isDefault: true
            ),
            SimpleGuideSet(
                name: "救急看護",
                description: "救急外来での看護記録に特化したガイド（ER経過観察記録対応）",
                categories: emergencyNursingCategories,
                isDefault: false
            )
        ]
        saveGuideSets()
    }
    
    private func loadSelectedGuide() {
        if let savedIdString = userDefaults.string(forKey: selectedGuideKey),
           let savedId = UUID(uuidString: savedIdString) {
            selectedGuideSetId = savedId
        } else {
            // デフォルトを選択
            selectedGuideSetId = guideSets.first { $0.isDefault }?.id
        }
    }
    
    private func saveGuideSets() {
        if let encoded = try? JSONEncoder().encode(guideSets) {
            userDefaults.set(encoded, forKey: guideSetsKey)
        }
    }
    
    func selectGuideSet(_ guideSet: SimpleGuideSet) {
        selectedGuideSetId = guideSet.id
        userDefaults.set(guideSet.id.uuidString, forKey: selectedGuideKey)
        objectWillChange.send() // 変更を通知
    }
}

struct SessionView: View {
    @EnvironmentObject var sessionStore: SessionStore
    @EnvironmentObject var recordingService: RecordingService
    @EnvironmentObject var sttService: STTService
    @EnvironmentObject var openAIService: OpenAIService
    @EnvironmentObject var storageService: StorageService
    @EnvironmentObject var qrService: QRService
    @EnvironmentObject var promptManager: PromptManager
    @EnvironmentObject var simpleMedicalGuideManager: SimpleMedicalGuideManager
    
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
    @State private var showingUploadStatus = false
    @State private var uploadMessage = ""
    
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
            
            // アップロード状態オーバーレイ
            if showingUploadStatus {
                uploadStatusOverlay
            }
            
            // 医療記録ガイドオーバーレイ（フッターを除外）
            if showingMedicalGuide {
                VStack(spacing: 0) {
                    MedicalGuideOverlay(isShowing: $showingMedicalGuide, simpleMedicalGuideManager: simpleMedicalGuideManager)
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
        .onChange(of: storageService.isUploading) {
            handleUploadStatusChange()
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
            // 救急看護師専用ボタン（デフォルト）
            Button(action: { generateNursingResponse() }) {
                HStack {
                    Image(systemName: "cross.case.fill")
                        .foregroundColor(.pink)
                    Text("救急看護記録")
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.pink.opacity(0.1))
                .cornerRadius(8)
            }
            
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
    
    private var uploadStatusOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                // アップロード中の場合は進捗インジケーターを表示
                if storageService.isUploading {
                    ProgressView()
                        .scaleEffect(1.2)
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    
                    // 進捗パーセンテージ（0-100%）
                    if storageService.uploadProgress > 0 {
                        ProgressView(value: storageService.uploadProgress, total: 1.0)
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            .frame(width: 200)
                        
                        Text("\(Int(storageService.uploadProgress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    // 完了/エラー時のアイコン
                    Image(systemName: storageService.error != nil ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(storageService.error != nil ? .red : .green)
                }
                
                Text(uploadMessage)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 10)
        }
        .transition(.opacity)
        .animation(.easeInOut, value: showingUploadStatus)
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
                let dictionaryProcessedTranscription = promptManager.processTextWithDictionary(rawTranscription)
                
                // 相対時間変換を適用
                let relativeTimeResult = sttService.parseRelativeTimeFromText(dictionaryProcessedTranscription)
                let finalProcessedTranscription = relativeTimeResult.processedText
                
                await MainActor.run {
                    // チャットに最終変換後のトランスクリプトを追加
                    let message = ChatMessage(content: finalProcessedTranscription, isUser: true, timestamp: Date())
                    chatMessages.append(message)
                    
                    // セッションに最終変換後のトランスクリプトを保存
                    if let currentSession = activeSession {
                        sessionStore.addTranscript(finalProcessedTranscription, to: currentSession)
                        print("[SessionView] stopRecording: activeSession.transcripts.count after addTranscript = \(currentSession.transcripts.count)")
                        if let lastTranscript = currentSession.transcripts.last {
                            print("[SessionView] stopRecording: last transcript added = \(lastTranscript.text)")
                        }
                        
                        // デバッグ情報を出力
                        if !relativeTimeResult.detectedDates.isEmpty {
                            print("[SessionView] 検出された時間表現: \(relativeTimeResult.detectedDates.count)件")
                            for detectedDate in relativeTimeResult.detectedDates {
                                print("  - \(detectedDate.originalText) → 計算結果: \(detectedDate.calculatedDate)")
                            }
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
    
    private func generateNursingResponse() {
        guard let currentActiveSession = activeSession else {
            showError("現在のセッションがアクティブではありません。")
            isProcessing = false
            return
        }

        guard !currentActiveSession.transcripts.isEmpty else {
            showError("音声記録がありません。まず音声を録音してください。")
            return
        }
        
        isProcessing = true
        
        Task {
            do {
                // 救急看護師用プロンプトを使用
                let nursingPrompt = """
あなたは、看護師がテンプレートを見ながら音声で話した内容をもとに、医療記録を正確かつ簡潔に構造化する役割を担っています。

以下の自然文は、複数回に分けて音声で入力された内容の蓄積です。  
この情報をもとに、テンプレートの各項目に該当する情報を記入してください。

---

【出力ルール】

1. 入力文に該当する情報があるテンプレート項目は、簡潔に記載してください。
2. 入力文に該当する記述がまったく見当たらない場合、その項目は「*記載なし*」と明記してください（アスタリスクで囲ってください）。
3. 意識レベル（GCS）、呼吸数、収縮期血圧の3つがそろっている場合は、qSOFAスコア（0〜3）を自動で算出し、テンプレートの所定位置に記入してください。
4. 自然文中に「時刻（例：朝7時、10時半など）」と「それに紐づく出来事（例：発症、搬送、飲食、来院など）」が含まれていれば、それらを抽出して時刻順に並べ、テンプレート末尾に「■時系列記録まとめ：」として出力してください。
5. 入力に含まれない内容を推測・補完しないでください。現場の安全性を重視してください。

---

【自然文（音声入力内容）】
{transcript}

---

【出力テンプレート構造】

◆ER経過観察記録◆  
- 搬送（救急車）：  
- 妊娠：  
- 付き添い：  
- 【持ち物】：  
- 確認者：  
- 受け取り者：  
- 【症候】：  
- 【経過】：  
- 【既往歴】：  
- 【アレルギー】：  

＜入退院支援チェックリスト＞  
- 【キーパーソン】：  
- 【同居人の有無】：あり／なし／*記載なし*  
- 【住宅】：自宅／施設（施設形態：）／*記載なし*  
- 【生活環境】：戸建て／集合住宅 段の利用：あり／なし／*記載なし*  
- [ADL]：  
- 【各種手帳】：あり（身体障害／精神障害）／なし／*記載なし*  
- 【介護認定】：あり／なし／申請中（事業所名／ケアマネジャー：）／*記載なし*  
- 【利用中のサービス】：あり（内容）／なし／*記載なし*  
- 【生活保護受給】：あり／なし／*記載なし*  
　- 担当区：  
　- 担当者：  
- 【職業】：  
- 【障害高齢者の日常生活自立度】：
　（J1:交通機関利用外出／J2:隣近所外出／A1:介助外出・日中ベッド離れ／A2:外出少・寝起き生活／B1:車椅子移乗・ベッド離れ食事排泄／B2:介助車椅子移乗／C1:自力寝返り／C2:寝返り不可）  
- 【認知症高齢者の日常生活自立度】：
　（Ⅰ:自立／Ⅰa:見守り必要家庭外／Ⅰb:見守り必要家庭内／Ⅱa:日中問題行動・介助必要／Ⅱb:夜間問題行動・介助必要／Ⅲ:日常的問題行動・常時介助／Ⅳ:著しい精神症状・専門医療必要）  
- 来院時間：  
- 【感染対策】：  
- 第一印象（ショック兆候）：あり／なし（蒼白、冷感、虚脱、脈拍触知不能、呼吸不全）

■一次評価  
- A（気道）：  
- B（呼吸）：呼吸数　回/分 SpO2= %  
　- 呼吸異常：あり／なし  
　- 補助筋使用：あり／なし  
　- 気管偏位：あり／なし  
　- 頸静脈怒張：あり／なし  
　- 呼吸音減弱：あり／なし  
　- 肺副雑音：あり／なし  
　- 皮下気腫：あり／なし  
- C（循環）：HR　回/分、BP　mmHg  
　- チアノーゼ：あり／なし  
　- CRT：〇秒  
　- 皮膚の湿潤：あり／なし  
　- 顔面蒼白：あり／なし  
- D（意識）：GCS E V M 合計 M  
- E（体温）：〇°C  
　- 四肢冷感：あり／なし  
　- 皮膚湿潤：あり／なし  
- QSOFA：スコア（0〜3）

【新型コロナウイルススクリーニング】  
- 過去1ヶ月以内の感染歴：あり／なし  
- 過去3日以内の陽性者との接触：あり／なし  

■初療  
- 移動方法：  
- 名前・生年月日確認：  
- 最終飲食：  
- 飲酒：  
- 喫煙：  
- 最終排泄：  

【入院・帰宅前チェックリスト】：  

---

■時系列記録まとめ：  
- HH:MM　出来事（できるだけ簡潔に）
"""
                
                let response = try await openAIService.generateNursingResponse(
                    prompt: nursingPrompt,
                    transcripts: currentActiveSession.transcripts
                )
                
                await MainActor.run {
                    // チャットにAI応答を追加
                    let message = ChatMessage(content: response, isUser: false, timestamp: Date())
                    chatMessages.append(message)
                    
                    // セッションにAI応答を保存（救急看護記録として）
                    sessionStore.addNursingResponse(response, to: currentActiveSession)
                    
                    lastAIResponse = response
                    isProcessing = false
                    showingPromptSelector = false // モーダルを閉じる
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
        // 録音が進行中の場合は停止
        if recordingService.isRecording {
            stopRecording()
        }
        
        // セッション終了処理（SessionStoreで自動的にAzureアップロードが実行される）
        sessionStore.endCurrentSession()
        
        print("[SessionView] Session ended and Azure upload initiated")
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
    
    private func handleUploadStatusChange() {
        if storageService.isUploading {
            uploadMessage = "セッションデータをAzureにアップロード中..."
            showingUploadStatus = true
        } else {
            if storageService.error != nil {
                uploadMessage = "アップロードに失敗しました"
            } else {
                uploadMessage = "アップロード完了"
            }
            
            // 2秒後に状態表示を隠す
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                showingUploadStatus = false
            }
        }
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
    let simpleMedicalGuideManager: SimpleMedicalGuideManager
    @State private var selectedCategory: MedicalGuideCategory?
    @State private var dragOffset: CGFloat = 0
    @State private var showingGuideSelection = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 全画面の半透明背景
                Color.black.opacity(0.3)
                    .ignoresSafeArea(.all)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isShowing = false
                        }
                    }
                
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
                                ForEach(simpleMedicalGuideManager.currentCategories) { category in
                                    MedicalCategoryCard(
                                        category: category,
                                        isSelected: selectedCategory?.id == category.id
                                    ) {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            selectedCategory = selectedCategory?.id == category.id ? nil : category
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
                    
                    Spacer()
                        .frame(height: 120) // フッター分のスペースを確保
                }
            }
        }
        .sheet(isPresented: $showingGuideSelection) {
            MedicalGuideManagerView()
        }
    }
    
    
    private var dragHandle: some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.secondary.opacity(0.5))
                .frame(width: 36, height: 4)
        }
        .padding(.top, 8)
        .padding(.bottom, 6)
    }
    
    private var overlayHeaderView: some View {
        VStack(spacing: 8) {
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
                
                VStack(spacing: 2) {
                    Text("医療記録入力ガイド")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("現在: \(simpleMedicalGuideManager.selectedGuideSet?.name ?? "一般医療")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // ガイド変更ボタン
                Button("変更") {
                    showingGuideSelection = true
                }
                .foregroundColor(.blue)
                .font(.caption)
            }
            
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
    let category: MedicalGuideCategory
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
