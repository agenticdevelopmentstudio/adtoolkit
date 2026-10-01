import { describe, it, expect } from 'vitest'
import { fenceCode, prettyJson } from '../lib/pretty-json'

describe('prettyJson', () => {
  it('indents a JSON document', () => {
    expect(prettyJson('{"a":1,"b":[true]}')).toBe('{\n  "a": 1,\n  "b": [\n    true\n  ]\n}')
  })

  it('indents each record of JSON Lines', () => {
    expect(prettyJson('{"a":1}\n\n{"b":2}\n')).toBe('{\n  "a": 1\n}\n{\n  "b": 2\n}')
  })

  it('returns null for text that is neither', () => {
    expect(prettyJson('not json')).toBeNull()
    expect(prettyJson('{"a":1}\nnope')).toBeNull()
    expect(prettyJson('   ')).toBeNull()
  })
})

describe('fenceCode', () => {
  it('fences with more backticks than the body holds', () => {
    expect(fenceCode('a ```` b', 'json')).toBe('`````json\na ```` b\n`````\n')
    expect(fenceCode('x\n')).toBe('```\nx\n```\n')
  })
})
