# GitHub Copilot Instruction File

## 基本方針

- すべて日本語で出力してください
- コードのコメントも日本語で記述してください
- シンプルで読みやすいコードを心がけてください
- 既存のコーディングスタイルとアーキテクチャに従ってください

## プロジェクト概要

このプロジェクトは、Azure Container Apps 上で Dapr を利用したマイクロサービスアプリケーションを構築する学習プロジェクトです。基本的な商品管理 CRUD 機能を持つシンプルなアプリケーションで、Terraform によるインフラ管理と GitHub Actions による CI/CD パイプラインを実装しています。

## 技術スタック

### バックエンド
- **言語**: Python 3.13.3
- **フレームワーク**: Flask 3.1.1
- **ミドルウェア**: Dapr 1.15.0 (Secret stores, State stores)
- **主要ライブラリ**: 
  - `dapr` - Dapr Python SDK
  - `flask-cors` - CORS 対応
  - `gunicorn` - WSGI サーバー

### フロントエンド
- **フレームワーク**: Next.js 15.2.4 (App Router)
- **言語**: TypeScript 5.x
- **スタイリング**: Tailwind CSS 3.4.x
- **UI コンポーネント**: shadcn/ui
- **アイコン**: Lucide React
- **フォーム管理**: React Hook Form + Zod

### インフラ
- **IaC**: Terraform
- **コンテナ**: Docker
- **CI/CD**: GitHub Actions
- **クラウド**: Azure (Container Apps, Container Registry, Cosmos DB, Key Vault, NAT Gateway, Private Endpoint, Log Analytics, Application Insights)

## ディレクトリ構造

```
.
├── .github/workflows/        # GitHub Actions ワークフロー定義
├── infra/                    # Terraform 構成ファイル
├── src/
│   ├── backend/              # Python Flask バックエンド
│   │   ├── main.py           # Flask アプリケーションのメインファイル
│   │   ├── components/       # Dapr コンポーネント
│   │   ├── Dockerfile
│   │   └── requirements.txt
│   └── frontend/             # Next.js フロントエンド
│       ├── app/              # Next.js App Router
│       ├── components/       # UI コンポーネント
│       ├── lib/              # 共通ライブラリ、ヘルパー関数
│       ├── Dockerfile
│       └── package.json
```

## コーディング規約

### Python (バックエンド)

1. **Flask API エンドポイント**:
   - JSON レスポンスには `Response(json.dumps(..., ensure_ascii=False), mimetype='application/json; charset=utf-8')` を使用して日本語を適切に処理してください
   - エラーハンドリングは `try-except` ブロックで実装し、適切な HTTP ステータスコードを返してください
   - 例外発生時は `traceback.print_exc()` でデバッグ情報を出力してください

2. **Dapr 統合**:
   - Dapr Client は `with DaprClient() as d:` のコンテキストマネージャーで使用してください
   - State Store 名は `STATE_STORE_NAME` 定数を使用してください
   - State の保存・取得時は JSON シリアライゼーション/デシリアライゼーションを適切に処理してください

3. **命名規則**:
   - 関数名は `snake_case` を使用してください
   - 定数は `UPPER_SNAKE_CASE` を使用してください

### TypeScript/React (フロントエンド)

1. **Next.js App Router**:
   - Server Components をデフォルトで使用してください
   - Client Components が必要な場合は `"use client"` ディレクティブを明示的に追加してください
   - Server Actions は `lib/actions/` ディレクトリに配置してください

2. **コンポーネント設計**:
   - shadcn/ui コンポーネントを活用してください
   - 再利用可能なコンポーネントは `components/` ディレクトリに配置してください
   - Lucide React を使用してアイコンを実装してください

3. **フォーム処理**:
   - React Hook Form と Zod を使用してフォームバリデーションを実装してください
   - フォームの送信処理は Server Actions で実装してください

