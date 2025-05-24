#!/usr/bin/env swift

import Foundation

// 統合された相対時間解析機能のテスト
func testRelativeTimeParser() {
    print("=== 相対時間解析機能テスト ===")
    
    let parser = RelativeTimeParser.shared
    
    // 現在のデバイス時刻を表示
    let deviceTime = parser.getCurrentDeviceTime()
    print("📱 デバイス時刻: \(deviceTime.formattedString)")
    print("   タイムゾーン: \(deviceTime.timeZoneIdentifier)")
    print("   UTC オフセット: \(deviceTime.timeZoneOffset)\n")
    
    // テストケース
    let testCases = [
        "30分前に患者さんが来院されました",
        "2時間後に手術予定です", 
        "3日前から症状が続いています",
        "昨日から調子が悪いです",
        "明日手術を行います",
        "1週間後に再診をお願いします"
    ]
    
    for (index, testCase) in testCases.enumerated() {
        print("テスト\(index + 1): \(testCase)")
        
        let result = parser.parseRelativeTime(from: testCase)
        print("変換結果: \(result.processedText)")
        
        for detectedDate in result.detectedDates {
            let typeLabel = detectedDate.isTimeUnit ? "時刻系" : "日付系"
            print("  → \(detectedDate.originalText) (\(typeLabel))")
        }
        print("")
    }
    
    // 混合パターンのテスト
    print("=== 混合パターンテスト ===")
    let complexText = "30分前に来院し、3日前から症状があります。2時間後に手術、明日退院予定です。"
    print("入力: \(complexText)")
    
    let complexResult = parser.parseRelativeTime(from: complexText)
    print("変換: \(complexResult.processedText)")
    
    print("\n検出された時間表現:")
    for (index, detectedDate) in complexResult.detectedDates.enumerated() {
        let typeLabel = detectedDate.isTimeUnit ? "時刻のみ表示" : "日付のみ表示"
        print("  \(index + 1). \(detectedDate.originalText) → \(typeLabel)")
    }
    
    print("\n=== テスト完了 ===")
}

// メイン実行
testRelativeTimeParser() 