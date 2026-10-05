
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| whole-point-label-001 | rounds-width-up | Label whose measured width is 41.2 | Intrinsic width 42 |
| whole-point-label-002 | rounds-width-up | Label whose measured width is already 40 | Intrinsic width 40 |
| whole-point-label-003 | keeps-the-height | Any label | Intrinsic height equals the measured height |
| whole-point-label-004 | passes-through-unknown-width | A label reporting no intrinsic width | It still reports none |
| whole-point-label-005 | behaves-as-a-label | Set a string on the label | The string shows as in an ordinary label |