4. **命名規則**:
   - コンポーネント名は `PascalCase` を使用してください
   - 関数名と変数名は `camelCase` を使用してください
   - 型定義は `types/` ディレクトリに配置してください

### Terraform (インフラ)

1. **リソース命名**:
   - Azure リソース名には prefix を付けてください（例: `rg-`, `vnet-`, `snet-`）
   - 環境名は `var.environment_name` を使用してください

2. **構成ファイル**:
   - メインリソースは `main.tf` に定義してください
   - バックエンド固有のリソースは `backend.tf` に定義してください
   - 変数は `variables.tf`、出力は `outputs.tf` に定義してください
   - ローカル変数は `locals.tf` に定義してください

3. **タグ付け**:
   - すべてのリソースに `local.tags` を適用してください

## API エンドポイント

### バックエンド API (product-api)

- `GET /healthz` - ヘルスチェック
- `GET /products` - 全商品の取得
- `GET /products/{id}` - 特定商品の取得
- `POST /products` - 商品の作成
- `PUT /products/{id}` - 商品の更新
- `DELETE /products/{id}` - 商品の削除

リクエスト/レスポンス形式:
```json
{
  "id": "uuid",
  "name": "商品名",
  "price": 1000
}
```

## 開発ガイドライン

### バックエンド開発

1. 新しい API エンドポイントを追加する場合:
   - Flask ルートデコレータを使用してエンドポイントを定義してください
   - Dapr State Store との統合を適切に実装してください
   - エラーハンドリングを必ず実装してください
   - 日本語文字列の処理を考慮してください

2. Dapr コンポーネントの追加:
   - `src/backend/components/` ディレクトリに YAML ファイルを作成してください
   - シークレットは `secrets.json` で管理してください（Git にはコミットしないでください）

### フロントエンド開発

1. 新しいページを追加する場合:
   - `app/` ディレクトリ内に適切なルートを作成してください
   - Server Components を優先的に使用してください
   - レイアウトが必要な場合は `layout.tsx` を作成してください

2. 新しい UI コンポーネントを追加する場合:
   - 可能な限り shadcn/ui の既存コンポーネントを活用してください
   - 新規コンポーネントは `components/` ディレクトリに配置してください
   - TypeScript の型定義を適切に行ってください

3. API 呼び出し:
   - Server Actions を使用してバックエンド API を呼び出してください
   - エラーハンドリングを適切に実装してください

### インフラ開発

1. 新しい Azure リソースを追加する場合:
   - 適切なファイル（`main.tf` または `backend.tf`）に定義してください
   - 命名規則に従ってリソース名を設定してください
   - 必要な変数を `variables.tf` に追加してください
   - タグを適用してください

2. GitHub Actions ワークフロー:
   - ワークフローファイルは `.github/workflows/` ディレクトリに配置してください
   - 既存のワークフロー（`terraform.yml`, `frontend.yml`, `backend.yml`）に従ってください

## テストとデバッグ

### ローカル開発環境

- バックエンド: `dapr run --app-id product-api --app-port 5002 --dapr-http-port 3500 --resources-path ./components/ python main.py`
- フロントエンド: `npm run dev`

### デバッグ用ツール

- `rest.http` ファイルを使用して API エンドポイントをテストしてください

## セキュリティとベストプラクティス

1. **シークレット管理**:
   - シークレットは Git にコミットしないでください
   - Azure Key Vault を使用してシークレットを管理してください

2. **エラーハンドリング**:
   - 詳細なエラー情報は本番環境では公開しないでください
   - 適切な HTTP ステータスコードを返してください

3. **CORS 設定**:
   - バックエンドは `flask-cors` を使用して CORS を設定していますが、本番環境では適切に制限してください

## デプロイメント

- Azure へのデプロイは Azure Developer CLI（`azd`）を使用してください
- CI/CD パイプラインは GitHub Actions で自動化されています
- Terraform によるインフラのプロビジョニングと、アプリケーションのデプロイを分離して管理してください
