
Not applicable: Config Status reads the operator's own monitoring configuration and deploy-project metadata from the app's backend, stores it only in the in-memory shared cache, and handles no credentials or personal data (integration `tokenEnvVar` is an environment-variable name, not a secret).

