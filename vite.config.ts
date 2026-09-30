import solidPlugin from "@solidjs/vite-plugin"
import { defineConfig } from "vitest/config"

export default defineConfig({
  plugins: [solidPlugin()],
  test: {
    retry: 2,
    globals: true,
    environment: "jsdom",
    css: false,
    setupFiles: "./vitest.setup.ts",
  },
  resolve: {
    conditions: ["development", "browser"],
  },
})
