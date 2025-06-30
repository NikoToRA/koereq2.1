//
//  MedicalGuideManagerView.swift
//  Koereq
//
//  Created by Koereq Team on 2025/06/30.
//

import SwiftUI

struct MedicalGuideManagerView: View {
    @StateObject private var medicalGuideManager = MedicalGuideManager()
    @State private var showingAddCategory = false
    @State private var showingEditCategory: MedicalGuideCategory?
    @State private var showingResetAlert = false
    @State private var showingExportImport = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(medicalGuideManager.categories) { category in
                        if category.isEnabled {
                            CategoryRow(category: category) {
                                showingEditCategory = category
                            }
                        }
                    }
                    .onMove { source, destination in
                        medicalGuideManager.moveCategory(from: source, to: destination)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let category = medicalGuideManager.categories[index]
                            medicalGuideManager.deleteCategory(category)
                        }
                    }
                } header: {
                    Text("カテゴリー一覧")
                } footer: {
                    Text("カテゴリーをタップして編集、長押しで並び替え")
                        .font(.caption)
                }
                
                Section {
                    Button(action: { showingAddCategory = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                            Text("新しいカテゴリーを追加")
                        }
                    }
                    
                    Button(action: { showingExportImport = true }) {
                        HStack {
                            Image(systemName: "arrow.up.arrow.down.circle.fill")
                                .foregroundColor(.blue)
                            Text("エクスポート/インポート")
                        }
                    }
                    
                    Button(action: { showingResetAlert = true }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise.circle.fill")
                                .foregroundColor(.orange)
                            Text("デフォルトに戻す")
                        }
                    }
                }
            }
            .navigationTitle("医療記録ガイド管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showingAddCategory) {
                CategoryEditView(
                    category: nil,
                    medicalGuideManager: medicalGuideManager
                )
            }
            .sheet(item: $showingEditCategory) { category in
                CategoryEditView(
                    category: category,
                    medicalGuideManager: medicalGuideManager
                )
            }
            .sheet(isPresented: $showingExportImport) {
                ExportImportView(medicalGuideManager: medicalGuideManager)
            }
            .alert("デフォルトに戻す", isPresented: $showingResetAlert) {
                Button("キャンセル", role: .cancel) { }
                Button("リセット", role: .destructive) {
                    medicalGuideManager.resetToDefaults()
                }
            } message: {
                Text("すべてのカテゴリーをデフォルト設定に戻します。この操作は取り消せません。")
            }
        }
    }
}

// MARK: - Category Row

struct CategoryRow: View {
    let category: MedicalGuideCategory
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundColor(category.color)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("\(category.items.count)個の項目")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Category Edit View

struct CategoryEditView: View {
    let category: MedicalGuideCategory?
    let medicalGuideManager: MedicalGuideManager
    
    @State private var title: String = ""
    @State private var icon: String = ""
    @State private var selectedColor: Color = .blue
    @State private var items: [String] = []
    @State private var newItem: String = ""
    @State private var isEnabled: Bool = true
    @State private var showingIconPicker = false
    @State private var showingColorPicker = false
    
    @Environment(\.dismiss) private var dismiss
    
