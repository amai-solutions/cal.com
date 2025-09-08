# ---- Base con toolchain nativa ----
FROM node:20-bullseye-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
  ca-certificates git python3 build-essential pkg-config libc6-dev libvips-dev openssl curl \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Entorno de build
ENV NODE_ENV=production
ENV PORT=3000
ENV NEXT_TELEMETRY_DISABLED=1
# Subir heap de Node para evitar OOM durante el build
ENV NODE_OPTIONS=--max-old-space-size=6144
# Hace que tu next.config ignore ESLint/TS en build (ya lo tienes como !!process.env.CI)
ENV CI=1

# Placeholders SOLO para que next.config no lance errores en build.
# En runtime Dokploy los sobreescribe con tus valores reales.
ENV NEXT_PUBLIC_WEBAPP_URL="https://build-placeholder.local"
ENV NEXTAUTH_URL="https://build-placeholder.local/api/auth"
ENV NEXTAUTH_SECRET="build_placeholder_secret"
ENV CALENDSO_ENCRYPTION_KEY="build_placeholder_encryption_key"

# Yarn Berry
RUN corepack enable

# Copiamos el monorepo
COPY . .

# 1) Instalar dependencias (respeta yarn.lock)
RUN yarn install --immutable

# 2) Generar Prisma (Client + tipos Zod) ANTES del build
RUN yarn workspace @calcom/prisma generate

# 3) Compilar SOLO la web y lo que realmente usa
RUN npx turbo run build --filter=@calcom/web

EXPOSE 3000

# 4) Migraciones en arranque y levantar la web
CMD ["sh","-lc","yarn workspace @calcom/prisma db-deploy && yarn workspace @calcom/web start"]
