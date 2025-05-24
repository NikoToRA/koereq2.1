# API キー設定ガイド

## 概要
このアプリは Azure OpenAI サービスを使用して AI 機能を提供します。アプリを正常に動作させるためには、API キーの設定が必要です。

## 設定手順

### 1. APIKeys.xcconfig ファイルの作成

```bash
# プロジェクトルートで実行
cd KoEReq/Koereq/
cp APIKeys.xcconfig.template APIKeys.xcconfig
```

### 2. API キーの設定

`APIKeys.xcconfig` ファイルを開き、以下の値を実際のものに置き換えてください：

```
// Azure OpenAI Configuration
AZURE_OPENAI_API_KEY = あなたのAzure OpenAI APIキー
AZURE_OPENAI_ENDPOINT = https://あなたのリソース名.openai.azure.com/
AZURE_OPENAI_DEPLOYMENT_NAME = あなたのデプロイメント名
AZURE_OPENAI_API_VERSION = 2024-08-01-preview
```

### 3. Azure OpenAI の設定情報の取得方法

1. **Azure Portal** にログインします
2. **Azure OpenAI リソース** を開きます
3. **キーとエンドポイント** セクションから以下を取得：
   - API キー
   - エンドポイント
4. **モデルのデプロイ** セクションからデプロイメント名を確認

### 4. プロジェクトのビルド

Xcode でプロジェクトを開き、通常通りビルドしてください。設定が正しければ、アプリが正常に動作します。

## セキュリティについて

- `APIKeys.xcconfig` ファイルは `.gitignore` に含まれており、Git リポジトリにコミットされません
- API キーは安全に管理し、他人と共有しないでください
- 本番環境では、より安全な環境変数やキーストアの使用を検討してください

## トラブルシューティング

### エラー: "Unable to open base configuration reference file"

このエラーが表示される場合は、上記の手順1を実行して `APIKeys.xcconfig` ファイルを作成してください。

### API 呼び出しエラー

- API キーが正しいか確認してください
- エンドポイント URL が正しいか確認してください
- デプロイメント名が正しいか確認してください
- Azure OpenAI リソースの課金状況を確認してください

## サポート

問題が解決しない場合は、プロジェクトのIssueセクションで報告してください。 