# Lambda Web Adapter container for Node 20 + Express

FROM node:20-alpine AS base
WORKDIR /app

# Install dev deps to build Prisma client
FROM base AS deps
COPY package*.json ./
RUN npm ci

FROM deps AS build
COPY tsconfig.json ./
COPY prisma ./prisma
COPY src ./src
RUN npm run prisma:generate && npm run build

# Prune dev deps for runtime layer
FROM deps AS runtime-deps
RUN npm prune --omit=dev

# Fetch AWS Lambda Web Adapter binary
FROM public.ecr.aws/awsguru/aws-lambda-adapter:0.8.3 AS aws-lambda-adapter

FROM node:20-alpine AS runtime
WORKDIR /app

ENV NODE_ENV=production \
    PORT=8080 \
    AWS_LWA_ENABLE_COMPRESSION=true

COPY --from=runtime-deps /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY package*.json ./

# Copy adapter binary
COPY --from=aws-lambda-adapter /aws-lambda-adapter /usr/local/bin/aws-lambda-adapter

EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/aws-lambda-adapter"]
CMD ["node","dist/index.js"]

