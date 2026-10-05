
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | best-practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | best-practices |
| [graceful-degradation](agenticdevelopercookbook://compliance/reliability#graceful-degradation) | passed | reliability |
| [resource-efficiency](agenticdevelopercookbook://compliance/performance#resource-efficiency) | passed | performance |
| [state-recovery](agenticdevelopercookbook://compliance/reliability#state-recovery) | partial | reliability |

The hook does one job, scroll-edge locking, and it touches only the DOM element it is given. `use-edge-lock.test.ts` covers mount, both resize directions, follow within the slack, leaving a reader put, the filtered-list regression, and both EL-1 and EL-2. It degrades gracefully when `ResizeObserver` is absent. It avoids re-wiring on every render and removes its listeners on unmount. State recovery is partial: element swaps reset cleanly, but a change to `edge` while the same element stays mounted leaves the scroll and resize handlers measuring from the old edge. That residual is described in `edge-change-while-mounted`.

