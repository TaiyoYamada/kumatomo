# くまトモ

**熊本の「好き」をつなげるコミュニティアプリ**

くまトモは、熊本の魅力を発見し、共有するためのローカルコミュニティプラットフォームです。お店やスポット、日常の小さな発見を写真や文章でシェアして、熊本の魅力をみんなで広げていきます。



## 主な機能

| 機能 | 説明 |
|------|------|
| **投稿・共有** | 写真とテキストで気軽にスポットや発見を投稿 |
| **市町村別掲示板** | 各市町村ごとのローカル掲示板 |
| **お店検索** | 熊本県内のお店を検索・クーポン取得 |
| **ポータル機能** | 熊本県主要サイト・広告のポータル画面 |
| **通知・お知らせ** | 運営からのお知らせ・更新通知 |


## プロジェクト構成

```
kumatomo/
├── api/              # Laravel バックエンドAPI
├── admin/            # 管理画面（Next.js）
├── kumatomo_ios/     # iOS アプリ（SwiftUI）
├── infra/            # インフラ構成
│   ├── terraform/    # AWS リソース定義
│   └── sam/          # SAM テンプレート
├── docker/           # Docker 設定ファイル
├── docs/             # ドキュメント
└── .github/          # GitHub Actions ワークフロー
```

## 技術スタック


### バックエンド API (`api/`)

| 技術 | バージョン |
|------|-----------|
| PHP | 8.4 |
| Laravel | 12.x |
| Laravel Sanctum | 4.x（API認証） |
| Bref | 2.x（AWS Lambda対応） |
| MySQL | 8.0 |
| Redis | 7.x |
| Meilisearch | 最新（全文検索） |

### 管理画面 (`admin/`)

| 技術 | バージョン |
|------|-----------|
| Next.js | 16.x |
| React | 19.x |
| TypeScript | 5.x |
| TailwindCSS | 4.x |
| Radix UI | 最新（UIコンポーネント） |
| React Hook Form + Zod | フォームバリデーション |

### iOS アプリ (`kumatomo_ios/`)

| 技術 | バージョン |
|------|-----------|
| Swift | 6.x |
| SwiftUI | 最新 |
| 対応iOS | 17+ |
| Xcode | 16以降 |

### インフラストラクチャ (`infra/`)

| サービス | 用途 |
|---------|------|
| **AWS Lambda** | サーバーレスAPI実行環境 |
| **Amazon RDS** | MySQL データベース |
| **Amazon S3** | 静的ファイル・画像ストレージ |
| **Amazon CloudFront** | CDN |
| **AWS VPC** | ネットワーク構成 |
| **AWS IAM** | アクセス管理 |
| **AWS SSM** | パラメータストア |
| **Terraform** | IaC（インフラ構成管理） |
| **AWS SAM** | サーバーレスデプロイ |

### CI/CD

| ツール | 用途 |
|-------|------|
| GitHub Actions | 自動デプロイ |
| `deploy-api.yml` | API の AWS へのデプロイ |
| `deploy-admin.yml` | 管理画面のデプロイ |

## クイックスタート

### Docker コンテナの起動

```bash
cp .env.example .env
cp api/.env.example api/.env

# コンテナ起動
docker compose build
docker compose up -d
```

### 起動されるサービス

| サービス | ポート | 説明 |
|---------|--------|------|
| API (Laravel) | 8000 | バックエンドAPI |
| MySQL | 3306 | データベース |
| Redis | 6379 | キャッシュ |
| Meilisearch | 7700 | 検索エンジン |
| Admin (Next.js) | 3000 | 管理画面 |

詳細なセットアップ手順は [開発ガイド](./docs/DEVELOPMENT.md) を参照してください。


## ライセンス

本プロジェクトは [LICENSE](./LICENSE) の内容に従います。


## ドキュメント

| ドキュメント | 説明 |
|-------------|------|
| [開発ガイド](./docs/DEVELOPMENT.md) | 開発環境セットアップ、開発コマンド |
| [デプロイガイド](./docs/DEPLOYMENT.md) | Terraform、SAM、CI/CD デプロイ手順 |
