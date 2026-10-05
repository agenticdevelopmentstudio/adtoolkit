
Not applicable: this file consults no feature-flag system — whether verification runs at all, and which secret it checks against, is decided entirely by the caller (`hooks.ts`'s own `if (!secret) throw` gate ahead of each call).

