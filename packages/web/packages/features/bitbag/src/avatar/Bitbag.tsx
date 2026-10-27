"use client";

import {
  useEffect,
  useImperativeHandle,
  useRef,
  useSyncExternalStore,
  type ReactElement,
  type Ref,
} from "react";
import gsap from "gsap";
import {
  useAvatarEngine,
  type AvatarRig,
  type ExpressionEffect,
  type MoodMap,
  type Tuning,
} from "@agenticdevelopertoolkit/avatar";
import { EXPRESSIONS, POSES, type BitbagExpression } from "./expressions";
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
  GOLD,
  IRIS,
  IRIS_BASE_R,
  STEM_LEFT,
  STEM_RIGHT,
  STEM_WIDTH,
} from "./geometry";

// ── How bitbag configures the engine's behavior (all mood-vocabulary lives here,
//    not in the engine) ──

/** Which inactivity rung is which mood. */
const MOODS: MoodMap<BitbagExpression> = { idle: "idle", bored: "bored", asleep: "asleep" };

/**
 * bitbag never nods off on his own: pushing both inactivity thresholds to
 * Infinity keeps the idle ladder pinned at "active" forever, so when left alone
 * he stays alert (blinking + looking around) instead of drifting bored → asleep.
 * These fields only ever feed `idle > X` comparisons in the engine, never a
 * timer, so Infinity simply means "that rung is unreachable." Manual moods still
 * work — the debug menu / chat can still set `bored`/`asleep` deliberately.
 * Must be a stable module constant: the engine memoizes tuning on identity, so
 * an inline object would re-run the blink/ladder effects every render.
 */
const TUNING: Partial<Tuning> = { boredAfterMs: Infinity, asleepAfterMs: Infinity };

/** The ways he giggles when poked, drawn at random so a run of pokes never plays
 *  the same bit twice in a row: the squeezed-eye laugh, the upside-down whirl, the
 *  wide-eyed bounce. */
const GIGGLES: readonly BitbagExpression[] = ["laughing", "silly", "excited"];
let lastGiggle: BitbagExpression | null = null;
const giggle = (): BitbagExpression => {
  const pool = GIGGLES.filter((g) => g !== lastGiggle);
  lastGiggle = pool[Math.floor(Math.random() * pool.length)] ?? GIGGLES[0]!;
  return lastGiggle;
};

/** A click STARTLES a sleeping bitbag (he jolts wide-eyed); otherwise he giggles. */
const pokeReaction = (resting: BitbagExpression): { expression: BitbagExpression; ms: number } =>
  resting === "asleep"
    ? { expression: "startled", ms: 1700 } // the startle lingers a touch longer
    : { expression: giggle(), ms: 1400 };

/** Blinks pause while the eyes are deliberately controlled (the laugh squeeze). */
const BLINK_SUPPRESSED: BitbagExpression[] = ["laughing"];

// ── Incidental per-mood motion: moods with no animation loop can read as a frozen
//    frame, so each gets a slow micro-life. These ride bitbag's anatomy (the idle
//    layer + the face group), so they live here as the engine's
//    `perExpressionEffects` rather than in the engine. ──

/** Asleep: mostly dead still, but every few seconds a tiny twitch or a slumped drift. */
const asleepStir: ExpressionEffect = (rig) => {
  const el = rig.idleLayer?.current;
  if (!el) return;
  const rnd = (m: number): number => (Math.random() * 2 - 1) * m;
  let timer: ReturnType<typeof setTimeout> | undefined;
  const stir = (): void => {
    if (Math.random() < 0.6) {
      // a quick, very slight twitch that springs back
      gsap
        .timeline()
        .to(el, { rotation: rnd(1.6), x: rnd(1.5), svgOrigin: rig.pivot, duration: 0.12, ease: "power2.out" })
        .to(el, { rotation: 0, x: 0, svgOrigin: rig.pivot, duration: 0.55, ease: "sine.out" });
    } else {
      // a slow, slight shift in how he's curled up
      gsap.to(el, { x: rnd(4), y: rnd(3), rotation: rnd(1), svgOrigin: rig.pivot, duration: 2.6 + Math.random() * 1.6, ease: "sine.inOut", overwrite: "auto" });
    }
    timer = setTimeout(stir, 4000 + Math.random() * 4000);
  };
  // first stir only after he's settled into sleep for a little while
  timer = setTimeout(stir, 4000 + Math.random() * 3000);
  return () => {
    if (timer) clearTimeout(timer);
    gsap.killTweensOf(el);
    gsap.to(el, { x: 0, y: 0, rotation: 0, svgOrigin: rig.pivot, duration: 0.5, ease: "power2.out" });
  };
};

