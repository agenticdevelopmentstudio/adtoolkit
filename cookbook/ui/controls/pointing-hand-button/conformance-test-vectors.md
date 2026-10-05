
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| pointing-hand-button-001 | cursor-rect | Trigger the cursor-rect update on a button laid out at bounds (0, 0, 100, 30) | A cursor rect covering (0, 0, 100, 30) is registered with the pointing-hand cursor |
| pointing-hand-button-003 | tracking-area-replacement | Trigger the hover-tracking registration step twice in succession on the same instance | Among the button's registered hover-tracking regions, exactly one is owned by the button and configured to remain active regardless of window focus — the second call replaced the first instead of adding a duplicate |
| pointing-hand-button-004 | always-active-tracking | Trigger the hover-tracking registration step on a button whose window does not have focus | A registered hover-tracking region covers the button's bounds, is owned by the button, and is configured to report entry, exit, and movement while remaining active regardless of window focus |
| pointing-hand-button-005 | enter-cursor | Deliver a synthetic pointer-entered event | The current system cursor becomes the pointing-hand cursor |
| pointing-hand-button-006 | move-cursor | Deliver a synthetic pointer-moved event | The current system cursor becomes the pointing-hand cursor |
| pointing-hand-button-007 | exit-cursor | Deliver a synthetic pointer-exited event | The current system cursor becomes the default arrow cursor |
| pointing-hand-button-008 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

