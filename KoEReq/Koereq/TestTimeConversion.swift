import Foundation

// 時間変換機能のテスト
class TimeConversionTest {
    
    static func runTests() {
        print("=== 時間変換機能テスト開始 ===")
        
        let parser = RelativeTimeParser.shared
        
        // 現在時刻を表示
        let now = Date()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        print("現在時刻: \(formatter.string(from: now))")
        print("")
        
        // テストケース
        let testCases = [
            "30分後に到着予定です",
            "1時間後に手術を開始します",
            "今から30分後に薬を投与します",
            "今から1時間後に検査結果が出ます",
            "3日前から症状があります",
            "明日手術予定です"
        ]
        
        for (index, testCase) in testCases.enumerated() {
            print("テスト\(index + 1): \(testCase)")
            
            let result = parser.parseRelativeTime(from: testCase)
            print("変換結果: \(result.processedText)")
            
            if !result.detectedDates.isEmpty {
                print("検出された時間表現:")
                for detectedDate in result.detectedDates {
                    let typeLabel = detectedDate.isTimeUnit ? "時刻" : "日付"
                    print("  - \(detectedDate.originalText) → \(formatByType(detectedDate.calculatedDate, isTimeUnit: detectedDate.isTimeUnit)) (\(typeLabel))")
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