/** Bored: a slow, heavy sag on the face keeps him listless but alive. */
const boredSag: ExpressionEffect = (rig) => {
  const face = rig.face?.ref.current;
  if (!face) return;
  const sag = gsap.to(face, { y: 2.5, duration: 3.5, repeat: -1, yoyo: true, ease: "sine.inOut", overwrite: "auto" });
  return () => {
    sag.kill();
    gsap.to(face, { y: 0, duration: 0.4, ease: "power2.out", overwrite: "auto" });
  };
};

/** Sad: a slow forward/downward head droop so he looks dejected, not just blue. */
const sadDroop: ExpressionEffect = (rig) => {
  const face = rig.face?.ref.current;
  if (!face) return;
  const droop = gsap.to(face, { rotation: 4, y: 3, transformOrigin: "50% 100%", duration: 0.9, ease: "power2.out", overwrite: "auto" });
  return () => {
    droop.kill();
    gsap.to(face, { rotation: 0, y: 0, transformOrigin: "50% 60%", duration: 0.5, ease: "power2.out", overwrite: "auto" });
  };
};

const PER_EXPRESSION_EFFECTS: Partial<Record<BitbagExpression, ExpressionEffect>> = {
  asleep: asleepStir,
  bored: boredSag,
  sad: sadDroop,
};

// ── Reduced motion ──
//
// Everything above animates through gsap, which a host's CSS kill-switch
// (`animation: none` under `prefers-reduced-motion`) cannot touch: gsap writes
// transforms straight onto the elements on its own ticker, so no CSS rule
// reaches it. Left alone bitbag breathes, blinks, sways and tracks the cursor
// forever — automatic, indefinite motion running alongside the page's content,
// which is what WCAG 2.2.2 is about.
//
// The engine has no reduced-motion switch, so this stills him through its
// ordinary configuration instead of patching it. Four levers, and it takes all
// four — each loop has a different owner:
//
//   • Pinning `expression` to a non-idle pose makes the engine's `curious`
//     false, which is the only gate on the always-on breath loop and the idle
//     fidget (their amplitudes are hardcoded, not tunable). `inquisitive` is
//     the pin: awake, eyes open, and `bob`/`wiggle` both 0, so `applyPose`
//     starts no loops of its own.
//   • Zeroed gaze/tilt/lean amplitudes leave the cursor-follow timers running
//     but multiplying out to no displacement.
//   • Suppressing the blink on every expression, rather than the laugh alone.
//   • Dropping the per-expression effects above, whose sag and stir are the
//     remaining `repeat: -1` timelines.
//
// What survives is the one-shot pose tween on mount — well under the 5 seconds
// 2.2.2 draws its line at. The cost is that bitbag holds one face and stops
// reacting, which is the trade a reader asking for reduced motion is making.
const REDUCED_TUNING: Partial<Tuning> = { ...TUNING, gazeMax: 0, tiltMax: 0, leanMax: 0 };
const REDUCED_EXPRESSION: BitbagExpression = "inquisitive";
const NO_EXPRESSION_EFFECTS: Partial<Record<BitbagExpression, ExpressionEffect>> = {};
const NO_POKE = (): void => {};

const MOTION_QUERY = "(prefers-reduced-motion: reduce)";

