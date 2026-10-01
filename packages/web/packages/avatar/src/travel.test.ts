import { afterEach, describe, expect, it, vi } from "vitest";
import { travelFrom } from "./travel";

// jsdom does no layout and has no Web Animations API, so the element's box is stubbed
// and `animate` records what it was asked to play.
function perch(box: { left: number; top: number; width: number; height: number }): {
  el: HTMLElement;
  animate: ReturnType<typeof vi.fn>;
  cancel: ReturnType<typeof vi.fn>;
} {
  const el = document.createElement("div");
  el.style.transformOrigin = "0px 0px";
  document.body.append(el);
  el.getBoundingClientRect = () => DOMRect.fromRect({ x: box.left, y: box.top, width: box.width, height: box.height });
  const cancel = vi.fn();
  const animate = vi.fn(() => ({ cancel, addEventListener: () => {} }) as unknown as Animation);
  el.animate = animate as unknown as HTMLElement["animate"];
  return { el, animate, cancel };
}

const rect = (left: number, top: number, width: number, height: number): DOMRect =>
  DOMRect.fromRect({ x: left, y: top, width, height });

type Frame = { transform: string; offset: number };
const framesOf = (animate: ReturnType<typeof vi.fn>, call = 0): Frame[] => animate.mock.calls[call]![0] as Frame[];
const timingOf = (animate: ReturnType<typeof vi.fn>, call = 0): KeyframeAnimationOptions =>
  animate.mock.calls[call]![1] as KeyframeAnimationOptions;

describe("travelFrom", () => {
  afterEach(() => {
    document.body.innerHTML = "";
    vi.unstubAllGlobals();
  });

  it("starts drawn over where it was, sized as it was, and ends at its new perch", () => {
    const { el, animate } = perch({ left: 100, top: 200, width: 100, height: 50 });
    travelFrom(el, rect(0, 0, 50, 25), { duration: 300 });
    const frames = framesOf(animate);
    // Half the width about a top-left origin at (100, 200): the top-left must go back 100, 200.
    expect(frames[0]!.transform).toBe("translate(-100px, -200px) scale(0.5)");
    expect(frames.at(-1)!.transform).toBe("none");
    expect(timingOf(animate).duration).toBe(300);
  });

  it("keeps the transform its CSS gives it at the new perch, and ends on it", () => {
    const { el, animate } = perch({ left: 100, top: 200, width: 100, height: 50 });
    el.style.transform = "translateX(10px)";
    travelFrom(el, rect(0, 0, 100, 50), { duration: 300 });
    const frames = framesOf(animate);
    expect(frames[0]!.transform).toBe("translateX(10px) translate(-100px, -200px) scale(1)");
    expect(frames.at(-1)!.transform).toBe("translateX(10px)");
  });

  it("bounces on landing, after the move and on top of it", () => {
    const { el, animate } = perch({ left: 100, top: 200, width: 100, height: 50 });
    travelFrom(el, rect(0, 0, 100, 50), { duration: 300, bounce: 6, bounceDuration: 200 });
    const frames = framesOf(animate);
    expect(timingOf(animate).duration).toBe(500);
    // Landed at 300 of 500, then up and down again.
    expect(frames[1]).toMatchObject({ offset: 0.6, transform: "none" });
    expect(frames.some((f) => f.transform === "translateY(-6px)" && f.offset > 0.6)).toBe(true);
    expect(frames.at(-1)!.transform).toBe("none");
  });

  it("lands at once, without animating, for a reader who asked for reduced motion", () => {
    vi.stubGlobal("matchMedia", (q: string) => ({ matches: q.includes("reduce") }));
    const { el, animate } = perch({ left: 100, top: 200, width: 100, height: 50 });
    expect(travelFrom(el, rect(0, 0, 50, 25), { duration: 300, bounce: 6 })).toBeNull();
    expect(animate).not.toHaveBeenCalled();
  });

  it("does nothing when there is nowhere to go and no bounce", () => {
    const { el, animate } = perch({ left: 100, top: 200, width: 100, height: 50 });
    expect(travelFrom(el, rect(100, 200, 100, 50), { duration: 300 })).toBeNull();
    expect(animate).not.toHaveBeenCalled();
  });

  it("stops a travel still running before starting the next, so they never fight", () => {
    const { el, cancel } = perch({ left: 100, top: 200, width: 100, height: 50 });
    travelFrom(el, rect(0, 0, 50, 25), { duration: 300 });
    travelFrom(el, rect(10, 10, 50, 25), { duration: 300 });
    expect(cancel).toHaveBeenCalledTimes(1);
  });
});
