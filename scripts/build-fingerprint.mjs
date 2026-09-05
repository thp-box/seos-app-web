import { createHash } from "node:crypto"
import { readdir, readFile } from "node:fs/promises"
async function files(directory) {
  const entries = await readdir(directory, { withFileTypes: true })
  const nested = await Promise.all(entries.map(entry => entry.isDirectory()
    ? files(`${directory}/${entry.name}`) : [`${directory}/${entry.name}`]))
  return nested.flat()
}
export async function fingerprint() {
  const names = [...await files("app/javascript"), ...await files("scripts"), "package.json", "yarn.lock"].sort()
  const hash = createHash("sha256")
  for (const name of names) hash.update(name).update(await readFile(name))
  return hash.digest("hex")
}

export async function fileDigest(name) {
  return createHash("sha256").update(await readFile(name)).digest("hex")
}
