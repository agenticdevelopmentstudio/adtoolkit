
Not applicable: this file consults no feature-flag system of any kind; `enrichDeployErrors` is invoked unconditionally from `sync.ts`'s `runCycle` on every full sync cycle, with the cooldown/token gating already documented under Behavioral Requirements as its only on/off lever.

