# Example Skill

> Brief one-line description

## Overview

[Detailed description of what this skill does and why it's useful]

## Installation

```bash
# Test locally
claude --plugin-dir ./plugins/skills/example-skill

# Or copy to your Claude skills directory
cp -r plugins/skills/example-skill ~/.claude/skills/
```

## Usage

```bash
# Basic usage
/example-skill <required-param>

# With options
/example-skill <required-param> --option value
```

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `param1` | Yes | Description |
| `--option` | No | Description (default: value) |

## Examples

### Example 1: Basic Usage

```
/example-skill my-input
```

Output:
```
[Expected output]
```

## Configuration

This skill can be configured via environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `EXAMPLE_VAR` | Description | `default` |

## Dependencies

- [Tool or service required]

## Troubleshooting

### Issue: [Common problem]

**Solution:** [How to fix it]

## Changelog

### 1.0.0
- Initial release

## Author

Data Engineering Team
