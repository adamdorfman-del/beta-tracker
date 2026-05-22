FROM --platform=linux/amd64 node:20-slim

RUN npm install -g pnpm

WORKDIR /app

COPY pnpm-workspace.yaml ./
COPY package.json ./
COPY tsconfig.json ./
COPY tsconfig.base.json ./
COPY lib/ ./lib/
COPY artifacts/api-server/ ./artifacts/api-server/
COPY artifacts/beta-tracker/ ./artifacts/beta-tracker/

RUN pnpm install

ENV PORT=8080
ENV BASE_PATH=/
ENV NODE_ENV=production

ARG VITE_CLERK_PUBLISHABLE_KEY
ENV VITE_CLERK_PUBLISHABLE_KEY=$VITE_CLERK_PUBLISHABLE_KEY

ARG VITE_CLERK_PROXY_URL
ENV VITE_CLERK_PROXY_URL=$VITE_CLERK_PROXY_URL

RUN pnpm --filter @workspace/beta-tracker build
RUN pnpm --filter @workspace/api-server build

WORKDIR /app/artifacts/api-server

EXPOSE 8080

CMD ["node", "--enable-source-maps", "./dist/index.mjs"]
