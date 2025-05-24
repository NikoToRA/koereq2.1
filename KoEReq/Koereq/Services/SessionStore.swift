//
//  SessionStore.swift
//  Koereq
//
//  Created by Koereq Team on 2025/05/23.
//

import Foundation
import UIKit

class SessionStore: ObservableObject {
    @Published var sessions: [Session] = []
    @Published var currentSession: Session?
    @Published var isLoading = false
    @Published var error: Error?
    
    private let userDefaults = UserDefaults.standard
    private let sessionsKey = "cachedSessions"
    private var cleanupTimer: Timer?
    
    init() {
        // 24時間ごとのクリーンアップタイマーを設定
        self.cleanupTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            self?.cleanupOldData()
        }
        
        loadSessions()
        cleanupOldData() // 起動時にも古いデータをクリーンアップ
        
        // バックグラウンドから復帰時のクリーンアップ
        setupBackgroundCleanup()
        
        print("SessionStore initialized with 24-hour cache system")
    }
    
    deinit {
        cleanupTimer?.invalidate()
    }
    
    // MARK: - Session Management
    
    func createNewSession() -> Session {
        let newSession = Session() // id, startedAt は自動
        currentSession = newSession
        sessions.insert(newSession, at: 0)
        saveSessions()
        print("New session created: \(newSession.id)")
        return newSession
    }
    
    func endCurrentSession() {
        guard var session = currentSession else { return }
        
        session.endedAt = Date()
        session.summary = generateSessionSummary(session)
        
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
        }
        saveSessions()
        print("Session ended: \(session.id)")
        currentSession = nil
    }
    
    func addTranscript(_ text: String, to session: Session) {
        guard var updatedSession = currentSession else { return }
        
        let transcript = TranscriptChunk(
            text: text,
            sequence: updatedSession.transcripts.count + 1
        )
        
        updatedSession.transcripts.append(transcript)
        
        if let index = sessions.firstIndex(where: { $0.id == updatedSession.id }) {
            sessions[index] = updatedSession
        }
        currentSession = updatedSession
        saveSessions()
        print("Transcript added to session: \(updatedSession.id)")
    }
    
    func addAIResponse(_ content: String, promptType: PromptType, to session: Session) {
        guard var updatedSession = currentSession else { return }
        
        let response = AIResponse(
            content: content,
            promptType: promptType,
            sequence: updatedSession.aiResponses.count + 1
        )
        
        updatedSession.aiResponses.append(response)

        if let index = sessions.firstIndex(where: { $0.id == updatedSession.id }) {
            sessions[index] = updatedSession
        }
        currentSession = updatedSession
        saveSessions()
        print("AI Response added to session: \(updatedSession.id)")
    }
    
    // MARK: - Local Storage Operations
    
    private func saveSessions() {
        do {
            let data = try JSONEncoder().encode(sessions)
            userDefaults.set(data, forKey: sessionsKey)
            print("Sessions saved to UserDefaults")
        } catch {
            print("Failed to save sessions: \(error)")
        }
    }
    
    private func loadSessions() {
        isLoading = true
        defer { isLoading = false }
        
        guard let data = userDefaults.data(forKey: sessionsKey) else {
            sessions = []
            print("No cached sessions found")
            return
        }
        
        do {
            sessions = try JSONDecoder().decode([Session].self, from: data)
            print("Loaded \(sessions.count) cached sessions")
        } catch {
            print("Failed to load sessions: \(error)")
            sessions = []
        }
    }
    
    private func cleanupOldData() {
        print("Starting 24-hour cleanup...")
        let twentyFourHoursAgo = Date().addingTimeInterval(-86400) // 24時間前
        let initialCount = sessions.count
        
        // 24時間以上古いセッションを削除
        sessions.removeAll { session in
            session.startedAt < twentyFourHoursAgo
        }
        
        // 削除されたセッションがあれば保存
        if sessions.count != initialCount {
            saveSessions()
            print("Cleaned up \(initialCount - sessions.count) old sessions")
        }
        
        // 音声ファイルのクリーンアップも実行
        cleanupOldAudioFiles()
    }
    
    private func cleanupOldAudioFiles() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let twentyFourHoursAgo = Date().addingTimeInterval(-86400)
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: documentsPath, includingPropertiesForKeys: [.creationDateKey], options: [])
            
            for file in files {
                // .m4aファイルのみ対象
                guard file.pathExtension == "m4a" else { continue }
                
                let attributes = try file.resourceValues(forKeys: [.creationDateKey])
                if let creationDate = attributes.creationDate, creationDate < twentyFourHoursAgo {
                    try FileManager.default.removeItem(at: file)
                    print("Deleted old audio file: \(file.lastPathComponent)")
                }
            }
        } catch {
            print("Failed to cleanup old audio files: \(error)")
        }
    }
    
    private func setupBackgroundCleanup() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.cleanupOldData()
        }
    }
    
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
