# Mirror sync: export the Confluence space to confluence-mirror/ and commit.
# Requires: cme configured (cme config edit auth.confluence, export.output_path
# pointing at <repo>/confluence-mirror), CONFLUENCE_SPACE_URL set.
#
# Schedule nightly, e.g.:
#   schtasks /Create /TN "ConfluenceMirrorSync" `
#     /TR "powershell -ExecutionPolicy Bypass -File <repo>\scripts\sync.ps1" `
#     /SC DAILY /ST 07:30

$ErrorActionPreference = "Stop"
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")

if (-not $env:CONFLUENCE_SPACE_URL) {
    Write-Error "CONFLUENCE_SPACE_URL is not set (e.g. https://<yoursite>.atlassian.net/wiki/spaces/<SPACEKEY>)"
    exit 1
}

Write-Host "==> Exporting $env:CONFLUENCE_SPACE_URL"
cme spaces $env:CONFLUENCE_SPACE_URL

Set-Location $RepoRoot
git add confluence-mirror
git commit -m "chore(mirror): confluence sync" --allow-empty
Write-Host "==> Sync committed. Push manually or let your remote job handle it."
