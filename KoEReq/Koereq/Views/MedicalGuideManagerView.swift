//
//  MedicalGuideManagerView.swift
//  Koereq
//
//  Created by Koereq Team on 2025/06/30.
//

import SwiftUI

struct MedicalGuideManagerView: View {
    @EnvironmentObject var medicalGuideManager: MedicalGuideManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(medicalGuideManager.guideSets) { guideSet in
                        GuideSetRow(
                            guideSet: guideSet,
                            isSelected: medicalGuideManager.selectedGuideSetId == guideSet.id
                        ) {
                            medicalGuideManager.selectGuideSet(guideSet)
                        }
                    }
                } header: {
                    Text("利用可能なガイド")
                } footer: {
                    Text("使用したいガイドセットを選択してください。セッション中の医療ガイドが変更されます。")
                        .font(.caption)
                }
            }
            .navigationTitle("医療ガイド設定")
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

struct GuideSetRow: View {
    let guideSet: MedicalGuideSet
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(guideSet.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if guideSet.isDefault {
                            Text("デフォルト")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(guideSet.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(guideSet.categories.count)個のカテゴリー")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.8))
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    MedicalGuideManagerView()
}