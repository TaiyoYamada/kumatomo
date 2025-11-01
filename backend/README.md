Kumatomo Backend (Express + Prisma + AWS Lambda Web Adapter)

- Language: TypeScript
- Framework: Express
- Runtime: AWS Lambda (Node.js 20) via Lambda Web Adapter (LWA)
- ORM: Prisma
- Database: PostgreSQL

Structure
- src/app.ts – Express app wiring
- src/index.ts – HTTP server entry (used by LWA)
- src/routes/ – route definitions, path parity with Laravel
- src/controllers/ – controller implementations (Prisma-based)
- prisma/schema.prisma – generated from Laravel migrations
- scripts/generate-prisma-from-laravel.ts – generator from api/database/migrations

Setup
1) Copy .env.example to .env and set DATABASE_URL to your PostgreSQL instance.
2) Install deps and generate Prisma client: npm ci && npm run prisma:generate
3) Build TypeScript: npm run build
4) Local dev (no Lambda): npm run start:dev (listens on PORT, default 8080)

Generate Prisma schema from Laravel
- npm run prisma:sync
- Reads ../api/database/migrations and ../api/app/Enums/ShopGenre.php, writes prisma/schema.prisma and runs prisma generate

Docker (Lambda Web Adapter)
- docker build -t kumatomo-backend:latest .
- Deploy image to AWS Lambda (Function URL or API Gateway). Container listens on 8080.

Notes / Parity Gaps
- Auth: dev-only Bearer token (Authorization: Bearer <userId>). Replace with JWT/Cognito as needed.
- Images: upload endpoints are placeholders; integrate S3 with presigned URLs.
- AI: /ai/chat is a placeholder; wire up your provider and log with Prisma.
- Storage proxy (/storage/...): not implemented; serve via S3 or CDN.
- BigInt JSON: IDs serialized as strings to avoid precision loss.

Once auth and uploads are wired, iOS/web clients can call the same paths with identical payloads.

