//
//  HomeView.swift
//  Koereq
//
//  Created by Koereq Team on 2025/05/23.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var sessionStore: SessionStore
    @EnvironmentObject var promptManager: PromptManager
    
    @State private var showingPromptManager = false
    @State private var showingUserDictionary = false
    @State private var navigateToNewSession = false
    
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
    
    var body: some View {
        HStack(spacing: 12) {
            // 日時表示
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
            
            // セッション情報
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(session.summary.isEmpty ? "音声記録セッション" : session.summary)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(2)
                    
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
                
                HStack(spacing: 12) {
                    Label("\(session.transcripts.count)", systemImage: "waveform")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Label("\(session.aiResponses.count)", systemImage: "brain")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if let endedAt = session.endedAt {
                        let duration = Int(endedAt.timeIntervalSince(session.startedAt) / 60)
                        Text("\(duration)分")
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
