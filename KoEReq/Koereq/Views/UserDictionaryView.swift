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
            return promptManager.userDictionary.sorted { $0.term < $1.term }
        } else {
            return promptManager.searchDictionary(query: searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // ヘッダー
                headerView
                
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
            DictionaryEntryEditView(entry: nil) { term, reading, definition in
                promptManager.addDictionaryEntry(term: term, reading: reading, definition: definition)
            }
        }
        .sheet(item: $editingEntry) { entry in
            DictionaryEntryEditView(entry: entry) { term, reading, definition in
                promptManager.updateDictionaryEntry(id: entry.id, term: term, reading: reading, definition: definition)
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
            
            Text("ユーザー辞書")
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
    
    private var searchBarView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("用語を検索", text: $searchText)
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
            Image(systemName: "book.closed")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.5))
            
            if searchText.isEmpty {
                Text("辞書項目がありません")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("医療用語や専門用語を登録して\n音声認識の精度を向上させましょう")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button(action: { showingAddEntry = true }) {
                    Text("最初の項目を追加")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            } else {
                Text("検索結果がありません")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("「\(searchText)」に一致する項目が見つかりません")
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
            LazyVStack(spacing: 12) {
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.term)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if !entry.reading.isEmpty {
                        Text("読み: \(entry.reading)")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
                
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
            
            if !entry.definition.isEmpty {
                Text(entry.definition)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            
            HStack {
                Text("作成: \(formatDate(entry.createdAt))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if entry.updatedAt != entry.createdAt {
                    Text("更新: \(formatDate(entry.updatedAt))")
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

struct DictionaryEntryEditView: View {
    let entry: DictionaryEntry?
    let onSave: (String, String, String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var term: String
    @State private var reading: String
    @State private var definition: String
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    init(entry: DictionaryEntry?, onSave: @escaping (String, String, String) -> Void) {
        self.entry = entry
        self.onSave = onSave
        self._term = State(initialValue: entry?.term ?? "")
        self._reading = State(initialValue: entry?.reading ?? "")
        self._definition = State(initialValue: entry?.definition ?? "")
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("用語")
                        .font(.headline)
                    
                    TextField("医療用語を入力", text: $term)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("読み方")
                        .font(.headline)
                    
                    TextField("ひらがなで読み方を入力", text: $reading)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("定義・説明")
                        .font(.headline)
                    
                    TextEditor(text: $definition)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding(20)
            .navigationTitle(entry == nil ? "新規項目" : "項目編集")
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
        !term.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func saveEntry() {
        let trimmedTerm = term.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedReading = reading.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDefinition = definition.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedTerm.isEmpty else {
            alertMessage = "用語を入力してください"
            showingAlert = true
            return
        }
        
        onSave(trimmedTerm, trimmedReading, trimmedDefinition)
        dismiss()
    }
}

#Preview {
    UserDictionaryView()
        .environmentObject(PromptManager())
}
