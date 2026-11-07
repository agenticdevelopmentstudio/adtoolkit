import { describe, expect, it } from 'vitest'
import { OVERVIEW_ID, contentDocument, type DocCard, type DocNode } from '../help/document/model'
import { apiRoutesOf, glossaryOf, plainText, sectionsOf, stepOf, termMatches } from '../help/document/parts'
import { readProgress, startOf, stepsDone, toggle } from '../help/document/progress'

function card(name: string, over: Partial<DocCard> = {}): DocCard {
  return {
    crumb: null,
    name,
    addr: '',
    blurb: `<p>${name} blurb</p>`,
    borrowed: null,
    description: [],
    api: [],
    links: [],
    tech: { stack: [], notes: [], from: null },
    screenshots: [],
    ...over,
  }
}

function leaf(id: string, label: string): DocNode {
  return { id, label, addr: '', told: true, open: [id], children: [] }
}

const index: DocNode[] = [leaf('glossary', 'Glossary'), leaf('first', 'First tutorial'), leaf('second', 'Second tutorial')]
const bodies = {
  '': card('Tutorials', { description: ['<p>All of them.</p>'] }),
  glossary: card('Glossary', {
    description: [
      '<p>Words.</p>',
      '<h3>Ecosystem</h3>',
      '<p>A product.</p>',
      '<p>Tutorials: <a href="/tutorials/first">First</a></p>',
      '<h3>Feature</h3>',
      '<p>Part of one.</p>',
      '<p>Tutorials: <a href="/tutorials/first">First</a>, <a href="/tutorials/second">Second</a></p>',
      '<h3>Orphan</h3>',
      '<p>No tutorial &amp; nothing else, though <a href="/tutorials/second">Second</a> is prose.</p>',
    ],
  }),
  first: card('First tutorial', {
    description: ['<p>Before you start.</p>', '<h3>Make it</h3>', '<p>Do this.</p>', '<h3>Use it</h3>', '<ol><li>Then this.</li></ol>'],
    api: ['<p>A <code>GET</code> or <code>PUT</code> of <code>/x/{x id}</code>, and <code>/y?z=1</code>.</p>'],
    links: [{ kind: 'site', name: 'Users', url: '/hub/users', note: null }],
  }),
  second: card('Second tutorial', { description: ['<h3>Only step</h3>', '<p>Go.</p>'] }),
} satisfies Record<string, DocCard>

const doc = contentDocument({
  topicId: 'tutorials',
  base: '/tutorials',
  title: 'Tutorials',
  descriptionTitle: 'Overview',
  index,
  bodies,
  builtFrom: 'test',
  tutorials: { glossaryId: 'glossary' },
})

