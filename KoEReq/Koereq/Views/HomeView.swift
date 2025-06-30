//
//  HomeView.swift
//  Koereq
//
//  Created by Koereq Team on 2025/05/23.
//

import SwiftUI

// MARK: - Simple Guide Selection View
struct SimpleGuideSelectionView: View {
    @EnvironmentObject var simpleMedicalGuideManager: SimpleMedicalGuideManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(simpleMedicalGuideManager.guideSets) { guideSet in
                        SimpleGuideRow(
                            guideSet: guideSet,
                            isSelected: simpleMedicalGuideManager.selectedGuideSetId == guideSet.id
                        ) {
                            simpleMedicalGuideManager.selectGuideSet(guideSet)
                        }
                    }
                } header: {
                    Text("利用可能なガイド")
                } footer: {
                    Text("使用したいガイドセットを選択してください。セッション中の医療ガイドが変更されます。")
                        .font(.caption)
                }
            }
            .navigationTitle("医療ガイド設定")
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

struct SimpleGuideRow: View {
    let guideSet: SimpleGuideSet
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(guideSet.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if guideSet.isDefault {
                            Text("デフォルト")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(guideSet.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(guideSet.categories.count)個のカテゴリー")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.8))
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct HomeView: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var sessionStore: SessionStore
    @EnvironmentObject var promptManager: PromptManager
    
    @State private var showingPromptManager = false
    @State private var showingUserDictionary = false
    @State private var showingMedicalGuideManager = false
    @State private var navigateToNewSession = false
    @State private var showingAzureStatus = false
    @State private var azureConnectionStatus = "未確認"
    @State private var isTestingAzure = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // ヘッダー
                headerView
                
                // メインコンテンツ
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // セッション一覧
                        if sessionStore.sessions.isEmpty {
                            emptyStateView
                        } else {
                            sessionListView
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20) // newSessionButtonがヘッダー下にあった時のpadding
                }
                .refreshable {
                    // セッション一覧を更新
                    sessionStore.reloadSessions()
                }
                
                // 新規セッション開始ボタン (画面下部に移動)
                newSessionButton
                    .padding(.horizontal) // 左右のパディングを追加
                    .padding(.bottom)    // 下部のパディングを追加
            }
            .navigationBarHidden(true)
            .onAppear {
                sessionStore.reloadSessions()
            }
            .navigationDestination(isPresented: $navigateToNewSession) {
                SessionView()
            }
            .navigationDestination(for: Session.self) { selectedSessionInLink in
                SessionViewWrapper(sessionToSet: selectedSessionInLink)
            }
        }
        .sheet(isPresented: $showingPromptManager) {
            PromptManagerView()
        }
        .sheet(isPresented: $showingUserDictionary) {
            UserDictionaryView()
        }
        .sheet(isPresented: $showingMedicalGuideManager) {
            SimpleGuideSelectionView()
        }
        .alert("Azure Storage 保存状況", isPresented: $showingAzureStatus) {
            Button("OK") { }
        } message: {
            if azureConnectionStatus == "接続成功" {
                Text("Azure Storage への保存機能は正常に動作しています。\nセッション終了時にデータが自動保存されます。")
            } else {
                Text("Azure Storage への接続に失敗しました。\nネットワークまたは設定をご確認ください。\n\nデータは24時間のローカルキャッシュに保存されます。")
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            // ログアウトボタン
            Button(action: logout) {
                HStack(spacing: 4) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("ログアウト")
                        .font(.caption)
                }
                .foregroundColor(.red)
            }
            
            Spacer()
            
            // タイトル
            VStack(spacing: 2) {
                Text("Koereq v2.1")
                    .font(.headline)
                    .fontWeight(.bold)
                
                if let user = userManager.currentUser {
                    Text(user.facilityName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // 設定ボタン群
            HStack(spacing: 12) {
                Button(action: { showingUserDictionary = true }) {
                    VStack(spacing: 2) {
                        Image(systemName: "text.bubble")
                        Text("変換辞書")
                            .font(.caption2)
                    }
                    .foregroundColor(.blue)
                }
                
                Button(action: { showingPromptManager = true }) {
                    VStack(spacing: 2) {
                        Image(systemName: "text.bubble")
                        Text("プロンプト")
                            .font(.caption2)
                    }
                    .foregroundColor(.blue)
                }
                
                Button(action: { showingMedicalGuideManager = true }) {
                    VStack(spacing: 2) {
                        Image(systemName: "list.clipboard")
                        Text("医療ガイド")
                            .font(.caption2)
                    }
                    .foregroundColor(.blue)
                }
                
                Button(action: testAzureConnection) {
                    VStack(spacing: 2) {
                        if isTestingAzure {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: azureConnectionStatus == "接続成功" ? "cloud.fill" : "cloud")
                        }
                        Text("保存状況")
                            .font(.caption2)
                    }
                    .foregroundColor(azureConnectionStatus == "接続成功" ? .green : 
                                   azureConnectionStatus == "接続失敗" ? .red : .gray)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
    }
    
    private var newSessionButton: some View {
        Button(action: startNewSession) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("新規セッション開始")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("音声記録を開始します")
                        .font(.caption)
                        .opacity(0.8)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .opacity(0.6)
            }
            .foregroundColor(.white)
            .padding(20)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [.blue, .blue.opacity(0.8)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("セッションがありません")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("新規セッションを開始して\n音声記録を始めましょう")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
    }
    
    private var sessionListView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最近のセッション")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 4)
            
            ForEach(sessionStore.sessions) { session in
                NavigationLink(value: session) {
                    SessionCardView(session: session)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private func startNewSession() {
        let session = sessionStore.createNewSession()
        sessionStore.currentSession = session
        self.navigateToNewSession = true
    }
    
    private func logout() {
        userManager.logout()
    }
    
    private func testAzureConnection() {
        isTestingAzure = true
        azureConnectionStatus = "接続中"
        
        Task {
            do {
                let isConnected = try await sessionStore.testAzureConnection()
                await MainActor.run {
                    azureConnectionStatus = isConnected ? "接続成功" : "接続失敗"
                    isTestingAzure = false
                    showingAzureStatus = true
                }
            } catch {
                await MainActor.run {
                    azureConnectionStatus = "接続失敗"
                    isTestingAzure = false
                    showingAzureStatus = true
                    print("[HomeView] Azure connection test failed: \(error)")
                }
            }
        }
    }
}

struct SessionViewWrapper: View {
    @EnvironmentObject var sessionStore: SessionStore
    let sessionToSet: Session

    var body: some View {
        SessionView()
            .onAppear {
                sessionStore.currentSession = sessionToSet
                // セッション設定後にUIの更新をトリガー
                sessionStore.objectWillChange.send()
            }
    }
}

struct SessionCardView: View {
    let session: Session
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter
    }
    
    // 転写内容から患者情報を抽出
    private func extractPatientInfo() -> String {
        let transcriptText = session.transcripts.map { $0.text }.joined(separator: " ")
        
        if transcriptText.isEmpty {
            return "記録なし"
        }
        
        // より詳細な医療キーワード
        let patientKeywords = [
            // 年齢・性別
            "歳", "才", "男性", "女性", "男", "女", "歳の", "才の",
            // 主訴・症状
            "痛い", "痛み", "熱", "発熱", "咳", "頭痛", "腹痛", "胸痛", "息苦しい", "呼吸困難",
            "めまい", "吐き気", "嘔吐", "下痢", "便秘", "しびれ", "腫れ", "かゆみ", "発疹",
            "じんましん", "アレルギー", "風邪", "インフルエンザ", "高血圧", "糖尿病",
            // 部位
            "頭", "首", "肩", "胸", "背中", "腰", "腹", "お腹", "手", "足", "膝", "関節",
            "心臓", "肺", "胃", "肝臓", "腎臓", "喉", "目", "耳", "鼻",
            // 診療情報
            "初診", "再診", "緊急", "救急", "外来", "紹介", "検査", "診断", "薬", "処方",
            "血圧", "体温", "脈拍", "血糖値", "検査結果"
        ]
        
        // キーワードを含む文を優先度付きで抽出
        let sentences = transcriptText.components(separatedBy: CharacterSet(charactersIn: "。！？\n"))
        var patientInfo: [String] = []
        var symptomInfo: [String] = []
        
        for sentence in sentences {
            let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.count < 5 { continue } // 短すぎる文は除外
            
            // 年齢・性別情報を優先
            if (trimmed.contains("歳") || trimmed.contains("才") || 
                trimmed.contains("男性") || trimmed.contains("女性")) && 
               patientInfo.count < 1 {
                let shortText = String(trimmed.prefix(25))
                patientInfo.append(shortText + (trimmed.count > 25 ? "..." : ""))
                continue
            }
            
            // 症状・主訴情報
            for keyword in patientKeywords {
                if trimmed.contains(keyword) && symptomInfo.count < 1 {
                    let shortText = String(trimmed.prefix(35))
                    if !symptomInfo.contains(where: { $0.contains(shortText.prefix(15)) }) {
                        symptomInfo.append(shortText + (trimmed.count > 35 ? "..." : ""))
                    }
                    break
                }
            }
            
            if patientInfo.count >= 1 && symptomInfo.count >= 1 {
                break
            }
        }
        
        // 結果をまとめる
        var result: [String] = []
        result.append(contentsOf: patientInfo)
        result.append(contentsOf: symptomInfo)
        
        if result.isEmpty {
            // キーワードがない場合は最初の意味のある文を表示
            for sentence in sentences {
                let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.count >= 10 { // 10文字以上の文
                    return String(trimmed.prefix(40)) + (trimmed.count > 40 ? "..." : "")
                }
            }
            return "音声記録あり"
        }
        
        return result.joined(separator: " / ")
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // 日時表示（維持）
            VStack(spacing: 4) {
                Text(dateFormatter.string(from: session.startedAt))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                
                Text(timeFormatter.string(from: session.startedAt))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 40)
            
            // 患者情報メイン表示
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("患者情報")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if session.endedAt == nil {
                        Text("進行中")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                    }
                }
                
                // 患者の特徴的情報を表示
                Text(extractPatientInfo())
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
                // 記録数のみ表示（時間情報削除）
                HStack(spacing: 12) {
                    Label("\(session.transcripts.count)件記録", systemImage: "waveform")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if session.aiResponses.count > 0 {
                        Label("\(session.aiResponses.count)件応答", systemImage: "brain")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.6))
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }
}

#Preview {
    HomeView()
        .environmentObject(UserManager())
        .environmentObject(SessionStore())
        .environmentObject(PromptManager())
}
