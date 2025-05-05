#  CoupleMate – カップル向けデートプラン共有アプリ

カップルがデートプランを作成・共有し、思い出を記録できるアプリ。


---


## 開発環境まとめ

| 項目      | 内容                                 |
| ------- | ---------------------------------- |
| フロントエンド | SwiftUI（iOS）                       |
| バックエンド  | Laravel 11.x（Sail使用）               |
| DB      | MySQL 8.x（Dockerで起動）               |
| 認証      | Firebase Authentication            |
| API通信   | REST API（JSON形式）                   |
| ストレージ   | ImgBB（無料外部API）予定                   |
| 管理ツール   | Postman（APIテスト） / Sequel Ace（DB確認） |

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
docker compose up -d         # コンテナ起動
docker compose exec app php artisan key:generate
docker compose exec app php artisan migrate

```

### よく使うコマンド：

```bash
docker compose exec app php artisan migrate:fresh --seed
docker compose exec laravel.test tail -n 50 storage/logs/laravel.log　# LaravelAPIのログ確認
docker compose exec app php artisan tinker
docker compose exec laravel.test php artisan migrate # マイグレーション
docker compose exec laravel.test php artisan migrate:status　#　マイグレーションの状態確認
docker compose down          # コンテナ停止
docker compose ps            # 実行中コンテナの確認
```
---

## Firebase設定メモ

* 使用サービス：Firebase Authentication
* 現在有効な認証方法：

  * メールアドレス＋パスワード
  * Appleサインイン（予定）
* Swift側でログイン後、Laravel APIにIDトークンを送信してユーザーを特定

---

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

| ブランチ名      | 役割                                             |
|-----------------|--------------------------------------------------|
| `main`          | 公開用の安定ブランチ（App Storeリリース対象）     |
| `develop`       | 開発のメインブランチ（動作確認OKの状態）         |
| `issue/xxx`     | issueベースの作業用ブランチ（例：`issue/10` など）|

---


## TODO（自分メモ）

* [ ] Storageサービスの最終決定（Cloudinary or ImgBB）
* [ ] 本番環境（Render）にデプロイ予定

---

## ライセンス

MITライセンス（個人用）
