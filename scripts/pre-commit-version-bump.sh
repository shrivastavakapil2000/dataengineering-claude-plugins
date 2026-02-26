#!/usr/bin/env bash
# pre-commit hook: auto-bump plugin patch versions when plugin files change.
# Keeps manifest.json, registry.json, and marketplace.json in sync.
#
# Install: npm run setup-hooks
set -euo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
REGISTRY="$REPO_ROOT/plugins/registry.json"
MARKETPLACE="$REPO_ROOT/.claude-plugin/marketplace.json"
SKILLS_DIR="$REPO_ROOT/plugins/skills"

# --- Dependency check ---
if ! command -v jq &>/dev/null; then
    echo "pre-commit: jq not found, skipping version bump" >&2
    exit 0
fi

# --- Phase 1: Detect changed plugins ---
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACMR)
CHANGED_PLUGINS=()

while IFS= read -r file; do
    if [[ "$file" =~ ^plugins/skills/([^/]+)/ ]]; then
        plugin_name="${BASH_REMATCH[1]}"
        # Deduplicate
        if [[ ! " ${CHANGED_PLUGINS[*]:-} " =~ " $plugin_name " ]]; then
            CHANGED_PLUGINS+=("$plugin_name")
        fi
    fi
done <<< "$STAGED_FILES"

if [[ ${#CHANGED_PLUGINS[@]} -eq 0 ]]; then
    exit 0
fi

# --- Phase 2 & 3: Bump each changed plugin ---
BUMPED_ANY=false

for plugin_name in "${CHANGED_PLUGINS[@]}"; do
    MANIFEST="$SKILLS_DIR/$plugin_name/manifest.json"

    if [[ ! -f "$MANIFEST" ]]; then
        echo "pre-commit: $plugin_name has no manifest.json, skipping" >&2
        continue
    fi

    # Idempotency: if manifest is already staged with a higher version than HEAD, skip
    STAGED_VER=$(git show ":plugins/skills/$plugin_name/manifest.json" 2>/dev/null | jq -r '.version // empty' 2>/dev/null || echo "")
    HEAD_VER=$(git show "HEAD:plugins/skills/$plugin_name/manifest.json" 2>/dev/null | jq -r '.version // empty' 2>/dev/null || echo "0.0.0")

    if [[ -n "$STAGED_VER" && "$STAGED_VER" != "$HEAD_VER" ]]; then
        echo "pre-commit: $plugin_name already bumped ($HEAD_VER -> $STAGED_VER), skipping"
        continue
    fi

    # Read current version from working tree
    CURRENT_VER=$(jq -r '.version // empty' "$MANIFEST")
    if [[ -z "$CURRENT_VER" ]]; then
        echo "pre-commit: $plugin_name manifest.json missing version field, skipping" >&2
        continue
    fi

    IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VER"
    NEW_PATCH=$((PATCH + 1))
    NEW_VER="$MAJOR.$MINOR.$NEW_PATCH"

    # Update manifest.json
    TMP=$(mktemp "$MANIFEST.XXXXXX")
    trap "rm -f '$TMP'" EXIT
    jq --arg v "$NEW_VER" '.version = $v' "$MANIFEST" > "$TMP" && mv "$TMP" "$MANIFEST"

    # Update registry.json
    TMP=$(mktemp "$REGISTRY.XXXXXX")
    jq --arg n "$plugin_name" --arg v "$NEW_VER" \
        '(.plugins[] | select(.name == $n)).version = $v' "$REGISTRY" > "$TMP" && mv "$TMP" "$REGISTRY"

    # Update marketplace.json
    TMP=$(mktemp "$MARKETPLACE.XXXXXX")
    jq --arg n "$plugin_name" --arg v "$NEW_VER" \
        '(.plugins[] | select(.name == $n)).version = $v' "$MARKETPLACE" > "$TMP" && mv "$TMP" "$MARKETPLACE"

    echo "pre-commit: bumped $plugin_name $CURRENT_VER -> $NEW_VER"
    BUMPED_ANY=true
done

# --- Phase 4: Update lastUpdated and re-stage ---
if [[ "$BUMPED_ANY" == true ]]; then
    TMP=$(mktemp "$REGISTRY.XXXXXX")
    jq --arg d "$(date +%Y-%m-%d)" '.lastUpdated = $d' "$REGISTRY" > "$TMP" && mv "$TMP" "$REGISTRY"

    git add "$REGISTRY" "$MARKETPLACE"
    for plugin_name in "${CHANGED_PLUGINS[@]}"; do
        if [[ -f "$SKILLS_DIR/$plugin_name/manifest.json" ]]; then
            git add "$SKILLS_DIR/$plugin_name/manifest.json"
        fi
    done
fi

exit 0
