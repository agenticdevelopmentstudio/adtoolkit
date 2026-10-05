
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| settings-card-views-001 | group-caption | Construct a group container titled "Section" wrapping a single row | A caption showing "Section" in the caption font and secondary-text color appears above the card |
| settings-card-views-002 | group-omits-caption-when-title-absent | Construct a group container with no title, wrapping a single row | No caption is rendered; only the card appears |
| settings-card-views-003 | group-caption-spacing | Construct a titled group container and measure the rendered layout | The vertical gap between the caption's bottom edge and the card's top edge is 6pt |
| settings-card-views-004 | group-stretches-full-width | Place a group container in a container 400pt wide | The rendered group container occupies the full 400pt width, leading-aligned |
| settings-card-views-005 | group-title-not-auto-localized | Add a string-catalog entry mapping the literal string passed as the title to a different translation, then render the group container with that same text held in a variable | The caption displays the original untranslated string, not the localized entry |
| settings-card-views-006 | card-fills-rounded-elevated-surface | Render a card with solid content under a known theme | The card's background pixel color matches the theme's elevated-surface value, and its clip shape is a continuous-corner rounded rectangle with radius 10 (or matches a snapshot-test baseline for the rendered corner) |
| settings-card-views-007 | card-stretches-full-width | Place a card in a container 400pt wide | The rendered card occupies the full 400pt width, leading-aligned |
| settings-card-views-008 | card-row-insets-content | Render a card row wrapping a single label inside a card of known width | The label's frame is inset 14pt from each side edge and 9pt from top and bottom |
| settings-card-views-009 | card-row-stretches-full-width | Place a card row in a container 400pt wide | The rendered row occupies the full 400pt width, leading-aligned |
| settings-card-views-010 | divider-renders-hairline | Render a divider under a known theme | A horizontal bar exactly 1pt tall appears, filled with the theme's divider color |
| settings-card-views-011 | divider-insets-from-leading-edge | Render a divider inside a card 400pt wide | The hairline starts 14pt from the leading edge and extends to the trailing edge with no trailing inset |
| settings-card-views-012 | panel-inset-pads-uniformly | Apply the panel-inset operation to a 300×300pt view | The modified view's content is inset 20pt on all four sides |
| settings-card-views-013 | search-field-wraps-native-control | Instantiate a search field with a placeholder and a bound text value, and inspect the produced view hierarchy | The produced view is, or contains, a genuine native search-field control |
| settings-card-views-014 | search-field-filters-live | Inspect the native control the search field creates | The control is configured to send its search action on every keystroke rather than waiting for a submit action |
| settings-card-views-015 | search-field-writes-through-binding | Type a character into the live field so its search action fires | The bound text value updates to the field's new text |
| settings-card-views-016 | search-field-avoids-cursor-jump | Place the insertion point mid-string in the field, then update it with a text value equal to the field's current text | The field's text is not reassigned and the insertion point does not move |
| settings-card-views-018 | search-field-sizes-to-fitting-height | Ask the search field to size itself with a proposed width of 200 and no proposed height | The returned height equals the wrapped control's own natural height, and the returned width is 200 |
| settings-card-views-019 | search-field-placeholder-not-auto-localized | Add a string-catalog entry mapping the literal string passed as the placeholder to a different translation, then construct the search field with that same text held in a variable | The field's placeholder shows the original untranslated string |
| settings-card-views-020 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

One requirement from the source implementation — keeping a rebindable
write-back target in sync across repeated re-renders of the surrounding
declarative view — is a mechanic of bridging a native control into a
declarative UI framework rather than a portable behavior; see Platform Notes. Two further checks against restricting a type's visibility
to its own defining module are a language-level access-control concern
with no user-visible effect; see Design Decisions and Platform Notes.

