# RTP Database MCP

Read-only access to the RTP PostgreSQL database for querying audiences, deliveries, vendors, and failed jobs.

## Setup

See [audience-delivery-mcp](https://github.com/resonate/audience-delivery-mcp) for full setup instructions.

### Claude Desktop Config

Add to `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "rtp_mcp": {
      "command": "<REPO_PATH>/audience-delivery-mcp/.venv/bin/python",
      "args": ["<REPO_PATH>/audience-delivery-mcp/rtp_mcp.py"],
      "env": {
        "RTP_DB_HOST": "pgprod01.proda.aws.resonatedigital.net",
        "RTP_DB_USER": "<YOUR_RTP_USERNAME>",
        "RTP_DB_PASSWORD": "<YOUR_RTP_PASSWORD>"
      }
    }
  }
}
```

## Tools

| Tool | Description |
|------|-------------|
| `execute_query` | Run arbitrary SELECT/WITH queries |
| `get_table_schema` | Get column schema for a table |
| `audience` | Get an audience by key |
| `audiences` | Paginated list of audiences |
| `get_vendor_segment_ids` | Get vendor audience keys for an audience |
| `get_failed_deliveries` | Active failed deliveries (error or stuck >6hrs) |
| `get_bad_state_deliveries` | Deliveries not delivered in 7 days, not scheduled today |
| `vendors` | List all vendors |
| `get_active_delivered_audiences` | Paginated active deliveries with vendor/account filter |
| `get_configuration_id_and_account_id` | Get config ID for an audience/vendor pair |
| `list_rtp_tables` | List all database tables |

## Requirements

- VPN access to Resonate internal network
- RTP database credentials
