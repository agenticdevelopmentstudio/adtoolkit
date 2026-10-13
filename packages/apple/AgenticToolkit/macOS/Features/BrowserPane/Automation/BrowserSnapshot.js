// BrowserSnapshot.js — the page-world runtime behind BrowserAutomation.
// Installed once per document (version-checked); every call returns plain JSON.
(function () {
  if (window.__adkitchen && window.__adkitchen.version === 1) { return; }

  const refs = new Map();            // ref -> WeakRef<Element>
  window.__adkitchenRefs = refs;
  let generation = 0;
  let nextRef = 1;
  let mutationCount = 0;
  try {
    new MutationObserver(() => { mutationCount += 1; })
      .observe(document.documentElement || document,
        { childList: true, subtree: true, attributes: true, characterData: true });
  } catch (e) { /* leave the counter at 0 rather than fail the install */ }

  const NAME_LIMIT = 100, VALUE_LIMIT = 50;
  const LANDMARKS = { header: 'banner', nav: 'navigation', main: 'main', footer: 'contentinfo',
    aside: 'complementary', form: 'form', section: 'region', article: 'article' };
  const TAGS = { a: 'link', button: 'button', select: 'combobox', textarea: 'textbox', option: 'option',
    img: 'img', table: 'table', thead: 'rowgroup', tbody: 'rowgroup', tfoot: 'rowgroup', tr: 'row',
    th: 'columnheader', td: 'cell', ul: 'list', ol: 'list', li: 'listitem', dialog: 'dialog',
    progress: 'progressbar', meter: 'meter', summary: 'button', details: 'group', iframe: 'iframe' };
  const INPUT_TYPES = { button: 'button', submit: 'button', reset: 'button', image: 'button',
    checkbox: 'checkbox', radio: 'radio', range: 'slider', number: 'spinbutton', search: 'searchbox',
    hidden: null };
  const VALID_ROLES = new Set(['alert','alertdialog','application','article','banner','button','cell',
    'checkbox','columnheader','combobox','complementary','contentinfo','dialog','document','feed','figure',
    'form','grid','gridcell','group','heading','img','link','list','listbox','listitem','main','menu',
    'menubar','menuitem','menuitemcheckbox','menuitemradio','navigation','option','progressbar','radio',
    'radiogroup','region','row','rowgroup','rowheader','scrollbar','search','searchbox','separator','slider',
    'spinbutton','status','switch','tab','table','tablist','tabpanel','textbox','timer','toolbar','tooltip',
    'tree','treegrid','treeitem','presentation','none']);
  const NAME_FROM_CONTENT = new Set(['button','link','heading','cell','columnheader','rowheader','option',
    'tab','menuitem','menuitemcheckbox','menuitemradio','treeitem','tooltip','gridcell','switch']);
  const INTERACTIVE = new Set(['button','link','textbox','searchbox','checkbox','radio','combobox','listbox',
    'option','slider','spinbutton','switch','tab','menuitem','menuitemcheckbox','menuitemradio','treeitem']);

  const collapse = (s) => (s || '').replace(/\s+/g, ' ').trim();
  const cut = (s, n) => (s.length > n ? s.slice(0, n) + '…' : s);

  function roleOf(el) {
    const explicit = collapse(el.getAttribute('role') || '').split(' ')[0];
    if (explicit && VALID_ROLES.has(explicit)) { return explicit === 'none' ? 'presentation' : explicit; }
    const tag = el.tagName.toLowerCase();
    if (tag === 'a') { return el.hasAttribute('href') ? 'link' : null; }
    if (tag === 'input') {
      const type = (el.getAttribute('type') || 'text').toLowerCase();
      if (type in INPUT_TYPES) { return INPUT_TYPES[type]; }
      return 'textbox';
    }
    if (/^h[1-6]$/.test(tag)) { return 'heading'; }
    if (tag in LANDMARKS) { return LANDMARKS[tag]; }
    if (tag in TAGS) { return TAGS[tag]; }
    if (el.isContentEditable && el.getAttribute('contenteditable') !== null) { return 'textbox'; }
    return null;
  }

  function isHiddenUncached(el) {
    const tag = el.tagName.toLowerCase();
    if (tag === 'script' || tag === 'style' || tag === 'noscript' || tag === 'template' || tag === 'head') { return true; }
    if (el.hidden || el.getAttribute('aria-hidden') === 'true') { return true; }
    if (tag === 'input' && (el.getAttribute('type') || '').toLowerCase() === 'hidden') { return true; }
    if (tag === 'img' && el.getAttribute('alt') === '') { return true; }
    const style = window.getComputedStyle(el);
    if (style.display === 'none' || style.visibility === 'hidden') { return true; }
    if (tag !== 'option' && el.children.length === 0) {
      const r = el.getBoundingClientRect();
      if (r.width === 0 && r.height === 0 && !collapse(el.textContent)) { return true; }
    }
    return false;
  }

  function labelText(el) {
    const ids = el.getAttribute('aria-labelledby');
    if (ids) {
      const parts = ids.split(/\s+/).map((id) => document.getElementById(id)).filter(Boolean)
        .map((n) => collapse(n.textContent));
      if (parts.join(' ').trim()) { return parts.join(' ').trim(); }
    }
    const label = el.getAttribute('aria-label');
    if (label && collapse(label)) { return collapse(label); }
    if (el.labels && el.labels.length) {
      const own = Array.from(el.labels).map((l) => {
        const clone = l.cloneNode(true);
        clone.querySelectorAll('input,select,textarea,button').forEach((c) => c.remove());
        return collapse(clone.textContent);
      }).filter(Boolean).join(' ');
      if (own) { return own; }
    }
    for (const attr of ['alt', 'title', 'placeholder']) {
      const v = el.getAttribute(attr);
      if (v && collapse(v)) { return collapse(v); }
    }
    return '';
  }

  function nameOf(el, role) {
    const fromAttributes = labelText(el);
    if (fromAttributes) { return { name: cut(fromAttributes, NAME_LIMIT), fromContent: false }; }
    if (role && NAME_FROM_CONTENT.has(role)) {
      const text = collapse(el.textContent);
      if (text) { return { name: cut(text, NAME_LIMIT), fromContent: true }; }
    }
    return { name: '', fromContent: false };
  }

  function isInteractive(el, role) {
    if (role && INTERACTIVE.has(role)) { return true; }
    const tag = el.tagName.toLowerCase();
    if (['input', 'select', 'textarea', 'button'].includes(tag)) { return true; }
    if (tag === 'a' && el.hasAttribute('href')) { return true; }
    if (el.isContentEditable) { return true; }
    if (el.hasAttribute('onclick')) { return true; }
    const tabindex = el.getAttribute('tabindex');
    return tabindex !== null && Number(tabindex) >= 0;
  }

  function statesOf(el, role) {
    const states = [];
    const aria = (n) => el.getAttribute(n);
    if (el.checked === true || aria('aria-checked') === 'true') { states.push('checked'); }
    if (el.disabled === true || aria('aria-disabled') === 'true') { states.push('disabled'); }
    if (aria('aria-expanded') === 'true' || (el.tagName.toLowerCase() === 'details' && el.open)) { states.push('expanded'); }
    if (el.selected === true || aria('aria-selected') === 'true') { states.push('selected'); }
    if (aria('aria-pressed') === 'true') { states.push('pressed'); }
    if (el.required === true || aria('aria-required') === 'true') { states.push('required'); }
    return states;
  }

  function valueOf(el, role) {
    const tag = el.tagName.toLowerCase();
    if (tag === 'input') {
      const type = (el.getAttribute('type') || 'text').toLowerCase();
      if (['password', 'checkbox', 'radio', 'button', 'submit', 'reset', 'image', 'file'].includes(type)) { return null; }
      return el.value ? cut(collapse(el.value), VALUE_LIMIT) : null;
    }
    if (tag === 'select' || tag === 'textarea') { return el.value ? cut(collapse(el.value), VALUE_LIMIT) : null; }
    if (role === 'slider' || role === 'spinbutton') {
      const v = el.getAttribute('aria-valuenow');
      return v ? cut(v, VALUE_LIMIT) : null;
    }
    return null;
  }

  function assignRef(el) {
    const ref = 'e' + (nextRef++);
    refs.set(ref, new WeakRef(el));
    el.__adkitchenRef = ref;
    return ref;
  }

  // Per-snapshot memos: each element's hidden state, role and "has a non-generic
  // descendant" answer are computed once, so deep div soup stays linear.
  const hiddenMemo = new Map(), roleMemo = new Map(), descendantMemo = new Map();

  function isHidden(el) {
    if (!hiddenMemo.has(el)) { hiddenMemo.set(el, isHiddenUncached(el)); }
    return hiddenMemo.get(el);
  }

  function roleMemoized(el) {
    if (!roleMemo.has(el)) { roleMemo.set(el, roleOf(el)); }
    return roleMemo.get(el);
  }

  function hasNonGenericDescendant(el) {
    if (descendantMemo.has(el)) { return descendantMemo.get(el); }
    let found = false;
    for (const child of el.children) {
      if (isHidden(child)) { continue; }
      const childRole = roleMemoized(child);
      if ((childRole !== null && childRole !== 'presentation') || isInteractive(child, null)
          || hasNonGenericDescendant(child)) { found = true; break; }
    }
    descendantMemo.set(el, found);
    return found;
  }

  // Returns an array of nodes (an element may collapse into its children).
  function build(el, depthLeft, opts) {
    if (isHidden(el)) { return []; }
    const tag = el.tagName.toLowerCase();
    let role = roleMemoized(el);
    if (role === 'presentation') { role = null; }
    const interactive = isInteractive(el, role);
    const generic = role === null && !interactive;

    if (generic) {
      if (!hasNonGenericDescendant(el)) {
        const text = collapse(el.textContent);
        return (text && !opts.interactiveOnly) ? [{ role: 'text', text: cut(text, NAME_LIMIT) }] : [];
      }
      return childrenOf(el, depthLeft, opts);
    }

    const node = { role: role || 'generic', states: statesOf(el, role), children: [] };
    const { name, fromContent } = nameOf(el, role);
    if (name) { node.name = name; }
    node.ref = assignRef(el);
    if (role === 'heading') {
      const m = /^h([1-6])$/.exec(tag);
      node.level = m ? Number(m[1]) : Number(el.getAttribute('aria-level') || 2);
    }
    if (role === 'link' && el.href) { node.url = el.href; }
    const value = valueOf(el, role);
    if (value !== null) { node.value = value; }

    if (tag === 'iframe') {
      let doc = null;
      try { doc = el.contentDocument; } catch (e) { doc = null; }
      if (doc && doc.body && depthLeft !== 0) { node.children = childrenOf(doc.body, depthLeft, opts); }
      return [node];
    }
    if (!fromContent && depthLeft !== 0) { node.children = childrenOf(el, depthLeft, opts); }
    if (opts.interactiveOnly && !interactive && node.children.length === 0) { return []; }
    return [node];
  }

  function childrenOf(el, depthLeft, opts) {
    const out = [];
    const next = depthLeft === null ? null : depthLeft - 1;
    if (next === -1) { return out; }
    for (const child of el.childNodes) {
      if (child.nodeType === Node.TEXT_NODE) {
        const text = collapse(child.textContent);
        if (text && !opts.interactiveOnly) { out.push({ role: 'text', text: cut(text, NAME_LIMIT) }); }
      } else if (child.nodeType === Node.ELEMENT_NODE) {
        out.push(...build(child, next, opts));
      }
    }
    return out;
  }

  function resolveScope(scope) {
    if (!scope) { return null; }
    const held = refs.get(scope);
    if (held) { return held.deref() || null; }
    try { return document.querySelector(scope); } catch (e) { return null; }
  }

  function snapshot(opts) {
    opts = opts || {};
    const scopeEl = resolveScope(opts.scope);   // resolved before refs reset
    generation += 1;
    refs.clear();
    hiddenMemo.clear(); roleMemo.clear(); descendantMemo.clear();
    nextRef = 1;
    const depth = (typeof opts.depth === 'number' && opts.depth > 0) ? opts.depth : null;
    const options = { interactiveOnly: !!opts.interactiveOnly };
    let root;
    if (scopeEl) {
      const built = build(scopeEl, depth, options);
      root = built.length === 1 && built[0].role !== 'text' ? built[0]
        : { role: 'document', name: document.title || '', states: [], children: built };
    } else {
      root = { role: 'document', states: [], children: document.body ? childrenOf(document.body, depth, options) : [] };
      if (document.title) { root.name = cut(collapse(document.title), NAME_LIMIT); }
    }
    return { url: location.href, title: document.title || '', generation: generation, root: root };
  }

  // Elements visible in the last snapshot whose name or text contains `text` (case-insensitive).
  function find(text) {
    const needle = collapse(text).toLowerCase();
    const out = [];
    for (const [ref, held] of refs) {
      const el = held.deref();
      if (!el || !el.isConnected) { continue; }
      const role = roleOf(el) || 'generic';
      const { name } = nameOf(el, role);
      // Own accessible name plus own direct text nodes only: containers must not
      // match on their descendants' text.
      const own = Array.from(el.childNodes).filter((n) => n.nodeType === Node.TEXT_NODE)
        .map((n) => n.textContent).join(' ');
      const hay = (name + ' ' + collapse(own)).toLowerCase();
      if (needle && hay.includes(needle)) { out.push({ ref: ref, role: role, name: name }); }
    }
    return out;
  }

  function text(scope) {
    const el = resolveScope(scope) || document.querySelector('main') || document.body;
    return el ? el.innerText : '';
  }

  function resolve(ref, gen) {
    if (gen !== generation) { return { error: 'stale' }; }
    const held = refs.get(ref);
    if (!held) { return { error: 'unknown' }; }
    const el = held.deref();
    if (!el || !el.isConnected) { return { error: 'stale' }; }
    return { el: el };
  }

  function focusedLandmark() {
    let el = document.activeElement;
    while (el && el !== document.body) {
      const role = roleOf(el);
      if (role === 'form' || (role && Object.values(LANDMARKS).includes(role)) || el.tagName.toLowerCase() === 'dialog') {
        return el.__adkitchenRef || null;
      }
      el = el.parentElement;
    }
    return null;
  }

  window.__adkitchen = {
    version: 1,
    snapshot: snapshot,
    find: find,
    text: text,
    mutations: () => mutationCount,
    focusedLandmark: focusedLandmark,
    resolve: resolve,
    generation: () => generation,
  };
})();
