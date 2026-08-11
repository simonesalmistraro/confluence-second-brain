# Confluence Second Brain

Turn a Confluence space into a grep-first, agent-ready knowledge vault: a nightly
markdown mirror, a shared notes layer, and [Basic Memory](https://github.com/basicmachines-co/basic-memory)
wired into [opencode](https://opencode.ai) so every developer on the team gets the
same setup by cloning one repo.

No vector database. No embedding pipeline. Plain markdown plus agentic retrieval
(search, grep, read) covers wiki-scale corpora, and you can add heavier RAG later
if you ever prove you need it.

## Architecture

```
                       nightly CI job (service account)
  Confluence Cloud ──────────────────────────────────────► confluence-mirror/
                                                                  │
  developers ──── git clone / pull ───────────────────────────────┤
                                                                  ▼
  opencode ── opencode.jsonc (auto-loaded) ── Basic Memory MCP ── vault
      │                                                           ▲
      └── confluence-writer agent ── Atlassian remote MCP ── writes back to Confluence
                                                                  │
  notes/ ◄── team knowledge, written by humans and agents ────────┘
```

Two content layers:

- `confluence-mirror/` is a **read-only** export of your Confluence space,
  refreshed by a scheduled job. Never edit it by hand; the sync overwrites it.
- `notes/` is the **writable** team knowledge base. This is where value compounds:
  decisions, gotchas, runbooks, anything the wiki does not capture.

## Quickstart (per developer)

1. Clone this repo (your team's fork of it, with the mirror populated).
2. Run the bootstrap script:
   - Windows: `powershell -ExecutionPolicy Bypass -File scripts\bootstrap.ps1`
   - Linux/macOS: `bash scripts/bootstrap.sh`
3. Authenticate your model provider: `opencode auth login`
4. Start working: run `opencode` from the repo root. The project-level
   `opencode.jsonc` wires up Basic Memory and the Atlassian MCP automatically.
5. (Optional, for Confluence writes) authorize the Atlassian remote MCP:
   `opencode mcp auth atlassian`

That is the entire per-developer footprint: clone, bootstrap, one API key,
one optional OAuth. Everything else rides in through `git pull`.

## Mirror sync (one maintainer, or CI)

The mirror is populated by [confluence-markdown-exporter](https://github.com/Spenhouet/confluence-markdown-exporter)
(`cme`). Exports are incremental: unchanged pages are skipped.

**Recommended: central sync.** One scheduled CI job runs the export with a
service account and commits the result. Developers only pull. See
[`ci-examples/`](ci-examples/) for GitHub Actions and GitLab CI sketches.

**Fallback: manual sync.** Any one person runs it locally:

```sh
# one-time auth setup (URL, username, API token)
cme config edit auth.confluence
# point output at the mirror folder
cme config edit export.output_path

# then, nightly or whenever
scripts/sync.ps1        # Windows
scripts/sync.sh         # Linux/macOS
```

Set `CONFLUENCE_SPACE_URL` in your environment first, e.g.
`https://<yoursite>.atlassian.net/wiki/spaces/<SPACEKEY>`.

## Security model. Read this before you share anything.

A markdown mirror **flattens Confluence ACLs**. The export contains every page
the exporting account can read, and repo access replaces per-page permissions.

- **Use a service account with least privilege** for the central sync, scoped to
  only the spaces this team should see. Never populate a shared mirror with a
  personal token: your personal account almost certainly reads more than your
  teammates are entitled to.
- **Repo audience must be a subset of the space audience.** If anyone with repo
  access could not open the space in Confluence, the setup is leaking.
- **This template repo is public and content-free by design.** Your team's fork,
  which holds the actual mirror and notes, must live on a private/internal
  remote. Check where a remote points before you push.
- **Tokens live in environment variables, OS credential stores, or CI secrets.**
  Never in the vault, the config files in this repo, or a commit. `.gitignore`
  already covers `*.env` and sync logs; keep it that way.
- **Model endpoint is data egress.** Sending wiki content to an LLM API is an
  export of company data. Confirm which endpoint is sanctioned by your
  organization (direct API, cloud tenant, internal gateway) in writing before
  the first sync ever runs.

## Retrieval philosophy

Order of operations for the agent (encoded in `AGENTS.md`):

1. `basic-memory` search (hybrid full-text + semantic over the whole vault)
2. grep/read the mirror directly for bulk or exhaustive questions
3. Atlassian MCP point-reads only for freshness (something changed today)

Do not add a vector pipeline until you have concrete examples of questions this
setup failed to answer. Flat storage plus a competent agent goes much further
than most teams expect, and every layer you skip is a layer nobody maintains.

## Writing to Confluence

The `confluence-writer` agent (defined in `opencode.jsonc`) is the only place
Atlassian MCP tools are enabled. This keeps dozens of tool schemas out of your
token budget on every normal prompt. Invoke it explicitly when you want to
create or update a Confluence page; verify the result in the browser the first
few times.

## Repo layout

```
opencode.jsonc            project config: models, MCP servers, agents, tool scoping
AGENTS.md                 instructions the agent loads: layout, retrieval order, rules
confluence-mirror/        read-only nightly export (empty in this template)
notes/                    writable team knowledge base
scripts/bootstrap.ps1     per-developer setup, Windows
scripts/bootstrap.sh      per-developer setup, Linux/macOS
scripts/sync.ps1          mirror export + commit, Windows
scripts/sync.sh           mirror export + commit, Linux/macOS
ci-examples/              scheduled central sync sketches (GitHub Actions, GitLab CI)
```

## License

MIT. See [LICENSE](LICENSE).
