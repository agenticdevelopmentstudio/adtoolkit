/**
 * Whether next.config is being loaded by `next typegen` and nothing else.
 *
 * Typegen loads the config under PHASE_PRODUCTION_BUILD, the same phase as `next build`, so
 * neither the phase nor anything else Next hands a config tells the two apart. The workspace
 * typecheck (`typecheck-all.py`, the build closure's `typegen_first`) sets `TYPEGEN_ONLY=1`
 * for that one command, and this is its single reader: `frameNext` asks it before refusing an
 * unset rewrite variable, and a hand-written config (admin's `backend-url.ts`) asks it the same
 * way. Typegen reads only a rewrite's SOURCE, so a destination it never serves need not exist.
 *
 * Only the exact value `1` counts. `next build` and `next dev` never set it, so both keep
 * refusing a missing variable by name, and a stray `TYPEGEN_ONLY=0` or `=false` does not
 * switch that guard off.
 */
export const TYPEGEN_ONLY_FLAG = "TYPEGEN_ONLY";

/**
 * The origin a rewrite gets under typegen when its variable is unset: the `.invalid` TLD never
 * resolves, so even a config that escaped into a real server could send nothing anywhere.
 */
export const TYPEGEN_ONLY_ORIGIN = "http://typegen-only.invalid";

export function isTypegenOnly(
  env: Readonly<Record<string, string | undefined>> = process.env,
): boolean {
  return env[TYPEGEN_ONLY_FLAG] === "1";
}
