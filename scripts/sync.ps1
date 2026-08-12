# Mirror sync: export the Confluence space to confluence-mirror/ and commit.
# Requires: cme configured (cme config edit auth.confluence, export.output_path
# pointing at <repo>/confluence-mirror), CONFLUENCE_SPACE_URL set.
#
# Auth per deployment (cme config edit auth.confluence):
#   Cloud      url + username + api_token
#   Server/DC  url (include the context path) + pat, leave username/api_token blank
# cme keys credentials by URL, so they cannot be supplied as flat env vars.
#
# Schedule nightly, e.g.:
#   schtasks /Create /TN "ConfluenceMirrorSync" `
#     /TR "powershell -ExecutionPolicy Bypass -File <repo>\scripts\sync.ps1" `
#     /SC DAILY /ST 07:30

$ErrorActionPreference = "Stop"
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")

# Space URL shape differs by deployment:
#   Cloud      https://<yoursite>.atlassian.net/wiki/spaces/<SPACEKEY>
#   Server/DC  https://<host>/<contextpath>/display/<SPACEKEY>
if (-not $env:CONFLUENCE_SPACE_URL) {
    Write-Error "CONFLUENCE_SPACE_URL is not set. Cloud: https://<yoursite>.atlassian.net/wiki/spaces/<KEY> | Server/DC: https://<host>/confluence/display/<KEY>"
    exit 1
}

Write-Host "==> Exporting $env:CONFLUENCE_SPACE_URL"
cme spaces $env:CONFLUENCE_SPACE_URL

Set-Location $RepoRoot
git add confluence-mirror
git commit -m "chore(mirror): confluence sync" --allow-empty
Write-Host "==> Sync committed. Push manually or let your remote job handle it."
