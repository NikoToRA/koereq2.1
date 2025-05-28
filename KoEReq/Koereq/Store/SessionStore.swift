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
    private let uploadedSessionsKey = "uploadedSessions"
    private var cleanupTimer: Timer?
    private let storageService = StorageService()
    private var uploadedSessionIds: Set<String> = []
    
    init() {
        // 24時間ごとのクリーンアップタイマーを設定
        self.cleanupTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            self?.cleanupOldData()
        }
        
        loadSessions()
        loadUploadedSessions() // 新規追加：アップロード済みセッションを読み込み
        cleanupOldData() // 起動時にも古いデータをクリーンアップ
        
        // バックグラウンドから復帰時のクリーンアップ
        setupBackgroundCleanup()
        
        print("SessionStore initialized with 24-hour cache system and Azure integration")
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
        
        // セッション終了時にAzureにアップロード
        uploadSessionToAzure(session)
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
    
    func reloadSessions() {
        loadSessions()
        print("Sessions reloaded from UserDefaults")
    }
    
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
    
    private func loadUploadedSessions() {
        if let data = userDefaults.data(forKey: uploadedSessionsKey),
           let sessionIds = try? JSONDecoder().decode(Set<String>.self, from: data) {
            uploadedSessionIds = sessionIds
            print("Loaded \(uploadedSessionIds.count) uploaded session IDs")
        } else {
            uploadedSessionIds = []
            print("No uploaded session record found")
        }
    }
    
    private func saveUploadedSessions() {
        if let data = try? JSONEncoder().encode(uploadedSessionIds) {
            userDefaults.set(data, forKey: uploadedSessionsKey)
            print("Saved \(uploadedSessionIds.count) uploaded session IDs")
        }
    }
    
    private func markSessionAsUploaded(_ sessionId: String) {
        uploadedSessionIds.insert(sessionId)
        saveUploadedSessions()
        print("[SessionStore] Session marked as uploaded: \(sessionId)")
    }
    
    private func isSessionAlreadyUploaded(_ sessionId: String) -> Bool {
        return uploadedSessionIds.contains(sessionId)
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
        
        // アップロード済みセッションリストもクリーンアップ（24時間以上古いセッションIDを削除）
        let currentSessionIds = Set(sessions.map { $0.id.uuidString })
        let initialUploadedCount = uploadedSessionIds.count
        uploadedSessionIds = uploadedSessionIds.intersection(currentSessionIds)
        
        if uploadedSessionIds.count != initialUploadedCount {
            saveUploadedSessions()
            print("Cleaned up \(initialUploadedCount - uploadedSessionIds.count) old uploaded session records")
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
    
    // MARK: - Azure Upload Integration
    
    private func uploadSessionToAzure(_ session: Session) {
        let sessionId = session.id.uuidString
        
        // 重複チェック：既にアップロード済みのセッションはスキップ
        if isSessionAlreadyUploaded(sessionId) {
            print("[SessionStore] Session already uploaded, skipping: \(sessionId)")
            return
        }
        
        Task {
            do {
                // 関連する音声ファイルを取得
                let audioFiles = getSessionAudioFiles(sessionId: sessionId)
                
                // Azureにアップロード
                try await storageService.uploadSession(session, audioFiles: audioFiles)
                
                // アップロード成功時にマーク
                await MainActor.run {
                    markSessionAsUploaded(sessionId)
                }
                
                print("[SessionStore] Successfully uploaded session to Azure: \(sessionId)")
                
            } catch {
                print("[SessionStore] Failed to upload session to Azure: \(error)")
                // エラーはログに記録するが、ローカルデータは保持
                // 重複防止マークは行わない（再試行可能にする）
            }
        }
    }
    
    func uploadSessionManually(_ session: Session) async throws {
        let audioFiles = getSessionAudioFiles(sessionId: session.id.uuidString)
        try await storageService.uploadSession(session, audioFiles: audioFiles)
    }
    
    func testAzureConnection() async throws -> Bool {
        return try await storageService.testAzureConnection()
    }
    
    private func getSessionAudioFiles(sessionId: String) -> [URL] {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        var audioFiles: [URL] = []
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: documentsPath, includingPropertiesForKeys: [.creationDateKey], options: [])
            
            print("[SessionStore DEBUG] Looking for audio files for session: \(sessionId)")
            print("[SessionStore DEBUG] Found \(files.count) files in documents directory")
            
            for file in files {
                // .m4aファイルのみ対象
                guard file.pathExtension == "m4a" else { continue }
                
                let fileName = file.lastPathComponent
                print("[SessionStore DEBUG] Checking audio file: \(fileName)")
                
                // セッションIDを含むファイル、または最近作成されたvoice_*.m4aファイルを検索
                let sessionMatches = fileName.contains(sessionId)
                let isVoiceFile = fileName.hasPrefix("voice_")
                
                if sessionMatches {
                    print("[SessionStore DEBUG] Found session-specific audio file: \(fileName)")
                    audioFiles.append(file)
                } else if isVoiceFile {
                    // セッション作成時刻付近に作成された音声ファイルを探す
                    if let session = currentSession ?? sessions.first(where: { $0.id.uuidString == sessionId }) {
                        let attributes = try? file.resourceValues(forKeys: [.creationDateKey])
                        if let creationDate = attributes?.creationDate {
                            let timeDifference = abs(creationDate.timeIntervalSince(session.startedAt))
                            // セッション開始から1時間以内に作成されたファイルを対象
                            if timeDifference < 3600 {
                                print("[SessionStore DEBUG] Found time-related audio file: \(fileName) (time diff: \(timeDifference)s)")
                                audioFiles.append(file)
                            }
                        }
                    }
                }
            }
            
            print("[SessionStore DEBUG] Found \(audioFiles.count) audio files for session \(sessionId)")
            for file in audioFiles {
                print("[SessionStore DEBUG] - \(file.lastPathComponent)")
            }
            
        } catch {
            print("[SessionStore ERROR] Failed to get session audio files: \(error)")
        }
        
        return audioFiles.sorted { $0.lastPathComponent < $1.lastPathComponent }
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