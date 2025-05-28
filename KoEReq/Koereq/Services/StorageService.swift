//
//  StorageService.swift
//  Koereq
//
//  Created by Koereq Team on 2025/05/23.
//

import Foundation
import CryptoKit

class StorageService: ObservableObject {
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    @Published var error: Error?
    
    // Azure機能を有効化
    private let isAzureEnabled = true
    
    // Azure Storage Configuration
    // コスト最適化のための階層管理
    // - Hot: 即時アクセス（過去7日）
    // - Cool: 月次レポート用（8-180日）  
    // - Archive: 長期保存（180日以降）
    private var connectionString: String {
        guard let connectionString = Bundle.main.object(forInfoDictionaryKey: "AzureStorageConnectionString") as? String,
              !connectionString.isEmpty,
              connectionString != "$(AZURE_STORAGE_CONNECTION_STRING)" else {
            print("[StorageService ERROR] Azure Storage connection string not configured")
            return ""
        }
        return connectionString
    }
    
    private var containerName: String {
        guard let containerName = Bundle.main.object(forInfoDictionaryKey: "AzureStorageContainerName") as? String,
              !containerName.isEmpty,
              containerName != "$(AZURE_STORAGE_CONTAINER_NAME)" else {
            return "koereq-sessions"
        }
        return containerName
    }
    
    private var accountName: String {
        guard let accountName = Bundle.main.object(forInfoDictionaryKey: "AzureStorageAccountName") as? String,
              !accountName.isEmpty,
              accountName != "$(AZURE_STORAGE_ACCOUNT_NAME)" else {
            print("[StorageService ERROR] Azure Storage account name not configured")
            return ""
        }
        return accountName
    }
    
