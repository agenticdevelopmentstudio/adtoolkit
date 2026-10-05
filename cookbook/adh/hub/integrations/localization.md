
Not applicable: this client authors no user-facing string literal of its own — every runtime string
this module builds is a URL, a JSON key, or a fixed structural constant (the base path, the callback
path); every message a caller can observe (an error's message, a test result's summary, an
adopted-installation row's skipped/warning) originates in the backend's response body, extracted by the
shared error-message/error-code helpers, not authored here.

