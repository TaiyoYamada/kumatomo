FROM node:20-alpine

WORKDIR /app

# package.jsonをコピー
COPY package.json ./

# npmで依存関係をインストール
RUN npm install

# ソースコードをコピー
COPY . .

# ポート3000を公開
EXPOSE 3000

# デフォルトコマンド（docker-compose.ymlでオーバーライドされる）
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0"]
