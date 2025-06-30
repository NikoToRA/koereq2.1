//
//  MedicalGuideManager.swift
//  Koereq
//
//  Created by Koereq Team on 2025/06/30.
//

import SwiftUI
import Combine

class MedicalGuideManager: ObservableObject {
    @Published var categories: [MedicalGuideCategory] = []
    
    private let userDefaults = UserDefaults.standard
    private let categoriesKey = "medicalGuideCategories"
    
    init() {
        loadCategories()
    }
    
    // MARK: - Load/Save Methods
    
    func loadCategories() {
        if let data = userDefaults.data(forKey: categoriesKey),
           let decodedCategories = try? JSONDecoder().decode([MedicalGuideCategory].self, from: data) {
            self.categories = decodedCategories.sorted { $0.order < $1.order }
        } else {
            // 初回起動時はデフォルトカテゴリーをロード
            self.categories = MedicalGuideCategory.defaultCategories
            saveCategories()
        }
    }
    
    func saveCategories() {
        if let encoded = try? JSONEncoder().encode(categories) {
            userDefaults.set(encoded, forKey: categoriesKey)
        }
    }
    
    // MARK: - Category Management
    
    func addCategory(_ category: MedicalGuideCategory) {
        var newCategory = category
        newCategory.order = categories.count
        categories.append(newCategory)
        saveCategories()
    }
    
    func updateCategory(_ category: MedicalGuideCategory) {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index] = category
            saveCategories()
        }
    }
    
    func deleteCategory(_ category: MedicalGuideCategory) {
        categories.removeAll { $0.id == category.id }
        // 順序を再設定
        for (index, var category) in categories.enumerated() {
            category.order = index
            categories[index] = category
        }
        saveCategories()
    }
    
    func moveCategory(from source: IndexSet, to destination: Int) {
        categories.move(fromOffsets: source, toOffset: destination)
        // 順序を再設定
        for (index, var category) in categories.enumerated() {
            category.order = index
            categories[index] = category
        }
        saveCategories()
    }
    
    // MARK: - Item Management
    
    func addItem(to categoryId: UUID, item: String) {
        if let index = categories.firstIndex(where: { $0.id == categoryId }) {
            categories[index].items.append(item)
            saveCategories()
        }
    }
    
    func updateItem(in categoryId: UUID, oldItem: String, newItem: String) {
        if let categoryIndex = categories.firstIndex(where: { $0.id == categoryId }),
           let itemIndex = categories[categoryIndex].items.firstIndex(of: oldItem) {
            categories[categoryIndex].items[itemIndex] = newItem
            saveCategories()
        }
    }
    
    func deleteItem(from categoryId: UUID, item: String) {
        if let index = categories.firstIndex(where: { $0.id == categoryId }) {
            categories[index].items.removeAll { $0 == item }
            saveCategories()
        }
    }
    
    func moveItem(in categoryId: UUID, from source: IndexSet, to destination: Int) {
        if let index = categories.firstIndex(where: { $0.id == categoryId }) {
            categories[index].items.move(fromOffsets: source, toOffset: destination)
            saveCategories()
        }
    }
    
    // MARK: - Reset
    
    func resetToDefaults() {
        categories = MedicalGuideCategory.defaultCategories
        saveCategories()
    }
    
    // MARK: - Export/Import
    
    func exportCategories() -> String? {
        if let data = try? JSONEncoder().encode(categories) {
            return data.base64EncodedString()
        }
        return nil
    }
    
    func importCategories(from base64String: String) -> Bool {
        guard let data = Data(base64Encoded: base64String),
              let importedCategories = try? JSONDecoder().decode([MedicalGuideCategory].self, from: data) else {
            return false
        }
        categories = importedCategories
        saveCategories()
        return true
    }
}