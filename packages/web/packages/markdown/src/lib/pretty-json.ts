/**
 * JSON, or JSON Lines, laid out for reading: two-space indents, one record after
 * another. Returns null when the text is neither, so a caller can show it as
 * written instead of guessing.
 */
export function prettyJson(text: string): string | null {
  const trimmed = text.trim()
  if (!trimmed) return null
  try {
    return JSON.stringify(JSON.parse(trimmed), null, 2)
  } catch {
    // Not one document; perhaps one per line.
  }
  const lines = trimmed.split('\n').filter((line) => line.trim() !== '')
  if (lines.length < 2) return null
  const records: string[] = []
  for (const line of lines) {
    try {
      records.push(JSON.stringify(JSON.parse(line), null, 2))
    } catch {
      return null
    }
  }
  return records.join('\n')
}

/** A Markdown code fence around `body`, longer than any backtick run inside it. */
export function fenceCode(body: string, lang = ''): string {
  const longest = Math.max(2, ...(body.match(/`+/g) ?? []).map((run) => run.length))
  const fence = '`'.repeat(longest + 1)
  return `${fence}${lang}\n${body}${body.endsWith('\n') ? '' : '\n'}${fence}\n`
}
