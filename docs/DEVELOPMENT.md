# 開発ガイド

本ドキュメントでは、くまトモの開発環境セットアップと開発コマンドを説明します。

## 目次

- [前提条件](#前提条件)
- [環境セットアップ](#環境セットアップ)
- [Docker 開発環境](#docker-開発環境)
- [API 開発](#api-開発)
- [管理画面開発](#管理画面開発)
- [iOS アプリ開発](#ios-アプリ開発)
- [テスト](#テスト)
- [コードフォーマット](#コードフォーマット)


## 前提条件

| ツール | バージョン | 用途 |
|--------|-----------|------|
| Docker Desktop | 最新 | コンテナ環境 |
| Node.js | 20以降 | 管理画面開発 |
| Composer | 2.x | PHP依存関係管理 |
| Xcode | 16以降 | iOS開発（オプション） |



## 環境セットアップ

### 1. リポジトリのクローン

```bash
git clone https://github.com/your-username/kumatomo.git
cd kumatomo
```

### 2. 環境変数の設定

```bash
# ルートディレクトリ
cp .env.example .env

# APIディレクトリ
cp api/.env.example api/.env
```



## Docker 開発環境

### コンテナの起動

```bash
# ビルド & 起動
docker compose build
docker compose up -d
```

### 起動されるサービス

| サービス | ポート | 説明 |
|---------|--------|------|
| `laravel.test` | 8000 | Laravel API |
| `mysql` | 3306 | MySQL データベース |
| `redis` | 6379 | キャッシュ |
| `meilisearch` | 7700 | 全文検索エンジン |
| `mailpit` | 8025 | メール確認（開発用） |
| `next.admin` | 3000 | 管理画面 |

### Docker 操作コマンド

```bash
# コンテナ停止
docker compose down

# ログ確認
docker compose logs -f laravel.test

# コンテナに入る
docker compose exec laravel.test bash

# データベースリセット
docker compose down -v  # ボリューム削除
docker compose up -d
```

---

## API 開発

### 初期設定

```bash
docker compose exec laravel.test bash
cd /var/www/html

# マイグレーション実行
php artisan migrate

# シーダー実行（テストデータ）
php artisan db:seed
```

### よく使うコマンド

```bash
# キャッシュクリア
php artisan cache:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear

# ルート一覧表示
php artisan route:list

# Tinker（対話型シェル）
php artisan tinker

# キュー処理
php artisan queue:work
```

### コード生成

```bash
# コントローラー作成
php artisan make:controller UserController --api

# モデル + マイグレーション + シーダー作成
php artisan make:model Post -mfs

# リクエストクラス作成
php artisan make:request StorePostRequest

# リソースクラス作成
php artisan make:resource PostResource
```

---

## 管理画面開発

### ホストマシンからの起動

```bash
cd admin
npm install
npm run dev
```

http://localhost:3000 でアクセス

### コマンド一覧

```bash
# 開発サーバー
npm run dev

# プロダクションビルド
npm run build

# プロダクションサーバー起動
npm run start

# Lint チェック
npm run lint
```

---

## iOS アプリ開発

### Xcode プロジェクトを開く

```bash
open kumatomo.xcodeproj
```

### ビルド & 実行

1. Xcode で `kumatomo_ios` スキームを選択
2. シミュレーターまたは実機を選択
3. `Cmd + R` でビルド & 実行

### 設定ファイル

- `kumatomo_ios/Config/` - API エンドポイント等の設定
- `kumatomo_ios/.swiftlint.yml` - SwiftLint 設定
- `kumatomo_ios/.swiftformat` - SwiftFormat 設定


## テスト

### API テスト

```bash
cd api

# 全テスト実行
php artisan test

# 特定のテストのみ
php artisan test --filter=UserTest

# カバレッジレポート
php artisan test --coverage

# 並列実行
php artisan test --parallel
```

### iOS テスト

Xcode で `Cmd + U` を押してテストを実行


## コードフォーマット

### API (PHP)

```bash
cd api

# Laravel Pint でフォーマット
./vendor/bin/pint

# 差分のみ確認
./vendor/bin/pint --test

# 静的解析（PHPStan）
./vendor/bin/phpstan analyse
```

### iOS (Swift)

```bash
cd kumatomo_ios

# SwiftLint 実行
swiftlint

# SwiftFormat 実行
swiftformat .
```


## 関連ドキュメント

- [AGENTS.md](../AGENTS.md) - AI アシスタント向けコーディング規約
- [kumatomo_ios/AGENTS.md](../kumatomo_ios/AGENTS.md) - iOS 固有のガイドライン
- [DEPLOYMENT.md](./DEPLOYMENT.md) - デプロイガイド
