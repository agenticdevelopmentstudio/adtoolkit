
| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | seed-sections-from-props, hide-empty-sections | open with emails only | only the Email section renders, seeded from the email list |
| T2 | hide-empty-sections | open with phones only | only the SMS section renders |
| T3 | hide-empty-sections | open with both | both sections render |
| T4 | assemble-send-payload | open with emails ["a@x.io","b@x.io"], phones ["+15550100"]; type "Hi" into the email note; click Send | the send callback is called with an email entry of recipients ["a@x.io","b@x.io"] and note "Hi", and an sms entry of recipients ["+15550100"] and note "" |
| T5 | disable-send-when-empty | open with emails and phones both empty/absent | no section renders; Send disabled |
| T6 | provide-note-per-section | open with emails only | Email section shows a labeled, optional note field |
| T7 | recipients-are-read-only | attempt to remove a seeded recipient chip | no removal occurs; the recipient list accepts no edits |
| T8 | confirm-cancel-when-populated | Cancel on a freshly opened, unedited modal | closes immediately (pre-seeded recipients alone are not "populated") |
| T9 | confirm-cancel-when-populated | type text into a note, then Cancel | discard confirm opens |
| T10 | confirm-cancel-when-populated | type text into a note, then press Esc | discard confirm opens |
| T11 | confirm-cancel-when-populated | type text into a note, then click the backdrop | discard confirm opens |
| T12 | confirm-cancel-when-populated | discard confirm open, click Discard | modal closes and resets |
| T13 | confirm-cancel-when-populated | discard confirm open, click Cancel (stay) | confirm closes; modal remains open with its text intact |
| T14 | no-enter-to-send | focus the note field, press Enter | a newline is inserted; Send is not triggered |
| T15 | block-dismissal-when-busy | busy true, Esc/backdrop/Cancel | dismissal blocked; Send disabled; spinner shown; no discard confirm even if populated |
| T16 | reset-on-close | populate a note, close via Discard, reopen with a fresh mount | note is empty again; recipients re-seeded from current inputs |
| T17 | label-controls | inspect the rendered result | each recipient list and note field has an accessible label; the dialog traps and restores focus |
| T18 | custom-title | open without a title, then with title "Invite teammates" | dialog heading reads "Send invitation", then "Invite teammates" |