    init(category: MedicalGuideCategory?, medicalGuideManager: MedicalGuideManager) {
        self.category = category
        self.medicalGuideManager = medicalGuideManager
        
        if let category = category {
            _title = State(initialValue: category.title)
            _icon = State(initialValue: category.icon)
            _selectedColor = State(initialValue: category.color)
            _items = State(initialValue: category.items)
            _isEnabled = State(initialValue: category.isEnabled)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("基本情報") {
                    TextField("カテゴリー名", text: $title)
                    
                    HStack {
                        Text("アイコン")
                        Spacer()
                        Button(action: { showingIconPicker = true }) {
                            HStack {
                                Image(systemName: icon.isEmpty ? "questionmark.circle" : icon)
                                    .foregroundColor(selectedColor)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    HStack {
                        Text("カラー")
                        Spacer()
                        Button(action: { showingColorPicker = true }) {
                            HStack {
                                Circle()
                                    .fill(selectedColor)
                                    .frame(width: 24, height: 24)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Toggle("有効", isOn: $isEnabled)
                }
                
                Section("項目") {
                    ForEach(items, id: \.self) { item in
                        Text(item)
                    }
                    .onDelete { indexSet in
                        items.remove(atOffsets: indexSet)
                    }
                    .onMove { source, destination in
                        items.move(fromOffsets: source, toOffset: destination)
                    }
                    
                    HStack {
                        TextField("新しい項目を追加", text: $newItem)
                        Button("追加") {
                            if !newItem.isEmpty {
                                items.append(newItem)
                                newItem = ""
                            }
                        }
                        .disabled(newItem.isEmpty)
                    }
                }
            }
            .navigationTitle(category == nil ? "新規カテゴリー" : "カテゴリー編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveCategory()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .sheet(isPresented: $showingIconPicker) {
                IconPickerView(selectedIcon: $icon)
            }
            .sheet(isPresented: $showingColorPicker) {
                ColorPickerView(selectedColor: $selectedColor)
            }
        }
    }
    
    private func saveCategory() {
        let newCategory = MedicalGuideCategory(
            id: category?.id ?? UUID(),
            title: title,
            icon: icon.isEmpty ? "folder.fill" : icon,
            colorHex: selectedColor.toHex(),
            items: items,
            order: category?.order ?? medicalGuideManager.categories.count,
            isEnabled: isEnabled
        )
        
        if category == nil {
            medicalGuideManager.addCategory(newCategory)
        } else {
            medicalGuideManager.updateCategory(newCategory)
        }
        
        dismiss()
    }
}

// MARK: - Icon Picker View

struct IconPickerView: View {
    @Binding var selectedIcon: String
    @Environment(\.dismiss) private var dismiss
    
    let icons = [
        "person.fill", "clock.fill", "waveform.path.ecg", "stethoscope",
        "doc.text.magnifyingglass", "cross.case.fill", "heart.fill", "brain",
        "lungs.fill", "eye.fill", "ear.fill", "nose.fill", "mouth.fill",
        "hand.raised.fill", "figure.walk", "bed.double.fill", "pills.fill",
        "syringe.fill", "bandage.fill", "thermometer", "drop.fill",
        "allergens", "microbe.fill", "shield.fill", "exclamationmark.triangle.fill"
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 20) {
                    ForEach(icons, id: \.self) { icon in
                        Button(action: {
                            selectedIcon = icon
                            dismiss()
                        }) {
                            VStack {
                                Image(systemName: icon)
                                    .font(.largeTitle)
                                    .foregroundColor(selectedIcon == icon ? .blue : .primary)
                                    .frame(width: 50, height: 50)
                                    .background(
                                        selectedIcon == icon ?
                                        Color.blue.opacity(0.2) : Color.clear
                                    )
                                    .cornerRadius(10)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("アイコンを選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Color Picker View

struct ColorPickerView: View {
    @Binding var selectedColor: Color
    @Environment(\.dismiss) private var dismiss
    
    let colors: [Color] = [
        .blue, .green, .red, .orange, .purple, .pink,
        .yellow, .indigo, .teal, .brown, .gray, .mint,
        .cyan, .brown
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 20) {
                    ForEach(colors, id: \.self) { color in
                        Button(action: {
                            selectedColor = color
                            dismiss()
                        }) {
                            Circle()
                                .fill(color)
                                .frame(width: 50, height: 50)
                                .overlay(
                                    selectedColor == color ?
                                    Circle()
                                        .stroke(Color.primary, lineWidth: 3)
                                        .padding(2) : nil
                                )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("カラーを選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Export/Import View

struct ExportImportView: View {
    let medicalGuideManager: MedicalGuideManager
    @State private var exportedData: String = ""
    @State private var importData: String = ""
    @State private var showingImportAlert = false
    @State private var importSuccess = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("エクスポート") {
                    Text("現在の設定をエクスポートして他のデバイスで使用できます")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("エクスポート") {
                        if let data = medicalGuideManager.exportCategories() {
                            exportedData = data
                        }
                    }
                    
                    if !exportedData.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("エクスポートデータ:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(exportedData)
                                .font(.system(.caption, design: .monospaced))
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .textSelection(.enabled)
                            
                            Button("コピー") {
                                UIPasteboard.general.string = exportedData
                            }
                            .font(.caption)
                        }
                    }
                }
                
                Section("インポート") {
                    Text("他のデバイスからエクスポートしたデータを貼り付けてください")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $importData)
                        .font(.system(.caption, design: .monospaced))
                        .frame(height: 100)
                    
                    Button("インポート") {
                        showingImportAlert = true
                    }
                    .disabled(importData.isEmpty)
                }
            }
            .navigationTitle("エクスポート/インポート")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .alert("インポート確認", isPresented: $showingImportAlert) {
                Button("キャンセル", role: .cancel) { }
                Button("インポート") {
                    importSuccess = medicalGuideManager.importCategories(from: importData)
                    if importSuccess {
                        dismiss()
                    }
                }
            } message: {
                Text("現在の設定は上書きされます。続行しますか？")
            }
        }
    }
}

#Preview {
    MedicalGuideManagerView()
}