"use client";
import { type Dispatch, type SetStateAction, useCallback, useEffect, useState } from "react";

/**
 * `useState` whose value survives reloads, stored as JSON in localStorage under `key`.
 * The same shape as {@link useEnvFilter} and {@link useActivityTtl}: it starts at
 * `initial` on first render and hydrates from storage in an effect, so SSR/first-paint
 * match. `decode` turns the parsed JSON back into a `T`, returning `undefined` for
 * anything it doesn't recognise — a value written by an older build, or hand-edited —
 * which keeps the default rather than rendering a shape the view never expected.
 */
export function usePersistedState<T>(
  key: string,
  initial: T,
  decode: (raw: unknown) => T | undefined,
  encode: (v: T) => unknown = (v) => v,
): [T, Dispatch<SetStateAction<T>>] {
  const [value, setValue] = useState<T>(initial);

  useEffect(() => {
    try {
      const raw = localStorage.getItem(key);
      if (raw === null) return;
      const decoded = decode(JSON.parse(raw) as unknown);
      // One-shot hydration after first render so SSR/first-paint match — external
      // store sync, not derived state.
      // eslint-disable-next-line react-hooks/set-state-in-effect
      if (decoded !== undefined) setValue(decoded);
    } catch {
      // localStorage unavailable / bad JSON — keep the default.
    }
    // `decode` is read once, at hydration; a caller passing an inline function must not
    // re-hydrate (and clobber the reader's choice) on every render.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [key]);

  const set = useCallback<Dispatch<SetStateAction<T>>>(
    (next) => {
      setValue((prev) => {
        const v = typeof next === "function" ? (next as (p: T) => T)(prev) : next;
        try {
          localStorage.setItem(key, JSON.stringify(encode(v)));
        } catch {
          // ignore persistence failure — the in-memory choice still applies
        }
        return v;
      });
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [key],
  );

  return [value, set];
}

/** Decoder for a persisted boolean flag. */
export const decodeBoolean = (raw: unknown): boolean | undefined => (typeof raw === "boolean" ? raw : undefined);
