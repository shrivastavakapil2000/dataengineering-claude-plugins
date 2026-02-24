#!/bin/bash
# Example Hook Script
#
# This script is called by Claude Code on the configured event.
# Input is provided via stdin as JSON.
#
# Exit codes:
#   0 - Success, continue normally
#   1 - Error, block the action (for pre-hooks)
#   2 - Error, but continue anyway

set -euo pipefail

# Read input from stdin
INPUT=$(cat)

# Parse relevant fields (example for PostToolUse)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // empty')

# Your hook logic here
case "$TOOL_NAME" in
  "Bash")
    # Example: Log bash commands
    echo "Bash command executed" >&2
    ;;
  *)
    # No action for other tools
    ;;
esac

# Output (optional) - will be shown to Claude
# echo '{"message": "Hook completed successfully"}'

exit 0
