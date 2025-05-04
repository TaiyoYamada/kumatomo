## 📁 ディレクトリ構成（予定含む）

```plaintext
CoupleMate/
├── App/                   // アプリのエントリーポイント（@main）、ルーティング処理
├── Models/                // ユーザーモデル・デートモデルなど
├── Resources/             // Assetsやカスタムフォントなど
├── Services/              // Firebase・API通信関連のサービス
├── Utils/                 // 共通処理や拡張
├── ViewModels/            // ビジネスロジック（ObservableObject）
├── Views/                 // SwiftUIビュー
└── README.md              // ←このファイル！
```

---

## 🐳 Docker 開発メモ

### 🔹 Laravel サーバーの起動・停止

```bash
# サーバー起動（バックグラウンド）
docker compose up -d

# サーバー停止
docker compose down

# サービス確認
docker compose ps
```

### 🔹 Laravel アクセス

* API確認: `http://127.0.0.1:8000/api/memories`
* IPが変わる場合があるので注意（特にSwiftUIからアクセスする場合）

```bash
# 現在のローカルIP確認
ipconfig getifaddr en0
```

### 🔹 Artisan コマンド例

```bash
# マイグレーション実行
docker compose exec laravel.test php artisan migrate

# シーディングなど
# docker compose exec laravel.test php artisan db:seed
```

---

## 📱 SwiftUI側 Tips（例）

* UserAPIService を通じて Laravel API にアクセス
* プロフィール保存： `POST /api/users`
* プロフィール取得： `GET /api/users/{id}`

---

## ✍️ 書きたいこと（ToDo）

* Laravel API のエンドポイント一覧
* 認証まわり（Firebase Auth or Token）
* Storageの構成
* Supabase / Firestore の違いと移行履歴
* よく使うGitHubのコマンド

---

## 🧪 Postman利用メモ（APIテスト）

* POST /api/users

  * Content-Type: `application/json`
  * Body:

  ```json
  {
    "email": "sample@example.com",
    "fullName": "たいよう",
    "bio": "よろしくお願いします",
    "relationshipStatus": "Single",
    "interests": ["映画", "読書"]
  }
  ```

---

## 🧠 備考

* `.env` ファイルは `.env.example` を参考にコピーして調整
* Laravel Sail を使っていない場合は、Dockerfile / docker-compose.yml のサービス名に注意（`api` や `laravel.test` など）
