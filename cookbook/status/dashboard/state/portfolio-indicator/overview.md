
Portfolio Indicator is the single derivation of the whole-portfolio status sign, shared by the status header's pill and the landing sign in the board shell; in the current tree its callers are the board shell and the wallboard status view. It reads two independent feeds: the board state (for what's wrong) and Live Snapshot (for whether the data backing that claim is fresh). It returns a result holding a glyph key (`pillKey`) and a problem count (`count`).

Portfolio Indicator exists so that the rule for "when is status unknown" lives in one place and the signs that show portfolio status can never disagree. It does not format text: callers format their own headline text from `pillKey`/`count`.

Use it anywhere a view needs to show one portfolio-wide status verdict. Do not re-derive the unknown rule, the snapshot staleness rule, or the board staleness rule in a caller.

