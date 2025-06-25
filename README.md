#  dailystory　（仮）

**daily-story** は、毎日のお題に対してユーザーが100文字以内の物語を投稿し、みんなで共有・評価し合うSNS型の物語投稿アプリです。

---

## 特徴

- **毎日更新されるお題** に対して物語を投稿
- **100文字以内**のショートストーリー制限
- 投稿は **全体公開**、他のユーザーの投稿が一覧表示
- **いいね機能** による共感評価
- 日別・週間・月間の **ランキング機能**
- **ログイン必須**（ユーザーアカウント管理あり）
- 管理者画面（お題の管理や不適切投稿の削除）

---

## 開発環境まとめ

| 項目      | 内容                                 |
| ------- | ---------------------------------- |
| フロントエンド | SwiftUI（iOS）                       |
| バックエンド  | Laravel 11.x（Laravel Sail + Docker）  |
| DB      | MySQL 8.x（Dockerで起動）               |
| 認証      | Laravel Sanctum（トークンベース認証）           |
| API通信   | REST API（JSON形式、Bearerトークンによる認証）     ||
| ストレージ   | ImgBB（画像アップロード用の無料外部APIを使用予定）        |
| 管理ツール   | Postman（APIテスト） / Sequel Ace（DB確認） |
|　サーバー　|　Render?? |
| 管理者画面       | Vue.js + TypeScript + Vuetify（SPA構成で構築予定）                         |

---


## ディレクトリ構成（ローカル）

```plaintext
CoupleMate/
├── CoupleMate-iOS/       # iOSアプリ (SwiftUI)
│   └── CoupleMate.xcodeproj
│   └── Views/, Models/, Services/, ...
│   └── GoogleService-Info.plist（追加済）
│   └── .gitignore（Xcode用）
│
├── CoupleMate-api/       # Laravel APIサーバー
│   └── app/, routes/, database/, ...
│   └── .env（Git除外）
│   └── docker-compose.yml
│   └── .gitignore（Laravel用）
```

---

## Laravel APIの起動手順（ローカル専用）

```bash
docker compose build
docker compose up -d
```

### よく使うコマンド：

```bash
docker compose exec laravel.test php artisan migrate:fresh --seed
docker compose exec laravel.test tail -n 50 storage/logs/laravel.log　# LaravelAPIのログ確認
docker compose exec laravel.test php artisan tinker
docker compose exec laravel.test php artisan key:generate
docker compose exec laravel.test php artisan migrate # マイグレーション
docker compose exec laravel.test php artisan migrate:status　#　マイグレーションの状態確認
docker compose down          # コンテナ停止
docker compose ps            # 実行中コンテナの確認
```
```
ipconfig getifaddr en0 # IPアドレスの確認
```
## 開発ツールの使い方

### Postman

* APIの動作確認用。


### Sequel Ace

* MySQL接続情報：

  ```
  ホスト: 127.0.0.1
  ユーザー名: sail
  パスワード: password
  ポート: 3306
  データベース: laravel
  ```

---

## ブランチ管理ルール（GitHub）

### ブランチ構成

| ブランチ名       | 役割                                                                 |
|------------------|----------------------------------------------------------------------|
| `main`           | 公開用の安定ブランチ（App Storeリリース対象）                       |
| `develop`        | 開発のメインブランチ（動作確認OKの状態）                            |
| `feature/XXX`    | 新機能の実装用（例：`feature/14-post-submission`）                  |
| `fix/XXX`        | 軽微なバグ修正（例：`fix/22-login-button-color`）                   |
| `hotfix/XXX`     | 本番環境の緊急修正（例：`hotfix/token-expiry-bug`）                |
| `release/XXX`    | リリース準備（例：`release/v1.0.0`）                                |

### ブランチ命名ルール

- `feature/番号-機能名`
- `fix/番号-修正内容`
- `release/バージョン名`
- `hotfix/バグ内容`

### 補足ルール
- 基本的に`main`には直接コミットしない。
- `develop`にマージする前に動作確認を行う。
- ブランチの削除はマージ後に行う。

---


## TODO（自分メモ）

* [ ] Storageサービスの最終決定（Cloudinary or ImgBB）
* [ ] 本番環境（Render）にデプロイ予定

- httpsにしたい

---

## ライセンス

MITライセンス（個人用）
