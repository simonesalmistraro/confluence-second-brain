#!/usr/bin/env bash
# Mirror sync: export the Confluence space to confluence-mirror/ and commit.
# Requires: cme configured (cme config edit auth.confluence, export.output_path
# pointing at <repo>/confluence-mirror), CONFLUENCE_SPACE_URL set.
#
# Auth per deployment (cme config edit auth.confluence):
#   Cloud      url + username + api_token
#   Server/DC  url (include the context path) + pat, leave username/api_token blank
# cme keys credentials by URL, so they cannot be supplied as flat env vars.
#
# Schedule via cron, e.g.:
#   30 7 * * * CONFLUENCE_SPACE_URL=https://... /path/to/repo/scripts/sync.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Space URL shape differs by deployment:
#   Cloud      https://<yoursite>.atlassian.net/wiki/spaces/<SPACEKEY>
#   Server/DC  https://<host>/<contextpath>/display/<SPACEKEY>
: "${CONFLUENCE_SPACE_URL:?Set CONFLUENCE_SPACE_URL — Cloud: https://<yoursite>.atlassian.net/wiki/spaces/<KEY>, Server/DC: https://<host>/confluence/display/<KEY>}"

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

echo "==> Exporting $CONFLUENCE_SPACE_URL"
cme spaces "$CONFLUENCE_SPACE_URL"

cd "$REPO_ROOT"
git add confluence-mirror
git commit -m "chore(mirror): confluence sync" --allow-empty
echo "==> Sync committed. Push manually or let your remote job handle it."
