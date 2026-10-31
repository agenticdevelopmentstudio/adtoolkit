import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import { render, act } from '@testing-library/react'
import { createRef, createElement } from 'react'
import type { CSSProperties } from 'react'
import { CHAT_INSIDE_ATTR, useChatSizing, type ChatEngagement } from '../hooks/useChatSizing'
import type { InlineChatSizing } from '../modes/InlineChat'

// jsdom doesn't lay anything out, so getBoundingClientRect returns zeros.
// Stub the prototype so the hook's chatBottom / anchorBottom math is meaningful.
const ORIGINAL_GBCR = Element.prototype.getBoundingClientRect
const rectsByElement = new WeakMap<Element, DOMRect>()

function setRect(el: Element, rect: Partial<DOMRect>) {
  rectsByElement.set(el, {
    x: 0, y: 0, width: 0, height: 0, top: 0, left: 0, right: 0, bottom: 0,
    toJSON: () => ({}),
    ...rect,
  } as DOMRect)
}

beforeEach(() => {
  Element.prototype.getBoundingClientRect = function () {
    return rectsByElement.get(this) ?? { x: 0, y: 0, width: 0, height: 0, top: 0, left: 0, right: 0, bottom: 0, toJSON: () => ({}) } as DOMRect
  }
  Object.defineProperty(window, 'innerHeight', { configurable: true, value: 800 })
})

afterEach(() => {
  Element.prototype.getBoundingClientRect = ORIGINAL_GBCR
})

interface ProbeApi {
  style: CSSProperties
  className: string
  collapsed: boolean
  engaged: boolean
  el: HTMLDivElement | null
}

interface EngagementProbe extends ProbeApi {
  /** Renders again with new engagement options — the host re-rendering its chat. */
  rerender: (engagement: ChatEngagement) => void
}

/**
 * Renders a component using the hook with a controlled chat-element rect.
 * Returns the latest hook output (after the layoutEffect fires) and the
 * resolved ref element. Tests assert against `api.style.maxHeight` etc.
 */
function renderProbe(
  sizing: InlineChatSizing | undefined,
  chatRect: Partial<DOMRect>,
  engagement?: ChatEngagement,
): EngagementProbe {
  const api: EngagementProbe = {
    style: {},
    className: '',
    collapsed: false,
    engaged: false,
    el: null,
    rerender: () => {},
  }

  function Probe({ engagement }: { engagement?: ChatEngagement }) {
    const { ref, style, className, collapsed, engaged } = useChatSizing(sizing, engagement)
    api.style = style
    api.className = className
    api.collapsed = collapsed
    api.engaged = engaged
    return createElement('div', {
      ref: (el: HTMLDivElement | null) => {
        ref.current = el
        api.el = el
        if (el) setRect(el, chatRect)
      },
    })
  }

  const { rerender } = render(createElement(Probe, { engagement }))
  api.rerender = (next) => rerender(createElement(Probe, { engagement: next }))
  return api
}

