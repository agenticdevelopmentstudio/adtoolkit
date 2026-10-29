import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { describe, expect, it } from "vitest";
import character from "@character/character.json";
import rig from "@character/rig.json";
import poses from "@character/poses.json";
import timelines from "@character/timelines.json";
import behavior from "@character/behavior.json";
import sayings from "@character/sayings.json";
import { loadConfig } from "../config/load";
import { SCENARIOS } from "./scenarios";
import { recordScenario } from "./record";

const config = loadConfig({ character, rig, poses, timelines, behavior, sayings });
const yawn = SCENARIOS.find((s) => s.name === "yawn")!;

/** The recordings checked in beside the character JSON. Not importable: they
 *  are read as files. See the `CHARACTER_DIR` note in vitest.config.ts. */
const GOLDENS_DIR = join(process.env.CHARACTER_DIR!, "goldens");

describe("recordScenario", () => {
  it("emits one line per frame, ending with a single newline", () => {
    const out = recordScenario(config, yawn);
    expect(out.endsWith("\n")).toBe(true);
    expect(out.endsWith("\n\n")).toBe(false);
    expect(out.trimEnd().split("\n")).toHaveLength(Math.floor(yawn.duration * yawn.fps) + 1);
  });

  it("writes the documented line shape", () => {
    const first = JSON.parse(recordScenario(config, yawn).split("\n")[0]!);
    expect(first.f).toBe(0);
    expect(first.t).toBe(0);
    expect(first.items).toHaveLength(14);
    const item = first.items[0];
    expect(Object.keys(item).sort()).toEqual(["id", "k", "m", "p", "pts"]);
    expect(item.m).toHaveLength(6);
    expect(typeof item.k).toBe("string");
  });

  it("is byte-identical across runs", () => {
    expect(recordScenario(config, yawn)).toBe(recordScenario(config, yawn));
  });

  it("runs every scenario, and a scripted command unfolds over time", () => {
    for (const s of SCENARIOS) {
      expect(recordScenario(config, s).length).toBeGreaterThan(0);
    }

    // `length > 0` is not a test. It passed while every scripted command in five
    // of these ten scenarios landed already expired and snapped to its end
    // state inside a single frame (Ruling 48) — the goldens were wrong and the
    // suite was green. What that bug destroyed is DURATION, so duration is what
    // is asserted here: the yawn is played at t=1 and takes about two and a half
    // seconds (`engine.test.ts` pins that), so the mouth it drives must still be
    // TRAVELLING a full second later. The window is deliberately t=2..3.4 rather
    // than one starting at the command: a frozen command clock does not stop the
    // mouth from moving right after the play, it stops it from moving *later*,
    // because the tween is created already past its own deadline and completes
    // in a single frame. Measured on this config the window holds 42 distinct
    // mouth shapes; with the command clock frozen it holds exactly 1.
    const frames = recordScenario(config, yawn).trimEnd().split("\n").map((l) => JSON.parse(l));
    const shapes = new Set<string>();
    for (let f = 120; f <= 204; f += 1) {
      shapes.add(JSON.stringify(frames[f].items.find((i: { id: string }) => i.id === "mouth").pts));
    }
    expect(shapes.size).toBeGreaterThan(10);
  });

  it("covers every mood in poses.json", () => {
    const moods = SCENARIOS.find((s) => s.name === "moods")!;
    const scripted = new Set<string>();
    const probe = { setMood: (m: string | null) => { if (m) scripted.add(m); } };
    for (const step of moods.script) step.do(probe as never);
    expect([...scripted].sort()).toEqual(Object.keys(config.poses.poses).sort());
  });
});

// The checked-in goldens are what every OTHER platform is verified against: the
// Swift replay in `OlyloAvatar` reads these exact files. Nothing above compares
// the recorder's output to them, and for one day nothing did anywhere -- so when
// `ac3b5de` moved the antenna's inward damp from the renderer to the write, the
// goldens kept the old shape, stayed green, and the Swift port faithfully
// reproducing the NEW behaviour looked like the thing that was broken (Ruling
// 113). A recording that nothing re-checks is not a golden, it is a fossil.
//
// `skipIf`, because the character this suite loads is not always the one the
// goldens were recorded against. A checkout of THIS repo alone -- which is what
// `deployment/run-ci` does -- has no `characters/olylo` in any ancestor and falls
// back to the copy bundled in `src/__fixtures__/olylo`, which deliberately does
// not vendor 93MB of recorded frames. Skipping the comparison there leaves the
// six recorder tests above running, which excluding the whole file did not.
// Every run that can see the real character still compares, and that is every
// run inside whatsnow-toolkit, CI's root workspace run included.
describe.skipIf(!existsSync(GOLDENS_DIR))("the checked-in goldens", () => {
  const dir = GOLDENS_DIR;

  it.each(SCENARIOS.map((s) => s.name))("%s.jsonl matches what src/ records today", (name) => {
    const scenario = SCENARIOS.find((s) => s.name === name)!;
    const fresh = recordScenario(config, scenario);
    const onDisk = readFileSync(join(dir, `${name}.jsonl`), "utf8");
    if (fresh === onDisk) return;

    // Never `expect(fresh).toBe(onDisk)` -- these run to 43MB and vitest would
    // try to render a character diff of the whole thing. Report the first
    // differing line instead, which is the only part anyone can act on.
    const a = fresh.split("\n");
    const b = onDisk.split("\n");
    // Scan to the LONGER of the two: `findIndex` over `a` alone returns -1 when
    // the fresh output is a strict prefix of the file (a scenario that got
    // shorter), and would report the difference as "line 0".
    let i = 0;
    while (i < Math.max(a.length, b.length) && a[i] === b[i]) i += 1;
    expect.fail(
      `${name}.jsonl is stale (${b.length} lines on disk, ${a.length} fresh). ` +
        `First difference at line ${i + 1}. ` +
        `Re-record with: python3 tools/avatar/record_golden.py ${name}  (from the whatsnow-toolkit root)`,
    );
  });
});
