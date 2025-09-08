# ---- base con toolchain para deps nativas ----
FROM node:20-bullseye-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
  ca-certificates git python3 build-essential pkg-config libc6-dev libvips-dev openssl curl \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app
ENV NODE_ENV=production
ENV PORT=3000
# sube heap para evitar OOM al compilar todo
ENV NODE_OPTIONS=--max-old-space-size=8192

RUN corepack enable

# Copiamos todo el repo (Yarn Berry + monorepo)
COPY . .

# --- Parche mínimo para que build completo no reviente ---
# El app de docs (ui-playground) importa un componente con hooks y Next exige "use client".
# Insertamos la directiva al inicio del archivo afectado.
RUN sed -i '1s/^/"use client";\n/' packages/ui/components/avatar/UserAvatarGroup.tsx || true

# Instala deps y compila TODO (sin filtros)
RUN yarn install --immutable
RUN npx turbo run build

EXPOSE 3000

# Migraciones y arranque de la app web (el resto ya compiló)
CMD sh -c "yarn workspace @calcom/prisma db-deploy && yarn workspace @calcom/web start"