describe('useChatSizing — content-hugging math', () => {
  it('returns empty style when sizing is undefined (defaults to fixed)', () => {
    const api = renderProbe(undefined, { bottom: 700 })
    expect(api.style).toEqual({})
  })

  it('returns empty style when the active behavior is fixed', () => {
    const api = renderProbe({ active: { mode: 'fixed' } }, { bottom: 700 })
    expect(api.style).toEqual({})
    expect(api.el?.classList.contains('pc-hugging')).toBe(false)
  })

  it('resolves css length: px', () => {
    const api = renderProbe(
      { active: { mode: 'content-hugging', maxHeight: { kind: 'css', value: '400px' } } },
      { bottom: 700 },
    )
    expect(api.style.maxHeight).toBe('400px')
  })

  it('resolves css length: vh', () => {
    const api = renderProbe(
      { active: { mode: 'content-hugging', maxHeight: { kind: 'css', value: '60vh' } } },
      { bottom: 700 },
    )
    // 60% of innerHeight=800 = 480
    expect(api.style.maxHeight).toBe('480px')
  })

  it('resolves viewport-offset: chatBottom - topOffsetPx', () => {
    const api = renderProbe(
      { active: { mode: 'content-hugging', maxHeight: { kind: 'viewport-offset', topOffsetPx: 80 } } },
      { bottom: 780 },
    )
    expect(api.style.maxHeight).toBe('700px')
  })

  it('keeps its viewport-offset cap when the page scrolls the chat away', () => {
    const api = renderProbe(
      { active: { mode: 'content-hugging', maxHeight: { kind: 'viewport-offset', topOffsetPx: 80 } } },
      { bottom: 780 },
    )
    act(() => {
      setRect(api.el!, { bottom: 125 })
      window.dispatchEvent(new Event('scroll'))
    })
    expect(api.style.maxHeight).toBe('700px')
  })

  it('resolves element-offset: chatBottom - (anchorBottom + gapPx)', () => {
    const anchor = document.createElement('div')
    document.body.appendChild(anchor)
    setRect(anchor, { bottom: 120 })
    const ref = createRef<HTMLElement>()
    // @ts-expect-error – test-only direct ref assignment
    ref.current = anchor

    const api = renderProbe(
      { active: { mode: 'content-hugging', maxHeight: { kind: 'element-offset', ref, gapPx: 40 } } },
      { bottom: 780 },
    )
    // 780 - (120 + 40) = 620
    expect(api.style.maxHeight).toBe('620px')
  })

  it('element-offset: gapPx defaults to 0', () => {
    const anchor = document.createElement('div')
    document.body.appendChild(anchor)
    setRect(anchor, { bottom: 100 })
    const ref = createRef<HTMLElement>()
    // @ts-expect-error – test-only direct ref assignment
    ref.current = anchor

    const api = renderProbe(
      { active: { mode: 'content-hugging', maxHeight: { kind: 'element-offset', ref } } },
      { bottom: 780 },
    )
    expect(api.style.maxHeight).toBe('680px')
  })

  it('element-offset: null anchor falls back to chatBottom', () => {
    const ref = createRef<HTMLElement>() // .current stays null
    const api = renderProbe(
      { active: { mode: 'content-hugging', maxHeight: { kind: 'element-offset', ref, gapPx: 0 } } },
      { bottom: 500 },
    )
    expect(api.style.maxHeight).toBe('500px')
  })

  it('clamps negative results to 0', () => {
    const api = renderProbe(
      { active: { mode: 'content-hugging', maxHeight: { kind: 'viewport-offset', topOffsetPx: 1000 } } },
      { bottom: 200 },
    )
    // 200 - 1000 = -800 → clamped to 0
    expect(api.style.maxHeight).toBe('0px')
  })

  it('adds and removes the hugging class on the chat element and its parent', () => {
    const api: ProbeApi = { style: {}, className: '', collapsed: false, engaged: false, el: null }
    const refs: { parent: HTMLDivElement | null; chat: HTMLDivElement | null } = {
      parent: null,
      chat: null,
    }

    function Probe() {
      const { ref, style } = useChatSizing({
        active: { mode: 'content-hugging', maxHeight: { kind: 'css', value: '300px' } },
      })
      api.style = style
      return createElement(
        'div',
        {
          className: 'pc-inline',
          ref: (el: HTMLDivElement | null) => { if (el) refs.parent = el },
        },
        createElement('div', {
          ref: (el: HTMLDivElement | null) => {
            ref.current = el
            api.el = el
            if (el) {
              refs.chat = el
              setRect(el, { bottom: 700 })
            }
          },
        }),
      )
    }

    const { unmount } = render(createElement(Probe))
    expect(refs.chat?.classList.contains('pc-hugging')).toBe(true)
    expect(refs.parent?.classList.contains('pc-hugging')).toBe(true)

    unmount()
    expect(refs.parent?.classList.contains('pc-hugging')).toBe(false)
  })

  it('recomputes on window resize', () => {
    const api = renderProbe(
      { active: { mode: 'content-hugging', maxHeight: { kind: 'css', value: '50vh' } } },
      { bottom: 700 },
    )
    expect(api.style.maxHeight).toBe('400px') // 50% of 800

    act(() => {
      Object.defineProperty(window, 'innerHeight', { configurable: true, value: 1000 })
      window.dispatchEvent(new Event('resize'))
    })
    expect(api.style.maxHeight).toBe('500px') // 50% of 1000
  })
})

