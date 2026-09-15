import basicSsl from "@vitejs/plugin-basic-ssl";
import path from "node:path";
import { defineConfig } from "vite";
import EnvironmentPlugin from "vite-plugin-environment";

import viteBaseConfig, { embedCoreEnvVars } from "../vite.config";

export default defineConfig((configEnv) => {
  /** @type {import('vite').UserConfig} */
  const config = {
    ...viteBaseConfig,
    base: "/embed/",
    plugins: [
      EnvironmentPlugin({
        EMBED_PUBLIC_EMBED_FINGER_PRINT: embedCoreEnvVars.EMBED_PUBLIC_EMBED_FINGER_PRINT,
        EMBED_PUBLIC_EMBED_VERSION: embedCoreEnvVars.EMBED_PUBLIC_EMBED_VERSION,
        EMBED_PUBLIC_VERCEL_URL: embedCoreEnvVars.EMBED_PUBLIC_VERCEL_URL,
        EMBED_PUBLIC_WEBAPP_URL: embedCoreEnvVars.EMBED_PUBLIC_WEBAPP_URL,
        EMBED_PUBLIC_EMBED_LIB_URL: embedCoreEnvVars.EMBED_PUBLIC_EMBED_LIB_URL,
        NEXT_PUBLIC_IS_E2E: embedCoreEnvVars.NEXT_PUBLIC_IS_E2E,
      }),
      ...(process.argv.includes("--https") ? [basicSsl()] : []),
    ],
    server: {
      headers: {},
    },
    build: {
      emptyOutDir: true,
      rollupOptions: {
        input: {
          preview: path.resolve(__dirname, "preview.html"),
          embed: path.resolve(__dirname, "src/embed.ts"),
        },
        plugins: [
          {
            generateBundle: (code, bundle) => {
              bundle["embed.js"].code = `!function(){${bundle["embed.js"].code}}()`;
            },
          },
        ],
        output: {
          entryFileNames: "[name].js",
          dir: "../../../apps/web/public/embed",
        },
      },
    },
  };

  if (configEnv.mode === "development") {
    config.build.watch = {
      include: ["src/**"],
    };
  }
  return config;
});
