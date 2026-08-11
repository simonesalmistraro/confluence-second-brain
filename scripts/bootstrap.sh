#!/usr/bin/env bash
# Per-developer setup for the Confluence second brain (Linux/macOS).
# Run: bash scripts/bootstrap.sh
#
# Installs: uv, opencode, basic-memory, confluence-markdown-exporter.
# Registers this repo as the Basic Memory project.
# Does NOT handle secrets: you run `opencode auth login` yourself afterwards.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "==> Repo root: $REPO_ROOT"

# 1. uv (Python toolchain)
if ! command -v uv >/dev/null 2>&1; then
    echo "==> Installing uv"
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
else
    echo "==> uv already installed: $(uv --version)"
fi

# 2. opencode
if ! command -v opencode >/dev/null 2>&1; then
    echo "==> Installing opencode"
    if command -v npm >/dev/null 2>&1; then
        npm install -g opencode-ai@latest
    else
        curl -fsSL https://opencode.ai/install | bash
    fi
else
    echo "==> opencode already installed: $(opencode --version)"
fi

# 3. Basic Memory + register this repo as the vault
echo "==> Installing basic-memory"
uv tool install basic-memory
echo "==> Registering vault project"
basic-memory project add main "$REPO_ROOT"

# 4. Confluence exporter (only needed if you run syncs locally; harmless otherwise)
echo "==> Installing confluence-markdown-exporter"
uv tool install confluence-markdown-exporter

cat <<'EOF'

Bootstrap done. Remaining manual steps:
  1. opencode auth login          (your model provider API key)
  2. opencode mcp auth atlassian  (optional, only for Confluence writes)
  3. If you run mirror syncs locally: cme config edit auth.confluence
     and set CONFLUENCE_SPACE_URL in your environment.
EOF
