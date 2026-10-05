
Not applicable: this component has no view lifecycle states. Its only
state machine is the migration/transaction sequencing described under
Behavioral Requirements (**save-tabs-atomic-rollback**,
**project-directories-whole-replace**) and the crash-recovery behavior
documented on the base project database component (its idempotent, `IF
NOT EXISTS`/conditional-`ALTER`-guarded migrations, exercised by this
extension's own working-directory test fixture that crashes
mid-migration).

