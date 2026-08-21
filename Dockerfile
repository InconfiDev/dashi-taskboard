# syntax=docker/dockerfile:1

# ---------- build ----------
FROM node:24-slim AS build
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY . .

RUN npm run build:web \
 && npm prune --omit=dev \
 && npm cache clean --force

# ---------- runtime ----------
FROM node:24-slim
WORKDIR /app

ENV NODE_ENV=production \
    CODEX_TASKBOARD_HOST=0.0.0.0 \
    CODEX_TASKBOARD_PORT=47823 \
    CODEX_TASKBOARD_DATA_DIR=/data

COPY --from=build /app ./

RUN mkdir -p /data && chown -R node:node /data /app
USER node

EXPOSE 47823

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD node -e "fetch('http://127.0.0.1:'+(process.env.CODEX_TASKBOARD_PORT||47823)+'/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

CMD ["node", "server/index.mjs"]
