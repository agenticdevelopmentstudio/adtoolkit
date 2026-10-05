
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| model-fit-policy-001 | tier-classification, tier-threshold-defaults | Compute the tier for a disk size of 12.5 GB and physical RAM of 64 GB, with thresholds omitted. | `ok` — estimated 15.0 GB is about 23% of RAM, under the default 25% warn threshold. |
| model-fit-policy-002 | tier-classification | Compute the tier for a disk size of 14 GB and physical RAM of 64 GB. | `warn` — estimated 16.8 GB is about 26% of RAM, at or above 25% and below 50%. |
| model-fit-policy-003 | tier-classification | Compute the tier for a disk size of 27 GB and physical RAM of 64 GB. | `block` — estimated 32.4 GB is about 51% of RAM, at or above the default 50% block threshold. |
| model-fit-policy-004 | tier-unknown-size, tier-zero-ram | Compute the tier for an unknown disk size at 64 GB RAM, and for a 1-byte disk size at 0 RAM. | Both return nothing. |
| model-fit-policy-005 | verdict-block-reason-format, footprint-description-format, verdict-required-thresholds | Compute the verdict for model `qwen3-coder-next:latest`, disk size 51 GB, physical RAM 64 GB, warn threshold 25, block threshold 50, pressure normal. | A `block` result whose reason contains `"qwen3-coder-next:latest"`, `"~61.2 GB (~96% of RAM)"`, and `"50% of 64.0 GB"`. |
| model-fit-policy-006 | footprint-description-format, gb-string-format, ram-pct-computation | Compute the footprint description for estimated bytes 24 GB and physical RAM 64 GB. | Returns exactly `"~24.0 GB (~38% of RAM)"`. |
| model-fit-policy-007 | fit-info-ok-text | Compute the fit info for disk size 8.9 GB and physical RAM 64 GB. | Text `"8.9 GB (~17% of RAM)"` paired with tier `ok`. |
| model-fit-policy-008 | fit-info-warn-text | Compute the fit info for disk size 20 GB and physical RAM 64 GB. | Text `"20.0 GB ⚠ large: ~38% of RAM"` paired with tier `warn`. |
| model-fit-policy-009 | fit-info-block-text | Compute the fit info for disk size 51 GB and physical RAM 64 GB. | Text `"51.0 GB — won't run: exceeds memory budget"` paired with tier `block`. |
| model-fit-policy-010 | fit-info-unknown | Compute the fit info for an unknown disk size at 64 GB RAM. | Returns nothing. |
| model-fit-policy-011 | pressure-verdict-elevated, verdict-pressure-precedence | Compute the verdict for model `llama3.1:8b`, physical RAM 64 GB, warn threshold 25, block threshold 50, pressure warning, once with a known disk size of 4.9 GB and once with an unknown disk size. | A `deferred` result whose reason contains `"memory pressure is warning"` in both cases, even with a known small size or an unknown size. |
| model-fit-policy-012 | verdict-allow-non-block-tier, pressure-verdict-normal | Compute the verdict under normal pressure for disk sizes 4.9 GB (`ok`), 20 GB (`warn`), and unknown, all at 64 GB RAM. | `allow` in all three cases. |
| model-fit-policy-013 | picker-label-known | Compute the picker label for model `deepseek-coder-v2:16b`, disk size 8.9 GB, physical RAM 64 GB. | Returns exactly `"deepseek-coder-v2:16b — 8.9 GB (~17% of RAM)"`. |
| model-fit-policy-014 | picker-label-known | Compute the picker label for model `huge`, disk size 51 GB, physical RAM 64 GB. | Returns exactly `"huge — 51.0 GB — won't run: exceeds memory budget"`. |
| model-fit-policy-015 | picker-label-unknown | Compute the picker label for model `mystery`, an unknown disk size, physical RAM 64 GB. | Returns exactly `"mystery"`. |
| model-fit-policy-016 | estimated-bytes, resident-overhead-multiplier | Compute estimated bytes for a disk size of 51 GB. | Returns `61,200,000,000` (`51,000,000,000 × 1.2`). |
| model-fit-policy-017 | ram-pct-zero-ram | Compute a percentage of RAM for a 1 GB byte count against 0 physical RAM. | Returns `0`. |
| model-fit-policy-018 | default-thresholds, threshold-setting-keys | Read the default warn threshold, default block threshold, warn-threshold setting key, and block-threshold setting key directly. | `25`, `50`, `"ai_guard_warn_pct"`, and `"ai_guard_block_pct"` respectively. |
| model-fit-policy-019 | memory-pressure-cases, tier-cases, verdict-cases, fit-info-shape | Construct one instance each of the memory pressure level (`warning`), the tier (`warn`), the verdict (`block`, reason `"x"`), and the fit-info structure (text `"t"`, tier `ok`), and compare each for equality with itself. | Each equals itself; each also can be safely passed across a concurrent boundary. |
| model-fit-policy-020 | namespace-isolation | Call the tier computation synchronously from two different concurrency contexts, with no waiting. | Both call sites run without waiting on the call, because this policy carries no isolation of its own. |

