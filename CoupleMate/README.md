

## ディレクトリ構成（予定含む）

```plaintext
CoupleMate/
├── App/                   // アプリのエントリーポイント（@main）、ルーティング処理
├── Models/                // ユーザーモデル・デートモデルなど
├── Resources/             // Assetsやカスタムフォントなど
├── Services/              // Firebase関連のサービス
├── Utils/                 // 共通処理や拡張
├── ViewModels/            // ビジネスロジック
├── Views/                 // SwiftUIビュー
└── README.md              // ←このファイル！
```

## Docker 

Laravelサーバーを起動
yamadataiyou → Development → Laravel 
`docker compose up -d`

Dockerを終了
`docker compose down`

動いているか確認
`docker compose ps`


ブラウザでチェック
`http://127.0.0.1:8000/api/memories`

IPアドレスの確認
ipconfig getifaddr en0

ローカルPアドレスの確認方法
ipconfig getifaddr en0

phpマイグレーション
docker compose exec laravel.test php artisan migrate


