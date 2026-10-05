
Not applicable: this file consults no feature-flag system. Its only on/off levers are `config.heartbeatUrl` and `config.alertWebhookUrl` each being `null` or not (documented under Configuration), and `opts.fullSync`, which is a caller-decided cadence value, not a flag lookup this file performs.

