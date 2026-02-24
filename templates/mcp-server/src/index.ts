import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";

// Configuration from environment
const config = {
  apiKey: process.env.EXAMPLE_API_KEY,
  baseUrl: process.env.EXAMPLE_BASE_URL || "https://api.example.com",
  timeout: parseInt(process.env.EXAMPLE_TIMEOUT || "30000", 10),
};

if (!config.apiKey) {
  console.error("EXAMPLE_API_KEY environment variable is required");
  process.exit(1);
}

// Create MCP server
const server = new McpServer({
  name: "example-mcp-server",
  version: "1.0.0",
});

// Define tools
server.tool(
  "list_items",
  "List items from the service",
  {
    limit: z.number().optional().describe("Maximum items to return"),
    filter: z.string().optional().describe("Filter criteria"),
  },
  async ({ limit = 10, filter }) => {
    // TODO: Implement API call
    return {
      content: [
        {
          type: "text",
          text: JSON.stringify({ items: [], total: 0 }, null, 2),
        },
      ],
    };
  }
);

server.tool(
  "get_item",
  "Get details of a specific item",
  {
    id: z.string().describe("Item identifier"),
  },
  async ({ id }) => {
    // TODO: Implement API call
    return {
      content: [
        {
          type: "text",
          text: JSON.stringify({ id, name: "Example", status: "active" }, null, 2),
        },
      ],
    };
  }
);

// Start server
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("Example MCP Server running on stdio");
}

main().catch(console.error);