const subscribeToMotionPreference = (onChange: () => void): (() => void) => {
  const mq = window.matchMedia(MOTION_QUERY);
  mq.addEventListener("change", onChange);
  return () => mq.removeEventListener("change", onChange);
};

/**
 * Whether the reader has asked for reduced motion, tracked live so toggling the
 * OS setting stills or wakes him without a reload. The server snapshot is
 * `false`, but nothing turns on it: hosts mount him client-only (he runs gsap
 * timelines, which don't survive hydration).
 */
function usePrefersReducedMotion(): boolean {
  return useSyncExternalStore(
    subscribeToMotionPreference,
    () => window.matchMedia(MOTION_QUERY).matches,
    () => false,
  );
}

export interface BitbagProps {
  /** Deliberate mood from a driver (chat today, persona later). */
  expression?: BitbagExpression;
  /**
   * A deliberate gaze direction, normalized: x ∈ [-1,1] (right is +), y ∈ [-1,1]
   * (down is +). e.g. `{ x: 0, y: 1 }` makes him look straight down — at an input
   * sitting below him. While set, it overrides his cursor-follow and his idle
   * look-around. Omit or pass null to hand his eyes back to those reflexes.
   */
  gaze?: { x: number; y: number } | null;
  /**
   * Fires with each short utterance he blurts (his speech-bubble text, e.g.
   * "zzz", "well?", "yes!"), so a driver can echo it transiently in a status line.
   */
  onSpeak?: (text: string) => void;
  /**
   * When true, he keeps his expressions but stays silent — no speech bubbles and
   * no `onSpeak`. Used while a command is processing so the status holds the
   * thinking spinner rather than his chatter.
   */
  mute?: boolean;
  /**
   * Whether a click on him pokes him (default true). A host that gives his click
   * a job of its own — the dock, where tapping him opens his chat or sends — turns
   * it off and pokes him itself through `handleRef`, only when the job calls for it.
   */
  pokeOnClick?: boolean;
  /** Imperative access for a host that drives his reactions itself. */
  handleRef?: Ref<BitbagHandle>;
}

/** What a host can make bitbag do directly. */
export interface BitbagHandle {
  /** Poke him: he giggles (at random), or startles if he was asleep. */
  poke: () => void;
}

