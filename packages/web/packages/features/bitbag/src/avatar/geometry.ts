// bitbag's letterform and palette — the ONE copy, drawn by both the live rig
// (Bitbag.tsx) and the still (BitbagMark.tsx), so the still a host shows while
// the rig's chunk loads can never drift from the face that replaces it.
// Everything is in the rig's viewBox units.

export const GOLD = "#e8a33d"; // bb's lit resting color — his signature ember (see expressions.ts BODY)
export const IRIS = "#ffe9c6"; // warm cream iris spark (fixed — pops bright against the ember ring)
export const EYE_BG = "#17130f"; // eye interior — warm near-black ink, opaque (not a see-through hole)
export const IRIS_BASE_R = 9; // base iris radius (viewBox units); poses scale it via `pupil`

/** Eyebrows — plain arcs peaking over each eye. */
export const BROW_LEFT = "M106,-27 Q128,-43 150,-27";
export const BROW_RIGHT = "M180,-27 Q202,-43 224,-27";
export const BROW_WIDTH = 5;
export const BROW_OPACITY = 0.85;

/**
 * The ascender stems of the two `b`s. Each is tangent to its bowl's left edge
 * (center − half-stroke = bowl leftmost), so it never pokes out further left
 * than the eye, and it runs the full height of the bowl so the side reads as
 * the straight wall of a 'b' rather than curling into a '6'.
 */
export const STEM_LEFT = "M92.5,-12 L92.5,103";
export const STEM_RIGHT = "M166.5,-12 L166.5,103";
export const STEM_WIDTH = 9;

/** The bowls are the eyes: a ring around a dark counter holding the iris. */
export const EYE_LEFT_X = 123;
export const EYE_RIGHT_X = 197;
export const EYE_Y = 72;
export const EYE_RING_R = 35;
export const EYE_COUNTER_R = 27;
