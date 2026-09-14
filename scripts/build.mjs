import * as esbuild from "esbuild"
import { mkdir, writeFile } from "node:fs/promises"
import { fingerprint, fileDigest } from "./build-fingerprint.mjs"

const options = {
  entryPoints: ["app/javascript/application.js", "app/javascript/map.js"], bundle: true, sourcemap: true, metafile: true,
  format: "esm", outdir: "app/assets/builds",
  loader: { ".woff2": "file", ".png": "file" }, assetNames: "fonts/[name]-[hash]",
  plugins: [{ name: "build-manifest", setup(build) {
    build.onEnd(async result => {
      if (result.errors.length) return
      await mkdir("tmp", { recursive: true })
      const outputs = Object.fromEntries(await Promise.all(Object.keys(result.metafile.outputs).map(async name => [name, await fileDigest(name)])))
      await writeFile("tmp/assets-build.json", JSON.stringify({ fingerprint: await fingerprint(), outputs }))
    })
  } }]
}
if (process.argv.includes("--watch")) {
  const context = await esbuild.context(options)
  await context.watch()
} else {
  await esbuild.build(options)
}
