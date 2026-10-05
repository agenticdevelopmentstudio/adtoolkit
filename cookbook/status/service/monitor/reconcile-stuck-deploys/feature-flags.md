
Not applicable: this file consults no feature-flag system of any kind; `reconcileVanishedDeploys` and `expireUnconfirmedDeploys` are invoked unconditionally from `sync.ts`'s `runCycle` (on every tick and every full cycle respectively), with the cooldown/token/backoff gating already documented under Behavioral Requirements as their only on/off levers.

