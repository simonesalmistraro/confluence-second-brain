#!/usr/bin/env bash
# Mirror sync: export the Confluence space to confluence-mirror/ and commit.
# Requires: cme configured (cme config edit auth.confluence, export.output_path
# pointing at <repo>/confluence-mirror), CONFLUENCE_SPACE_URL set.
#
# Schedule via cron, e.g.:
#   30 7 * * * CONFLUENCE_SPACE_URL=https://... /path/to/repo/scripts/sync.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

: "${CONFLUENCE_SPACE_URL:?Set CONFLUENCE_SPACE_URL, e.g. https://<yoursite>.atlassian.net/wiki/spaces/<SPACEKEY>}"

echo "==> Exporting $CONFLUENCE_SPACE_URL"
cme spaces "$CONFLUENCE_SPACE_URL"

cd "$REPO_ROOT"
git add confluence-mirror
git commit -m "chore(mirror): confluence sync" --allow-empty
echo "==> Sync committed. Push manually or let your remote job handle it."
