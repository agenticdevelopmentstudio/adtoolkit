
Not applicable: this file consults no feature-flag system. Its only branching on a fixed value is the literal string comparison `platform === "vercel"` in `deployEnv` and `isRealEnvDeployRow`, which is a data-driven rule, not a flag lookup.

