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

# 3. Basic Memory + register this repo as the vault
Write-Host "==> Installing basic-memory"
uv tool install basic-memory
Write-Host "==> Registering vault project"
basic-memory project add main $RepoRoot

# 4. Confluence exporter (only needed if you run syncs locally; harmless otherwise)
Write-Host "==> Installing confluence-markdown-exporter"
uv tool install confluence-markdown-exporter

Write-Host ""
Write-Host "Bootstrap done. Remaining manual steps:"
Write-Host "  1. opencode auth login          (your model provider API key)"
Write-Host "  2. opencode mcp auth atlassian  (optional, only for Confluence writes)"
Write-Host "  3. If you run mirror syncs locally: cme config edit auth.confluence"
Write-Host "     and set CONFLUENCE_SPACE_URL in your environment."
