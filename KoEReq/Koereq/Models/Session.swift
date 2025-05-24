//
//  Session.swift
//  Koereq
//
//  Created by Koereq Team on 2025/05/23.
//

import Foundation

struct Session: Identifiable, Codable, Hashable {
    let id: UUID
    var startedAt: Date
    var endedAt: Date?
    var summary: String
    var transcripts: [TranscriptChunk]
    var aiResponses: [AIResponse]
    
    init() {
        self.id = UUID()
        self.startedAt = Date()
        self.endedAt = nil
        self.summary = ""
        self.transcripts = []
        self.aiResponses = []
    }
}

struct TranscriptChunk: Identifiable, Codable, Hashable {
    let id: UUID
    let text: String
    let createdAt: Date
    let sequence: Int
    
    init(text: String, sequence: Int) {
        self.id = UUID()
        self.text = text
        self.createdAt = Date()
        self.sequence = sequence
    }
}

struct AIResponse: Identifiable, Codable, Hashable {
    let id: UUID
    let content: String
    let promptType: PromptType
    let createdAt: Date
    let sequence: Int
    
    init(content: String, promptType: PromptType, sequence: Int) {
        self.id = UUID()
        self.content = content
        self.promptType = promptType
        self.createdAt = Date()
        self.sequence = sequence
    }
}

enum PromptType: Codable, CaseIterable, Hashable {
    case medicalChart
    case referralLetter
    case consultation
    case custom(name: String, prompt: String)

    static var allCases: [PromptType] {
        return [.medicalChart, .referralLetter, .consultation]
    }
    
    var displayName: String {
        switch self {
        case .medicalChart:
            return "カルテ生成"
        case .referralLetter:
            return "紹介状作成"
        case .consultation:
            return "AIに相談"
        case .custom(let name, _):
            return name
        }
    }
    
    var promptTemplate: String {
        switch self {
        case .medicalChart:
            return "以下の音声記録を基に、医療カルテの形式で整理してください：\n\n{transcript}"
        case .referralLetter:
            return "以下の音声記録を基に、紹介状を作成してください：\n\n{transcript}"
        case .consultation:
            return "以下の音声記録について、医療専門家として相談に応じてください：\n\n{transcript}"
        case .custom(_, let prompt):
            return prompt
        }
    }
}
