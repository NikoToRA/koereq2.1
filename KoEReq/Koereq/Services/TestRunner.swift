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
    
    // MARK: - Azure Storage テスト
    
    static func runAzureStorageTests() async {
        print("=== Azure Storage 接続テスト ===\n")
        
        let storageService = StorageService()
        
        // 0. 設定値の確認
        print("🔧 設定値確認中...")
        printAzureConfig()
        
        // 1. 接続テスト
        print("\n🔌 Azure Storage 接続テスト中...")
        do {
            let isConnected = try await storageService.testAzureConnection()
            if isConnected {
                print("✅ Azure Storage 接続成功")
                print("   コンテナー 'koereq-sessions' が確認できました")
            } else {
                print("❌ Azure Storage 接続失敗")
                print("   コンテナーが見つからないか、認証に失敗しました")
                return
            }
        } catch {
            print("❌ Azure Storage 接続エラー: \(error)")
            print("   設定を確認してください")
            return
        }
        
        // 2. ダミーセッションのアップロードテスト
        print("\n📤 ダミーセッションアップロードテスト中...")
        let testSession = createTestSession()
        
        do {
            // テスト用の空音声ファイル配列でアップロード
            try await storageService.uploadSession(testSession, audioFiles: [])
            print("✅ ダミーセッションアップロード成功")
            print("   セッションID: \(testSession.id)")
            print("   転写データ: \(testSession.transcripts.count)件")
            print("   AI応答: \(testSession.aiResponses.count)件")
            print("\n📝 Azure Portal で確認してください:")
            print("   コンテナー: koereq-sessions")
            print("   パス: unknown/\(testSession.id.uuidString)/")
            print("   ファイル: meta.json, transcript.txt")
        } catch {
            print("❌ ダミーセッションアップロード失敗: \(error)")
            print("   詳細なエラー内容を確認してください")
        }
        
        print("\n=== Azure Storage テスト完了 ===")
    }
    
    // 現在のセッションを終了してAzureアップロードをテストする機能
    static func testCurrentSessionUpload() async {
        print("=== 現在セッションのAzureアップロードテスト ===\n")
        
        let sessionStore = SessionStore()
        
        // 現在のセッションがあるかチェック
        guard let currentSession = sessionStore.currentSession else {
            print("❌ 現在アクティブなセッションがありません")
            print("   先に録音セッションを開始してください")
            return
        }
        
        print("📋 現在のセッション情報:")
        print("   セッションID: \(currentSession.id)")
        print("   開始時刻: \(currentSession.startedAt)")
        print("   転写データ数: \(currentSession.transcripts.count)")
        print("   AI応答数: \(currentSession.aiResponses.count)")
        
        print("\n🔚 セッションを終了してAzureにアップロード中...")
        
        // セッション終了（これによりAzureアップロードが自動実行される）
        sessionStore.endCurrentSession()
        
        // 少し待機してアップロード完了を待つ
        try? await Task.sleep(nanoseconds: 3_000_000_000) // 3秒待機
        
        print("✅ セッション終了とアップロード処理が完了しました")
        print("\n📝 Azure Portal で以下を確認してください:")
        print("   コンテナー: koereq-sessions")
        print("   パス: unknown/\(currentSession.id.uuidString)/")
        print("   期待されるファイル:")
        print("   - meta.json (セッションメタデータ)")
        print("   - transcript.txt (転写データ)")
        if currentSession.transcripts.count > 0 {
            print("   - 音声ファイル (voice_*.m4a)")
        }
        
        print("\n=== 現在セッションアップロードテスト完了 ===")
    }
    
    private static func printAzureConfig() {
        let accountName = Bundle.main.object(forInfoDictionaryKey: "AzureStorageAccountName") as? String ?? "未設定"
        let containerName = Bundle.main.object(forInfoDictionaryKey: "AzureStorageContainerName") as? String ?? "未設定"
        let connectionString = Bundle.main.object(forInfoDictionaryKey: "AzureStorageConnectionString") as? String ?? "未設定"
        let accountKey = Bundle.main.object(forInfoDictionaryKey: "AzureStorageAccountKey") as? String ?? "未設定"
        
        print("   ストレージアカウント名: \(accountName)")
        print("   コンテナー名: \(containerName)")
        print("   接続文字列: \(connectionString.prefix(50))...")
        print("   アクセスキー: \(accountKey.prefix(10))...")
        
        // 設定の妥当性チェック
        var issues: [String] = []
        
        if accountName == "未設定" || accountName.contains("$(") {
            issues.append("ストレージアカウント名が未設定")
        }
        
        if containerName == "未設定" || containerName.contains("$(") {
            issues.append("コンテナー名が未設定")
        }
        
        if connectionString == "未設定" || connectionString.contains("$(") {
            issues.append("接続文字列が未設定")
        }
        
        if accountKey == "未設定" || accountKey.contains("$(") {
            issues.append("アクセスキーが未設定")
        }
        
        if !issues.isEmpty {
            print("\n⚠️  設定に問題があります:")
            for issue in issues {
                print("   - \(issue)")
            }
        } else {
            print("   ✅ 設定値は正常に読み込まれています")
        }
    }
    
    private static func createTestSession() -> Session {
        var session = Session()
        session.endedAt = Date()
        session.summary = "テストセッション - Azure Storage動作確認用"
        
        // ダミー転写データ
        let transcript1 = TranscriptChunk(text: "患者さんの症状について記録します", sequence: 1)
        let transcript2 = TranscriptChunk(text: "血圧は正常範囲内でした", sequence: 2)
        session.transcripts = [transcript1, transcript2]
        
        // ダミーAI応答
        let aiResponse = AIResponse(
            content: "記録された症状から、経過観察が推奨されます",
            promptType: .summary,
            sequence: 1
        )
        session.aiResponses = [aiResponse]
        
        return session
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
    
    // 統合テスト実行
    static func runAllTests() async {
        print("🧪 統合テスト開始\n")
        
        // 1. 相対時間解析テスト
        runModifiedTests()
        
        print("\n" + "="*50 + "\n")
        
        // 2. Azure Storage テスト
        await runAzureStorageTests()
        
        print("\n🎉 全てのテスト完了")
    }
    
    // セッション終了時のアップロード流れをテストする機能
    static func testSessionEndFlow() async {
        print("=== セッション終了→Azureアップロード フローテスト ===\n")
        
        let sessionStore = SessionStore()
        
        // 1. 新しいセッションを作成
        print("📋 新しいテストセッションを作成中...")
        let testSession = sessionStore.createNewSession()
        print("   セッションID: \(testSession.id)")
        
        // 2. ダミーデータを追加
        print("\n📝 ダミーデータを追加中...")
        sessionStore.addTranscript("テスト転写: 患者さんの症状について記録します", to: testSession)
        sessionStore.addAIResponse("テストAI応答: 症状を確認しました", promptType: .summary, to: testSession)
        
        // 3. セッション終了（自動的にAzureアップロードが開始される）
        print("\n🔚 セッションを終了してAzureアップロード実行中...")
        sessionStore.endCurrentSession()
        
        // 4. アップロード完了まで待機
        print("⏳ アップロード完了を待機中...")
        var waitTime = 0
        let maxWaitTime = 30 // 最大30秒待機
        
        while sessionStore.storageService.isUploading && waitTime < maxWaitTime {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒待機
            waitTime += 1
            
            let progress = Int(sessionStore.storageService.uploadProgress * 100)
            print("   進捗: \(progress)% (待機時間: \(waitTime)秒)")
        }
        
        // 5. 結果報告
        if sessionStore.storageService.error != nil {
            print("❌ アップロードエラー: \(sessionStore.storageService.error!)")
        } else if !sessionStore.storageService.isUploading {
            print("✅ アップロード完了!")
            print("\n📝 Azure Portal で以下を確認してください:")
            print("   コンテナー: koereq-sessions")
            print("   パス: unknown/\(testSession.id.uuidString)/")
            print("   期待されるファイル:")
            print("   - meta.json")
            print("   - transcript.txt")
        } else {
            print("⏰ アップロードがタイムアウトしました (30秒)")
        }
        
        print("\n=== セッション終了フローテスト完了 ===")
    }
} 