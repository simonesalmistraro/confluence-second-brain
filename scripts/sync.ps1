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

# Windows MAX_PATH safety (260-char TOTAL-path limit), asserted on every export so
# the committed mirror can never carry a path that breaks `git checkout` on Windows.
# The fix is flat layout (depth 1) — Confluence's ancestor breadcrumb is what blows
# the limit, not any single name. {page_id} keeps filenames unique even after the
# length cap truncates a long title, so truncation only ever costs readability.
# filename_length=150 leaves headroom under 260 for a deepish clone path; see
# README "Windows path safety" for the budget. These are cme global config, but a
# Windows-safe layout is a strictly-better default for this dedicated vault.
cme config set export.page_path='{space_name}/{page_id}_{page_title}.md'
cme config set export.attachment_path='{space_name}/attachments/{attachment_file_id}{attachment_extension}'
cme config set export.filename_length=150
cme config set 'export.filename_encoding={"<":"_",">":"_",":":"_","\"":"_","/":"_","\\":"_","|":"_","?":"_","*":"_"}'

Write-Host "==> Exporting $env:CONFLUENCE_SPACE_URL"
cme spaces $env:CONFLUENCE_SPACE_URL

Set-Location $RepoRoot
git add confluence-mirror
git commit -m "chore(mirror): confluence sync" --allow-empty
Write-Host "==> Sync committed. Push manually or let your remote job handle it."
