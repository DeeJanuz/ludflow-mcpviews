# Ludflow MCP Views Plugin

Custom renderers for [Ludflow](https://ludflow.com) tools in [MCP Views](https://github.com/DeeJanuz/ludflow-mcpviews).

## Installation

Install via the MCP Views plugin registry:

```
mcp-views-cli plugin add ludflow
```

Or install manually by downloading the latest release ZIP and extracting to `~/.mcp-views/plugins/ludflow/`.

## Building

```bash
./build.sh
```

This produces `ludflow-plugin.zip` containing the manifest and all renderer files.
Production is the default build channel, and the build fails if the manifest or
embedded app origin points at staging. For a staging VM package, run:

```bash
LUDFLOW_MCPVIEWS_BUILD_CHANNEL=staging ./build.sh
```

## Multi-Org Auth

Ludflow uses org-scoped OAuth tokens in MCPViews.

- Use `list_organizations` to discover which organizations the user belongs to.
- MCPViews enriches those results with `has_mcpviews_token`, `mcpviews_token_status`, and `mcpviews_token_refreshable` so agents can see whether a given org is authenticated, refreshable, or missing local auth.
- For follow-up Ludflow tool calls in a non-default org, include `organization_id` in the tool arguments.
- If a target org has no stored token or is `expired_unrefreshable`, call `start_plugin_auth` with plugin `ludflow` and that `organization_id` before retrying. MCPViews opens the in-app email-code flow by default; use `auth_flow: "browser"` only for advanced OAuth recovery.

## Renderers

### Tool Views

| Renderer | Tools |
|----------|-------|
| `rich_content` | `list_organizations`, `search_codebase`, `vector_search`, `get_code_units`, `get_document`, `write_document`, `move_document`, `delete_document`, `list_documents`, `get_dependencies`, `get_file_content`, `get_module_overview`, `get_analysis_stats`, `get_column_context` |
| `structured_data` | `get_data_schema`, `get_data_lake_schema`, `manage_data_sources`, `manage_data_tables`, `manage_data_draft`, `get_business_concepts`, `manage_knowledge_entries` |

### Standalone App Pages

These renderers appear in the MCP Views app launcher and let users open Ludflow-style pages without leaving MCP Views:

| Renderer | Launcher Label | Purpose |
|----------|----------------|---------|
| `ludflow_documents_home` | `Documents` | Browse folders and documents, filter by status or sort order, and open document content in a new rich text tab with version switching |
| `ludflow_data_governance` | `Data Governance` | Explore data sources, inspect tables, drill into column context, and open the embedded Knowledge Dex panel |

The legacy `ludflow_knowledge_dex` renderer still exists as an alias, but it now opens the embedded Knowledge Dex view inside the Data Governance workspace instead of appearing as a separate launcher page.

## License

Proprietary — free to use, not open source. See [LICENSE](LICENSE) for details.
