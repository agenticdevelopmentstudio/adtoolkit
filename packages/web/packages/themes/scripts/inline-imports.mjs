// A stylesheet with each RELATIVE `@import './x.css';` replaced by that file's text,
// recursively — what a bundler hands the page. A theme sheet that shares another's roles
// (fishlamp.css and mikefullerton-landing.css both import fishlamp-palette.css) holds only
// its own declarations; anything that reads a sheet as a whole theme rather than through a
// bundler (build-theme-data.mjs's strings for ThemeStyle's raw injection, contrast-check.mjs)
// must read it through this. A remote `@import url(...)` font request is left alone.
// Ships beside build-theme-data.mjs (package.json `files`): postinstall imports it.
import { readFile } from 'node:fs/promises'
import { dirname, join } from 'node:path'

const RELATIVE_IMPORT = /@import\s+['"](\.\.?\/[^'"]+)['"]\s*;/g

export async function inlineImports(path, seen = new Set()) {
  if (seen.has(path)) throw new Error(`inline-imports: ${path} imports itself`)
  const css = await readFile(path, 'utf8')
  const parts = []
  let last = 0
  for (const m of css.matchAll(RELATIVE_IMPORT)) {
    parts.push(css.slice(last, m.index))
    parts.push(await inlineImports(join(dirname(path), m[1]), new Set([...seen, path])))
    last = m.index + m[0].length
  }
  parts.push(css.slice(last))
  return parts.join('')
}
