//
//  PromptManagerView.swift
//  Koereq
//
//  Created by Koereq Team on 2025/05/23.
//

import SwiftUI

struct PromptManagerView: View {
    @EnvironmentObject var promptManager: PromptManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingAddPrompt = false
    @State private var editingPrompt: CustomPrompt?
    @State private var showingDeleteAlert = false
    @State private var promptToDelete: CustomPrompt?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // ヘッダー
                headerView
                
                // プロンプト一覧
                ScrollView {
                    LazyVStack(spacing: 12) {
                        // デフォルトプロンプト
                        defaultPromptsSection
                        
                        // カスタムプロンプト
                        customPromptsSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingAddPrompt) {
            PromptEditView(prompt: nil) { name, content in
                promptManager.addCustomPrompt(name: name, content: content)
            }
        }
        .sheet(item: $editingPrompt) { prompt in
            PromptEditView(prompt: prompt) { name, content in
                promptManager.updateCustomPrompt(id: prompt.id, name: name, content: content)
            }
        }
        .alert("プロンプトを削除", isPresented: $showingDeleteAlert) {
            Button("削除", role: .destructive) {
                if let prompt = promptToDelete {
                    promptManager.deleteCustomPrompt(id: prompt.id)
                }
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("このプロンプトを削除しますか？この操作は取り消せません。")
        }
    }
    
    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("戻る")
                }
                .foregroundColor(.blue)
            }
            
            Spacer()
            
            Text("プロンプトマネージャー")
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            Button(action: { showingAddPrompt = true }) {
                Image(systemName: "plus")
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
    }
    
    private var defaultPromptsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("デフォルトプロンプト")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 4)
            
            ForEach(promptManager.defaultPrompts, id: \.displayName) { promptType in
                DefaultPromptCardView(promptType: promptType)
            }
        }
    }
    
    private var customPromptsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("カスタムプロンプト")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(promptManager.customPrompts.count)件")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 4)
            
            if promptManager.customPrompts.isEmpty {
                emptyCustomPromptsView
            } else {
                ForEach(promptManager.customPrompts) { prompt in
                    CustomPromptCardView(
                        prompt: prompt,
                        onEdit: { editingPrompt = prompt },
                        onDelete: { 
                            promptToDelete = prompt
                            showingDeleteAlert = true
                        }
                    )
                }
            }
        }
    }
    
    private var emptyCustomPromptsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "text.bubble")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("カスタムプロンプトがありません")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: { showingAddPrompt = true }) {
                Text("最初のプロンプトを作成")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct DefaultPromptCardView: View {
    let promptType: PromptType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(promptType.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("デフォルト")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(4)
            }
            
            Text(promptType.promptTemplate)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(3)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }
}

struct CustomPromptCardView: View {
    let prompt: CustomPrompt
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(prompt.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Menu {
                    Button(action: onEdit) {
                        Label("編集", systemImage: "pencil")
                    }
                    
                    Button(action: onDelete) {
                        Label("削除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                }
            }
            
            Text(prompt.content)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            HStack {
                Text("作成: \(formatDate(prompt.createdAt))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if prompt.updatedAt != prompt.createdAt {
                    Text("更新: \(formatDate(prompt.updatedAt))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct PromptEditView: View {
    let prompt: CustomPrompt?
    let onSave: (String, String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var content: String
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    init(prompt: CustomPrompt?, onSave: @escaping (String, String) -> Void) {
        self.prompt = prompt
        self.onSave = onSave
        self._name = State(initialValue: prompt?.name ?? "")
        self._content = State(initialValue: prompt?.content ?? "")
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("プロンプト名")
                        .font(.headline)
                    
                    TextField("プロンプト名を入力", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("プロンプト内容")
                        .font(.headline)
                    
                    Text("{transcript} の部分に音声記録が挿入されます")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $content)
                        .frame(minHeight: 200)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding(20)
            .navigationTitle(prompt == nil ? "新規プロンプト" : "プロンプト編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        savePrompt()
                    }
                    .disabled(!isValid)
                }
            }
        }
        .alert("エラー", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func savePrompt() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            alertMessage = "プロンプト名を入力してください"
            showingAlert = true
            return
        }
        
        guard !trimmedContent.isEmpty else {
            alertMessage = "プロンプト内容を入力してください"
            showingAlert = true
            return
        }
        
        onSave(trimmedName, trimmedContent)
        dismiss()
    }
}

#Preview {
    PromptManagerView()
        .environmentObject(PromptManager())
}
