#  ひだまり
## アプリの概要

- 熊本県掲示板アプリ
まだ知られていない、温かくて魅力的なお店を発見し、その魅力を広めるためのコミュニティアプリです。
ユーザーは、アプリを使って「ひだまり」のような素敵なスポットを見つけ、その魅力を写真や文章で投稿することができます。

## 主な機能

- **投稿機能**: お店の写真や感想を、簡単に投稿できます。
- **発見機能**: マップやカテゴリから、新しいお店を探すことができます。
- **クーポン機能**: 投稿することで、お店で使えるクーポンを獲得できます。

---

## docs

### 要件定義書

```
https://docs.google.com/document/d/1oieeV_WKE8YKsUwU8Ret50e5lnSVQDKWlBRMlKIioBg/edit?tab=t.0
```

### DB設計書
```
https://docs.google.com/spreadsheets/d/1mYCOM8me72SK_WAiY8aZAGK7daOr7pVdh0_Mcgv9Zto/edit?gid=1467023154#gid=1467023154

```

## 開発環境まとめ

| 項目      | 内容                                 |
| ------- | ---------------------------------- |
| フロントエンド | SwiftUI（iOS）                       |
| バックエンド  | Laravel 11.x（Laravel Sail + Docker）  |
| DB      | MySQL 8.x（Dockerで起動）               |
| 認証      | Laravel Sanctum（トークンベース認証）           |
| API通信   | REST API（JSON形式、Bearerトークンによる認証）     ||
| 画像ストレージ   | ImgBB（画像アップロード用の無料外部APIを使用予定） |
| 管理者画面       | Vue.js + TypeScript + Vuetify（SPA構成で構築予定）|
| その他開発ツール   | Postman（APIテスト） / Sequel Ace（DB確認） |
|　本番環境（予定）　| Render |

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

```
xcodebuild -scheme Hidamari -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep error:
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
