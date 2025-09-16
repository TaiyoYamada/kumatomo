# くまトモ
くまトモは、熊本の「好き」をつなげるコミュニティアプリです。お店やスポット、日常の小さな発見を写真や文章でシェアして、熊本の魅力をみんなで広げていきます。フロントエンド（Vue.js）と バックエンド API（Laravel）、 iOS クライアント（SwiftUI）を同一リポジトリで管理しています。


## 特長
- 熊本に特化したローカルコミュニティ
- 市町村ごとの掲示板
- 熊本県主要サイト・広告のポータル画面
- 写真とテキストで気軽に投稿・検索
- お店の検索・クーポン取得
- シンプルで直感的なUI

## リポジトリ構成
- `admin/` - 管理者画面（Vue+Vuetify+Typescript）
- `api/` — Laravel 製の REST API
- `kumatomo_ios/` — iOS クライアント（SwiftUI）
- `docs/` — README や図などのドキュメント
- `docker/` - ローカル開発用コンテナ

## 動作環境
- Frontend: Vite + Vue3 + Vuetify3 + TypeScript
- Backend: PHP 8.x, Laravel 10.x, Composer, MySQL/SQLite
- iOS: Xcode 15 以降, Swift 5.9 以降（iOS 17 目安）
- 推奨: Docker Desktop（ローカル開発の簡略化）

## セットアップ

### 開発環境の起動（Docker）

```
docker compose build
docker compose up -d
```

## ライセンス


本プロジェクトは `MIT LICENSE` の内容に従います。



