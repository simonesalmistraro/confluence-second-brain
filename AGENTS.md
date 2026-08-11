# Vault guide

This repository is a knowledge vault: a read-only Confluence mirror plus a
writable team notes layer, indexed by Basic Memory.

## Layout rules

- `confluence-mirror/` is a read-only nightly mirror of Confluence. **Never edit
  files there**; the sync job overwrites them. To change Confluence content, use
  the `confluence-writer` agent (Atlassian MCP tools).
- `notes/` is the working knowledge base. Write new knowledge there via
  basic-memory tools (`write_note`). One topic per file. Link related notes with
  `[[wikilinks]]`.
- Never write secrets, tokens, or credentials into any file in this vault.

## Retrieval order

1. `basic-memory` search first (hybrid full-text + semantic across the vault).
2. For bulk or exhaustive questions ("list every page that mentions X"), grep
   and read `confluence-mirror/` directly.
3. Atlassian MCP point-reads only when freshness matters (the page may have
   changed since last night's sync). Note the mirror is at most one day stale.

## Writing back to Confluence

- Only the `confluence-writer` agent has Atlassian tools enabled.
- Prefer updating an existing page over creating a new one; search for it first.
- After any write, state the page URL so a human can verify.

## Troubleshooting

- MCP server failing: `opencode mcp debug <name>`, then re-auth with
  `opencode mcp auth <name>` (OAuth tokens expire silently).
- Mirror looks stale: check the scheduled sync job before assuming pages moved.
- Search misses on vocabulary mismatch: try grep with synonyms across the
  mirror before concluding the knowledge is absent.
