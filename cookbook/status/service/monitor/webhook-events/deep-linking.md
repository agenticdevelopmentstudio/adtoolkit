
Not applicable: this file defines no application URL scheme or route of its own — it only maps an in-memory webhook body to an in-memory `ProviderDeploy` row or `null`; the HTTP routes that receive the webhooks (`` /hooks/vercel ``, `` /hooks/railway ``) belong to `routes/hooks.ts`, external to this file.

