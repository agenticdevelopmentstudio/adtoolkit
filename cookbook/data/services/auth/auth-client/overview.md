
This recipe is a headless authentication client: eleven dependency-free
modules that together give a host application a bearer-token session backed
by a same-origin, cookie-based refresh mechanism, cross-site single sign-on
against a shared authorization server (the AS), MFA/WebAuthn completion (both
at login time and in self-serve account security), and an authenticated
request wrapper the rest of the app builds on. It has no visual surface of
its own — every UI component in the auth family (login forms, callback pages,
account-security screens) is a consumer of this contract, not part of it.

