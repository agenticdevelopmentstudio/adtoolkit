
Not applicable: the given implementations delegate network transport, authentication, and
credential storage to the host application's own API client and to the web implementation's
shared authenticated request helpers; no given implementation reads, stores, or transmits a
credential directly. The persona content these implementations do carry — name, description,
character, voice, model prompt, demo-chat script, special interests — is user-authored feature
data handled as an opaque payload, with no additional PII classification, redaction, or retention
logic applied by this component itself.

