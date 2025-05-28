# Azure Storage 設定ガイド

## 概要
このアプリは Azure Blob Storage を使用してセッションデータ（音声ファイル、転写データ、メタデータ）を保存します。

## 前提条件
- Azure アカウント
- Azure Storage アカウントの作成権限

## 設定手順

### 1. Azure Storage アカウントの作成

1. **Azure Portal** (https://portal.azure.com) にログイン
2. **リソースの作成** をクリック
3. **ストレージ アカウント** を検索して選択
4. 以下の設定で作成：
   - **リソースグループ**: 新規作成または既存を選択
   - **ストレージ アカウント名**: `koereqstorage` (一意の名前)
   - **地域**: Japan East または最寄りの地域
   - **パフォーマンス**: Standard
   - **冗長性**: LRS (Locally Redundant Storage)

### 2. Blob コンテナーの作成

1. 作成したストレージ アカウントを開く
2. 左メニューから **コンテナー** を選択
3. **+ コンテナー** をクリック
4. コンテナー名: `koereq-sessions`
5. パブリック アクセス レベル: **プライベート**

### 3. アクセスキーの取得

1. ストレージ アカウントの左メニューから **アクセス キー** を選択
2. **key1** の以下の情報をコピー：
   - **ストレージ アカウント名**
   - **キー**
   - **接続文字列**

### 4. アプリケーションの設定

`KoEReq/Koereq/APIKeys.xcconfig` ファイルを編集：

```
// Azure Storage Configuration
AZURE_STORAGE_CONNECTION_STRING = DefaultEndpointsProtocol=https;AccountName=YOUR_ACCOUNT_NAME;AccountKey=YOUR_ACCOUNT_KEY;EndpointSuffix=core.windows.net
AZURE_STORAGE_CONTAINER_NAME = koereq-sessions
AZURE_STORAGE_ACCOUNT_NAME = YOUR_ACCOUNT_NAME
AZURE_STORAGE_ACCOUNT_KEY = YOUR_ACCOUNT_KEY
```

### 5. 設定値の置換

以下の値を実際の値に置き換えてください：

- `YOUR_ACCOUNT_NAME`: ストレージアカウント名
- `YOUR_ACCOUNT_KEY`: アクセスキー
- `YOUR_CONNECTION_STRING`: 接続文字列

### 例：
```
AZURE_STORAGE_CONNECTION_STRING = DefaultEndpointsProtocol=https;AccountName=koereqstorage;AccountKey=abc123def456...;EndpointSuffix=core.windows.net
AZURE_STORAGE_CONTAINER_NAME = koereq-sessions
AZURE_STORAGE_ACCOUNT_NAME = koereqstorage
AZURE_STORAGE_ACCOUNT_KEY = abc123def456...
```

## データ保存構造

アップロードされるデータは以下の構造で保存されます：

```
koereq-sessions/
├── {facilityId}/
│   └── {sessionId}/
│       ├── meta.json          // セッションメタデータ
│       ├── transcript.txt     // 転写データ
│       ├── audio_1.m4a       // 音声ファイル1
│       ├── audio_2.m4a       // 音声ファイル2
│       └── ...
```

## セキュリティについて

- ストレージアカウントは **プライベート** に設定
- アクセスキーは `.gitignore` で除外済み
- 本番環境では **SAS トークン** または **Azure AD認証** の使用を推奨

## トラブルシューティング

### 接続エラー
1. ストレージアカウント名とキーが正しいか確認
2. コンテナー名が正しいか確認
3. ネットワーク接続を確認

### アップロードエラー
1. ファイルサイズ制限を確認 (最大5GB)
2. Azure Storage の課金状況を確認
3. ログを確認してエラーの詳細を調査

### アクセス拒否エラー
1. アクセスキーが有効か確認
2. コンテナーのアクセス権限を確認
3. ストレージアカウントのファイアウォール設定を確認

## 機能テスト

アプリ内で以下の方法で接続をテストできます：

```swift
// SessionStore インスタンスから
let sessionStore = SessionStore()
let isConnected = try await sessionStore.testAzureConnection()
print("Azure connection: \(isConnected)")
```

## 料金について

- Azure Storage の料金は使用量に基づく
- 医療データの保存期間に応じて課金
- 削除ポリシーの設定を推奨

## サポート

設定に問題がある場合は、以下を確認してください：
1. Azure Portal でのストレージアカウント状態
2. APIKeys.xcconfig の設定値
3. アプリのコンソールログ 