//
//  MedicalGuideModel.swift
//  Koereq
//
//  Created by Koereq Team on 2025/06/30.
//

import SwiftUI

// MARK: - Medical Guide Category Model
struct MedicalGuideCategory: Codable, Identifiable, Equatable {
    let id: UUID
    var title: String
    var icon: String
    var colorHex: String
    var items: [String]
    var order: Int
    var isEnabled: Bool
    
    init(id: UUID = UUID(), title: String, icon: String, colorHex: String, items: [String], order: Int, isEnabled: Bool = true) {
        self.id = id
        self.title = title
        self.icon = icon
        self.colorHex = colorHex
        self.items = items
        self.order = order
        self.isEnabled = isEnabled
    }
    
    var color: Color {
        Color(hex: colorHex) ?? .blue
    }
}

// MARK: - Default Categories
extension MedicalGuideCategory {
    static let defaultCategories: [MedicalGuideCategory] = [
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
}

// MARK: - Color Extension
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    func toHex() -> String {
        guard let components = UIColor(self).cgColor.components else { return "#000000" }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        
        return String(format: "#%02lX%02lX%02lX",
                      lroundf(r * 255),
                      lroundf(g * 255),
                      lroundf(b * 255))
    }
}