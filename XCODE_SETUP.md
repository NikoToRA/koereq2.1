# Xcodeでの起動手順

## 🚀 即座にXcodeで開く方法

### 1. Xcodeプロジェクトを開く
```bash
# ターミナルでプロジェクトディレクトリに移動
cd /Users/HirayamaSuguru2/Desktop/Koereqv2.1

# Xcodeでプロジェクトを開く
open KoEReq.xcodeproj
```

または、Finderで `KoEReq.xcodeproj` をダブルクリック

### 2. Azure認証情報の設定（必須）

プロジェクトが開いたら、以下のファイルを編集：

#### OpenAIService.swift
```swift
// 15行目付近
private let apiKey = "YOUR_AZURE_OPENAI_API_KEY"
private let endpoint = "https://YOUR_RESOURCE_NAME.openai.azure.com/"
```

#### StorageService.swift  
```swift
// 15行目付近
private let connectionString = "YOUR_AZURE_BLOB_STORAGE_CONNECTION_STRING"
```

### 3. ビルド設定の確認

1. プロジェクトナビゲーターで「KoEReq」プロジェクトを選択
2. 「KoEReq」ターゲットを選択
3. 「Signing & Capabilities」タブで：
   - Team を設定（Apple Developer Account）
   - Bundle Identifier を変更（例：`com.yourcompany.koeReq`）

### 4. 必要な権限の確認

Info.plist に以下が設定済み：
- ✅ マイク使用許可
- ✅ 音声認識許可  
- ✅ 写真ライブラリ保存許可

### 5. シミュレーターまたは実機で実行

1. Xcodeの上部でターゲットデバイスを選択
2. ▶️ ボタンをクリックしてビルド・実行

## 📱 動作確認手順

### 初回起動時
1. ログイン画面が表示される
2. 施設ID、ユーザーID、施設名を入力してログイン

### 音声機能テスト
1. 「新規セッション開始」をタップ
2. 右下の🎤ボタンで録音開始
3. 音声を録音して停止
4. テキスト化されることを確認

### AI機能テスト（Azure設定後）
1. 音声録音後、左下の「AI生成」ボタンをタップ
2. プロンプトを選択（カルテ生成など）
3. AI応答が表示されることを確認

### QRコード機能テスト
1. AI応答後、QRコードボタンが表示される
2. タップしてQRコード生成を確認

## 🔧 トラブルシューティング

### ビルドエラーが発生する場合
1. Xcode → Product → Clean Build Folder
2. 再度ビルドを実行

### 音声認識が動作しない場合
- iOS設定 → プライバシーとセキュリティ → マイク → KoEReq を有効化
- iOS設定 → プライバシーとセキュリティ → 音声認識 → KoEReq を有効化

### Azure接続エラーの場合
- APIキーとエンドポイントが正しく設定されているか確認
- ネットワーク接続を確認

## 📋 開発者向け情報

### プロジェクト構造
```
KoEReq.xcodeproj/          # Xcodeプロジェクトファイル
├── KoEReq/
│   ├── Models/            # データモデル
│   ├── Services/          # ビジネスロジック
│   ├── Views/             # SwiftUI画面
│   ├── CoreData/          # データベース定義
│   └── Assets.xcassets/   # アプリアイコン・画像
└── README.md              # プロジェクト概要
```

### 主要な依存関係
- iOS 17.0+
- SwiftUI
- CoreData
- Speech Framework
- AVFoundation
- CoreImage

### カスタマイズポイント
- プロンプトテンプレートの変更：`PromptType` enum
- UI色・デザインの変更：各Viewファイル
- データモデルの拡張：CoreDataモデル

---

**これで完了です！** Xcodeでプロジェクトを開いて、Azure認証情報を設定すれば即座に動作確認できます。