
| State | Appearance change |
|-------|------------------|
| Default | Cursor is the default arrow cursor until the pointer enters `bounds`; this component applies no other styling of its own outside of cursor management. |
| Pressed | Not styled by this component; the source overrides none of the platform's press-handling, so the native bezel press feedback applies unmodified. |
| Disabled | Not implemented: none of the overridden methods reads the enabled state, so the cursor-rect update and the pointer-entered/moved handlers set the pointing-hand cursor unconditionally, even on a disabled button that cannot be clicked. |
| Focused | Not styled by this component; no focus-ring override appears in source, so the platform's native focus appearance applies unmodified. |
| Loading | Not applicable: this component performs no asynchronous work and defines no loading state. |

