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

# 3. Basic Memory + register this repo as the vault.
# basic-memory reserves a 'main' project at install time pointing at its own data
# dir, so `project add main <repo>` fails with "already exists with different path".
# Register the repo under a dedicated project name instead (idempotent on re-run)
# and make it the default. opencode.jsonc pins this same project on the MCP, so
# retrieval targets the repo vault regardless of the machine's global default.
BM_PROJECT="confluence-second-brain"
echo "==> Installing basic-memory"
uv tool install basic-memory
echo "==> Registering vault project '$BM_PROJECT'"
if basic-memory project list 2>/dev/null | grep -q "$BM_PROJECT"; then
    echo "==> Project '$BM_PROJECT' already registered; skipping add"
else
    basic-memory project add "$BM_PROJECT" "$REPO_ROOT"
fi
basic-memory project default "$BM_PROJECT"

# 4. Confluence exporter (only needed if you run syncs locally; harmless otherwise)
echo "==> Installing confluence-markdown-exporter"
uv tool install confluence-markdown-exporter

# Windows MAX_PATH-safe export layout (flat, depth 1). sync.* re-asserts this on
# every run; setting it here means even manual `cme` reads use the safe layout.
# See README "Windows path safety" for the rationale and the filename_length budget.
echo "==> Applying Windows-safe cme export layout"
cme config set export.page_path='{space_name}/{page_id}_{page_title}.md'
cme config set export.attachment_path='{space_name}/attachments/{attachment_file_id}{attachment_extension}'
cme config set export.filename_length=150
cme config set 'export.filename_encoding={"<":"_",">":"_",":":"_","\"":"_","/":"_","\\":"_","|":"_","?":"_","*":"_"}'

cat <<'EOF'

Bootstrap done. Remaining manual steps:
  1. opencode auth login   (your model provider API key)
  2. Confluence credentials, only needed for writes and fresh point-reads:
     cp scripts/env.example.sh ~/.confluence-brain.env
     then fill it in and source it from your shell profile.
       Cloud      CONFLUENCE_URL + CONFLUENCE_USERNAME + CONFLUENCE_API_TOKEN
       Server/DC  CONFLUENCE_URL + CONFLUENCE_PAT
     The Atlassian MCP server is fetched on demand by uvx; nothing to install.
  3. If you run mirror syncs locally: cme config edit auth.confluence
     and set CONFLUENCE_SPACE_URL in your environment.
EOF