describe('parts', () => {
  it('splits a description at each ### into a lead and sections', () => {
    const { lead, sections } = sectionsOf(bodies.first.description)
    expect(lead).toEqual(['<p>Before you start.</p>'])
    expect(sections.map((s) => [s.id, s.title, s.html.length])).toEqual([
      ['make-it', 'Make it', 1],
      ['use-it', 'Use it', 1],
    ])
  })

  it('reads numeric and common named entities as their characters, and leaves unknown ones', () => {
    expect(plainText('<p>A&nbsp;&mdash;&#8217;s &#x2019; &amp; &hellip; &bogus; &#0;</p>')).toBe('A \u2014\u2019s \u2019 & \u2026 &bogus; &#0;')
  })

  it('keeps two steps with one title apart', () => {
    const { sections } = sectionsOf(['<h3>Save</h3>', '<h3>Save</h3>'])
    expect(sections.map((s) => s.id)).toEqual(['save', 'save-2'])
    // A title that is itself "Save 2" claims save-2, so a later repeat skips past it.
    const again = sectionsOf(['<h3>Save</h3>', '<h3>Save 2</h3>', '<h3>Save</h3>']).sections
    expect(again.map((s) => s.id)).toEqual(['save', 'save-2', 'save-3'])
  })

  it('reads each glossary term and the tutorials it links to', () => {
    const terms = glossaryOf(bodies.glossary.description, '/tutorials', new Set(['first', 'second']))
    expect(terms.map((t) => [t.id, t.tutorials])).toEqual([
      ['ecosystem', ['first']],
      ['feature', ['first', 'second']],
      ['orphan', []],
    ])
    expect(terms[0]!.html).toEqual(['<p>A product.</p>'])
    expect(terms[2]!.text).toBe('No tutorial & nothing else, though Second is prose.')
  })

  it('finds a Tutorials line written in bold or with attributes on its paragraph', () => {
    const terms = glossaryOf(
      [
        '<h3>Bold</h3>', '<p>One.</p>', '<p><strong>Tutorials:</strong> <a href="/tutorials/first">First</a></p>',
        '<h3>Classed</h3>', '<p>Two.</p>', '<p class="x">Tutorials: <a href="/tutorials/second">Second</a></p>',
      ],
      '/tutorials',
      new Set(['first', 'second']),
    )
    expect(terms.map((t) => [t.id, t.tutorials, t.html])).toEqual([
      ['bold', ['first'], ['<p>One.</p>']],
      ['classed', ['second'], ['<p>Two.</p>']],
    ])
  })

  it('makes the items of a step\'s first numbered list its sub-steps', () => {
    const section = {
      id: 'go',
      title: 'Go',
      titleHtml: 'Go',
      html: ['<p>First.</p>\n', '<ol>\n<li>One <code>x</code></li>\n<li>Two<ol><li>inner</li></ol></li>\n</ol>\n', '<p>Then.</p>'],
    }
    const step = stepOf(section)
    expect(step.before).toEqual(['<p>First.</p>\n'])
    expect(step.substeps).toEqual([
      { id: 'go/one-x', html: 'One <code>x</code>' },
      { id: 'go/two', html: 'Two<ol><li>inner</li></ol>' },
    ])
    expect(step.after).toEqual(['<p>Then.</p>'])
    // An id is the item's words, so adding an item above one leaves its id, and its tick, alone.
    const grown = stepOf({ ...section, html: ['<ol><li>Zero</li><li>One <code>x</code></li><li>Two</li></ol>'] })
    expect(grown.substeps.map((s) => s.id)).toEqual(['go/zero', 'go/one-x', 'go/two'])
    // Same words twice are told apart; long items keep their first six words; an empty one is "item".
    const repeated = stepOf({
      ...section,
      html: ['<ol><li><p>Save</p><pre>a</pre></li><li>Save</li><li>a b c d e f g h</li><li><code></code></li></ol>'],
    })
    expect(repeated.substeps.map((s) => s.id)).toEqual(['go/save', 'go/save-2', 'go/a-b-c-d-e-f', 'go/item'])
    // A list of one item is not a set of sub-steps.
    const single = stepOf({ ...section, html: ['<ol><li>Only</li></ol>'] })
    expect(single.substeps).toEqual([])
    expect(single.before).toEqual(['<ol><li>Only</li></ol>'])
    expect(step.start).toBe(1)
  })

  it('reads a list a code fence split in two as one, keeping its numbering', () => {
    const step = stepOf({
      id: 'go',
      title: 'Go',
      titleHtml: 'Go',
      html: [
        '<ol start="3"><li>Run it:</li></ol>',
        '<pre><code>npm run x</code></pre>',
        '<ol start="4"><li>Check it.</li><li>Ship it.</li></ol>',
        '<p>Done.</p>',
      ],
    })
    expect(step.start).toBe(3)
    expect(step.substeps.map((s) => s.html)).toEqual([
      'Run it:<pre><code>npm run x</code></pre>',
      'Check it.',
      'Ship it.',
    ])
    expect(step.after).toEqual(['<p>Done.</p>'])
  })

  it('reads the routes an API names, each method code going to the next path', () => {
    expect(
      apiRoutesOf([
        '<p>A <code>GET</code> of <code>/auth/me</code>, then a <code>GET</code> or <code>PUT</code> of <code>/a/{id}</code>.</p>',
        '<p>Under <code>/b?c={c}</code>, and <code>name</code> is not a route. <code>GET</code> of <code>/auth/me</code> again.</p>',
      ]),
    ).toEqual([
      { method: 'GET', path: '/auth/me' },
      { method: 'GET', path: '/a/{id}' },
      { method: 'PUT', path: '/a/{id}' },
      { path: '/b' },
    ])
  })

  it('keeps a method to its own block, strips a fragment, and reads a method and path in one code', () => {
    expect(
      apiRoutesOf([
        '<p>Send a <code>POST</code> request.</p>',
        '<p>The list is at <code>/x#top</code>, and <code>GET /auth/me</code> says who you are.</p>',
      ]),
    ).toEqual([{ path: '/x' }, { method: 'GET', path: '/auth/me' }])
  })

  it('gives a method written "to it" the path before it, not the next one', () => {
    expect(
      apiRoutesOf([
        '<p>A <code>GET</code> of <code>/p</code> lists them, a <code>POST</code> to it adds more, and a <code>DELETE</code> of <code>/p/{id}</code> removes one.</p>',
      ]),
    ).toEqual([
      { method: 'GET', path: '/p' },
      { method: 'POST', path: '/p' },
      { method: 'DELETE', path: '/p/{id}' },
    ])
  })

  it('matches a term when every word typed is in its name or definition', () => {
    const term = { title: 'Feature', text: 'Part of an ecosystem' }
    expect(termMatches(term, '')).toBe(true)
    expect(termMatches(term, 'feat eco')).toBe(true)
    expect(termMatches(term, 'feature website')).toBe(false)
  })
})

