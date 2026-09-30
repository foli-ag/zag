import { defineConfig } from "tsup"

// solid-js 2 ships ESM only, so the adapter does too
export default defineConfig({
  entry: ["src/index.ts"],
  format: ["esm"],
  target: "es2020",
  dts: true,
  clean: true,
})
