import {
  useEffect,
  useLayoutEffect,
  useRef,
  useState,
  type CSSProperties,
  type RefObject,
} from 'react'
import type { InlineChatSizing, InactiveSizingBehavior } from '../modes/InlineChat'

const HUGGING_CLASS = 'pc-hugging'
const DEFAULT_SIZING: InlineChatSizing = { active: { mode: 'fixed' } }

/**
 * Marks an element OUTSIDE the chat's box as part of the conversation anyway: a
 * press on it is not a tap away, so the chat's engagement stays exactly as it was.
 * Spread it as `{ [CHAT_INSIDE_ATTR]: '' }` on a control a host parks beside the
 * chat. bitbag's dock is why it exists: its `i` sits on the chat's corner, and a
 * press on it read as a tap away, so the chat folded and the dock — which closes on
 * that fold — hid the `i` before its click could land. It is deliberately NOT a tap
 * IN either: the press is for the control, and unfolding the box under a panel the
 * control just opened would bury the panel.
 */
export const CHAT_INSIDE_ATTR = 'data-pc-inside'

/**
 * Who owns engagement. Left out, the hook owns it outright. A host that has to act
 * on it hears each flip through `onEngagedChange`; a host that has to END it passes
 * `engaged` and takes the fact over, the way a controlled input takes over `value`.
 */
export interface ChatEngagement {
  /**
   * When set, this IS the engaged state, and the hook's own tracking only reports
   * what the gestures said through `onEngagedChange`. A host needs it to fold a
   * chat it hid itself: tracking alone left a hidden chat engaged — holding the
   * host's engaged-only CSS (a scrim, a raised z-index) over the page — until the
   * next tap or Escape happened to land.
   */
  engaged?: boolean
  /**
   * Hears each flip, called from the gesture that caused it (focus in, a tap in or
   * away, Escape) — never from a render or an effect — and only on a real change.
   * The typed alternative to reading `.pc-collapsed` back off the DOM, which a
   * class rename breaks silently.
   */
  onEngagedChange?: (engaged: boolean) => void
}

export interface ChatSizing {
  ref: RefObject<HTMLDivElement | null>
  style: CSSProperties
  /**
   * True while the user is interacting (focused or just clicked in) — or, when the
   * host passes `engaged`, whatever it says.
   */
  engaged: boolean
  /** True when showing the inactive `minimal` state (input bar only). */
  collapsed: boolean
  /** State/transition class names for the chat root (`pc-anim`, `pc-collapsed`). */
  className: string
}

/**
 * Drives the inline chat's size from its active/inactive sizing behaviors.
 *
 * Reuses the bottom-anchored, content-hugging mechanism (the box hugs its
 * content so growth extends the top edge upward). When an `inactive` behavior
 * is configured, it also tracks engagement — focus expands to the active
 * size, clicking away or pressing Escape collapses to the inactive size — and
 * exposes class hooks so CSS can animate the grow-up / grow-down. A press on an
 * element marked with `CHAT_INSIDE_ATTR` is not a click away, and an Escape that
 * something else already consumed (`defaultPrevented`) does not collapse: see
 * `onKeyDown` below. `engagement` lets a host observe or control the state.
 */
