// @vitest-environment jsdom
import { describe, it, expect, afterEach } from "vitest";
import { renderHook, act, cleanup } from "@testing-library/react";
import { usePersistedState, decodeBoolean } from "./use-persisted-state";
import { useSourceFilter } from "./use-source-filter";

afterEach(() => {
  cleanup();
  localStorage.clear();
});

describe("usePersistedState — gear settings survive a reload", () => {
  it("restores a value set in an earlier mount", () => {
    const first = renderHook(() => usePersistedState("k", false, decodeBoolean));
    act(() => first.result.current[1](true));
    first.unmount();
    const second = renderHook(() => usePersistedState("k", false, decodeBoolean));
    expect(second.result.current[0]).toBe(true);
  });

  it("keeps the default for a stored value the decoder doesn't recognise", () => {
    localStorage.setItem("k", JSON.stringify("yes"));
    const { result } = renderHook(() => usePersistedState("k", false, decodeBoolean));
    expect(result.current[0]).toBe(false);
  });

  it("persists each pane's source filter under its own key", () => {
    const a = renderHook(() => useSourceFilter("src-activity"));
    act(() => a.result.current.toggleSource("glitchtip"));
    a.unmount();
    expect(renderHook(() => useSourceFilter("src-activity")).result.current.sources.has("glitchtip")).toBe(false);
    expect(renderHook(() => useSourceFilter("src-problems")).result.current.sources.has("glitchtip")).toBe(true);
  });
});
