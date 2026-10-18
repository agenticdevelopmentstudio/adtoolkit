import type { ReactElement } from 'react'
import {
  BROW_LEFT,
  BROW_OPACITY,
  BROW_RIGHT,
  BROW_WIDTH,
  EYE_BG,
  EYE_COUNTER_R,
  EYE_LEFT_X,
  EYE_RIGHT_X,
  EYE_RING_R,
  EYE_Y,
  IRIS,
  IRIS_BASE_R,
  STEM_LEFT,
  STEM_RIGHT,
  STEM_WIDTH,
} from './avatar/geometry'

export interface BitbagMarkProps {
  /** Classes on the `<svg>`. Default `'bb-mark'`. */
  className?: string
}

/**
 * bitbag's likeness, still: two lowercase `b`s whose bowls are his eyes, under a
 * raised brow. The same letterform the live rig draws (both read
 * `avatar/geometry.ts`), minus the gsap blink/glance rig — so a host can show
 * him where nothing should animate, or stand him in while the rig's chunk loads
 * without anything moving when it arrives.
 *
 * Its own entry (`@agentic-toolkit/bitbag/mark`), deliberately: the main barrel
 * pulls in the rig, gsap and the chat, which is exactly the weight a stand-in
 * exists to avoid. No hooks, so it server-renders.
 *
 * The viewBox is a tight square around his face. The letterform paints in
 * `currentColor`, so it takes whatever ember the surrounding element is using;
 * only the eye counter (which has to read as a hole, not a highlight) and the
 * iris are pinned to his palette.
 */
export function BitbagMark({ className = 'bb-mark' }: BitbagMarkProps): ReactElement {
  return (
    <svg className={className} viewBox="78 -47 164 164" aria-hidden focusable="false">
      {/* Stems first, bowls over them: each bowl's fill swallows the bottom of
       * its stem, which is what turns two strokes into two `b`s. */}
      <g fill="none" stroke="currentColor" strokeLinecap="round">
        <path d={BROW_LEFT} strokeWidth={BROW_WIDTH} opacity={BROW_OPACITY} />
        <path d={BROW_RIGHT} strokeWidth={BROW_WIDTH} opacity={BROW_OPACITY} />
        <path d={STEM_LEFT} strokeWidth={STEM_WIDTH} />
        <path d={STEM_RIGHT} strokeWidth={STEM_WIDTH} />
      </g>
      {[EYE_LEFT_X, EYE_RIGHT_X].map((cx) => (
        <g key={cx}>
          <circle cx={cx} cy={EYE_Y} r={EYE_RING_R} fill="currentColor" />
          <circle cx={cx} cy={EYE_Y} r={EYE_COUNTER_R} fill={EYE_BG} />
          <circle cx={cx} cy={EYE_Y} r={IRIS_BASE_R} fill={IRIS} />
        </g>
      ))}
    </svg>
  )
}
