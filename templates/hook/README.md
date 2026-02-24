# Example Hook

> Automation hook that runs on [event]

## Overview

This hook triggers on [event] and performs [action].

## Installation

```bash
# Copy to your Claude hooks directory
cp -r plugins/hooks/example-hook ~/.claude/hooks/

# Make executable
chmod +x ~/.claude/hooks/example-hook/hook.sh
```

Add to your `~/.claude/settings.json`:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": {
          "tool": "Bash"
        },
        "command": "~/.claude/hooks/example-hook/hook.sh"
      }
    ]
  }
}
```

## Events

Available hook events:

| Event | Description | Input |
|-------|-------------|-------|
| `PreToolUse` | Before a tool is called | Tool name, input |
| `PostToolUse` | After a tool completes | Tool name, input, output |
| `Startup` | When Claude Code starts | Session info |
| `Shutdown` | When Claude Code exits | Session info |

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Success |
| `1` | Error - block action (pre-hooks only) |
| `2` | Error - continue anyway |

## Changelog

### 1.0.0
- Initial release

## Author

Data Engineering Team
