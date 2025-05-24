//
//  StorageService.swift
//  Koereq
//
//  Created by Koereq Team on 2025/05/23.
//

import Foundation

class StorageService: ObservableObject {
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    @Published var error: Error?
    
    // Azure機能は一時的に無効化（24時間ローカルキャッシュ優先）
    private let isAzureEnabled = false
    
    func uploadSession(_ session: Session, audioFiles: [URL]) async throws {
        // Azure機能が無効化されている場合は何もしない
        guard isAzureEnabled else {
            print("Azure upload is disabled - using local 24-hour cache only")
            return
        }
        
        // 将来のAzure実装用に保留
        print("Azure upload functionality will be implemented later")
    }
    
    private func uploadMetadata(session: Session, to folder: String) async throws {
        let metadata = SessionMetadata(
            sessionId: session.id.uuidString,
            facilityId: UserManager().currentUser?.facilityId ?? "",
            facilityName: UserManager().currentUser?.facilityName ?? "",
            startedAt: session.startedAt,
            endedAt: session.endedAt,
            summary: session.summary,
            transcriptCount: session.transcripts.count,
            aiResponseCount: session.aiResponses.count
        )
        
        let jsonData = try JSONEncoder().encode(metadata)
        try await uploadData(jsonData, to: "\(folder)/meta.json", contentType: "application/json")
    }
    
    private func uploadText(_ text: String, to path: String) async throws {
        guard let data = text.data(using: .utf8) else {
            throw StorageError.encodingError
        }
        try await uploadData(data, to: path, contentType: "text/plain")
    }
    
    private func uploadFile(from localURL: URL, to path: String) async throws {
        let data = try Data(contentsOf: localURL)
        try await uploadData(data, to: path, contentType: "audio/mp4")
    }
    
    private func uploadData(_ data: Data, to path: String, contentType: String) async throws {
        // Azure機能が無効化されているため、実装をスキップ
        throw StorageError.uploadFailed
    }
    

}

// MARK: - Storage Models

struct SessionMetadata: Codable {
    let sessionId: String
    let facilityId: String
    let facilityName: String
    let startedAt: Date
    let endedAt: Date?
    let summary: String
    let transcriptCount: Int
    let aiResponseCount: Int
    let uploadedAt: Date
    
    init(sessionId: String, facilityId: String, facilityName: String, startedAt: Date, endedAt: Date?, summary: String, transcriptCount: Int, aiResponseCount: Int) {
        self.sessionId = sessionId
        self.facilityId = facilityId
        self.facilityName = facilityName
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.summary = summary
        self.transcriptCount = transcriptCount
        self.aiResponseCount = aiResponseCount
        self.uploadedAt = Date()
    }
}

enum StorageError: Error, LocalizedError {
    case noUser
    case encodingError
    case uploadFailed
    case invalidConnectionString
    case invalidURL
    
    var errorDescription: String? {
        switch self {
        case .noUser:
            return "ユーザー情報が見つかりません"
        case .encodingError:
            return "データのエンコーディングに失敗しました"
        case .uploadFailed:
            return "アップロードに失敗しました"
        case .invalidConnectionString:
            return "無効な接続文字列です"
        case .invalidURL:
            return "無効なURLです"
        }
    }
}
