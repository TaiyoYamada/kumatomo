# くまトモ（KumaTomo）

くまトモは、熊本の「好き」をつなげるコミュニティアプリです。お店やスポット、日常の小さな発見を写真や文章でシェアして、地域の魅力をみんなで広げていきます。フロントエンド（Vue.js）と バックエンド API（Laravel）、 iOS クライアント（SwiftUI）を同一リポジトリで管理しています。

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

- Frontend: Vite + Vue3 + Vuetify3 + TypeScript
- Backend: PHP 8.x, Laravel 10.x, Composer, MySQL/SQLite
- iOS: Xcode 15 以降, Swift 5.9 以降（iOS 17 目安）
- 推奨: Docker Desktop（ローカル開発の簡略化）

## セットアップ

### 1) 開発環境の起動（Docker）

```
docker compose build
docker compose up -d
```

### 2) 環境変数（iOS → API 連携）

iOS 実行時に API のベース URL を指定します。

- Xcode の Scheme 環境変数に `API_BASE_URL` を設定（例: `http://localhost:8000/api`）
- 認証・プロフィール・画像アップロードなど全 API 呼び出しでこの値を利用します

## ライセンス


本プロジェクトは `MITLICENSE` の内容に従います。



