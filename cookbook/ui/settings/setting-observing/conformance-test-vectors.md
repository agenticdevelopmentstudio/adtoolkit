
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| setting-observing-001 | reads-through-source | Closure observer whose getter returns 3; read the value | 3, and the getter is asked on every read |
| setting-observing-002 | writes-through-source | Write 7 to a closure observer | The setter receives 7 |
| setting-observing-003 | notifies-after-write | Set a change callback, write 9, then let the main queue drain | The callback fires once with 9, and a read inside it returns 9 |
| setting-observing-004 | notifies-on-main-queue | Write while the main queue is draining | The callback has not yet fired when the write returns; it fires on the next main-queue turn |
| setting-observing-005 | callback-is-optional | Write a value with no callback assigned | No error; the setter still receives the value |
| setting-observing-006 | closure-form | Bind a checkbox view to a closure observer and toggle it | The setter is called and the checkbox reflects the stored value |
| setting-observing-007 | persisted-form-conforms | Use the persisted-settings observer wherever the contract is required | It reads, writes and notifies like the closure form |
| setting-observing-008 | skips-delivery-when-released | Write, release the observer before the queue drains | The callback never fires and nothing fails |
| setting-observing-009 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

