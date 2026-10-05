
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| ns-image-symbol-001 | returns-system-symbol-when-available | Name `plus`, description `Add` | A system image with non-zero width whose accessibility description is `Add` |
| ns-image-symbol-002 | never-returns-nothing | Name `no.such.symbol.anywhere`, description `Stop` | An image is returned; nothing traps or is absent |
| ns-image-symbol-003 | blank-fallback-is-symbol-sized | Name `no.such.symbol.anywhere`, description `Stop` | The image size equals 16 by 16 points |
| ns-image-symbol-004 | blank-fallback-is-template | Name `no.such.symbol.anywhere`, description `Stop` | The image is marked as a template image |
| ns-image-symbol-005 | blank-fallback-keeps-description | Name `no.such.symbol.anywhere`, description `Stop` | The image's accessibility description equals `Stop` |
| ns-image-symbol-006 | description-is-optional | Name `no.such.symbol.anywhere`, no description | A blank 16 by 16 template image with no accessibility description |

