# くまトモ（KumaTomo）

くまトモは、熊本の「好き」をつなげるコミュニティアプリです。お店やスポット、日常の小さな発見を写真や文章でシェアして、地域の魅力をみんなで広げていきます。バックエンド API（Laravel）と iOS クライアント（SwiftUI）を同一リポジトリで管理しています。

## 特長

- 投稿の作成・閲覧・検索ができるシンプルな体験
- プロフィール（アイコン/カバー/自己紹介/ロケーション）の簡単編集


## リポジトリ構成

- `admin` - 管理者画面（Vue+Vuetify+Typescript）
- `api/` — Laravel 製の REST API
- `kumatomo_ios/` — iOS クライアント（SwiftUI）
- `docs/` — README や図などのドキュメント
- `docker/`, `docker-compose.yml` — ローカル開発用コンテナ

## 動作環境

- Backend: PHP 8.x, Laravel 10.x, Composer, MySQL/SQLite
- iOS: Xcode 15 以降, Swift 5.9 以降（iOS 17 目安）
- 推奨: Docker Desktop（ローカル開発の簡略化）

## セットアップ

### 1) 開発環境の起動（Docker）

```
docker compose build
docker compose up -d
```

```
# API 用（コンテナ内で）
docker compose exec api bash -lc "composer install && cp .env.example .env && php artisan key:generate && php artisan migrate && php artisan storage:link"

# 必要ならシーディングも
docker compose exec api bash -lc "php artisan db:seed"
```

### 2) 環境変数（iOS → API 連携）

iOS 実行時に API のベース URL を指定します。

- Xcode の Scheme 環境変数に `API_BASE_URL` を設定（例: `http://localhost:8000/api`）
- 認証・プロフィール・画像アップロードなど全 API 呼び出しでこの値を利用します


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


## ライセンス


本プロジェクトは `MITLICENSE` の内容に従います。



