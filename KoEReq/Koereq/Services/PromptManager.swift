//
//  PromptManager.swift
//  Koereq
//
//  Created by Koereq Team on 2025/05/23.
//

import Foundation

class PromptManager: ObservableObject {
    @Published var customPrompts: [CustomPrompt] = []
    @Published var userDictionary: [DictionaryEntry] = []
    
    private let userDefaults = UserDefaults.standard
    private let customPromptsKey = "customPrompts"
    private let userDictionaryKey = "userDictionary"
    
    init() {
        loadCustomPrompts()
        loadUserDictionary()
    }
    
    // MARK: - Default Prompts
    
    var defaultPrompts: [PromptType] {
        return [
            .medicalChart,
            .referralLetter,
            .consultation
        ]
    }
    
    var allPrompts: [PromptType] {
        var prompts = defaultPrompts
        prompts.append(contentsOf: customPrompts.map { .custom(name: $0.name, prompt: $0.content) })
        return prompts
    }
    
    // MARK: - Custom Prompts Management
    
    func addCustomPrompt(name: String, content: String) {
        let newPrompt = CustomPrompt(name: name, content: content)
        customPrompts.append(newPrompt)
        saveCustomPrompts()
    }
    
    func updateCustomPrompt(id: UUID, name: String, content: String) {
        if let index = customPrompts.firstIndex(where: { $0.id == id }) {
            customPrompts[index].name = name
            customPrompts[index].content = content
            customPrompts[index].updatedAt = Date()
            saveCustomPrompts()
        }
    }
    
    func deleteCustomPrompt(id: UUID) {
        customPrompts.removeAll { $0.id == id }
        saveCustomPrompts()
    }
    
    func getPromptContent(for promptType: PromptType) -> String {
        return promptType.promptTemplate
    }
    
    // MARK: - User Dictionary Management
    
    func addDictionaryEntry(term: String, reading: String, definition: String) {
        let newEntry = DictionaryEntry(term: term, reading: reading, definition: definition)
        userDictionary.append(newEntry)
        saveUserDictionary()
    }
    
    func updateDictionaryEntry(id: UUID, term: String, reading: String, definition: String) {
        if let index = userDictionary.firstIndex(where: { $0.id == id }) {
            userDictionary[index].term = term
            userDictionary[index].reading = reading
            userDictionary[index].definition = definition
            userDictionary[index].updatedAt = Date()
            saveUserDictionary()
        }
    }
    
    func deleteDictionaryEntry(id: UUID) {
        userDictionary.removeAll { $0.id == id }
        saveUserDictionary()
    }
    
    func searchDictionary(query: String) -> [DictionaryEntry] {
        let lowercaseQuery = query.lowercased()
        return userDictionary.filter {
            $0.term.lowercased().contains(lowercaseQuery) ||
            $0.reading.lowercased().contains(lowercaseQuery) ||
            $0.definition.lowercased().contains(lowercaseQuery)
        }
    }
    
    // MARK: - Text Processing with Dictionary
    
    func processTextWithDictionary(_ text: String) -> String {
        var processedText = text
        
        // ユーザー辞書の用語を置換
        for entry in userDictionary {
            let pattern = "\\b\(NSRegularExpression.escapedPattern(for: entry.term))\\b"
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(location: 0, length: processedText.utf16.count)
                processedText = regex.stringByReplacingMatches(
                    in: processedText,
                    options: [],
                    range: range,
                    withTemplate: "\(entry.term)（\(entry.reading)）"
                )
            }
        }
        
        return processedText
    }
    
    // MARK: - Persistence
    
    private func saveCustomPrompts() {
        if let encoded = try? JSONEncoder().encode(customPrompts) {
            userDefaults.set(encoded, forKey: customPromptsKey)
        }
    }
    
    private func loadCustomPrompts() {
        if let data = userDefaults.data(forKey: customPromptsKey),
           let prompts = try? JSONDecoder().decode([CustomPrompt].self, from: data) {
            customPrompts = prompts
        }
    }
    
    private func saveUserDictionary() {
        if let encoded = try? JSONEncoder().encode(userDictionary) {
            userDefaults.set(encoded, forKey: userDictionaryKey)
        }
    }
    
    private func loadUserDictionary() {
        if let data = userDefaults.data(forKey: userDictionaryKey),
           let dictionary = try? JSONDecoder().decode([DictionaryEntry].self, from: data) {
            userDictionary = dictionary
        }
    }
    
    // MARK: - Export/Import
    
    func exportPrompts() -> Data? {
        let exportData = PromptExportData(
            customPrompts: customPrompts,
            userDictionary: userDictionary,
            exportedAt: Date()
        )
        
        return try? JSONEncoder().encode(exportData)
    }
    
    func importPrompts(from data: Data) throws {
        let importData = try JSONDecoder().decode(PromptExportData.self, from: data)
        
        // 重複チェックして追加
        for prompt in importData.customPrompts {
            if !customPrompts.contains(where: { $0.name == prompt.name }) {
                customPrompts.append(prompt)
            }
        }
        
        for entry in importData.userDictionary {
            if !userDictionary.contains(where: { $0.term == entry.term }) {
                userDictionary.append(entry)
            }
        }
        
        saveCustomPrompts()
        saveUserDictionary()
    }
}

// MARK: - Models

struct CustomPrompt: Identifiable, Codable {
    let id: UUID
    var name: String
    var content: String
    let createdAt: Date
    var updatedAt: Date
    
    init(name: String, content: String) {
        self.id = UUID()
        self.name = name
        self.content = content
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

struct DictionaryEntry: Identifiable, Codable {
    let id: UUID
    var term: String
    var reading: String
    var definition: String
    let createdAt: Date
    var updatedAt: Date
    
    init(term: String, reading: String, definition: String) {
        self.id = UUID()
        self.term = term
        self.reading = reading
        self.definition = definition
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

struct PromptExportData: Codable {
    let customPrompts: [CustomPrompt]
    let userDictionary: [DictionaryEntry]
    let exportedAt: Date
}