describe('a document with entries that have no card', () => {
  const plain = (index: DocNode[], cards: Record<string, DocCard>) =>
    contentDocument({ topicId: 'hub', base: '/hub', title: 'Hub', descriptionTitle: 'Overview', index, bodies: cards, builtFrom: 'test' })

  it('makes an untold leaf its own canonical, never a missing Overview under it', () => {
    const d = plain([{ id: 'x', label: 'X', addr: '', told: false, open: ['x'], children: [] }], { '': card('Hub') })
    const x = d.view(['x'])!
    expect(x.card).toBeNull()
    expect(x.canonical).toEqual(['x'])
    expect(d.canonicalPaths()).toContainEqual(['x'])
  })

  it('fails on a told leaf with no card instead of rendering an empty page', () => {
    const d = plain([leaf('x', 'X')], { '': card('Hub') })
    expect(() => d.view(['x'])).toThrow(/holds no card for it/)
  })
})

describe('a tutorial with nothing for its panes', () => {
  it('fails the build rather than falling back to a plain page', () => {
    expect(() =>
      contentDocument({
        topicId: 'tutorials',
        base: '/tutorials',
        title: 'Tutorials',
        descriptionTitle: 'Overview',
        index: [leaf('glossary', 'Glossary'), leaf('prose', 'Prose only')],
        bodies: { '': card('Tutorials'), glossary: card('Glossary'), prose: card('Prose only', { description: ['<p>Just words.</p>'] }) },
        builtFrom: 'test',
        tutorials: { glossaryId: 'glossary' },
      }),
    ).toThrow(/"prose" has no ### step/)
  })
})

describe('a tutorials document', () => {
  it('lists the Glossary and each tutorial at the root, after the Overview', () => {
    const root = doc.view([OVERVIEW_ID])!.rails[0]!
    expect(root.items.map((i) => [i.id, i.kind])).toEqual([
      [OVERVIEW_ID, undefined],
      ['glossary', 'glossary'],
      ['first', 'tutorial'],
      ['second', 'tutorial'],
    ])
    // A plain divider sets the Glossary apart from the tutorials under it.
    expect(root.items.map((i) => Boolean(i.divider))).toEqual([false, true, false, false])
  })

  it('lists only the panes a tutorial has something for', () => {
    const first = doc.view(['first', OVERVIEW_ID])!
    expect(first.rails[1]!.items.map((i) => i.id)).toEqual([OVERVIEW_ID, 'definitions', 'steps'])
    const second = doc.view(['second', OVERVIEW_ID])!
    expect(second.rails[1]!.items.map((i) => i.id)).toEqual([OVERVIEW_ID, 'definitions', 'steps'])
  })

  it('opens a tutorial on its Overview', () => {
    const bare = doc.view(['first'])!
    expect(bare.card).toBeNull()
    expect(bare.canonical).toEqual(['first', OVERVIEW_ID])
    const overview = doc.view(['first', OVERVIEW_ID])!
    expect(overview.tutorial?.part).toBe('overview')
    expect(overview.tutorial?.lead).toEqual(['<p>Before you start.</p>'])
    expect(overview.card?.name).toBe('First tutorial')
    // The Overview carries the API: the routes for its button to highlight.
    expect(overview.tutorial?.api).toEqual([
      { method: 'GET', path: '/x/{x id}' },
      { method: 'PUT', path: '/x/{x id}' },
      { path: '/y' },
    ])
    expect(doc.view(['second', OVERVIEW_ID])!.tutorial?.api).toEqual([])
  })

  it('reads a pane from its tutorial card', () => {
    const steps = doc.view(['first', 'steps'])!
    expect(steps.card?.name).toBe('First tutorial')
    expect(steps.title).toBe('Steps: First tutorial')
    expect(steps.tutorial?.steps.map((s) => s.id)).toEqual(['make-it', 'use-it'])
    const defs = doc.view(['second', 'definitions'])!
    expect(defs.tutorial?.terms.map((t) => t.id)).toEqual(['feature'])
    expect(defs.tutorial?.glossary).toEqual({ name: 'Glossary', href: '/tutorials/glossary' })
  })

  it('shows the Glossary with every tutorial a term can name', () => {
    const view = doc.view(['glossary'])!
    expect(view.glossary?.terms).toHaveLength(3)
    expect(view.glossary?.tutorials.second).toEqual({ name: 'Second tutorial', href: '/tutorials/second' })
  })

  it('prerenders every pane, and 404s a pane a tutorial lacks', () => {
    const paths = doc.paths().map((p) => p.join('/'))
    expect(paths).toContain('first/steps')
    expect(paths).toContain('second/definitions')
    // API and References are on the Overview, not panes of their own.
    expect(paths).not.toContain('first/api')
    expect(paths).not.toContain('first/references')
    expect(doc.view(['first', 'api'])).toBeNull()
  })

  it('fails when the glossary it names is missing', () => {
    expect(() =>
      contentDocument({
        topicId: 't',
        base: '/t',
        title: 'T',
        descriptionTitle: 'Overview',
        index: [leaf('first', 'First')],
        bodies: { first: bodies.first },
        builtFrom: 'test',
        tutorials: { glossaryId: 'glossary' },
      }),
    ).toThrow(/Glossary/)
  })
})

describe('tutorial progress', () => {
  const steps = [{ id: 'a' }, { id: 'b' }, { id: 'c' }]

  it('starts with nothing done and the first step active', () => {
    expect(startOf(steps)).toEqual({ v: 1, done: [], active: 'a' })
    expect(readProgress(null, steps)).toEqual(startOf(steps))
    expect(readProgress('not json', steps)).toEqual(startOf(steps))
  })

  it('moves to the next step not done when one is ticked', () => {
    let p = toggle(startOf(steps), steps, 'a', true)
    expect(p).toEqual({ v: 1, done: ['a'], active: 'b' })
    p = toggle(p, steps, 'c', true)
    expect(p.active).toBe('b')
    p = toggle(p, steps, 'b', true)
    expect(p.active).toBeNull()
  })

  it('makes a cleared step the active one', () => {
    const p = toggle({ v: 1, done: ['a', 'b'], active: 'c' }, steps, 'a', false)
    expect(p).toEqual({ v: 1, done: ['b'], active: 'a' })
  })

  describe('with sub-steps', () => {
    const nested = [{ id: 'a', substeps: [{ id: 'a/1' }, { id: 'a/2' }] }, { id: 'b' }]

    it('ticks and clears every sub-step with its step', () => {
      let p = toggle(startOf(nested), nested, 'a', true)
      expect(p).toEqual({ v: 1, done: ['a', 'a/1', 'a/2'], active: 'b' })
      p = toggle(p, nested, 'a', false)
      expect(p).toEqual({ v: 1, done: [], active: 'a' })
    })

    it('ticks the step and moves on once every sub-step is ticked', () => {
      let p = toggle(startOf(nested), nested, 'a/1', true)
      expect(p).toEqual({ v: 1, done: ['a/1'], active: 'a' })
      expect(stepsDone(p, nested)).toBe(0)
      p = toggle(p, nested, 'a/2', true)
      expect(p).toEqual({ v: 1, done: ['a/1', 'a/2', 'a'], active: 'b' })
      expect(stepsDone(p, nested)).toBe(1)
    })

    it('clears the step when a sub-step is cleared', () => {
      const p = toggle({ v: 1, done: ['a', 'a/1', 'a/2'], active: 'b' }, nested, 'a/1', false)
      expect(p).toEqual({ v: 1, done: ['a/2'], active: 'a' })
    })

    it('reads a step saved as done as having every sub-step done', () => {
      const raw = JSON.stringify({ v: 1, done: ['a'], active: 'b' })
      expect(readProgress(raw, nested)).toEqual({ v: 1, done: ['a', 'a/1', 'a/2'], active: 'b' })
    })
  })

  it('drops saved steps the tutorial no longer has', () => {
    const raw = JSON.stringify({ v: 1, done: ['a', 'gone'], active: 'gone' })
    expect(readProgress(raw, steps)).toEqual({ v: 1, done: ['a'], active: 'b' })
  })
})
