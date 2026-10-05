
Not applicable: neither `providerConn` nor `enumerateDeployProjects` consults a feature-flag system; whether a given provider is configured is gated entirely by that provider's integration row being active and carrying a resolvable token (active-integration-filter, token-lookup-via-secrets), never a flag-service lookup.

