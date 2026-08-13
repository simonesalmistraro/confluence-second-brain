# Per-developer setup for the Confluence second brain (Windows 11).
# Run from anywhere: powershell -ExecutionPolicy Bypass -File scripts\bootstrap.ps1
#
# Installs: uv, opencode, basic-memory, confluence-markdown-exporter.
# Registers this repo as the Basic Memory project.
# Does NOT handle secrets: you run `opencode auth login` yourself afterwards.

$ErrorActionPreference = "Stop"
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")

function Test-Command($name) {
    return [bool](Get-Command $name -ErrorAction SilentlyContinue)
}

Write-Host "==> Repo root: $RepoRoot"

# 1. uv (Python toolchain)
if (-not (Test-Command "uv")) {
    Write-Host "==> Installing uv"
    powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
    $env:Path = "$env:USERPROFILE\.local\bin;$env:Path"
} else {
    Write-Host "==> uv already installed: $(uv --version)"
}

# 2. opencode (needs Node; install Node via winget first if missing)
if (-not (Test-Command "npm")) {
    Write-Host "==> Node not found, installing via winget"
    winget install OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements
    Write-Host "==> Restart this shell if npm is still not found, then re-run bootstrap."
}
if (-not (Test-Command "opencode")) {
    Write-Host "==> Installing opencode"
    npm install -g opencode-ai@latest
} else {
    Write-Host "==> opencode already installed: $(opencode --version)"
}

# 3. Basic Memory + register this repo as the vault.
# basic-memory reserves a 'main' project at install time pointing at its own data
# dir, so `project add main <repo>` fails with "already exists with different path".
# Register the repo under a dedicated project name instead (idempotent on re-run)
# and make it the default. opencode.jsonc pins this same project on the MCP, so
# retrieval targets the repo vault regardless of the machine's global default.
$BmProject = "confluence-second-brain"
Write-Host "==> Installing basic-memory"
uv tool install basic-memory
Write-Host "==> Registering vault project '$BmProject'"
$bmProjects = (basic-memory project list 2>$null | Out-String)
if ($bmProjects -match [regex]::Escape($BmProject)) {
    Write-Host "==> Project '$BmProject' already registered; skipping add"
} else {
    basic-memory project add $BmProject $RepoRoot
}
basic-memory project default $BmProject

# 4. Confluence exporter (only needed if you run syncs locally; harmless otherwise)
Write-Host "==> Installing confluence-markdown-exporter"
uv tool install confluence-markdown-exporter

# Windows MAX_PATH-safe export layout (flat, depth 1). sync.* re-asserts this on
# every run; setting it here means even manual `cme` reads use the safe layout.
# See README "Windows path safety" for the rationale and the filename_length budget.
Write-Host "==> Applying Windows-safe cme export layout"
cme config set export.page_path='{space_name}/{page_id}_{page_title}.md'
cme config set export.attachment_path='{space_name}/attachments/{attachment_file_id}{attachment_extension}'
cme config set export.filename_length=150
# NOTE: cme's parse_encode_setting wraps this value in {} itself before json.loads,
# so the value must NOT include braces — passing {...} double-wraps, fails to parse,
# and silently yields an EMPTY map (no sanitization → forbidden chars like > survive).
cme config set 'export.filename_encoding="<":"_",">":"_",":":"_","\"":"_","/":"_","\\":"_","|":"_","?":"_","*":"_"'

Write-Host ""
Write-Host "Bootstrap done. Remaining manual steps:"
Write-Host "  1. opencode auth login   (your model provider API key)"
Write-Host "  2. Confluence credentials, only needed for writes and fresh point-reads."
Write-Host "     See scripts\env.example.sh for the variable list, then set them as"
Write-Host "     user environment variables (System > Environment Variables):"
Write-Host "       Cloud      CONFLUENCE_URL + CONFLUENCE_USERNAME + CONFLUENCE_API_TOKEN"
Write-Host "       Server/DC  CONFLUENCE_URL + CONFLUENCE_PAT"
Write-Host "     The Atlassian MCP server is fetched on demand by uvx; nothing to install."
Write-Host "  3. If you run mirror syncs locally: cme config edit auth.confluence"
Write-Host "     and set CONFLUENCE_SPACE_URL in your environment."
