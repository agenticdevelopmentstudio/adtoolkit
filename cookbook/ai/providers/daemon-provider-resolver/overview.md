
The daemon provider resolver is a stateless namespace — three operations
and no visual surface — that gives a headless host (the daemon) read-only
access to the AI-provider-configuration registry the main app pushes over
the provider-configuration sync component. Per its own documented contract
it is "the daemon-side registry read API — the mirror of the app's provider
resolver," reading "the config-identifier-keyed layout a headless host
receives via the provider-configuration sync so it can resolve a
configuration by id without the app." Hosts hand it a settings-reader
function over whatever backs the synced values (per the documented
contract, "a settings table"), so the resolver and its caller (the
daemon's chat-completion path) never see the settings store itself. Its
three operations answer: which configurations does the host currently
mirror (configurations), which one is selected for one-shot completions
(selected configuration), and what model is stored for a given
configuration (model lookup). It performs no writes, no network access, and
no logging of its own; every result is a pure function of what the supplied
function returns at the moment of the call.

