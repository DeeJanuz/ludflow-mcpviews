# Unreleased

- Replaced standalone Ludflow document, data governance, and Knowledge Dex page renderers with an embedded Ludflow app iframe backed by a one-time MCP OAuth handoff.
- Added the `ludflow_app` standalone renderer and declared Ludflow app `frame_origins` for MCPViews CSP allowlisting.
- Added iframe storage-access sandbox permission so WebKit/Tauri embeds can complete the Ludflow handoff before loading the real app.
