import Foundation

// 修正された相対時間解析機能のテスト実行
class TestRunner {
    
    static func runModifiedTests() {
        print("=== 修正された相対時間解析機能のテスト ===")
        print("デバイス時刻を基準として、時間単位は時刻のみ、日付単位は日付のみを表示\n")
        
        let parser = RelativeTimeParser.shared
        
        // デバイス時刻の確認
        let deviceTime = parser.getCurrentDeviceTime()
        print("📱 現在のデバイス時刻: \(deviceTime.formattedString)")
        print("   タイムゾーン: \(deviceTime.timeZoneIdentifier)")
        print("   オフセット: \(deviceTime.timeZoneOffset)\n")
        
        // テストケース
        let testCases = [
            // 時間単位（時刻のみ表示されるべき）
            "30分前に患者さんが来院されました",
            "2時間後に手術予定です",
            "15分前に薬を投与しました",
            
            // 日付単位（日付のみ表示されるべき）
            "3日前から症状が続いています",
            "1週間後に再診をお願いします",
            "2ヶ月前に検査を受けました",
            "昨日から調子が悪いです",
            "明日手術を行います",
            
            // 混合パターン
            "1時間前に到着し、3日前から症状があります",
            "昨日の朝、30分後に薬を飲む予定でした"
        ]
        
        for (index, testCase) in testCases.enumerated() {
            print("テスト \(index + 1):")
            print("入力: \(testCase)")
            
            let result = parser.parseRelativeTime(from: testCase)
            print("変換: \(result.processedText)")
            
            if !result.detectedDates.isEmpty {
                print("検出された表現:")
                for detectedDate in result.detectedDates {
                    let typeLabel = detectedDate.isTimeUnit ? "時刻" : "日付"
                    let formatted = formatByType(detectedDate.calculatedDate, isTimeUnit: detectedDate.isTimeUnit)
                    print("  - \(detectedDate.originalText) → \(formatted) (\(typeLabel)系)")
                }
            }
            print("")
        }
        
        print("=== テスト完了 ===")
    }
    
    private static func formatByType(_ date: Date, isTimeUnit: Bool) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        
        if isTimeUnit {
            // 時間単位：時刻のみ
            formatter.dateStyle = .none
            formatter.timeStyle = .short
        } else {
            // 日付単位：日付のみ
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
        }
        
        return formatter.string(from: date)
    }
}

// テスト実行のエントリーポイント
extension TestRunner {
    static func runQuickDemo() {
        print("🕐 簡単なデモンストレーション")
        
        let parser = RelativeTimeParser.shared
        let now = Date()
        
        // 現在時刻の表示
        let deviceFormatter = DateFormatter()
        deviceFormatter.locale = Locale(identifier: "ja_JP")
        deviceFormatter.dateStyle = .medium
        deviceFormatter.timeStyle = .short
        print("現在時刻: \(deviceFormatter.string(from: now))")
        
        let demoText = "30分前に来院し、3日前から症状があります。2時間後に手術予定です。"
        print("\nデモテキスト: \(demoText)")
        
        let result = parser.parseRelativeTime(from: demoText)
        print("変換結果: \(result.processedText)")
        
        print("\n詳細:")
        for date in result.detectedDates {
            let typeDesc = date.isTimeUnit ? "時刻のみ表示" : "日付のみ表示"
            print("・\(date.originalText) → \(typeDesc)")
        }
    }
} 