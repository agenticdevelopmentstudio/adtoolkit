// BrowserSnapshot.js — the page-world runtime behind BrowserAutomation.
// Installed once per document (version-checked); every call returns plain JSON.
(function () {
  if (window.__adkitchen && window.__adkitchen.version === 1) { return; }

  const refs = new Map();            // ref -> WeakRef<Element>
  window.__adkitchenRefs = refs;
  // A random six-digit base chosen once per document, advanced by one per
  // snapshot: short enough for a model to copy back without a slip, and
  // unlikely to repeat another document's (ref, generation) numbers.
  let generation = 100000 + Math.floor(Math.random() * 900000);
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
      // aria-level is only a level when it is a whole number from 1 up; "1.5",
      // "x" and "" would otherwise reach the Swift decoder as NaN or a fraction.
      const aria = Number(el.getAttribute('aria-level'));
      node.level = m ? Number(m[1]) : (Number.isInteger(aria) && aria >= 1 ? aria : 2);
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
        const ref = el.__adkitchenRef;
        const held = ref ? refs.get(ref) : null;
        return (held && held.deref() === el) ? ref : null;
      }
      el = el.parentElement;
    }
    return null;
  }

  function withElement(ref, gen, fn) {
    const r = resolve(ref, gen);
    if (r.error) { return { error: r.error }; }
    try { return { ok: fn(r.el) }; } catch (e) { return { error: 'script: ' + (e && e.message ? e.message : String(e)) }; }
  }

  function centre(el) {
    const r = el.getBoundingClientRect();
    return { x: r.left + r.width / 2, y: r.top + r.height / 2 };
  }

  function mouse(el, type, extra) {
    const c = centre(el);
    const init = Object.assign({ bubbles: true, cancelable: true, composed: true, clientX: c.x, clientY: c.y, view: window }, extra || {});
    el.dispatchEvent(new MouseEvent(type, init));
  }

  function click(ref, gen) {
    return withElement(ref, gen, (el) => {
      el.scrollIntoView({ block: 'center', inline: 'center' });
      if (el.tagName.toLowerCase() === 'option') {
        const select = el.closest('select');
        if (select) { select.value = el.value; select.dispatchEvent(new Event('input', { bubbles: true })); select.dispatchEvent(new Event('change', { bubbles: true })); }
        return true;
      }
      if (el.tagName.toLowerCase() === 'a' && el.getAttribute('target') === '_blank') { el.removeAttribute('target'); }
      mouse(el, 'pointerdown'); mouse(el, 'mousedown');
      if (typeof el.focus === 'function') { el.focus(); }
      mouse(el, 'pointerup'); mouse(el, 'mouseup');
      el.click();
      return true;
    });
  }

  const KEY_CODES = { Enter: 13, Escape: 27, Tab: 9, Backspace: 8, Delete: 46, ArrowUp: 38, ArrowDown: 40, ArrowLeft: 37, ArrowRight: 39, Home: 36, End: 35, PageUp: 33, PageDown: 34, ' ': 32 };

  function keyInit(key, mods) {
    const code = key.length === 1 ? ('Key' + key.toUpperCase()) : key;
    return { key: key, code: code, keyCode: KEY_CODES[key] || (key.length === 1 ? key.toUpperCase().charCodeAt(0) : 0),
      bubbles: true, cancelable: true, composed: true,
      metaKey: !!mods.meta, shiftKey: !!mods.shift, altKey: !!mods.alt, ctrlKey: !!mods.control };
  }

  function sendKey(target, key, mods) {
    const down = new KeyboardEvent('keydown', keyInit(key, mods));
    const prevented = !target.dispatchEvent(down);
    if (!prevented && key.length === 1 && !mods.meta && !mods.control) {
      target.dispatchEvent(new KeyboardEvent('keypress', keyInit(key, mods)));
      if ('value' in target && !target.readOnly) {
        // The prototype setter, not the instance one: React's value tracker
        // overrides the instance setter and drops the following input event
        // when the value it tracked already matches.
        setNativeValue(target, target.value + key);
        target.dispatchEvent(new InputEvent('input', { bubbles: true, data: key, inputType: 'insertText' }));
      } else if (target.isContentEditable) {
        document.execCommand('insertText', false, key);
      }
    }
    target.dispatchEvent(new KeyboardEvent('keyup', keyInit(key, mods)));
    return !prevented;
  }

  function type(ref, gen, text, submit) {
    return withElement(ref, gen, (el) => {
      el.focus();
      for (const ch of String(text)) { sendKey(el, ch, {}); }
      if (submit) {
        if (sendKey(el, 'Enter', {}) && el.form && typeof el.form.requestSubmit === 'function') { el.form.requestSubmit(); }
      }
      return true;
    });
  }

  // Writes `value` through the element's prototype setter, past any setter a
  // framework installed on the instance itself. Walks the prototype chain
  // rather than naming HTMLInputElement, so an element with a `value` of
  // another kind (output, li, a custom element) gets its own setter.
  function setNativeValue(el, value) {
    for (let proto = Object.getPrototypeOf(el); proto; proto = Object.getPrototypeOf(proto)) {
      const descriptor = Object.getOwnPropertyDescriptor(proto, 'value');
      if (descriptor && descriptor.set) { descriptor.set.call(el, value); return; }
    }
    el.value = value;
  }

  function fill(ref, gen, value) {
    return withElement(ref, gen, (el) => {
      el.focus();
      if (el.isContentEditable && !('value' in el)) {
        document.execCommand('selectAll', false, null);
        document.execCommand('insertText', false, String(value));
        return true;
      }
      if (typeof el.select === 'function') { el.select(); }
      setNativeValue(el, String(value));
      el.dispatchEvent(new InputEvent('input', { bubbles: true, data: String(value), inputType: 'insertReplacementText' }));
      el.dispatchEvent(new Event('change', { bubbles: true }));
      return true;
    });
  }

  function select(ref, gen, value) {
    return withElement(ref, gen, (el) => {
      const wanted = String(value);
      const options = Array.from(el.options || []);
      const match = options.find((o) => o.value === wanted) || options.find((o) => collapse(o.textContent) === wanted);
      if (!match) { throw new Error('no option "' + wanted + '"'); }
      setNativeValue(el, match.value);
      el.dispatchEvent(new Event('input', { bubbles: true }));
      el.dispatchEvent(new Event('change', { bubbles: true }));
      return true;
    });
  }

  function hover(ref, gen) {
    return withElement(ref, gen, (el) => {
      el.scrollIntoView({ block: 'center', inline: 'center' });
      for (const t of ['pointerover', 'mouseover', 'mouseenter', 'pointermove', 'mousemove']) {
        mouse(el, t, t.endsWith('enter') ? { bubbles: false } : {});
      }
      return true;
    });
  }

  // "Meta+Shift+ArrowDown", "Enter", "a"
  function pressKey(spec) {
    const parts = String(spec).split('+');
    const key = parts.pop();
    const mods = {};
    for (const p of parts) { mods[p.toLowerCase()] = true; }
    const target = document.activeElement || document.body;
    try { return { ok: sendKey(target, key === 'Space' ? ' ' : key, mods) }; }
    catch (e) { return { error: 'script: ' + e.message }; }
  }

  function scroll(ref, gen, direction, amount) {
    if (ref) { return withElement(ref, gen, (el) => { el.scrollIntoView({ block: 'center', inline: 'center' }); return true; }); }
    const px = typeof amount === 'number' ? amount : window.innerHeight * 0.8;
    const dx = direction === 'left' ? -px : direction === 'right' ? px : 0;
    const dy = direction === 'up' ? -px : direction === 'left' || direction === 'right' ? 0 : px;
    window.scrollBy(dx, dy);
    return { ok: true };
  }

  function rect(ref, gen) {
    return withElement(ref, gen, (el) => {
      el.scrollIntoView({ block: 'center', inline: 'center' });
      const r = el.getBoundingClientRect();
      return { x: r.left, y: r.top, width: r.width, height: r.height };
    });
  }

  function isVisible(ref, gen) {
    const r = resolve(ref, gen);
    if (r.error) { return false; }
    return !isHiddenUncached(r.el);   // never the snapshot memo: the page may have changed since
  }

  function hasText(needle) {
    return (document.body ? document.body.innerText : '').includes(needle);
  }

  function landmarkSnapshot(ref, depth) {
    const held = refs.get(ref);
    const el = held ? held.deref() : null;
    if (!el || !el.isConnected) { return null; }
    hiddenMemo.clear(); roleMemo.clear(); descendantMemo.clear();
    const built = build(el, depth, { interactiveOnly: false });
    return built.length ? built[0] : null;
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
    click: click, type: type, fill: fill, select: select, hover: hover, pressKey: pressKey,
    scroll: scroll, rect: rect, isVisible: isVisible, hasText: hasText,
    landmarkSnapshot: landmarkSnapshot,
  };
})();
