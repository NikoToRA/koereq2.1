# 簡単なXcode起動手順

## 🎯 最も確実な方法

### 1. Xcodeで新規プロジェクトを作成

1. **Xcodeを起動**
2. **「Create a new Xcode project」**を選択
3. **「iOS」→「App」**を選択
4. プロジェクト情報を入力：
   - **Product Name**: `KoEReq`
   - **Bundle Identifier**: `com.yourcompany.koeReq`
   - **Language**: `Swift`
   - **Interface**: `SwiftUI`
   - **Use Core Data**: ✅ チェック
5. **保存場所を選択**（デスクトップなど）

### 2. 作成したファイルをコピー

新規プロジェクトが作成されたら、以下の手順でファイルを統合：

#### A. 既存ファイルを削除
- `ContentView.swift` を削除（置き換えるため）

#### B. フォルダを作成
Xcodeのプロジェクトナビゲーターで右クリック → 「New Group」で以下を作成：
- `Models`
- `Services` 
- `Views`

#### C. ファイルをコピー

**Models フォルダに追加：**
- `/Users/HirayamaSuguru2/Desktop/Koereqv2.1/KoEReq/Models/Session.swift`
- `/Users/HirayamaSuguru2/Desktop/Koereqv2.1/KoEReq/Models/User.swift`

**Services フォルダに追加：**
- `/Users/HirayamaSuguru2/Desktop/Koereqv2.1/KoEReq/Services/RecordingService.swift`
- `/Users/HirayamaSuguru2/Desktop/Koereqv2.1/KoEReq/Services/STTService.swift`
- `/Users/HirayamaSuguru2/Desktop/Koereqv2.1/KoEReq/Services/OpenAIService.swift`
- `/Users/HirayamaSuguru2/Desktop/Koereqv2.1/KoEReq/Services/StorageService.swift`
- `/Users/HirayamaSuguru2/Desktop/Koereqv2.1/KoEReq/Services/QRService.swift`
- `/Users/HirayamaSuguru2/Desktop/Koereqv2.1/KoEReq/Services/SessionStore.swift`
- `/Users/HirayamaSuguru2/Desktop/Koereqv2.1/KoEReq/Services/PromptManager.swift`

**Views フォルダに追加：**
- `/Users/HirayamaSuguru2/Desktop/Koereqv2.1/KoEReq/Views/ContentView.swift`
- `/Users/HirayamaSuguru2/Desktop/Koereqv2.1/KoEReq/Views/LoginView.swift`
- `/Users/HirayamaSuguru2/Desktop/Koereqv2.1/KoEReq/Views/HomeView.swift`
- `/Users/HirayamaSuguru2/Desktop/Koereqv2.1/KoEReq/Views/SessionView.swift`
- `/Users/HirayamaSuguru2/Desktop/Koereqv2.1/KoEReq/Views/QRCodeView.swift`
- `/Users/HirayamaSuguru2/Desktop/Koereqv2.1/KoEReq/Views/PromptManagerView.swift`
- `/Users/HirayamaSuguru2/Desktop/Koereqv2.1/KoEReq/Views/UserDictionaryView.swift`

**メインファイルを置き換え：**
- `/Users/HirayamaSuguru2/Desktop/Koereqv2.1/KoEReq/KoEReqApp.swift` で `KoEReqApp.swift` を置き換え

### 3. Info.plistを更新

`Info.plist` を開いて以下を追加：

```xml
<!-- 音声録音権限 -->
<key>NSMicrophoneUsageDescription</key>
<string>このアプリは医療記録のために音声を録音します。</string>

<!-- 音声認識権限 -->
<key>NSSpeechRecognitionUsageDescription</key>
<string>このアプリは録音された音声をテキストに変換するために音声認識機能を使用します。</string>

<!-- 写真ライブラリ保存権限 -->
<key>NSPhotoLibraryAddUsageDescription</key>
<string>生成されたQRコードを写真ライブラリに保存するために使用します。</string>
```

### 4. Azure認証情報を設定

#### OpenAIService.swift を編集：
```swift
// 15行目付近
private let apiKey = "YOUR_AZURE_OPENAI_API_KEY"
private let endpoint = "https://YOUR_RESOURCE_NAME.openai.azure.com/"
```

#### StorageService.swift を編集：
```swift
// 15行目付近  
private let connectionString = "YOUR_AZURE_BLOB_STORAGE_CONNECTION_STRING"
```

### 5. ビルド・実行

1. **Signing & Capabilities** でTeamを設定
2. **▶️ ボタン**でビルド・実行

## 📋 ファイル追加の詳細手順

### Xcodeでファイルを追加する方法：

1. **プロジェクトナビゲーター**で対象フォルダを右クリック
2. **「Add Files to "KoEReq"」**を選択
3. **ファイルを選択**して「Add」をクリック
4. **「Copy items if needed」**にチェック
5. **「Add to target: KoEReq」**にチェック

### または、ドラッグ&ドロップ：

1. **Finder**で対象ファイルを選択
2. **Xcodeのプロジェクトナビゲーター**にドラッグ
3. **「Copy items if needed」**にチェック
4. **「Add to target: KoEReq」**にチェック

## 🚀 動作確認

1. **ビルドが成功**することを確認
2. **ログイン画面**が表示されることを確認
3. **施設情報を入力**してログイン
4. **音声録音機能**をテスト
5. **Azure設定後にAI機能**をテスト

---

**この方法が最も確実です！** 新規プロジェクト作成から始めることで、Xcodeプロジェクトファイルの破損を避けられます。