describe('useChatSizing — engagement & minimal', () => {
  it('is static when no inactive behavior is set (no engagement classes)', () => {
    const api = renderProbe(
      { active: { mode: 'content-hugging', maxHeight: { kind: 'css', value: '300px' } } },
      { bottom: 700 },
    )
    expect(api.collapsed).toBe(false)
    expect(api.className).not.toContain('pc-anim')
    expect(api.className).not.toContain('pc-collapsed')
  })

  it('starts collapsed with minimal inactive and animated transition', () => {
    const api = renderProbe(
      { active: { mode: 'content-hugging', maxHeight: { kind: 'css', value: '300px' } }, inactive: { mode: 'minimal' } },
      { bottom: 700 },
    )
    expect(api.collapsed).toBe(true)
    expect(api.className).toContain('pc-collapsed')
    expect(api.className).toContain('pc-anim') // animated is the default
    // collapsed (minimal) carries no maxHeight cap — the transcript collapses via CSS
    expect(api.style).toEqual({})
  })

  it('omits pc-anim when transition is none', () => {
    const api = renderProbe(
      { active: { mode: 'fixed' }, inactive: { mode: 'minimal' }, transition: 'none' },
      { bottom: 700 },
    )
    expect(api.className).toContain('pc-collapsed')
    expect(api.className).not.toContain('pc-anim')
  })

  it('expands on focusin and collapses again on Escape', () => {
    const api = renderProbe(
      { active: { mode: 'content-hugging', maxHeight: { kind: 'css', value: '300px' } }, inactive: { mode: 'minimal' } },
      { bottom: 700 },
    )
    expect(api.collapsed).toBe(true)

    act(() => {
      api.el?.dispatchEvent(new Event('focusin', { bubbles: true }))
    })
    expect(api.engaged).toBe(true)
    expect(api.collapsed).toBe(false)
    expect(api.className).not.toContain('pc-collapsed')
    // active behavior is content-hugging → its cap is applied while engaged
    expect(api.style.maxHeight).toBe('300px')

    act(() => {
      document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape' }))
    })
    expect(api.engaged).toBe(false)
    expect(api.collapsed).toBe(true)
  })

  it('collapses when a pointerdown lands outside the chat', () => {
    const api = renderProbe(
      { active: { mode: 'fixed' }, inactive: { mode: 'minimal' } },
      { bottom: 700 },
    )

    act(() => {
      api.el?.dispatchEvent(new Event('focusin', { bubbles: true }))
    })
    expect(api.collapsed).toBe(false)

    act(() => {
      document.body.dispatchEvent(new MouseEvent('pointerdown', { bubbles: true }))
    })
    expect(api.collapsed).toBe(true)
  })
})

