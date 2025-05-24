import Foundation

// MARK: - 使用例とテストケース

class RelativeTimeParserTests {
    
    static func runAllTests() {
        print("=== 相対時間解析機能のテスト開始 ===")
        
        testBasicRelativeExpressions()
        testSpecialExpressions()
        testMixedExpressions()
        testDeviceTimeInfo()
        testEdgeCases()
        
        print("=== テスト完了 ===\n")
    }
    
    /// 基本的な相対時間表現のテスト
    static func testBasicRelativeExpressions() {
        print("\n1. 基本的な相対時間表現のテスト")
        let parser = RelativeTimeParser.shared
        
        let testCases = [
            "30分前に患者さんが来院されました",
            "2時間後に手術予定です",
            "3日前から症状が続いています",
            "1週間後に再診をお願いします",
            "2ヶ月前に検査を受けました"
        ]
        
        for testCase in testCases {
            let result = parser.parseRelativeTime(from: testCase)
            print("  入力: \(testCase)")
            print("  変換: \(result.processedText)")
            print("  検出された日時: \(result.detectedDates.count)件")
            for detectedDate in result.detectedDates {
                print("    - \(detectedDate.originalText) → \(formatDateByType(detectedDate.calculatedDate, isTimeUnit: detectedDate.isTimeUnit))")
            }
            print("")
        }
    }
    
    /// 特殊表現のテスト
    static func testSpecialExpressions() {
        print("2. 特殊表現のテスト")
        let parser = RelativeTimeParser.shared
        
        let testCases = [
            "昨日の症状について話します",
            "明日の手術について説明します",
            "今日は調子が良いです",
            "先週の検査結果を確認します",
            "来月からお薬を変更します"
        ]
        
        for testCase in testCases {
            let result = parser.parseRelativeTime(from: testCase)
            print("  入力: \(testCase)")
            print("  変換: \(result.processedText)")
            print("")
        }
    }
    
    /// 複数の時間表現が含まれるテスト
    static func testMixedExpressions() {
        print("3. 複数時間表現のテスト")
        let parser = RelativeTimeParser.shared
        
        let complexText = "1週間前から症状が始まり、3日前に悪化し、明日手術を予定しています。1ヶ月後に経過観察をします。"
        let result = parser.parseRelativeTime(from: complexText)
        
        print("  入力: \(complexText)")
        print("  変換: \(result.processedText)")
        print("  検出された日時表現: \(result.detectedDates.count)件")
        for (index, detectedDate) in result.detectedDates.enumerated() {
            print("    \(index + 1). \(detectedDate.originalText) → \(formatDateByType(detectedDate.calculatedDate, isTimeUnit: detectedDate.isTimeUnit))")
        }
        print("")
    }
    
    /// デバイス時刻情報のテスト
    static func testDeviceTimeInfo() {
        print("4. デバイス時刻情報のテスト")
        let parser = RelativeTimeParser.shared
        let deviceTime = parser.getCurrentDeviceTime()
        
        print("  現在時刻: \(deviceTime.formattedString)")
        print("  タイムゾーン: \(deviceTime.timeZoneIdentifier)")
        print("  オフセット: \(deviceTime.timeZoneOffset)")
        print("  カレンダー: \(deviceTime.calendar.identifier)")
        print("")
    }
    
    /// エッジケースのテスト
    static func testEdgeCases() {
        print("5. エッジケースのテスト")
        let parser = RelativeTimeParser.shared
        
        let edgeCases = [
            "", // 空文字
            "時間表現が含まれていないテキスト",
            "100年前の出来事について", // 極端な値
            "0分前に何かが起こりました" // ゼロ値
        ]
        
        for testCase in edgeCases {
            let result = parser.parseRelativeTime(from: testCase)
            print("  入力: '\(testCase)'")
            print("  変換: '\(result.processedText)'")
            print("  検出件数: \(result.detectedDates.count)")
            print("")
        }
    }
    
    /// 日時フォーマットのヘルパー関数
    static func formatDateForDisplay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    /// 単位に応じた日時フォーマット関数
    static func formatDateByType(_ date: Date, isTimeUnit: Bool) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        
        if isTimeUnit {
            // 時間単位（分・時間）の場合：時刻のみ表示
            formatter.dateStyle = .none
            formatter.timeStyle = .short
        } else {
            // 日付単位（日・週・月・年）の場合：日付のみ表示
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
        }
        
        return formatter.string(from: date)
    }
}

// MARK: - 実用的な医療分野での使用例

class MedicalUseCaseExamples {
    
    static func demonstrateMedicalUseCases() {
        print("=== 医療分野での実用例 ===")
        
        let parser = RelativeTimeParser.shared
        
        let medicalScenarios = [
            "患者さんは2週間前から咳の症状があり、3日前に発熱しました。明日再診予定です。",
            "1ヶ月前に手術を受け、昨日抜糸を行いました。来週経過観察をします。",
            "5分前に救急搬送されてきた患者です。30分後に検査結果が出る予定です。",
            "去年から通院されており、先月から新しい薬を開始しています。"
        ]
        
        for (index, scenario) in medicalScenarios.enumerated() {
            print("\nシナリオ \(index + 1):")
            print("元のテキスト:")
            print("  \(scenario)")
            
            let result = parser.parseRelativeTime(from: scenario)
            print("日時情報を明確化したテキスト:")
            print("  \(result.processedText)")
            
            if !result.detectedDates.isEmpty {
                print("検出された日時:")
                for detectedDate in result.detectedDates {
                    print("  - \(detectedDate.originalText) → \(RelativeTimeParserTests.formatDateByType(detectedDate.calculatedDate, isTimeUnit: detectedDate.isTimeUnit))")
                }
            }
        }
        
        print("\n=== 医療分野での実用例 完了 ===")
    }
} 