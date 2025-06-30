//
//  MedicalGuideManager.swift
//  Koereq
//
//  Created by Koereq Team on 2025/06/30.
//

import SwiftUI
import Combine

// MARK: - Medical Guide Set Model
struct MedicalGuideSet: Identifiable {
    let id: UUID
    var name: String
    var description: String
    var categories: [MedicalGuideCategory]
    var isDefault: Bool
    
    init(id: UUID = UUID(), name: String, description: String, categories: [MedicalGuideCategory], isDefault: Bool = false) {
        self.id = id
        self.name = name
        self.description = description
        self.categories = categories
        self.isDefault = isDefault
    }
}

class MedicalGuideManager: ObservableObject {
    @Published var guideSets: [MedicalGuideSet] = []
    @Published var selectedGuideSetId: UUID?
    
    private let userDefaults = UserDefaults.standard
    private let selectedGuideKey = "selectedMedicalGuideSetId"
    
    var selectedGuideSet: MedicalGuideSet? {
        guideSets.first { $0.id == selectedGuideSetId }
    }
    
    var currentCategories: [MedicalGuideCategory] {
        selectedGuideSet?.categories.filter { $0.isEnabled } ?? []
    }
    
    init() {
        loadGuideSets()
        loadSelectedGuideSet()
    }
    
    private func loadGuideSets() {
        // Create default guide sets
        let generalCategories = [
            MedicalGuideCategory(
                title: "基本情報",
                icon: "person.fill",
                colorHex: "#007AFF",
                items: [
                    "年齢",
                    "性別",
                    "居住形態（独居・家族同居など）",
                    "介護度（要支援・要介護など）",
                    "ADL（日常生活動作の自立度）"
                ],
                order: 0
            ),
            MedicalGuideCategory(
                title: "病歴・既往歴",
                icon: "clock.fill",
                colorHex: "#FF9500",
                items: [
                    "主訴（今回の主な症状・問題）",
                    "現病歴（症状の経過・変化）",
                    "既往歴（過去の病気・手術歴）",
                    "内服薬（現在服用中の薬剤名）",
                    "生活歴（居住形態（施設など）、ADL、喫煙・飲酒）"
                ],
                order: 1
            ),
            MedicalGuideCategory(
                title: "バイタルサイン",
                icon: "waveform.path.ecg",
                colorHex: "#34C759",
                items: [
                    "意識レベルGCS（E, V, M）、瞳孔所見など",
                    "血圧（収縮期/拡張期 mmHg）",
                    "脈拍（回/分、リズム）",
                    "SpO2（%、室内気または酸素下）",
                    "酸素投与量（L/分、投与方法）",
                    "呼吸数（回/分）",
                    "体温（℃）"
                ],
                order: 2
            ),
            MedicalGuideCategory(
                title: "身体所見",
                icon: "stethoscope",
                colorHex: "#AF52DE",
                items: [
                    "外観・全身状態",
                    "頭頸部所見",
                    "胸部所見（心音・呼吸音）",
                    "腹部所見",
                    "四肢所見",
                    "皮膚所見",
                    "神経学的所見"
                ],
                order: 3
            ),
            MedicalGuideCategory(
                title: "検査・診断",
                icon: "doc.text.magnifyingglass",
                colorHex: "#5856D6",
                items: [
                    "血液検査結果",
                    "画像検査結果（X線・CT・MRIなど）",
                    "心電図所見",
                    "その他の検査結果",
                    "診断名・病名",
                    "病期・重症度"
                ],
                order: 4
            ),
            MedicalGuideCategory(
                title: "治療・方針",
                icon: "cross.case.fill",
                colorHex: "#FF2D55",
                items: [
                    "治療方針・計画",
                    "処方薬剤の変更",
                    "処置・手技の実施",
                    "患者・家族への説明内容",
                    "今後の予定・フォローアップ",
                    "注意事項・指導内容"
                ],
                order: 5
            )
        ]
        
        guideSets = [
            MedicalGuideSet(
                name: "一般医療",
                description: "一般的な医療記録に適用される標準的なガイド",
                categories: generalCategories,
                isDefault: true
            )
        ]
        
        // Set default if no selection
        if selectedGuideSetId == nil {
            selectedGuideSetId = guideSets.first { $0.isDefault }?.id
        }
    }
    
    private func loadSelectedGuideSet() {
        if let savedGuideIdString = userDefaults.string(forKey: selectedGuideKey),
           let savedGuideId = UUID(uuidString: savedGuideIdString) {
            selectedGuideSetId = savedGuideId
        }
    }
    
    func selectGuideSet(_ guideSet: MedicalGuideSet) {
        selectedGuideSetId = guideSet.id
        userDefaults.set(guideSet.id.uuidString, forKey: selectedGuideKey)
    }
}