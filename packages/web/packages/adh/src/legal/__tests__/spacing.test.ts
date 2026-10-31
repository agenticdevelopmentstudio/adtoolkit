import { readFileSync } from 'node:fs'
import { join } from 'node:path'
import { describe, expect, it } from 'vitest'

// A literal JSX text child that opens with a space right after a closing tag, and runs on past
// the line end (`</a> and related⏎`), loses that space under Next's SWC: the site rendered
// "agenticdeveloperhub.comand related". tsup and vitest's esbuild keep it, so a render test
// cannot see the bug; the source can. Write the space as `{' '}`, as the rest of the prose does.
const SOURCES = ['Terms.tsx', 'Privacy.tsx']
const FRAGILE = /<\/[a-z]+> [^\n{<]*$/m

describe('the legal prose', () => {
  it.each(SOURCES)('%s writes every space after a closing tag as {\' \'}', (file) => {
    const text = readFileSync(join(__dirname, '..', file), 'utf8')
    expect(text.match(FRAGILE)?.[0] ?? null).toBeNull()
  })
})
