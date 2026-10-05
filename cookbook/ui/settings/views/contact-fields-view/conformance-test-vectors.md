
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| contact-fields-view-001 | starts-empty | Create the view | The record equals an empty record and the name field is empty |
| contact-fields-view-002 | shows-every-field | Assign a full record | All four fields show their values |
| contact-fields-view-003 | load-is-not-a-change | Set a change callback and assign a record | The callback is never invoked |
| contact-fields-view-004 | edit-reports-whole-record | Type an email into the email field | The callback fires once with the whole record, including the unchanged name |
| contact-fields-view-005 | fields-carry-identifiers | Create with prefix client.contact | Identifiers are client.contact.name, .email, .phone and .url |
| contact-fields-view-006 | shows-every-field | Assign a record then read it back | The record round-trips unchanged |
| contact-fields-view-007 | reload-spares-the-field-being-edited | Focus the email field, type, then assign a record with a different name | The name updates and the email keeps the typed text |
| contact-fields-view-008 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

