# デプロイガイド

本ドキュメントでは、くまトモの各コンポーネントのデプロイ方法を説明します。



## 目次

- [前提条件](#前提条件)
- [インフラストラクチャ](#インフラストラクチャ)
- [API デプロイ](#api-デプロイ)
- [管理画面デプロイ](#管理画面デプロイ)
- [CI/CD パイプライン](#cicd-パイプライン)
- [環境変数](#環境変数)
- [トラブルシューティング](#トラブルシューティング)



## 前提条件

### 必要なツール

| ツール | バージョン | 用途 |
|--------|-----------|------|
| AWS CLI | 2.x | AWS リソースへのアクセス |
| Terraform | 1.x | インフラ構成管理 |
| AWS SAM CLI | 1.x | サーバーレスデプロイ |
| Docker | 最新 | コンテナ実行 |

### AWS 認証設定

```bash
# AWS CLI の設定
aws configure

# または環境変数で設定
export AWS_ACCESS_KEY_ID=your_access_key
export AWS_SECRET_ACCESS_KEY=your_secret_key
export AWS_DEFAULT_REGION=ap-northeast-1
```



## インフラストラクチャ

### Terraform による AWS リソースの管理

`infra/terraform/` ディレクトリには以下の AWS リソース定義が含まれています：

| ファイル | リソース |
|---------|---------|
| `vpc.tf` | VPC, サブネット, ルートテーブル |
| `rds.tf` | RDS MySQL インスタンス |
| `s3.tf` | S3 バケット（静的ファイル, 画像） |
| `cloudfront.tf` | CloudFront ディストリビューション |
| `iam.tf` | IAM ロール, ポリシー |
| `ssm.tf` | SSM パラメータストア |

### Terraform 操作コマンド

```bash
cd infra/terraform

# 初期化（初回のみ）
terraform init

# 変更内容のプレビュー
terraform plan

# リソースの作成/更新
terraform apply

# リソースの削除（注意）
terraform destroy
```

### 環境別設定

```bash
# terraform.tfvars を作成
cp terraform.tfvars.example terraform.tfvars

# 環境に応じた値を設定
vim terraform.tfvars
```

**`terraform.tfvars` の例:**

```hcl
project_name     = "kumatomo"
environment      = "production"
aws_region       = "ap-northeast-1"
db_instance_class = "db.t3.micro"
```



## API デプロイ

### AWS SAM によるサーバーレスデプロイ

くまトモ API は Bref を使用して AWS Lambda 上で動作します。

```bash
cd infra/sam

# ビルド
sam build

# デプロイ（ガイド付き）
sam deploy --guided

# 設定済みの場合
sam deploy
```

### SAM 設定ファイル

`infra/sam/samconfig.toml` にデプロイ設定が保存されます：

```toml
[default.deploy.parameters]
stack_name = "kumatomo-api"
s3_bucket = "kumatomo-sam-artifacts"
region = "ap-northeast-1"
confirm_changeset = true
capabilities = "CAPABILITY_IAM"
```

### 手動デプロイ手順

1. **依存関係のインストール**
   ```bash
   cd api
   composer install --no-dev --optimize-autoloader
   ```

2. **キャッシュの生成**
   ```bash
   php artisan config:cache
   php artisan route:cache
   php artisan view:cache
   ```

3. **SAM ビルド & デプロイ**
   ```bash
   cd ../infra/sam
   sam build
   sam deploy
   ```



## 管理画面デプロイ

### ビルドと静的ファイル出力

```bash
cd admin

# 依存関係インストール
npm ci

# プロダクションビルド
npm run build

# 出力結果: .next/ ディレクトリ
```

### デプロイ先

管理画面は以下のいずれかにデプロイ可能です：

- **Vercel** (推奨)
- **AWS Amplify**
- **AWS S3 + CloudFront** (静的エクスポートの場合)



## CI/CD パイプライン

### GitHub Actions ワークフロー

#### API デプロイ (`.github/workflows/deploy-api.yml`)

```yaml
# main ブランチへのプッシュでトリガー
on:
  push:
    branches: [main]
    paths:
      - 'api/**'
      - 'infra/sam/**'
```

**主な処理:**
1. AWS 認証
2. PHP 依存関係インストール
3. SAM ビルド
4. Lambda へデプロイ

#### 管理画面デプロイ (`.github/workflows/deploy-admin.yml`)

```yaml
on:
  push:
    branches: [main]
    paths:
      - 'admin/**'
```

**主な処理:**
1. Node.js セットアップ
2. 依存関係インストール
3. Next.js ビルド
4. デプロイ

### 必要な GitHub Secrets

| Secret 名 | 説明 |
|-----------|------|
| `AWS_ACCESS_KEY_ID` | AWS アクセスキー |
| `AWS_SECRET_ACCESS_KEY` | AWS シークレットキー |
| `AWS_REGION` | デプロイ先リージョン |

```bash
# GitHub CLI で設定
gh secret set AWS_ACCESS_KEY_ID
gh secret set AWS_SECRET_ACCESS_KEY
gh secret set AWS_REGION
```

---

## 環境変数

### 本番環境で必要な環境変数

#### API (AWS SSM パラメータストア)

| パラメータ名 | 説明 |
|-------------|------|
| `/kumatomo/prod/APP_KEY` | Laravel アプリケーションキー |
| `/kumatomo/prod/DB_HOST` | RDS エンドポイント |
| `/kumatomo/prod/DB_PASSWORD` | DBパスワード |
| `/kumatomo/prod/AWS_BUCKET` | S3 バケット名 |

#### 管理画面

| 変数名 | 説明 |
|--------|------|
| `NEXT_PUBLIC_API_URL` | API エンドポイント URL |

---

## トラブルシューティング

### よくある問題

#### Lambda デプロイ失敗

```bash
# CloudFormation スタックの状態確認
aws cloudformation describe-stacks --stack-name kumatomo-api

# ロールバック状態の場合
aws cloudformation delete-stack --stack-name kumatomo-api
sam deploy
```

#### Terraform state ロック

```bash
# ロックの強制解除（他に操作中のユーザーがいないことを確認）
terraform force-unlock <LOCK_ID>
```

#### Lambda コールドスタート

Bref の Lambda 関数は初回起動に時間がかかる場合があります。
Provisioned Concurrency の設定を検討してください。


## 参考リンク

- [AWS SAM Documentation](https://docs.aws.amazon.com/serverless-application-model/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Bref Documentation](https://bref.sh/docs/)
- [GitHub Actions Documentation](https://docs.github.com/actions)
