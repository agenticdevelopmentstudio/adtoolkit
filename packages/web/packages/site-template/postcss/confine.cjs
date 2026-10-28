/* site-template/postcss/confine.cjs
 *
 * `/*! @confine .marker *\/` — confine a stylesheet to the documents that carry `.marker`.
 *
 * Why: the App Router keeps a layout's stylesheet in the document after the reader navigates
 * out of its routes. A route group whose sheet resets the page (all of Tailwind, a base theme
 * that styles `:where(body)`, a second copy of the landing kit's sheets) therefore restyles `/`
 * whenever `/` is reached by a client navigation from that group, and only then. Confining the
 * sheet to documents that contain the group's own wrapper makes it inert everywhere else, at no
 * cost to the routes that mount it.
 *
 * How: every selector `S` of every style rule, imported ones included, becomes
 * `:where(:root:has(.marker)) S` — `S` inside a document that carries the marker — and, when `S`
 * is one compound and so could match `<html>` itself (`html`, `:root`, `*`, …), also `S` with
 * `:where(:root:has(.marker))` added to it (before any pseudo-element). `:where()` weighs nothing,
 * so specificity is unchanged, and the rules keep their places, so order is unchanged: on a route
 * that carries the marker the sheet cascades exactly as it did unconfined. (`@scope` would confine
 * as well, but a scoped rule also wins ties on scope proximity against every unscoped rule of
 * equal specificity, which reorders the cascade on the very routes the sheet belongs to.)
 * Grouping rules (`@layer`, `@media`, `@supports`, `@container`, `@starting-style`) keep their
 * place and have their contents confined. Rules that declare a name (`@font-face`, `@keyframes`,
 * `@property`, a `@layer` statement) stay global: they draw nothing on their own. A sheet that
 * already uses `@scope` is refused, since a selector inside one is read relative to its scope.
 *
 * The directive is a `/*!` comment, not an at-rule, because it has to survive Tailwind:
 * `@tailwindcss/postcss` inlines the sheet's `@import`s and, in a production build, drops every
 * at-rule it does not know and every comment but a `/*!` one. Next runs Tailwind before this
 * plugin whatever order the config lists them in, so the plugin reads the directive in `Once`
 * from whichever side of Tailwind it lands on, and rewrites in `OnceExit`, after every plugin's
 * `Once` (Tailwind's is where the inlining happens). The directive is removed from the output.
 *
 * A sheet without the directive passes through unchanged.
 */
'use strict'

// The whole comment is the directive (postcss's `text` keeps the `!`); prose that merely
// mentions it is not.
const DIRECTIVE = /^!\s*@confine\s+(\S+)\s*$/
// One class: the wrapper element a route group's layout renders.
const MARKER = /^\.[A-Za-z_][\w-]*$/
// At-rules whose body is a list of rules: their contents are confined in place. Anything else
// that is not a style rule stays where it is, as it was.
const GROUPING = new Set(['layer', 'media', 'supports', 'container', 'starting-style'])
// The pseudo-elements CSS2 wrote with one colon.
const LEGACY_PSEUDO_ELEMENT = /^:(before|after|first-line|first-letter)(?![\w-])/i
const HEX = /[0-9a-fA-F]/
const SPACE = /\s/

/**
 * One complex selector, read at its top level (outside strings, brackets and parentheses, with
 * escapes skipped): whether it is a single compound, and where its first pseudo-element starts.
 */
function shape(selector) {
  let depth = 0
  let quote = null
  let compound = true
  let pseudo = -1
  for (let i = 0; i < selector.length; i++) {
    const c = selector[i]
    if (c === '\\') {
      // `\31 ` — up to six hex digits and one optional whitespace; otherwise one character.
      let j = i + 1
      if (HEX.test(selector[j] || '')) {
        while (j < i + 7 && HEX.test(selector[j] || '')) j++
        if (SPACE.test(selector[j] || '')) j++
        i = j - 1
      } else {
        i = j
      }
      continue
    }
    if (quote) {
      if (c === quote) quote = null
      continue
    }
    if (c === '"' || c === "'") quote = c
    else if (c === '(' || c === '[') depth++
    else if (c === ')' || c === ']') depth--
    else if (depth === 0) {
      if (SPACE.test(c) || c === '>' || c === '+' || c === '~') compound = false
      else if (c === ':' && pseudo < 0 && (selector[i + 1] === ':' || LEGACY_PSEUDO_ELEMENT.test(selector.slice(i)))) pseudo = i
      if (c === ':' && selector[i + 1] === ':') i++
    }
  }
  return { compound, pseudo }
}

function confineSelector(selector, where) {
  const s = selector.trim()
  const out = [`${where} ${s}`]
  const { compound, pseudo } = shape(s)
  if (compound) out.push(pseudo < 0 ? `${s}${where}` : `${s.slice(0, pseudo)}${where}${s.slice(pseudo)}`)
  return out
}

function confine(container, where) {
  container.each((node) => {
    if (node.type === 'rule') node.selectors = node.selectors.flatMap((s) => confineSelector(s, where))
    else if (node.type === 'atrule' && GROUPING.has(node.name) && node.nodes) confine(node, where)
  })
}

const plugin = () => {
  // Per sheet: the marker its directive named, carried from `Once` to `OnceExit`.
  const markers = new WeakMap()
  return {
    postcssPlugin: 'site-template-confine',
    Once(root, { result }) {
      const directives = []
      root.walkComments((node) => {
        if (DIRECTIVE.test(node.text)) directives.push(node)
      })
      if (directives.length === 0) return
      if (directives.length > 1) throw directives[1].error('a sheet has one @confine')
      const node = directives[0]
      if (node.parent !== root) throw node.error('@confine belongs at the top level of the sheet')
      const marker = DIRECTIVE.exec(node.text)[1]
      if (!MARKER.test(marker)) {
        throw node.error(`@confine takes one class, like \`/*! @confine .my-group */\` — got \`${marker}\``)
      }
      node.remove()
      markers.set(result, marker)
    },
    OnceExit(root, { result }) {
      const marker = markers.get(result)
      if (marker === undefined) return
      root.walkAtRules('scope', (node) => {
        throw node.error('@confine cannot confine a sheet that uses @scope: its selectors are read relative to the scope')
      })
      confine(root, `:where(:root:has(${marker}))`)
      result.messages.push({ type: 'confine', plugin: 'site-template-confine', marker })
    },
  }
}
plugin.postcss = true

module.exports = plugin
