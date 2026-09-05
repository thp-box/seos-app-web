import { readFile, stat } from "node:fs/promises"
import { fingerprint, fileDigest } from "./build-fingerprint.mjs"
try {
  const manifest = JSON.parse(await readFile("tmp/assets-build.json", "utf8"))
  if (manifest.fingerprint !== await fingerprint()) throw new Error("sources modifiées")
  for (const [name, expected] of Object.entries(manifest.outputs)) {
    if (await fileDigest(name) !== expected) throw new Error(`${name} altéré`)
  }
  for (const name of ["application.js", "application.css"]) {
    if ((await stat(`app/assets/builds/${name}`)).size === 0) throw new Error(`${name} vide`)
  }
} catch (error) {
  console.error(`Assets absents ou périmés (${error.message}). Exécutez yarn build.`)
  process.exit(1)
}