describe('useChatSizing — a host observing and controlling engagement', () => {
  const MINIMAL: InlineChatSizing = { active: { mode: 'fixed' }, inactive: { mode: 'minimal' } }
  const focusIn = (api: ProbeApi) => api.el?.dispatchEvent(new Event('focusin', { bubbles: true }))
  const pressOn = (el: Element | null | undefined) =>
    el?.dispatchEvent(new MouseEvent('pointerdown', { bubbles: true }))

  it('reports each flip once, from the gesture — one tap in is pointerdown AND focusin', () => {
    const onEngagedChange = vi.fn()
    const api = renderProbe(MINIMAL, { bottom: 700 }, { onEngagedChange })
    // Mounting folded is not a flip.
    expect(onEngagedChange).not.toHaveBeenCalled()

    // Both land before React re-renders, so only the recorded value can dedupe them.
    act(() => {
      pressOn(api.el)
      focusIn(api)
    })
    expect(onEngagedChange.mock.calls).toEqual([[true]])

    act(() => {
      pressOn(document.body)
    })
    expect(onEngagedChange.mock.calls).toEqual([[true], [false]])

    // Already folded: Escape changes nothing, so it reports nothing.
    act(() => {
      document.body.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }))
    })
    expect(onEngagedChange.mock.calls).toEqual([[true], [false]])
  })

  it('reports nothing when no inactive behavior turns tracking on', () => {
    const onEngagedChange = vi.fn()
    const api = renderProbe({ active: { mode: 'fixed' } }, { bottom: 700 }, { onEngagedChange })
    act(() => {
      focusIn(api)
    })
    expect(onEngagedChange).not.toHaveBeenCalled()
  })

  it('takes a controlled `engaged` as the state — so a host can fold a chat it hid itself', () => {
    const onEngagedChange = vi.fn()
    const api = renderProbe(MINIMAL, { bottom: 700 }, { engaged: false, onEngagedChange })

    // The gesture is reported, but the host has not followed it: still folded.
    act(() => {
      focusIn(api)
    })
    expect(onEngagedChange.mock.calls).toEqual([[true]])
    expect(api.collapsed).toBe(true)

    act(() => {
      api.rerender({ engaged: true, onEngagedChange })
    })
    expect(api.collapsed).toBe(false)

    // The host folds it with no gesture at all (it hid the chat), and is not told
    // back about its own decision.
    act(() => {
      api.rerender({ engaged: false, onEngagedChange })
    })
    expect(api.collapsed).toBe(true)
    expect(api.engaged).toBe(false)
    expect(onEngagedChange.mock.calls).toEqual([[true]])

    // Folded by the host, a fresh focus is a real flip again.
    act(() => {
      focusIn(api)
    })
    expect(onEngagedChange.mock.calls).toEqual([[true], [true]])
  })

  it('leaves engagement as it was on a press on a control marked CHAT_INSIDE_ATTR', () => {
    const control = document.createElement('div')
    control.setAttribute(CHAT_INSIDE_ATTR, '')
    const glyph = document.createElement('span')
    control.appendChild(glyph)
    document.body.appendChild(control)
    const api = renderProbe(MINIMAL, { bottom: 700 })

    // Folded, a press on it does not unfold the box under whatever it opens.
    act(() => {
      pressOn(glyph)
    })
    expect(api.collapsed).toBe(true)

    act(() => {
      focusIn(api)
    })
    expect(api.collapsed).toBe(false)

    // Engaged, a press on it (on a child: the mark is found by `closest`) is not a
    // tap away.
    act(() => {
      pressOn(glyph)
    })
    expect(api.collapsed).toBe(false)

    // A press anywhere unmarked still is.
    act(() => {
      pressOn(document.body)
    })
    expect(api.collapsed).toBe(true)
    control.remove()
  })

  it('does not fold on an Escape something else already consumed', () => {
    const api = renderProbe(MINIMAL, { bottom: 700 })
    act(() => {
      focusIn(api)
    })
    expect(api.collapsed).toBe(false)

    // A popover beside the chat closing on the key: one press, one layer.
    const consumed = new KeyboardEvent('keydown', { key: 'Escape', bubbles: true, cancelable: true })
    consumed.preventDefault()
    act(() => {
      document.body.dispatchEvent(consumed)
    })
    expect(api.collapsed).toBe(false)

    // The next Escape is the chat's.
    act(() => {
      document.body.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true, cancelable: true }))
    })
    expect(api.collapsed).toBe(true)
  })
})
