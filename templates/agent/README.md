# Example Agent

> Specialized agent for [purpose]

## Overview

This agent is optimized for [specific domain or task type]. It provides:

- [Capability 1]
- [Capability 2]
- [Capability 3]

## Installation

```bash
# Copy to your Claude agents directory
cp -r plugins/agents/example-agent ~/.claude/agents/
```

## Usage

The agent is automatically available to Claude Code when installed. It can be invoked via the Task tool:

```
Task(subagent_type="example-agent", prompt="Your task description")
```

## Configuration

Edit the `manifest.json` to customize:

| Setting | Description | Default |
|---------|-------------|---------|
| `model` | LLM model to use | `sonnet` |
| `maxTurns` | Maximum conversation turns | `50` |

## Limitations

- [Known limitation 1]
- [Known limitation 2]

## Changelog

### 1.0.0
- Initial release

## Author

Data Engineering Team