export function Bitbag({
  expression,
  gaze = null,
  onSpeak,
  mute = false,
  pokeOnClick = true,
  handleRef,
}: BitbagProps): ReactElement {
  const svgRef = useRef<SVGSVGElement>(null);
  // Transform layers, outermost first, each with a single owner so they never
  // fight: idleRef = idle fidget (sway + breath), tiltRef = head-tilt toward a
  // deliberate gaze, leanRef = drift toward what he watches, bodyRef = emotional
  // scale/rotation/spin, faceRef = bob/wiggle + chameleon color.
  const idleRef = useRef<SVGGElement>(null);
  const tiltRef = useRef<SVGGElement>(null);
  const leanRef = useRef<SVGGElement>(null);
  const bodyRef = useRef<SVGGElement>(null);
  const faceRef = useRef<SVGGElement>(null);
  const leftEyeRef = useRef<SVGGElement>(null);
  const rightEyeRef = useRef<SVGGElement>(null);
  const leftBlinkRef = useRef<SVGGElement>(null);
  const rightBlinkRef = useRef<SVGGElement>(null);
  const leftIrisRef = useRef<SVGCircleElement>(null);
  const rightIrisRef = useRef<SVGCircleElement>(null);
  // Tiny lit pupils that persist when his eyes are shut (asleep) — outside the
  // eye-scale group so the closing bowl never squishes them flat.
  const leftDotRef = useRef<SVGCircleElement>(null);
  const rightDotRef = useRef<SVGCircleElement>(null);
  const browLeftRef = useRef<SVGGElement>(null);
  const browRightRef = useRef<SVGGElement>(null);
  const speechRef = useRef<SVGTextElement>(null);

  // bitbag's rig: only the channels the "bb" mark actually has — eyes, iris,
  // brows, face, body, the transform layers, and speech. No antennae/mouth/
  // descender. The refs never change identity, so this object can be rebuilt
  // each render harmlessly — the engine reads `.current` at effect time.
  const rig: AvatarRig = {
    svg: svgRef,
    pivot: "160 72", // between the eyes (the bowls, lowered onto the stems)
    idleLayer: idleRef,
    tiltLayer: tiltRef,
    leanLayer: leanRef,
    body: { ref: bodyRef },
    eyes: { leftRef: leftEyeRef, rightRef: rightEyeRef, blinkLeftRef: leftBlinkRef, blinkRightRef: rightBlinkRef },
    iris: { leftRef: leftIrisRef, rightRef: rightIrisRef, baseR: IRIS_BASE_R },
    // Each brow tilts about its own centre (just above its eye) for a natural,
    // local eyebrow lift/lower rather than swinging around the whole eye.
    brows: { leftRef: browLeftRef, rightRef: browRightRef, leftOrigin: "128 -34", rightOrigin: "202 -34" },
    face: { ref: faceRef, wiggleOrigin: "50% 60%" },
    speech: speechRef,
  };

  // Still, silent and unreactive when the reader has asked for reduced motion —
  // see REDUCED_TUNING above for why it takes all of these together. `mute`
  // rides along because a speech bubble popping in and drifting out is motion
  // too, and `gaze` is dropped for the same reason the amplitudes are zeroed.
  const still = usePrefersReducedMotion();

  const { effective, speech, poke: enginePoke } = useAvatarEngine<BitbagExpression>({
    expression: still ? REDUCED_EXPRESSION : expression,
    gaze: still ? null : gaze,
    onSpeak,
    mute: mute || still,
    poses: POSES,
    rig,
    moods: MOODS,
    tuning: still ? REDUCED_TUNING : TUNING,
    poke: pokeReaction,
    perExpressionEffects: still ? NO_EXPRESSION_EFFECTS : PER_EXPRESSION_EFFECTS,
    blinkSuppressed: still ? EXPRESSIONS : BLINK_SUPPRESSED,
  });
  // The poke goes with the rest of his motion when `still` — from a click and
  // from his host alike: the giggle it triggers is a `repeat: -1` shimmy, and a
  // looping animation is no more welcome for having been asked for.
  const poke = still ? NO_POKE : enginePoke;
  const clickable = pokeOnClick && !still;

  useImperativeHandle(handleRef, () => ({ poke }), [poke]);

  // Pinprick pupils: fade the tiny lit dots in when his eyes shut (asleep), so
  // there's always a spark in the dark; hidden when awake (the real irises show).
  const eyesShut = effective === "asleep";
  useEffect(() => {
    gsap.to([leftDotRef.current, rightDotRef.current], {
      opacity: eyesShut ? 1 : 0,
      duration: eyesShut ? 0.6 : 0.2,
      ease: "power2.out",
    });
  }, [eyesShut]);

  return (
    <svg
      ref={svgRef}
      viewBox="-15 -72 350 195"
      aria-label="bitbag"
      className="block h-auto w-full"
      onClick={clickable ? poke : undefined}
      style={{
        cursor: clickable ? "pointer" : undefined,
        pointerEvents: "auto",
        // Don't clip the glyph to the viewBox: the emotional `scale`/`rotation`
        // (and the silly spin) push his extremities past the box, and the default
        // SVG overflow:hidden would shear them off. Layout box is unchanged.
        overflow: "visible",
      }}
    >
      {/* full-bleed hit area so a click anywhere on him giggles (svg `auto` only
          hits painted pixels; his centre is transparent). `all` ignores fill. */}
      <rect x={-15} y={-72} width={350} height={195} fill="transparent" style={{ pointerEvents: "all" }} />

      {/* speech */}
      {speech && (
        <text
          ref={speechRef}
          x={160}
          y={-46}
          textAnchor="middle"
          fontFamily="monospace"
          fontWeight={400}
          fontSize={26}
          fill={GOLD}
          style={{ opacity: 0 }}
        >
          {speech.text}
        </text>
      )}

      <g ref={idleRef}>
        <g ref={tiltRef}>
          <g ref={leanRef}>
            <g ref={bodyRef}>
              <g ref={faceRef} style={{ color: GOLD }}>
                {/* eyebrows — plain arcs peaking over each eye. Everything that
                    paints with `currentColor` (the brows, the `b` stems + bowl
                    rings) recolors together via the per-pose `body` tween; only
                    the irises keep a fixed lit fill. Each brow tilts/raises about
                    its own centre via the rig's brow origins. */}
                <g ref={browLeftRef} opacity={BROW_OPACITY}>
                  <path d={BROW_LEFT} fill="none" stroke="currentColor" strokeWidth={BROW_WIDTH} strokeLinecap="round" />
                </g>
                <g ref={browRightRef} opacity={BROW_OPACITY}>
                  <path d={BROW_RIGHT} fill="none" stroke="currentColor" strokeWidth={BROW_WIDTH} strokeLinecap="round" />
                </g>

                {/* left b — the ascender STEM is a static part of the letterform
                    (it doesn't blink or scale with the eye); the BOWL below is the
                    eye: a ring (recolors with mood) around a dark counter holding
                    the iris. Stem drawn first so the bowl ring merges over it.
                    The stem is tangent to the bowl's left edge (center 92.5 −
                    half-stroke 4.5 = 88 = bowl leftmost), so it never pokes out
                    further left than the eye, and it runs the full height of the
                    bowl (down to ~baseline) so the left side reads as the straight
                    vertical wall of a 'b' rather than curling into a '6'. */}
                <path d={STEM_LEFT} stroke="currentColor" strokeWidth={STEM_WIDTH} fill="none" strokeLinecap="round" />
                <g ref={leftEyeRef}>
                  <g ref={leftBlinkRef}>
                    <circle cx={EYE_LEFT_X} cy={EYE_Y} r={EYE_RING_R} fill="currentColor" />
                    <circle cx={EYE_LEFT_X} cy={EYE_Y} r={EYE_COUNTER_R} fill={EYE_BG} />
                    <circle ref={leftIrisRef} cx={EYE_LEFT_X} cy={EYE_Y} r={IRIS_BASE_R} fill={IRIS} />
                  </g>
                </g>

                {/* right b — ascender stem + bowl (stem tangent to the bowl's
                    left edge: center 166.5 − 4.5 = 162 = bowl leftmost) */}
                <path d={STEM_RIGHT} stroke="currentColor" strokeWidth={STEM_WIDTH} fill="none" strokeLinecap="round" />
                <g ref={rightEyeRef}>
                  <g ref={rightBlinkRef}>
                    <circle cx={EYE_RIGHT_X} cy={EYE_Y} r={EYE_RING_R} fill="currentColor" />
                    <circle cx={EYE_RIGHT_X} cy={EYE_Y} r={EYE_COUNTER_R} fill={EYE_BG} />
                    <circle ref={rightIrisRef} cx={EYE_RIGHT_X} cy={EYE_Y} r={IRIS_BASE_R} fill={IRIS} />
                  </g>
                </g>
              </g>

              {/* tiny pinprick pupils — OUTSIDE the face + eye-scale groups, so no
                  tint and no eyelid-squish. Faded in only when his eyes shut. */}
              <circle ref={leftDotRef} cx={EYE_LEFT_X} cy={EYE_Y} r={2.6} fill={IRIS} opacity={0} style={{ filter: "drop-shadow(0 0 3px #ffe9c6) drop-shadow(0 0 1.5px #ffe9c6)" }} />
              <circle ref={rightDotRef} cx={EYE_RIGHT_X} cy={EYE_Y} r={2.6} fill={IRIS} opacity={0} style={{ filter: "drop-shadow(0 0 3px #ffe9c6) drop-shadow(0 0 1.5px #ffe9c6)" }} />
            </g>
          </g>
        </g>
      </g>
    </svg>
  );
}
