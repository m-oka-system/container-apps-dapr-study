# Azure Container Apps の学習

## 概要

このプロジェクトは、Azure Container Apps 上で Dapr を利用したマイクロサービスアプリケーションを構築し、Terraform によるインフラ管理と GitHub Actions による CI/CD パイプラインを学習することを目的としています。

フロントエンドは Next.js、バックエンドは Python で構成されています。
インフラの学習を目的として開発しているため、基本的な CRUD 機能のみを持つシンプルなアプリケーションとなっています。

![Image](https://github.com/user-attachments/assets/5f666695-2726-470b-a8e9-63444e02950b)

## インフラ構成図

![image](infra.drawio.svg)

## 機能一覧

- 商品管理
  - 新規登録
  - 一覧表示
  - 編集
  - 削除

## 使用技術

- バックエンド
  - Python 3.13.3
  - Flask 3.1.1
  - Dapr 1.15.0
    - Secret stores
    - State stores
- フロントエンド
  - Next.js 14.2.28
  - TypeScript
  - Tailwind CSS
  - shadcn/ui
  - Lucide React
- インフラ
  - Terraform
  - Docker
  - GitHub Actions
- クラウド (Azure)
  - Azure Container Apps
  - Azure Container Registry
  - Azure Cosmos DB
  - Azure Key Vault
  - NAT Gateway
  - Private Endpoint
  - Log Analytics
  - Application Insights

## ディレクトリ構成

```
.
├── .github/workflows/        # GitHub Actions ワークフロー定義
│   ├── terraform.yml
│   ├── frontend.yml
│   └── backend.yml
│
├── infra/                    # Terraform 構成ファイル (インフラ定義)
│   ├── main.tf               # メイン定義ファイル
│   ├── provider.tf           # プロバイダー
│   ├── variables.tf          # インプット変数
│   ├── outputs.tf            # 出力
│   ├── main.tfvars.json      # 環境変数
│   └── locals.tf             # ローカル変数
│
├── src/
│   ├── backend/              # バックエンドアプリケーション (Python)
│   │   ├── app/
│   │   │   └── main.py       # Flaskアプリケーションのメインファイル
│   │   ├── components/       # Dapr コンポーネント
│   │   ├── Dockerfile        # バックエンド用 Dockerfile
│   │   └── requirements.txt  # 依存パッケージリスト
│   │
│   └── frontend/             # フロントエンドアプリケーション (Next.js)
│       ├── app/              # Next.js App Router
│       ├── components/       # UIコンポーネント
│       ├── lib/              # 共通ライブラリ、ヘルパー関数
│       │   └── actions/      # Next.js Server Actions
│       ├── Dockerfile        # フロントエンド用 Dockerfile
│       ├── next.config.mjs   # Next.js 設定ファイル
│       ├── package.json      # 依存パッケージリスト
│       └── tsconfig.json     # TypeScript 設定ファイル
│
├── .gitignore                # Gitで無視するファイル定義
├── azure.yml                 # Azure Developer CLI (azd) の設定ファイル
└── rest.http                 # REST Client (デバッグ用)
```

## ローカル環境セットアップ

ローカル環境には以下のツールとランタイムが必要です。

| ツール    | バージョン | 目的                       |
| --------- | ---------- | -------------------------- |
| Node.js   | LTS (18+)  | フロントエンド開発とビルド |
| Python    | 3.13       | バックエンド API 開発      |
| Docker    | Latest     | コンテナベース開発         |
| Dapr CLI  | 1.15+      | ローカル Dapr ランタイム   |
| Azure CLI | Latest     | Azure サービス連携         |

### バックエンドのセットアップ

```bash
# 依存パッケージのインストール
cd "$(git rev-parse --show-toplevel)/src/backend"
python -m venv .venv
source .venv/bin/activate  # On Windows: .venv\\Scripts\\activate
pip install -r requirements.txt

# Cosmos DB の接続情報を設定
cd "$(git rev-parse --show-toplevel)/src/backend/components/"
cp secrets.sample.json secrets.json # secrets.json に Cosmos DB の接続情報を記述する

# ローカルでの実行 (Dapr を使用)
cd "$(git rev-parse --show-toplevel)/src/backend"
dapr run --app-id product-api --app-port 5002 --dapr-http-port 3500 --resources-path ./components/ python main.py
```

### フロントエンドのセットアップ

```bash
# 依存パッケージのインストール
cd "$(git rev-parse --show-toplevel)/src/frontend"
npm install

# ローカルでの実行
npm run dev
```

## Azure へのデプロイ

```bash
# サインイン
cd "$(git rev-parse --show-toplevel)"
azd auth login

# インフラ、アプリのデプロイ
azd up

# インフラのみのデプロイ
azd provision --preview
azd provision

# アプリのデプロイ
azd deploy frontend
azd deploy backend

# クリーンアップ
azd down
```
