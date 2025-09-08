# ---- Base con toolchain nativa ----
FROM node:20-bullseye-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
  ca-certificates git python3 build-essential pkg-config libc6-dev libvips-dev openssl curl \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Entorno
ENV NODE_ENV=production
ENV PORT=3000
ENV NEXT_TELEMETRY_DISABLED=1
# RAM de Node para evitar OOM en build
ENV NODE_OPTIONS=--max-old-space-size=6144

# Yarn Berry
RUN corepack enable

# Copiamos el monorepo
COPY . .

# 1) Instalar dependencias (respetando yarn.lock)
RUN yarn install --immutable

# 2) Generar artefactos de Prisma (client + zod) ANTES del build
RUN yarn workspace @calcom/prisma generate

# 3) Compilar SOLO la web y sus dependencias reales
RUN npx turbo run build --filter=@calcom/web

EXPOSE 3000

# Migraciones en arranque y boot de la web
CMD ["sh","-lc","yarn workspace @calcom/prisma db-deploy && yarn workspace @calcom/web start"]
