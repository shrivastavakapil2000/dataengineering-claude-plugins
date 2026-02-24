# Example MCP Server

> MCP server for integrating with [service name]

## Overview

This MCP server provides Claude Code with access to [service], enabling:

- [Capability 1]
- [Capability 2]
- [Capability 3]

## Prerequisites

- Node.js 18+
- [Service] account with API access
- API key stored in environment or secrets manager

## Installation

### 1. Install the Server

```bash
cd plugins/mcp-servers/example-mcp-server
npm install
npm run build
```

### 2. Configure Claude Settings

Add to your `~/.claude/settings.json`:

```json
{
  "mcpServers": {
    "example": {
      "command": "node",
      "args": ["path/to/dist/index.js"],
      "env": {
        "EXAMPLE_API_KEY": "${EXAMPLE_API_KEY}"
      }
    }
  }
}
```

### 3. Set Environment Variables

```bash
export EXAMPLE_API_KEY="your-api-key"
```

Or use AWS Secrets Manager / SSM Parameter Store.

## Available Tools

### `example_list_items`

List items from the service.

**Parameters:**
- `limit` (optional): Maximum items to return (default: 10)
- `filter` (optional): Filter criteria

### `example_get_item`

Get details of a specific item.

**Parameters:**
- `id` (required): Item identifier

## Configuration

| Variable | Required | Description | Default |
|----------|----------|-------------|---------|
| `EXAMPLE_API_KEY` | Yes | API authentication key | - |
| `EXAMPLE_BASE_URL` | No | API base URL | `https://api.example.com` |

## Development

```bash
npm install
npm run build
npm start
npm test
```

## Changelog

### 1.0.0
- Initial release

## Author

Data Engineering Team
