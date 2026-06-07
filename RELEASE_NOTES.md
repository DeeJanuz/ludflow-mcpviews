# Unreleased

- Rebuild the Ludflow plugin as a production-channel `0.5.13` release so MCPViews installs a fresh artifact instead of reusing the stale local `0.5.12` bundle.
- Keep org-scoped authentication on the email-code flow by publishing the manifest with `email_code_auth.enabled` and renderer calls that pass `authFlow: "email_code"`.
- Point MCP, OAuth, and embedded Ludflow app handoff URLs at `https://app.ludflow.com` for production alignment with DecidR.
