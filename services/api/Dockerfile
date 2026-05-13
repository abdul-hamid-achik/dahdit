FROM oven/bun:1.3.11-alpine AS base
WORKDIR /app

COPY package.json bun.lock* ./
COPY apps/web/package.json apps/web/package.json
COPY services/api/package.json services/api/package.json
COPY packages/morse-core/package.json packages/morse-core/package.json
COPY packages/shared-types/package.json packages/shared-types/package.json
COPY packages/tsconfig/package.json packages/tsconfig/package.json
RUN bun install --frozen-lockfile || bun install

COPY services/api services/api
COPY packages/morse-core packages/morse-core
WORKDIR /app/services/api

EXPOSE 4000
CMD ["bun", "src/index.ts"]
