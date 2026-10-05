
Not applicable: this logic contains no logging call of any kind — every caught error here (the
presence fetch, the poll-fallback refetches, a malformed live-stream frame) is discarded silently,
with no diagnostic output anywhere in this recipe.

