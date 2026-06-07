# Unreleased

- Bumped plugin release to `0.5.12` for staging embedded app tool discovery.
- Replaced standalone Ludflow document, data governance, and Knowledge Dex page renderers with an embedded Ludflow app iframe backed by a one-time MCP OAuth handoff.
- Added the `ludflow_app` standalone renderer and declared Ludflow app `frame_origins` for MCPViews CSP allowlisting.
- Added iframe storage-access sandbox permission so WebKit/Tauri embeds can complete the Ludflow handoff before loading the real app.
- Closed inactive native Ludflow panels on MCPViews tab switches so additional Ludflow renderer tabs can mount cleanly.
- Suppressed visible "Opening Ludflow" and "Loading Ludflow" transition copy while refreshing embedded app handoffs.
- Hid the native Ludflow child panel while MCPViews host overlays, such as the Apps launcher, are open so host chrome renders above the embedded app.
- Removed the embedded Ludflow wrapper toolbar/loading chrome so the real Ludflow app is the first visible interface.
- Pointed the local plugin package at staging Ludflow MCP/OAuth endpoints and added the `create_app_embed_session` renderer mapping so the embedded app handoff tool is discoverable.
