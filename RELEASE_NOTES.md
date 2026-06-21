# v0.5.19

- Grant clipboard permissions to the embedded Ludflow iframe so document link and public share link copy actions work inside Windows WebView2.
- Add a build guard that fails packaging if the iframe loses `clipboard-write`.

# v0.5.18

- Render Ludflow through the shared DOM iframe path with `create_app_embed_session` only.
- Remove the failed external-tab priming workaround, `mcpviews_close`, and parent-window close sentinel behavior.
- Rely on Ludflow server-side scoped embed-session auth so Better Auth tokens remain hidden from plugin JavaScript.
- Document that custom initial embed targets are limited to `/` and `/data-governance`; Ludflow sanitizes unsupported paths to `/`.
