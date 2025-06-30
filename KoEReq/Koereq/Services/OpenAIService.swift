//
//  OpenAIService.swift
//  Koereq
//
//  Created by Koereq Team on 2025/05/23.
//

import Foundation

@MainActor
class OpenAIService: ObservableObject {
    @Published var isGenerating = false
    @Published var error: Error?
    
    // TODO: 実際の値に置き換えてください
    // private let apiKey = "YOUR_AZURE_OPENAI_API_KEY"
    private var apiKey: String {
        // DEBUG: Info.plist の内容を確認
        print("[OpenAIService DEBUG] Attempting to read 'AzureOpenAIAPIKey' from Info.plist")
        // MODIFIED: Bundle.main.infoDictionary?.keys の扱いを修正
        if let keys = Bundle.main.infoDictionary?.keys {
            print("[OpenAIService DEBUG] Bundle.main.infoDictionary keys: \(Array(keys))")
        } else {
            print("[OpenAIService DEBUG] Bundle.main.infoDictionary is nil or has no keys.")
        }
        
        let apiKeyFromPlist = Bundle.main.object(forInfoDictionaryKey: "AzureOpenAIAPIKey")
        
        if apiKeyFromPlist == nil {
            print("[OpenAIService DEBUG] 'AzureOpenAIAPIKey' was NOT found in Info.plist (is nil).")
        } else {
            print("[OpenAIService DEBUG] Found value for 'AzureOpenAIAPIKey': \(apiKeyFromPlist!) (Type: \(type(of: apiKeyFromPlist!)))")
        }
        
        guard let apiKey = apiKeyFromPlist as? String else {
            print("[OpenAIService ERROR] Failed to cast 'AzureOpenAIAPIKey' to String or it was nil.")
            // 開発中はどの値が設定されているか確認するために infoDictionary の中身を出力するのも有効
            if let infoDict = Bundle.main.infoDictionary {
                print("[OpenAIService DEBUG] Full Info.plist dictionary: \(infoDict)")
            }
            fatalError("AzureOpenAIAPIKey not set correctly in Info.plist or is not a String.") // エラーメッセージを少し具体的に
        }
        
        // DEBUG: 読み取れたAPIキーの確認（最初の数文字だけ表示するなど、本番では削除）
        print("[OpenAIService DEBUG] Successfully read API Key (first 5 chars): \(String(apiKey.prefix(5)))")
        return apiKey
    }
    private let endpoint = "https://koereqv2.openai.azure.com/" // これはユーザーが既に入力済みと仮定
    private let deploymentName = "gpt-4.1-mini" // 実際のAzureデプロイ名に修正
    private let apiVersion = "2024-08-01-preview" // 最新の安定版APIバージョンに更新
    
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        return URLSession(configuration: config)
    }()
    
    // テスト用の簡単な接続確認メソッド
    func testConnection() async throws -> Bool {
        let url = URL(string: "\(endpoint)openai/deployments/\(deploymentName)/chat/completions?api-version=\(apiVersion)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "api-key")
        
        let testRequestBody = OpenAIRequest(
            messages: [
                OpenAIMessage(role: "user", content: "Hello")
            ],
            maxTokens: 10,
            temperature: 0.1
        )
        
        do {
            let jsonData = try JSONEncoder().encode(testRequestBody)
            request.httpBody = jsonData
            
            let (_, response) = try await session.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("[OpenAIService TEST] Connection test status: \(httpResponse.statusCode)")
                return httpResponse.statusCode == 200
            }
            return false
        } catch {
            print("[OpenAIService TEST] Connection test failed: \(error)")
            throw error
        }
    }
    
    func generateResponse(prompt: PromptType, transcripts: [TranscriptChunk]) async throws -> String {
        DispatchQueue.main.async { [weak self] in
            self?.isGenerating = true
        }
        
        defer {
            DispatchQueue.main.async { [weak self] in
                self?.isGenerating = false
            }
        }
        
        let combinedTranscript = transcripts.map { $0.text }.joined(separator: "\n")
        let finalPrompt = prompt.promptTemplate.replacingOccurrences(of: "{transcript}", with: combinedTranscript)
        
        let url = URL(string: "\(endpoint)openai/deployments/\(deploymentName)/chat/completions?api-version=\(apiVersion)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "api-key")
        
        let requestBody = OpenAIRequest(
            messages: [
                OpenAIMessage(role: "system", content: "あなたは医療専門家のアシスタントです。正確で専門的な回答を提供してください。"),
                OpenAIMessage(role: "user", content: finalPrompt)
            ],
            maxTokens: 2000,
            temperature: 0.7
        )
        
        do {
            let jsonData = try JSONEncoder().encode(requestBody)
            request.httpBody = jsonData
            
            // DEBUG: リクエスト詳細をログ出力
            print("[OpenAIService DEBUG] Request URL: \(url)")
            print("[OpenAIService DEBUG] Request Headers: \(request.allHTTPHeaderFields ?? [:])")
            if let bodyString = String(data: jsonData, encoding: .utf8) {
                print("[OpenAIService DEBUG] Request Body: \(bodyString)")
            }
            
            let (data, response) = try await session.data(for: request)
            
            // DEBUG: レスポンス詳細をログ出力
            if let httpResponse = response as? HTTPURLResponse {
                print("[OpenAIService DEBUG] Response Status Code: \(httpResponse.statusCode)")
                print("[OpenAIService DEBUG] Response Headers: \(httpResponse.allHeaderFields)")
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("[OpenAIService DEBUG] Response Body: \(responseString)")
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("[OpenAIService ERROR] Invalid response type")
                throw OpenAIError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                print("[OpenAIService ERROR] HTTP Error - Status Code: \(httpResponse.statusCode)")
                if let errorData = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
                    print("[OpenAIService ERROR] API Error: \(errorData.error.message)")
                    throw OpenAIError.apiError(errorData.error.message)
                } else {
                    print("[OpenAIService ERROR] Unknown HTTP Error")
                    throw OpenAIError.httpError(httpResponse.statusCode)
                }
            }
            
            let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
            
            guard let content = openAIResponse.choices.first?.message.content else {
                print("[OpenAIService ERROR] No content in response")
                throw OpenAIError.noContent
            }
            
            print("[OpenAIService SUCCESS] Generated response length: \(content.count) characters")
            return content
            
        } catch {
            print("[OpenAIService ERROR] Exception caught: \(error)")
            DispatchQueue.main.async { [weak self] in
                self?.error = error
            }
            throw error
        }
    }
    
    func generateNursingResponse(prompt: String, transcripts: [TranscriptChunk]) async throws -> String {
        DispatchQueue.main.async { [weak self] in
            self?.isGenerating = true
        }
        
        defer {
            DispatchQueue.main.async { [weak self] in
                self?.isGenerating = false
            }
        }
        
        let combinedTranscript = transcripts.map { $0.text }.joined(separator: "\n")
        let finalPrompt = prompt.replacingOccurrences(of: "{transcript}", with: combinedTranscript)
        
        let url = URL(string: "\(endpoint)openai/deployments/\(deploymentName)/chat/completions?api-version=\(apiVersion)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "api-key")
        
        let requestBody = OpenAIRequest(
            messages: [
                OpenAIMessage(role: "system", content: "あなたは救急看護師の記録作成を支援する専門的なAIアシスタントです。音声記録を構造化された医療記録に変換し、安全性と正確性を最優先に動作します。"),
                OpenAIMessage(role: "user", content: finalPrompt)
            ],
            maxTokens: 3000,
            temperature: 0.3
        )
        
        do {
            let jsonData = try JSONEncoder().encode(requestBody)
            request.httpBody = jsonData
            
            print("[OpenAIService DEBUG] Nursing Response Request URL: \(url)")
            
            let (data, response) = try await session.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("[OpenAIService DEBUG] Nursing Response Status Code: \(httpResponse.statusCode)")
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("[OpenAIService DEBUG] Nursing Response Raw: \(responseString)")
            }
            
            let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
            
            guard let content = openAIResponse.choices.first?.message.content else {
                print("[OpenAIService ERROR] No content in nursing response")
                throw OpenAIError.noContent
            }
            
            print("[OpenAIService SUCCESS] Generated nursing response length: \(content.count) characters")
            return content
            
        } catch {
            print("[OpenAIService ERROR] Nursing response exception: \(error)")
            DispatchQueue.main.async { [weak self] in
                self?.error = error
            }
            throw error
        }
    }
}

// MARK: - OpenAI API Models

struct OpenAIRequest: Codable {
    let messages: [OpenAIMessage]
    let maxTokens: Int
    let temperature: Double
    
    enum CodingKeys: String, CodingKey {
        case messages
        case maxTokens = "max_tokens"
        case temperature
    }
}

struct OpenAIMessage: Codable {
    let role: String
    let content: String
}

struct OpenAIResponse: Codable {
    let choices: [OpenAIChoice]
}

struct OpenAIChoice: Codable {
    let message: OpenAIMessage
}

struct OpenAIErrorResponse: Codable {
    let error: OpenAIErrorDetail
}

struct OpenAIErrorDetail: Codable {
    let message: String
    let type: String?
    let code: String?
}

enum OpenAIError: Error, LocalizedError {
    case invalidResponse
    case apiError(String)
    case httpError(Int)
    case noContent
    case encodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "無効なレスポンスです"
        case .apiError(let message):
            return "API エラー: \(message)"
        case .httpError(let code):
            return "HTTP エラー: \(code)"
        case .noContent:
            return "レスポンスにコンテンツがありません"
        case .encodingError:
            return "エンコーディングエラーです"
        }
    }
}
