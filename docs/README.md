# くまトモ（KumaTomo）

くまトモは、熊本の「好き」をつなげるコミュニティアプリです。お店やスポット、日常の小さな発見を写真や文章でシェアして、地域の魅力をみんなで広げていきます。本リポジトリはオープンソースとして公開しており、バックエンド API（Laravel）と iOS クライアント（SwiftUI）を同一リポジトリで管理しています。

## 特長

- 投稿の作成・閲覧・検索ができるシンプルな体験
- プロフィール（アイコン/カバー/自己紹介/ロケーション）の簡単編集
- 画像アップロードを含むモダンな REST API
- iOS クライアントは SwiftUI + Combine ベースで軽量・拡張しやすい構成

## リポジトリ構成

- `api/` — Laravel 製の REST API
- `kumatomo_ios/` — iOS クライアント（SwiftUI）
- `docs/` — 本 README や図などのドキュメント
- `docker/`, `docker-compose.yml` — ローカル開発用コンテナ

## 動作環境

- Backend: PHP 8.x, Laravel 10.x, Composer, MySQL/SQLite
- iOS: Xcode 15 以降, Swift 5.9 以降（iOS 17 目安）
- 推奨: Docker Desktop（ローカル開発の簡略化）

## セットアップ

### 1) 開発環境の起動（Docker）

```
docker compose up -d
```

初回は依存関係のインストールやマイグレーションを実行してください。

```
# API 用（コンテナ内で）
docker compose exec api bash -lc "composer install && cp .env.example .env && php artisan key:generate && php artisan migrate && php artisan storage:link"

# 必要ならシーディングも
docker compose exec api bash -lc "php artisan db:seed"
```

API の疎通確認:

```
curl http://localhost:8000/api
```

### 2) 環境変数（iOS → API 連携）

iOS 実行時に API のベース URL を指定します。

- Xcode の Scheme 環境変数に `API_BASE_URL` を設定（例: `http://localhost:8000/api`）
- 認証・プロフィール・画像アップロードなど全 API 呼び出しでこの値を利用します

### 3) iOS クライアントの起動

`kumatomo.xcodeproj` を Xcode で開いてビルド・実行してください。初回ログインやプロフィールの初期設定はアプリ上で行えます。

## API 概要

ベース URL は `http://localhost:8000/api`（開発例）です。代表的なエンドポイントは以下の通りです。

- 認証
  - `POST /login`, `POST /register`
  - 以降のエンドポイントは `Authorization: Bearer {token}` が必要
- プロフィール
  - 自分の情報取得: `GET /user`
  - 更新: `PUT /user/update`
    - Body（JSON, camelCase）例:
      ```json
      {
        "name": "くまたろう",
        "location": "熊本市中央区",
        "profileImageURL": "http://localhost:8000/storage/profile_images/xxx.jpg",
        "coverImageURL": "http://localhost:8000/storage/cover_images/xxx.jpg",
        "hasCompletedSetup": true
      }
      ```
- 画像アップロード（絶対 URL を返します）
  - プロフィール画像: `POST /upload-profile-image`（multipart/form-data: `image`）
  - カバー画像: `POST /upload-cover-image`（multipart/form-data: `image`）

認証後の使用例（cURL）:

```
TOKEN=... # /login で取得

curl -H "Authorization: Bearer $TOKEN" http://localhost:8000/api/user

curl -X PUT \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"hasCompletedSetup": true}' \
  http://localhost:8000/api/user/update
```

## コントリビューション

歓迎します！以下を目安に PR をお願いします。

1. Issue を立てて背景・目的・影響範囲を共有
2. ブランチを作成（例: `feat/...`, `fix/...`）
3. テストや動作確認手順を含む PR を作成
4. レビューのフィードバックを反映

指針（重要な契約）

- リクエスト/レスポンスは基本 camelCase
- 画像プロパティは `profileImageURL`（アイコン）/ `coverImageURL`（カバー）の2本
- 位置情報は `location` のみ（`city` は使いません）
- 画像アップロード API は絶対 URL を返します

## セキュリティ

脆弱性を発見した場合は、Issue ではなく直接メンテナへご連絡ください。調査の上、必要に応じてアドバイザリを公開します。

## ライセンス

本プロジェクトは `docs/LICENSE` の内容に従います。

## 謝辞

コミュニティの皆さま、OSS の作者の皆さまに感謝します。くまトモが皆さんの毎日を少し楽しくできますように！

