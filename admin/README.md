# kumatomo Admin Panel

Vue.js 3で構築されたkumatomoアプリの管理画面です。

## 機能

### お店管理
- お店一覧表示（テーブル形式）
- お店の検索・フィルタリング機能
- お店の新規登録
- お店情報の編集
- お店の削除（確認ダイアログ付き）
- お店画像のアップロード

## 技術スタック

- **フレームワーク**: Vue.js 3
- **ビルドツール**: Vite
- **ルーティング**: Vue Router 4
- **HTTP クライアント**: Axios
- **スタイリング**: CSS（スコープ付き）

## セットアップ

### 前提条件
- Node.js 16以上
- npm または yarn

### インストール

```bash
# 依存関係のインストール
npm install

# 環境変数の設定
cp .env.example .env
# .envファイルを編集してAPI URLを設定
```

### 開発サーバーの起動

```bash
npm run dev
```

ブラウザで `http://localhost:5173` にアクセスしてください。

### ビルド

```bash
# 本番用ビルド
npm run build

# ビルド結果のプレビュー
npm run preview
```

## API 設定

`.env`ファイルでAPIのベースURLを設定してください：

```
VITE_API_BASE_URL=http://localhost:8000/api
```

## ディレクトリ構成

```
src/
├── components/          # 再利用可能なコンポーネント
│   ├── common/         # 共通コンポーネント
│   └── feature/        # 機能固有のコンポーネント
├── layouts/            # レイアウトコンポーネント
├── pages/              # ページコンポーネント
├── router/             # ルーティング設定
├── services/           # API サービス
├── utils/              # ユーティリティ関数
└── assets/             # 静的アセット
```

## API エンドポイント

管理画面は以下のAPIエンドポイントを使用します：

- `GET /api/admin/shops` - お店一覧取得
- `GET /api/admin/shops/:id` - お店詳細取得
- `POST /api/admin/shops` - お店新規作成
- `PUT /api/admin/shops/:id` - お店更新
- `DELETE /api/admin/shops/:id` - お店削除
- `POST /api/admin/shops/upload-image` - 画像アップロード

## 認証

管理画面では認証トークンを使用します。トークンは`localStorage`の`admin_token`キーに保存されます。

## 開発ガイドライン

### コンポーネント作成
- 単一ファイルコンポーネント（.vue）を使用
- Composition APIを使用
- スコープ付きCSSを使用

### エラーハンドリング
- `utils/errorHandler.js`のユーティリティを使用
- ユーザーフレンドリーなエラーメッセージを表示

### スタイリング
- 一貫したデザインシステムを使用
- レスポンシブデザインを考慮
- アクセシビリティを考慮