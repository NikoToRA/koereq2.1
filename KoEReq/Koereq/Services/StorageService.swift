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
    
    // TODO: 実際の接続文字列に置き換えてください
    private let connectionString = "YOUR_AZURE_BLOB_STORAGE_CONNECTION_STRING"
    private let containerName = "koereq-sessions"
    
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 300
        return URLSession(configuration: config)
    }()
    
    func uploadSession(_ session: Session, audioFiles: [URL]) async throws {
        DispatchQueue.main.async { [weak self] in
            self?.isUploading = true
            self?.uploadProgress = 0.0
        }
        
        defer {
            DispatchQueue.main.async { [weak self] in
                self?.isUploading = false
                self?.uploadProgress = 0.0
            }
        }
        
        guard let facilityId = UserManager().currentUser?.facilityId else {
            throw StorageError.noUser
        }
        
        let sessionFolder = "\(facilityId)/\(session.id.uuidString)"
        
        // メタデータファイルの作成とアップロード
        try await uploadMetadata(session: session, to: sessionFolder)
        
        // 音声ファイルのアップロード
        for (index, audioURL) in audioFiles.enumerated() {
            let fileName = "voice_\(String(format: "%03d", index + 1)).m4a"
            try await uploadFile(from: audioURL, to: "\(sessionFolder)/\(fileName)")
            
            DispatchQueue.main.async { [weak self] in
                let numerator = Double(index + 1)
                let denominator = Double(audioFiles.count + session.transcripts.count + session.aiResponses.count + 1)
                if denominator > 0 {
                    self?.uploadProgress = numerator / denominator
                } else {
                    self?.uploadProgress = 0 // Or handle as an error/special case
                }
            }
        }
        
        // トランスクリプトファイルのアップロード
        for (index, transcript) in session.transcripts.enumerated() {
            let fileName = "transcript_\(String(format: "%03d", index + 1)).txt"
            try await uploadText(transcript.text, to: "\(sessionFolder)/\(fileName)")
            
            DispatchQueue.main.async { [weak self] in
                let numerator = Double(audioFiles.count + index + 1)
                let denominator = Double(audioFiles.count + session.transcripts.count + session.aiResponses.count + 1)
                if denominator > 0 {
                    self?.uploadProgress = numerator / denominator
                } else {
                    self?.uploadProgress = 0
                }
            }
        }
        
        // AI応答ファイルのアップロード
        for (index, response) in session.aiResponses.enumerated() {
            let fileName = "ai_response_\(String(format: "%03d", index + 1)).txt"
            try await uploadText(response.content, to: "\(sessionFolder)/\(fileName)")
            
            DispatchQueue.main.async { [weak self] in
                let numerator = Double(audioFiles.count + session.transcripts.count + index + 1)
                let denominator = Double(audioFiles.count + session.transcripts.count + session.aiResponses.count + 1)
                if denominator > 0 {
                    self?.uploadProgress = numerator / denominator
                } else {
                    self?.uploadProgress = 0
                }
            }
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.uploadProgress = 1.0
        }
    }
    
    private func uploadMetadata(session: Session, to folder: String) async throws {
        let metadata = SessionMetadata(
            sessionId: session.id.uuidString,
            facilityId: UserManager().currentUser?.facilityId ?? "",
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
        // SAS URLの生成（実際の実装では、バックエンドAPIからSAS URLを取得）
        let sasURL = try generateSASURL(for: path)
        
        var request = URLRequest(url: sasURL)
        request.httpMethod = "PUT"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.setValue("BlockBlob", forHTTPHeaderField: "x-ms-blob-type")
        request.httpBody = data
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 else {
            throw StorageError.uploadFailed
        }
    }
    
    private func generateSASURL(for path: String) throws -> URL {
        // 注意: これは簡略化された実装です
        // 実際の実装では、バックエンドAPIからSAS URLを取得するか、
        // Azure Storage SDKを使用してください
        
        guard let baseURL = extractStorageAccountURL(from: connectionString) else {
            throw StorageError.invalidConnectionString
        }
        
        let fullPath = "\(containerName)/\(path)"
        let urlString = "\(baseURL)/\(fullPath)?sv=2021-06-08&ss=b&srt=co&sp=rwdlacx&se=2025-12-31T23:59:59Z&st=2025-01-01T00:00:00Z&spr=https&sig=PLACEHOLDER_SIGNATURE"
        
        guard let url = URL(string: urlString) else {
            throw StorageError.invalidURL
        }
        
        return url
    }
    
    private func extractStorageAccountURL(from connectionString: String) -> String? {
        // 接続文字列からストレージアカウントURLを抽出
        let components = connectionString.components(separatedBy: ";")
        for component in components {
            if component.hasPrefix("BlobEndpoint=") {
                return String(component.dropFirst("BlobEndpoint=".count))
            }
        }
        return nil
    }
}

// MARK: - Storage Models

struct SessionMetadata: Codable {
    let sessionId: String
    let facilityId: String
    let startedAt: Date
    let endedAt: Date?
    let summary: String
    let transcriptCount: Int
    let aiResponseCount: Int
    let uploadedAt: Date
    
    init(sessionId: String, facilityId: String, startedAt: Date, endedAt: Date?, summary: String, transcriptCount: Int, aiResponseCount: Int) {
        self.sessionId = sessionId
        self.facilityId = facilityId
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
