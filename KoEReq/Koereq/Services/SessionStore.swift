//
//  SessionStore.swift
//  Koereq
//
//  Created by Koereq Team on 2025/05/23.
//

import Foundation
// import CoreData // コメントアウト

class SessionStore: ObservableObject {
    @Published var sessions: [Session] = []
    @Published var currentSession: Session?
    @Published var isLoading = false
    @Published var error: Error?
    
    // private let container: NSPersistentContainer // コメントアウト
    private let userManager = UserManager() // これは残すか、使い方に応じて検討
    
    init() {
        // container = NSPersistentContainer(name: "Koereq") // コメントアウト
        // container.loadPersistentStores { _, error in // コメントアウト
        //     if let error = error { // コメントアウト
        //         print("Core Data failed to load: \(error.localizedDescription)") // コメントアウト
        //     } // コメントアウト
        // } // コメントアウト
        // loadSessions() // コメントアウト (メモリ上のデータで初期化する場合は別途実装)
        print("SessionStore initialized (CoreData disabled)") // 初期化確認用
    }
    
    // MARK: - Session Management
    
    func createNewSession() -> Session {
        let newSession = Session() // id, startedAt は自動
        currentSession = newSession
        sessions.insert(newSession, at: 0)
        // saveSession(newSession) // CoreData保存処理はコメントアウト
        print("New session created: \(newSession.id)")
        return newSession
    }
    
    func endCurrentSession() {
        guard var session = currentSession else { return }
        
        session.endedAt = Date()
        session.summary = generateSessionSummary(session)
        
        // updateSession(session) // CoreData更新処理はコメントアウト
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session // メモリ上の配列を更新
        }
        print("Session ended: \(session.id)")
        currentSession = nil
    }
    
    func addTranscript(_ text: String, to session: Session) { // session引数はcurrentSessionを使うなら不要かも
        guard var updatedSession = currentSession else { return }
        
        let transcript = TranscriptChunk(
            // id: UUID(), // Session構造体側でUUID()がデフォルトなら不要
            text: text,
            // createdAt: Date(), // Session構造体側でDate()がデフォルトなら不要
            sequence: updatedSession.transcripts.count + 1
        )
        
        updatedSession.transcripts.append(transcript)
        
        // currentSession を更新してUIに反映させる
        if let index = sessions.firstIndex(where: { $0.id == updatedSession.id }) {
            sessions[index] = updatedSession
        }
        currentSession = updatedSession // これも重要
        
        // updateSession(updatedSession) // CoreData更新処理はコメントアウト
        print("Transcript added to session: \(updatedSession.id)")
    }
    
    func addAIResponse(_ content: String, promptType: PromptType, to session: Session) { // session引数はcurrentSessionを使うなら不要かも
        guard var updatedSession = currentSession else { return }
        
        let response = AIResponse(
            // id: UUID(),
            content: content,
            promptType: promptType,
            // createdAt: Date(),
            sequence: updatedSession.aiResponses.count + 1
        )
        
        updatedSession.aiResponses.append(response)

        if let index = sessions.firstIndex(where: { $0.id == updatedSession.id }) {
            sessions[index] = updatedSession
        }
        currentSession = updatedSession

        // updateSession(updatedSession) // CoreData更新処理はコメントアウト
        print("AI Response added to session: \(updatedSession.id)")
    }
    
    // MARK: - Core Data Operations (すべてコメントアウト)
    /*
    private func saveSession(_ session: Session) {
        // ... (既存のCoreData保存処理) ...
    }
    
    private func updateSession(_ session: Session) {
        // ... (既存のCoreData更新処理) ...
    }
    
    private func loadSessions() {
        // ... (既存のCoreData読み込み処理) ...
        // isLoading = true
        // sessions = [] // メモリのみの場合は空で初期化など
        // isLoading = false
    }
    
    private func convertToSession(_ entity: SessionEntity) -> Session? {
        // ... (既存の変換処理) ...
        return nil // 仮
    }
    
    private func saveContext() {
        // ... (既存のCoreData保存処理) ...
    }
    */
    
    private func generateSessionSummary(_ session: Session) -> String {
        // これはCoreDataに依存しないのでそのまま使える
        let transcriptCount = session.transcripts.count
        let responseCount = session.aiResponses.count
        
        if transcriptCount == 0 && responseCount == 0 {
            return "空のセッション"
        }
        
        let duration = session.endedAt?.timeIntervalSince(session.startedAt) ?? 0
        let minutes = Int(duration / 60)
        
        return "音声記録: \(transcriptCount)件, AI応答: \(responseCount)件 (約\(minutes)分)"
    }
}

// Session, TranscriptChunk, AIResponse 構造体の定義はそのまま利用
// (CoreDataとは独立したデータ構造として)

// MARK: - Session Extensions

extension Session {
    init(id: UUID, startedAt: Date, endedAt: Date?, summary: String, transcripts: [TranscriptChunk], aiResponses: [AIResponse]) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.summary = summary
        self.transcripts = transcripts
        self.aiResponses = aiResponses
    }
}

extension TranscriptChunk {
    init(id: UUID, text: String, createdAt: Date, sequence: Int) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
        self.sequence = sequence
    }
}

extension AIResponse {
    init(id: UUID, content: String, promptType: PromptType, createdAt: Date, sequence: Int) {
        self.id = id
        self.content = content
        self.promptType = promptType
        self.createdAt = createdAt
        self.sequence = sequence
    }
}