export function useChatSizing(
  sizing: InlineChatSizing | undefined,
  engagement: ChatEngagement = {},
): ChatSizing {
  const { active, inactive, transition = 'animated' } = sizing ?? DEFAULT_SIZING
  const { engaged: engagedProp, onEngagedChange } = engagement

  const ref = useRef<HTMLDivElement | null>(null)
  const [maxHeightPx, setMaxHeightPx] = useState<number | null>(null)
  const [ownEngaged, setOwnEngaged] = useState(false)
  // Controlled when the host passes `engaged`: its value is the fact, and our own
  // state is only what the gestures last said.
  const engaged = engagedProp ?? ownEngaged

  // The listeners below live as long as the chat does, so they read the CURRENT
  // engaged value and callback through a ref instead of re-subscribing on every
  // flip — the same latest-value idiom as `usePersonaGaze`.
  const latest = useRef({ engaged, onEngagedChange })
  latest.current = { engaged, onEngagedChange }

  // Engagement only matters when an inactive behavior is configured; otherwise
  // the box is static and behaves exactly as it did before this option existed.
  const tracksEngagement = inactive !== undefined

  useEffect(() => {
    if (!tracksEngagement) return
    if (typeof document === 'undefined') return
    const el = ref.current
    if (!el) return

    // Only a real flip is reported, and it is recorded at once: a tap in fires
    // pointerdown AND focusin before React re-renders, and the host must hear
    // "engaged" once, not twice.
    const report = (next: boolean): void => {
      if (next === latest.current.engaged) return
      latest.current.engaged = next
      setOwnEngaged(next)
      latest.current.onEngagedChange?.(next)
    }
    const engage = () => report(true)
    const onPointerDown = (e: Event) => {
      if (el.contains(e.target as Node)) report(true)
      // A press on a control the host marked as part of the conversation leaves
      // engagement as it was — see CHAT_INSIDE_ATTR.
      else if (!(e.target instanceof Element && e.target.closest(`[${CHAT_INSIDE_ATTR}]`))) {
        report(false)
      }
    }
    const onKeyDown = (e: KeyboardEvent) => {
      // An Escape something else already consumed was THAT layer's — a popover
      // beside the chat closing on it (bitbag's `i` panel, which consumes it from
      // a capture listener so it gets there first). Folding as well spent one
      // press on two layers, and a host that closes on the fold lost its panel
      // AND its chat to a key meant only for the panel.
      if (e.key === 'Escape' && !e.defaultPrevented) report(false)
    }

    el.addEventListener('focusin', engage)
    document.addEventListener('pointerdown', onPointerDown)
    document.addEventListener('keydown', onKeyDown)
    return () => {
      el.removeEventListener('focusin', engage)
      document.removeEventListener('pointerdown', onPointerDown)
      document.removeEventListener('keydown', onKeyDown)
    }
  }, [tracksEngagement])

  // The behavior in effect for the current engagement state.
  const behavior: InactiveSizingBehavior = engaged ? active : (inactive ?? active)
  const isHugging = behavior.mode === 'content-hugging'
  const isMinimal = behavior.mode === 'minimal'
  // Both content-hugging and minimal release the wrapper's fixed height so the
  // bottom-anchored box hugs its content (minimal hugs just the input bar,
  // because the transcript is collapsed by CSS).
  const releaseHeight = isHugging || isMinimal

  useLayoutEffect(() => {
    if (!releaseHeight) return
    if (typeof window === 'undefined' || typeof ResizeObserver === 'undefined') return
    const el = ref.current
    if (!el) return

    el.classList.add(HUGGING_CLASS)
    const parent = el.parentElement
    parent?.classList.add(HUGGING_CLASS)

    const releaseOnly = () => {
      el.classList.remove(HUGGING_CLASS)
      parent?.classList.remove(HUGGING_CLASS)
    }

    // `minimal` has no cap to compute — the transcript is collapsed by CSS, so
    // the box already hugs the input bar.
    if (behavior.mode !== 'content-hugging') {
      setMaxHeightPx(null)
      return releaseOnly
    }

    const cap = behavior.maxHeight
    const recompute = () => {
      const chatBottom = el.getBoundingClientRect().bottom
      if (cap.kind === 'css') {
        setMaxHeightPx(parseCssLength(cap.value, window.innerHeight))
        return
      }
      if (cap.kind === 'viewport-offset') {
        setMaxHeightPx(Math.max(0, chatBottom - cap.topOffsetPx))
        return
      }
      const anchor = cap.ref.current
      if (!anchor) {
        setMaxHeightPx(Math.max(0, chatBottom))
        return
      }
      const anchorBottom = anchor.getBoundingClientRect().bottom
      setMaxHeightPx(Math.max(0, chatBottom - (anchorBottom + (cap.gapPx ?? 0))))
    }

    const ro = new ResizeObserver(recompute)
    ro.observe(el)

    let anchorRo: ResizeObserver | null = null
    if (cap.kind === 'element-offset' && cap.ref.current) {
      anchorRo = new ResizeObserver(recompute)
      anchorRo.observe(cap.ref.current)
    }

    // No window `scroll` listener, deliberately. A fixed chat does not move when the page
    // scrolls, so it never needed one; a chat in the page's flow does, and capping it by
    // where scrolling had carried it crushed it: scrolled down to help's footer, the chat
    // was a 45px sliver, and each cap moved the page, which moved the scroll, which moved
    // the cap, so the page shook by a pixel on every frame.
    window.addEventListener('resize', recompute)

    // visualViewport reflects the iOS soft-keyboard height; window.resize
    // does not. Without these listeners, content-hugging maxHeight is stale
    // while the keyboard is open.
    const vv = window.visualViewport
    vv?.addEventListener('resize', recompute)
    vv?.addEventListener('scroll', recompute)

    recompute()

    return () => {
      ro.disconnect()
      anchorRo?.disconnect()
      window.removeEventListener('resize', recompute)
      vv?.removeEventListener('resize', recompute)
      vv?.removeEventListener('scroll', recompute)
      releaseOnly()
    }
  }, [releaseHeight, behavior])

  const classes: string[] = []
  if (transition === 'animated' && tracksEngagement) classes.push('pc-anim')
  if (isMinimal) classes.push('pc-collapsed')

  return {
    ref,
    style: isHugging && maxHeightPx != null ? { maxHeight: `${maxHeightPx}px` } : {},
    engaged,
    collapsed: isMinimal,
    className: classes.join(' '),
  }
}

function parseCssLength(value: string, viewportHeight: number): number {
  const trimmed = value.trim()
  const match = trimmed.match(/^(-?\d*\.?\d+)\s*(px|vh)?$/i)
  if (!match || match[1] === undefined) return 0
  const num = parseFloat(match[1])
  const unit = (match[2] ?? 'px').toLowerCase()
  if (unit === 'vh') return (num / 100) * viewportHeight
  return num
}
