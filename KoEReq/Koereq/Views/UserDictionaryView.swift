//
//  UserDictionaryView.swift
//  Koereq
//
//  Created by Koereq Team on 2025/05/23.
//

import SwiftUI

struct UserDictionaryView: View {
    @EnvironmentObject var promptManager: PromptManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var showingAddEntry = false
    @State private var editingEntry: DictionaryEntry?
    @State private var showingDeleteAlert = false
    @State private var entryToDelete: DictionaryEntry?
    
    private var filteredEntries: [DictionaryEntry] {
        if searchText.isEmpty {
            return promptManager.userDictionary.sorted { $0.wrongTerm < $1.wrongTerm }
        } else {
            return promptManager.searchDictionary(query: searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // ヘッダー
                headerView
                
                // 説明テキスト
                explanationView
                
                // 検索バー
                searchBarView
                
                // 辞書一覧
                if filteredEntries.isEmpty {
                    emptyStateView
                } else {
                    dictionaryListView
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingAddEntry) {
            DictionaryEntryEditView(entry: nil) { wrongTerm, correctTerm in
                promptManager.addDictionaryEntry(wrongTerm: wrongTerm, correctTerm: correctTerm)
            }
        }
        .sheet(item: $editingEntry) { entry in
            DictionaryEntryEditView(entry: entry) { wrongTerm, correctTerm in
                promptManager.updateDictionaryEntry(id: entry.id, wrongTerm: wrongTerm, correctTerm: correctTerm)
            }
        }
        .alert("辞書項目を削除", isPresented: $showingDeleteAlert) {
            Button("削除", role: .destructive) {
                if let entry = entryToDelete {
                    promptManager.deleteDictionaryEntry(id: entry.id)
                }
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("この辞書項目を削除しますか？この操作は取り消せません。")
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
            
            Text("音声変換辞書")
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            Button(action: { showingAddEntry = true }) {
                Image(systemName: "plus")
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
    }
    
    private var explanationView: some View {
        VStack(spacing: 8) {
            Text("音声認識の誤変換を修正")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text("例：「ご縁性肺炎」→「誤嚥性肺炎」、「著名」→「著明」")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
    }
    
    private var searchBarView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("変換を検索", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "text.bubble")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.5))
            
            if searchText.isEmpty {
                Text("変換辞書がありません")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("音声認識で間違いやすい用語を\n正しい表記に変換する設定を追加しましょう")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button(action: { showingAddEntry = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("最初の変換を追加")
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(25)
                }
            } else {
                Text("検索結果がありません")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("「\(searchText)」に一致する変換が見つかりません")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 60)
    }
    
    private var dictionaryListView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(filteredEntries) { entry in
                    DictionaryEntryCardView(
                        entry: entry,
                        onEdit: { editingEntry = entry },
                        onDelete: {
                            entryToDelete = entry
                            showingDeleteAlert = true
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }
}

struct DictionaryEntryCardView: View {
    let entry: DictionaryEntry
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // 変換表示
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    // 誤変換（左側）
                    VStack(alignment: .leading, spacing: 2) {
                        Text("誤変換")
                            .font(.caption2)
                            .foregroundColor(.red)
                            .fontWeight(.medium)
                        
                        Text(entry.wrongTerm)
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(6)
                    }
                    
                    // 矢印
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                    
                    // 正しい変換（右側）
                    VStack(alignment: .leading, spacing: 2) {
                        Text("正しい変換")
                            .font(.caption2)
                            .foregroundColor(.green)
                            .fontWeight(.medium)
                        
                        Text(entry.correctTerm)
                            .font(.subheadline)
                            .foregroundColor(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(6)
                    }
                    
                    Spacer()
                }
                
                // 作成日時
                Text("作成: \(formatDate(entry.createdAt))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // 操作ボタン
            VStack(spacing: 8) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .frame(width: 32, height: 32)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red)
                        .frame(width: 32, height: 32)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding(12)
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

struct DictionaryEntryEditView: View {
    let entry: DictionaryEntry?
    let onSave: (String, String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var wrongTerm: String
    @State private var correctTerm: String
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    init(entry: DictionaryEntry?, onSave: @escaping (String, String) -> Void) {
        self.entry = entry
        self.onSave = onSave
        self._wrongTerm = State(initialValue: entry?.wrongTerm ?? "")
        self._correctTerm = State(initialValue: entry?.correctTerm ?? "")
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 説明
                    VStack(spacing: 8) {
                        Text("音声認識の誤変換を修正する設定")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                        
                        Text("音声入力で間違って認識される言葉を、正しい表記に自動変換します")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // 入力フォーム
                    VStack(spacing: 20) {
                        // 誤変換される文字
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("誤変換される文字")
                                    .font(.headline)
                                    .foregroundColor(.red)
                                
                                Spacer()
                                
                                Text("例：ご縁性肺炎")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            TextField("音声認識で間違って入力される文字", text: $wrongTerm)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                )
                        }
                        
                        // 矢印
                        HStack {
                            Spacer()
                            Image(systemName: "arrow.down")
                                .font(.title2)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        
                        // 正しい変換
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("正しい変換")
                                    .font(.headline)
                                    .foregroundColor(.green)
                                
                                Spacer()
                                
                                Text("例：誤嚥性肺炎")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            TextField("正しく変換したい文字", text: $correctTerm)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle(entry == nil ? "新規変換追加" : "変換編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveEntry()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
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
        !wrongTerm.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !correctTerm.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func saveEntry() {
        let trimmedWrongTerm = wrongTerm.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCorrectTerm = correctTerm.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedWrongTerm.isEmpty else {
            alertMessage = "誤変換される文字を入力してください"
            showingAlert = true
            return
        }
        
        guard !trimmedCorrectTerm.isEmpty else {
            alertMessage = "正しい変換を入力してください"
            showingAlert = true
            return
        }
        
        guard trimmedWrongTerm != trimmedCorrectTerm else {
            alertMessage = "誤変換と正しい変換が同じです"
            showingAlert = true
            return
        }
        
        onSave(trimmedWrongTerm, trimmedCorrectTerm)
        dismiss()
    }
}

#Preview {
    UserDictionaryView()
        .environmentObject(PromptManager())
}