    private var accountKey: String {
        guard let accountKey = Bundle.main.object(forInfoDictionaryKey: "AzureStorageAccountKey") as? String,
              !accountKey.isEmpty,
              accountKey != "$(AZURE_STORAGE_ACCOUNT_KEY)" else {
            print("[StorageService ERROR] Azure Storage account key not configured")
            return ""
        }
        return accountKey
    }
    
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 300
        return URLSession(configuration: config)
    }()
    
    func uploadSession(_ session: Session, audioFiles: [URL]) async throws {
        guard isAzureEnabled else {
            print("Azure upload is disabled - using local 24-hour cache only")
            return
        }
        
        // 設定チェック
        guard !accountName.isEmpty && !accountKey.isEmpty else {
            throw StorageError.invalidConnectionString
        }
        
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
        
        let user = UserManager().currentUser
        let facilityId = user?.facilityId ?? "unknown"
        let sessionId = session.id.uuidString
        let folderPath = "\(facilityId)/\(sessionId)"
        
        let totalTasks = 2 + audioFiles.count // メタデータ + 転写 + 音声ファイル数
        var completedTasks = 0
        
        do {
            // 1. メタデータのアップロード
            try await uploadMetadata(session: session, to: folderPath)
            completedTasks += 1
            DispatchQueue.main.async { [weak self] in
                self?.uploadProgress = Double(completedTasks) / Double(totalTasks)
            }
            
            // 2. 転写データのアップロード
            let transcriptText = session.transcripts.map { $0.text }.joined(separator: "\n")
            try await uploadText(transcriptText, to: "\(folderPath)/transcript.txt")
            completedTasks += 1
            DispatchQueue.main.async { [weak self] in
                self?.uploadProgress = Double(completedTasks) / Double(totalTasks)
            }
            
            // 3. 音声ファイルのアップロード
            for (index, audioFile) in audioFiles.enumerated() {
                let fileName = "audio_\(index + 1).m4a"
                try await uploadFile(from: audioFile, to: "\(folderPath)/\(fileName)")
                completedTasks += 1
                DispatchQueue.main.async { [weak self] in
                    self?.uploadProgress = Double(completedTasks) / Double(totalTasks)
                }
            }
            
            print("[StorageService SUCCESS] Session uploaded to Azure: \(sessionId)")
            
        } catch {
            print("[StorageService ERROR] Upload failed: \(error)")
            DispatchQueue.main.async { [weak self] in
                self?.error = error
            }
            throw error
        }
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
        try await uploadData(data, to: path, contentType: "text/plain; charset=utf-8")
    }
    
    private func uploadFile(from localURL: URL, to path: String) async throws {
        let data = try Data(contentsOf: localURL)
        try await uploadData(data, to: path, contentType: "audio/mp4")
    }
    
    private func uploadData(_ data: Data, to blobPath: String, contentType: String) async throws {
        let url = URL(string: "https://\(accountName).blob.core.windows.net/\(containerName)/\(blobPath)")!
        
        // 現在の日時をGMT形式で取得
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss 'GMT'"
        dateFormatter.timeZone = TimeZone(identifier: "GMT")
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        let dateString = dateFormatter.string(from: Date())
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.setValue("BlockBlob", forHTTPHeaderField: "x-ms-blob-type")
        request.setValue("2020-12-06", forHTTPHeaderField: "x-ms-version")
        request.setValue(dateString, forHTTPHeaderField: "x-ms-date")
        request.setValue("\(data.count)", forHTTPHeaderField: "Content-Length")
        
        // 参照コスト最適化: 即座にCool層に保存（書き込み時のみ少し高く、読み込み時大幅節約）
        request.setValue("Cool", forHTTPHeaderField: "x-ms-access-tier")
        
        // Azure Storage 認証ヘッダーの生成
        let authHeader = try generateAuthorizationHeader(
            httpMethod: "PUT",
            url: url,
            contentLength: data.count,
            contentType: contentType,
            blobPath: blobPath,
            dateString: dateString
        )
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        
        request.httpBody = data
        
        print("[StorageService DEBUG] Uploading to: \(url)")
        print("[StorageService DEBUG] Content-Type: \(contentType)")
        print("[StorageService DEBUG] Data size: \(data.count) bytes")
        print("[StorageService DEBUG] Date header: \(dateString)")
        print("[StorageService DEBUG] Authorization: \(authHeader)")
        
        let (responseData, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StorageError.invalidURL
        }
        
        print("[StorageService DEBUG] Upload response status: \(httpResponse.statusCode)")
        print("[StorageService DEBUG] Response headers: \(httpResponse.allHeaderFields)")
        
        if let responseString = String(data: responseData, encoding: .utf8), !responseString.isEmpty {
            print("[StorageService DEBUG] Response body: \(responseString)")
        }
        
        guard httpResponse.statusCode == 201 else {
            print("[StorageService ERROR] Upload failed with status: \(httpResponse.statusCode)")
            throw StorageError.uploadFailed
        }
        
        print("[StorageService SUCCESS] Uploaded: \(blobPath)")
    }
    
    private func generateAuthorizationHeader(httpMethod: String, url: URL, contentLength: Int, contentType: String, blobPath: String, dateString: String) throws -> String {
        
        // Canonicalized Headersの正しい形式（x-ms-access-tierを追加し、アルファベット順で並べる）
        let canonicalizedHeaders = "x-ms-access-tier:Cool\nx-ms-blob-type:BlockBlob\nx-ms-date:\(dateString)\nx-ms-version:2020-12-06"
        
        // Canonicalized Resourceの正しい形式（完全なパスを使用）
        let canonicalizedResource = "/\(accountName)/\(containerName)/\(blobPath)"
        
        // String to Signの構築（Azure REST APIの仕様に準拠）
        let stringToSign = [
            httpMethod,                    // HTTP Verb
            "",                           // Content-Encoding
            "",                           // Content-Language
            "\(contentLength)",           // Content-Length
            "",                           // Content-MD5
            contentType,                  // Content-Type
            "",                           // Date (空文字、x-ms-dateを使用)
            "",                           // If-Modified-Since
            "",                           // If-Match
            "",                           // If-None-Match
            "",                           // If-Unmodified-Since
            "",                           // Range
            canonicalizedHeaders,         // CanonicalizedHeaders
            canonicalizedResource         // CanonicalizedResource
        ].joined(separator: "\n")
        
        print("[StorageService DEBUG] Date: \(dateString)")
        print("[StorageService DEBUG] Canonicalized Headers: \(canonicalizedHeaders)")
        print("[StorageService DEBUG] Canonicalized Resource: \(canonicalizedResource)")
        print("[StorageService DEBUG] String to sign: \(stringToSign)")
        
        guard let keyData = Data(base64Encoded: accountKey) else {
            throw StorageError.invalidConnectionString
        }
        
        let key = SymmetricKey(data: keyData)
        let signature = HMAC<SHA256>.authenticationCode(for: stringToSign.data(using: .utf8)!, using: key)
        let signatureBase64 = Data(signature).base64EncodedString()
        
        return "SharedKey \(accountName):\(signatureBase64)"
    }
    
    // テスト用の接続確認メソッド
    func testAzureConnection() async throws -> Bool {
        guard isAzureEnabled && !accountName.isEmpty && !accountKey.isEmpty else {
            print("[StorageService TEST] Azure not configured or disabled")
            return false
        }
        
        // コンテナの存在確認
        let url = URL(string: "https://\(accountName).blob.core.windows.net/\(containerName)?restype=container")!
        
        // 現在の日時をGMT形式で取得
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss 'GMT'"
        dateFormatter.timeZone = TimeZone(identifier: "GMT")
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        let dateString = dateFormatter.string(from: Date())
        
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.setValue("2020-12-06", forHTTPHeaderField: "x-ms-version")
        request.setValue(dateString, forHTTPHeaderField: "x-ms-date")
        
        let authHeader = try generateTestAuthorizationHeader(
            httpMethod: "HEAD",
            dateString: dateString
        )
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await session.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("[StorageService TEST] Azure connection test status: \(httpResponse.statusCode)")
            return httpResponse.statusCode == 200
        }
        
        return false
    }
    
    private func generateTestAuthorizationHeader(httpMethod: String, dateString: String) throws -> String {
        // Canonicalized Headersの正しい形式
        let canonicalizedHeaders = "x-ms-date:\(dateString)\nx-ms-version:2020-12-06"
        
        // Canonicalized Resourceの正しい形式（コンテナレベルのテスト用）
        let canonicalizedResource = "/\(accountName)/\(containerName)\nrestype:container"
        
        // String to Signの構築（Azure REST APIの仕様に準拠）
        let stringToSign = [
            httpMethod,                    // HTTP Verb
            "",                           // Content-Encoding
            "",                           // Content-Language
            "",                           // Content-Length
            "",                           // Content-MD5
            "",                           // Content-Type
            "",                           // Date (空文字、x-ms-dateを使用)
            "",                           // If-Modified-Since
            "",                           // If-Match
            "",                           // If-None-Match
            "",                           // If-Unmodified-Since
            "",                           // Range
            canonicalizedHeaders,         // CanonicalizedHeaders
            canonicalizedResource         // CanonicalizedResource
        ].joined(separator: "\n")
        
        print("[StorageService TEST DEBUG] String to sign: \(stringToSign)")
        
        guard let keyData = Data(base64Encoded: accountKey) else {
            throw StorageError.invalidConnectionString
        }
        
        let key = SymmetricKey(data: keyData)
        let signature = HMAC<SHA256>.authenticationCode(for: stringToSign.data(using: .utf8)!, using: key)
        let signatureBase64 = Data(signature).base64EncodedString()
        
        return "SharedKey \(accountName):\(signatureBase64)"
    }
    
    // MARK: - 参照・ダウンロード機能（手動での利用想定）
    
    /// 指定施設の全セッション一覧を取得
    func listSessions(facilityId: String) async throws -> [SessionMetadata] {
        guard isAzureEnabled && !accountName.isEmpty && !accountKey.isEmpty else {
            throw StorageError.invalidConnectionString
        }
        
        let url = URL(string: "https://\(accountName).blob.core.windows.net/\(containerName)?restype=container&comp=list&prefix=\(facilityId)/")!
        
        // 現在の日時をGMT形式で取得
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss 'GMT'"
        dateFormatter.timeZone = TimeZone(identifier: "GMT")
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        let dateString = dateFormatter.string(from: Date())
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("2020-12-06", forHTTPHeaderField: "x-ms-version")
        request.setValue(dateString, forHTTPHeaderField: "x-ms-date")
        
        let authHeader = try generateListAuthorizationHeader(
            httpMethod: "GET",
            dateString: dateString,
            facilityId: facilityId
        )
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        
        let (responseData, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw StorageError.uploadFailed
        }
        
        // XMLレスポンスからセッションIDを抽出し、メタデータを取得
        let sessionIds = extractSessionIdsFromXML(responseData)
        var sessionMetadataList: [SessionMetadata] = []
        
        for sessionId in sessionIds {
            do {
                let metadata = try await downloadSessionMetadata(facilityId: facilityId, sessionId: sessionId)
                sessionMetadataList.append(metadata)
            } catch {
                print("[StorageService] Failed to load metadata for session \(sessionId): \(error)")
            }
        }
        
        return sessionMetadataList.sorted { $0.startedAt > $1.startedAt }
    }
    
    /// 特定セッションのメタデータをダウンロード
    func downloadSessionMetadata(facilityId: String, sessionId: String) async throws -> SessionMetadata {
        let blobPath = "\(facilityId)/\(sessionId)/meta.json"
        let data = try await downloadBlob(blobPath: blobPath)
        return try JSONDecoder().decode(SessionMetadata.self, from: data)
    }
    
    /// 特定セッションの転写テキストをダウンロード
    func downloadSessionTranscript(facilityId: String, sessionId: String) async throws -> String {
        let blobPath = "\(facilityId)/\(sessionId)/transcript.txt"
        let data = try await downloadBlob(blobPath: blobPath)
        return String(data: data, encoding: .utf8) ?? ""
    }
    
    /// 特定セッションの音声ファイル一覧を取得
    func listSessionAudioFiles(facilityId: String, sessionId: String) async throws -> [String] {
        let prefix = "\(facilityId)/\(sessionId)/audio_"
        // 実装省略（必要に応じて詳細実装）
        return []
    }
    
    private func downloadBlob(blobPath: String) async throws -> Data {
        let url = URL(string: "https://\(accountName).blob.core.windows.net/\(containerName)/\(blobPath)")!
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss 'GMT'"
        dateFormatter.timeZone = TimeZone(identifier: "GMT")
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        let dateString = dateFormatter.string(from: Date())
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("2020-12-06", forHTTPHeaderField: "x-ms-version")
        request.setValue(dateString, forHTTPHeaderField: "x-ms-date")
        
        let authHeader = try generateDownloadAuthorizationHeader(
            httpMethod: "GET",
            blobPath: blobPath,
            dateString: dateString
        )
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        
        let (responseData, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw StorageError.uploadFailed
        }
        
        return responseData
    }
    
    private func extractSessionIdsFromXML(_ data: Data) -> [String] {
        // XMLパースからセッションIDを抽出（簡易実装）
        guard let xmlString = String(data: data, encoding: .utf8) else { return [] }
        
        var sessionIds: [String] = []
        let pattern = #"<Name>([^/]+)/([^/]+)/meta\.json</Name>"#
        
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let matches = regex.matches(in: xmlString, range: NSRange(xmlString.startIndex..., in: xmlString))
            
            for match in matches {
                if let sessionIdRange = Range(match.range(at: 2), in: xmlString) {
                    sessionIds.append(String(xmlString[sessionIdRange]))
                }
            }
        } catch {
            print("[StorageService] XML parsing error: \(error)")
        }
        
        return Array(Set(sessionIds)) // 重複除去
    }
    
    private func generateListAuthorizationHeader(httpMethod: String, dateString: String, facilityId: String) throws -> String {
        let canonicalizedHeaders = "x-ms-date:\(dateString)\nx-ms-version:2020-12-06"
        let canonicalizedResource = "/\(accountName)/\(containerName)\ncomp:list\nprefix:\(facilityId)/\nrestype:container"
        
        let stringToSign = [
            httpMethod, "", "", "", "", "", "", "", "", "", "", "",
            canonicalizedHeaders, canonicalizedResource
        ].joined(separator: "\n")
        
        guard let keyData = Data(base64Encoded: accountKey) else {
            throw StorageError.invalidConnectionString
        }
        
        let key = SymmetricKey(data: keyData)
        let signature = HMAC<SHA256>.authenticationCode(for: stringToSign.data(using: .utf8)!, using: key)
        let signatureBase64 = Data(signature).base64EncodedString()
        
        return "SharedKey \(accountName):\(signatureBase64)"
    }
    
    private func generateDownloadAuthorizationHeader(httpMethod: String, blobPath: String, dateString: String) throws -> String {
        let canonicalizedHeaders = "x-ms-date:\(dateString)\nx-ms-version:2020-12-06"
        let canonicalizedResource = "/\(accountName)/\(containerName)/\(blobPath)"
        
        let stringToSign = [
            httpMethod, "", "", "", "", "", "", "", "", "", "", "",
            canonicalizedHeaders, canonicalizedResource
        ].joined(separator: "\n")
        
        guard let keyData = Data(base64Encoded: accountKey) else {
            throw StorageError.invalidConnectionString
        }
        
        let key = SymmetricKey(data: keyData)
        let signature = HMAC<SHA256>.authenticationCode(for: stringToSign.data(using: .utf8)!, using: key)
        let signatureBase64 = Data(signature).base64EncodedString()
        
        return "SharedKey \(accountName):\(signatureBase64)"
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
