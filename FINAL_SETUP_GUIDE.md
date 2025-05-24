# 🎯 確実にビルドできるXcode設定手順

## 📋 手順1: Xcodeで新規プロジェクトを作成

### 1. Xcodeを起動
- **「Create a new Xcode project」**を選択

### 2. プロジェクトテンプレートを選択
- **「iOS」**を選択
- **「App」**を選択
- **「Next」**をクリック

### 3. プロジェクト情報を入力
- **Product Name**: `KoEReq`
- **Interface**: `SwiftUI`
- **Language**: `Swift`
- **Use Core Data**: ✅ **チェックを入れる**
- **Include Tests**: チェックを外す（オプション）
- **「Next」**をクリック

### 4. 保存場所を選択
- **デスクトップまたは任意の場所**を選択
- **「Create」**をクリック

## 📋 手順2: 作成したファイルを統合

### 1. 既存のファイルを削除
新規プロジェクトで自動生成された以下のファイルを削除：
- `ContentView.swift`（置き換えるため）

### 2. フォルダ構造を作成
プロジェクトナビゲーターで右クリック → **「New Group」**で以下を作成：
- `Models`
- `Services`
- `Views`

### 3. ファイルをコピー

#### Models フォルダに追加：
以下のファイルをドラッグ&ドロップ：
- `/Users/HirayamaSuguru2/Desktop/Koereqv2.1/KoEReq/Models/Session.swift`
- `/Users/HirayamaSuguru2/Desktop/Koereqv2.1/KoEReq/Models/User.swift`

#### Services フォルダに追加：
- `/Users/HirayamaSuguru2/Desktop/Koereqv2.1/KoEReq/Services/RecordingService.swift`
- `/Users/HirayamaSuguru2/Desktop/Koereqv2.1/KoEReq/Services/STTService.swift`
- `/Users/HirayamaSuguru2/Desktop/Koereqv2.1/KoEReq/Services/OpenAIService.swift`
- `/Users/HirayamaSuguru2/Desktop/Koereqv2.1/KoEReq/Services/StorageService.swift`
- `/Users/HirayamaSuguru2/Desktop/Koereqv2.1/KoEReq/Services/QRService.swift`
- `/Users/HirayamaSuguru2/Desktop/Koereqv2.1/KoEReq/Services/SessionStore.swift`
- `/Users/HirayamaSuguru2/Desktop/Koereqv2.1/KoEReq/Services/PromptManager.swift`

#### Views フォルダに追加：
- `/Users/HirayamaSuguru2/Desktop/Koereqv2.1/KoEReq/Views/ContentView.swift`
- `/Users/HirayamaSuguru2/Desktop/Koereqv2.1/KoEReq/Views/LoginView.swift`
- `/Users/HirayamaSuguru2/Desktop/Koereqv2.1/KoEReq/Views/HomeView.swift`
- `/Users/HirayamaSuguru2/Desktop/Koereqv2.1/KoEReq/Views/SessionView.swift`
- `/Users/HirayamaSuguru2/Desktop/Koereqv2.1/KoEReq/Views/QRCodeView.swift`
- `/Users/HirayamaSuguru2/Desktop/Koereqv2.1/KoEReq/Views/PromptManagerView.swift`
- `/Users/HirayamaSuguru2/Desktop/Koereqv2.1/KoEReq/Views/UserDictionaryView.swift`

#### メインファイルを置き換え：
- `/Users/HirayamaSuguru2/Desktop/Koereqv2.1/KoEReq/KoEReqApp.swift` で既存の `KoEReqApp.swift` を置き換え

### 4. ファイル追加時の注意点
ファイルをドラッグ&ドロップする際：
- ✅ **「Copy items if needed」**にチェック
- ✅ **「Add to target: KoEReq」**にチェック
- **「Add」**をクリック

## 📋 手順3: 権限設定

### プロジェクト設定で権限を追加：
1. **プロジェクトナビゲーターで「KoEReq」プロジェクト**（青いアイコン）をクリック
2. **「KoEReq」ターゲット**を選択
3. **「Info」タブ**をクリック
4. **「Custom iOS Target Properties」**で **「+」**をクリック

### 追加する権限：
1. **Key**: `Privacy - Microphone Usage Description`
   **Value**: `このアプリは医療記録のために音声を録音します。`

2. **Key**: `Privacy - Speech Recognition Usage Description`
   **Value**: `このアプリは録音された音声をテキストに変換するために音声認識機能を使用します。`

3. **Key**: `Privacy - Photo Library Additions Usage Description`
   **Value**: `生成されたQRコードを写真ライブラリに保存するために使用します。`

## 📋 手順4: ビルドテスト

### 1. ビルド実行
- **⌘+B** (Command + B) を押してビルド

### 2. エラーが出た場合
- **Product** → **Clean Build Folder** を実行
- 再度 **⌘+B** でビルド

### 3. 実行テスト
- **▶️ ボタン**でシミュレーターで実行
- **ログイン画面**が表示されることを確認

## 📋 手順5: Azure設定（動作確認後）

### OpenAIService.swift を編集：
```swift
// 15行目付近
private let apiKey = "YOUR_AZURE_OPENAI_API_KEY"
private let endpoint = "https://YOUR_RESOURCE_NAME.openai.azure.com/"
```

### StorageService.swift を編集：
```swift
// 15行目付近
private let connectionString = "YOUR_AZURE_BLOB_STORAGE_CONNECTION_STRING"
```

## 🎉 完了！

この手順により、確実にビルドできるKoEReq v2.1プロジェクトが完成します。

**重要**: 手順2のファイルコピーが最も重要です。必ず「Copy items if needed」と「Add to target」にチェックを入れてください。