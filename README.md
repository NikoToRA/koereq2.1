# KoEReq v2.1 - 医療向け音声記録支援アプリ

iOS 17対応のSwiftUIを使用した医療向け音声記録支援アプリです。Apple標準のSpeech Framework、Azure OpenAI、Azure Blob Storageを統合したプロトタイプ実装です。

## 🚀 主要機能

### 音声認識・記録
- Apple標準Speech Frameworkによる高精度音声認識
- リアルタイム音声レベル表示
- 音声ファイルの自動保存

### AI応答生成
- Azure OpenAI (GPT-4-1106-preview) による医療専門応答
- カルテ生成、紹介状作成、AI相談の定型プロンプト
- カスタムプロンプト作成・管理機能

### データ管理
- CoreDataによるローカルデータ永続化
- Azure Blob Storageへの自動アップロード
- 過去24時間のセッション履歴表示

### QRコード生成
- AI応答内容のQRコード化
- 写真ライブラリ保存・共有機能

### ユーザー辞書
- 医療用語の読み方・定義登録
- 音声認識精度向上支援

## 🛠 技術構成

| 項目 | 技術 |
|------|------|
| 音声認識 | Apple標準 Speech Framework |
| AI応答 | Azure OpenAI (GPT-4-1106-preview) |
| データ保存 | Azure Blob Storage |
| UIフレームワーク | SwiftUI |
| ローカルDB | CoreData |
| QRコード生成 | CoreImage |

## 📋 システム要件

- iOS 17.0以上
- Xcode 15.0以上
- Swift 5.9以上
- Azure OpenAI APIアクセス
- Azure Blob Storageアカウント

## ⚙️ セットアップ手順

### 1. プロジェクトのクローン
```bash
git clone <repository-url>
cd KoEReq
```

### 2. Azure認証情報の設定

#### OpenAIService.swift の設定
```swift
// KoEReq/Services/OpenAIService.swift
private let apiKey = "YOUR_AZURE_OPENAI_API_KEY"
private let endpoint = "https://YOUR_RESOURCE_NAME.openai.azure.com/"
```

#### StorageService.swift の設定
```swift
// KoEReq/Services/StorageService.swift
private let connectionString = "YOUR_AZURE_BLOB_STORAGE_CONNECTION_STRING"
```

### 3. Xcodeプロジェクトの作成

1. Xcodeを開く
2. "Create a new Xcode project" を選択
3. "iOS" → "App" を選択
4. プロジェクト情報を入力：
   - Product Name: `KoEReq`
   - Bundle Identifier: `com.yourcompany.koeReq`
   - Language: `Swift`
   - Interface: `SwiftUI`
   - Use Core Data: ✅

### 4. ファイルの統合

作成されたファイルをXcodeプロジェクトに追加：

```
KoEReq/
├── Models/
│   ├── Session.swift
│   └── User.swift
├── Services/
│   ├── RecordingService.swift
│   ├── STTService.swift
│   ├── OpenAIService.swift
│   ├── StorageService.swift
│   ├── QRService.swift
│   ├── SessionStore.swift
│   └── PromptManager.swift
├── Views/
│   ├── ContentView.swift
│   ├── LoginView.swift
│   ├── HomeView.swift
│   ├── SessionView.swift
│   ├── QRCodeView.swift
│   ├── PromptManagerView.swift
│   └── UserDictionaryView.swift
├── CoreData/
│   └── KoEReqDataModel.xcdatamodeld/
├── KoEReqApp.swift
└── Info.plist
```

### 5. フレームワークの追加

プロジェクト設定で以下のフレームワークを追加：
- `Speech.framework`
- `AVFoundation.framework`
- `CoreData.framework`
- `CoreImage.framework`

### 6. 権限設定の確認

Info.plistに以下の権限が設定されていることを確認：
- `NSMicrophoneUsageDescription`
- `NSSpeechRecognitionUsageDescription`
- `NSPhotoLibraryAddUsageDescription`

## 🏗 アーキテクチャ

```
[User]
  ↓ 音声入力
[iOS App]
  ├─ RecordingService（AVAudioRecorder）
  ├─ STTService（Apple Speech Framework）
  ├─ SessionStore（CoreData）
  ├─ OpenAIService（Azure GPT-4-1106-preview）
  ├─ StorageService（Azure Blob via SAS）
  ├─ QRService（CoreImage QRGenerator）
  └─ UI（SwiftUI Views）
```

## 📱 ユーザーフロー

1. **ログイン**: 施設ID、ユーザーID、施設名を入力
2. **ホーム画面**: セッション一覧表示、新規セッション開始
3. **セッション画面**: 
   - 音声録音・テキスト化
   - AI応答生成（4種類のプロンプト）
   - QRコード生成・共有
4. **管理機能**:
   - プロンプトマネージャー
   - ユーザー辞書

## 🎯 パフォーマンス目標

| 項目 | 目標値 |
|------|--------|
| 音声→文字表示 | ≤ 1.5秒 |
| AI応答表示 | ≤ 4秒 |
| メモリ使用量 | ≤ 400MB |
| バッテリー消費（30分録音） | ≤ 8% |

## 🔧 カスタマイズ

### プロンプトの追加
```swift
// PromptType enum に新しいケースを追加
case newPromptType

var promptTemplate: String {
    switch self {
    case .newPromptType:
        return "新しいプロンプトテンプレート: {transcript}"
    }
}
```

### Azure Blob Storage構造
```
/{facility_id}/
  └── {session_id}/
        ├─ meta.json（summary, timestamps）
        ├─ voice_001.m4a
        ├─ transcript_001.txt
        └─ ai_response_001.txt
```

## 🐛 トラブルシューティング

### 音声認識が動作しない
- マイクの権限が許可されているか確認
- iOS設定 → プライバシー → 音声認識でアプリが有効になっているか確認

### Azure接続エラー
- APIキーとエンドポイントURLが正しく設定されているか確認
- ネットワーク接続を確認
- Azure OpenAIサービスの利用制限を確認

### CoreDataエラー
- データモデルファイルが正しく追加されているか確認
- アプリを削除して再インストール（開発時）

## 📄 ライセンス

このプロジェクトは医療機関での使用を想定したプロトタイプです。
商用利用前に適切なセキュリティ監査とコンプライアンス確認を実施してください。

## 🤝 貢献

バグ報告や機能改善の提案は Issues でお知らせください。

---

**注意**: このアプリは医療データを扱うため、本番環境での使用前に以下を確認してください：
- HIPAA/個人情報保護法への準拠
- セキュリティ監査の実施
- データ暗号化の実装
- アクセス制御の強化