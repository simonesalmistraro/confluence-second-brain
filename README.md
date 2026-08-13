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
      └── confluence-writer agent ── Atlassian MCP ── writes back to Confluence
                                                                  │
  notes/ ◄── team knowledge, written by humans and agents ────────┘
```

Works against **Confluence Cloud and Confluence Server/Data Center 6.0+**.
See [Cloud vs Server/Data Center](#cloud-vs-serverdata-center) — it changes
which credentials you need and the shape of every URL.

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
4. (Optional, for Confluence writes and fresh point-reads) set your Confluence
   credentials as environment variables. Copy `scripts/env.example.sh`, fill in
   the block matching your deployment, keep the filled copy outside the repo,
   and source it from your shell profile.
5. Start working: run `opencode` from the repo root. The project-level
   `opencode.jsonc` wires up Basic Memory and the Atlassian MCP automatically.

That is the entire per-developer footprint: clone, bootstrap, one API key, one
optional Confluence token. Everything else rides in through `git pull`.

## Cloud vs Server/Data Center

The Atlassian MCP server used here
([mcp-atlassian](https://github.com/sooperset/mcp-atlassian)) runs locally via
`uvx` and speaks both deployments. Nothing in `opencode.jsonc` needs editing —
the env vars you export decide which auth path is used.

|                  | Cloud                                          | Server / Data Center 6.0+                       |
|------------------|------------------------------------------------|-------------------------------------------------|
| `CONFLUENCE_URL` | `https://yoursite.atlassian.net`               | `https://wiki.example.com/confluence` — **include the context path** |
| Credential       | `CONFLUENCE_USERNAME` + `CONFLUENCE_API_TOKEN` | `CONFLUENCE_PAT` (Personal Access Token)        |
| Where to get it  | id.atlassian.com → API tokens                  | Confluence profile → Personal Access Tokens      |
| Space URL        | `.../wiki/spaces/<KEY>`                        | `.../confluence/display/<KEY>`                   |
| `cme` auth field | `username` + `api_token`                       | `pat`                                            |

Server/DC notes:

- **The context path is the most common misconfiguration.** If your wiki lives
  at `https://wiki.example.com/confluence/display/ENG`, then `CONFLUENCE_URL` is
  `https://wiki.example.com/confluence`, not the bare host. A bare host returns
  redirects that look like auth failures.
- **PATs bypass SSO by design.** If your instance is behind SAML/OIDC, that is
  the point of a PAT — but it also means the token is a full standing
  credential with your entire read scope, not a scoped app grant. Treat it as
  password-grade, set an expiry, and revoke it when you change teams.
- Older instances (pre-7.9) have no PAT support. Check profile → Personal
  Access Tokens; if the page is missing, talk to your Confluence admin rather
  than falling back to your own password.
- Atlassian's hosted remote MCP (`https://mcp.atlassian.com/v1/sse`) is
  **Cloud-only** and will never reach a self-hosted instance. If you are on
  Cloud and prefer it, swap the `atlassian` entry for
  `{"type": "remote", "url": "https://mcp.atlassian.com/v1/sse", "oauth": {}}`
  and run `opencode mcp auth atlassian`.

## Mirror sync (one maintainer, or CI)

The mirror is populated by [confluence-markdown-exporter](https://github.com/Spenhouet/confluence-markdown-exporter)
(`cme`). Exports are incremental: unchanged pages are skipped.

**Recommended: central sync.** One scheduled CI job runs the export with a
service account and commits the result. Developers only pull. See
[`ci-examples/`](ci-examples/) for GitHub Actions and GitLab CI sketches.

**Fallback: manual sync.** Any one person runs it locally:

```sh
# one-time auth setup: URL, then username + api_token (Cloud) or pat (Server/DC)
cme config edit auth.confluence
# point output at the mirror folder
cme config edit export.output_path

# then, nightly or whenever
scripts/sync.ps1        # Windows
scripts/sync.sh         # Linux/macOS
```

`cme` keys credentials by URL internally, so they cannot be passed as flat env
vars — they must go through `cme config edit`.

Set `CONFLUENCE_SPACE_URL` in your environment first:

- Cloud: `https://<yoursite>.atlassian.net/wiki/spaces/<SPACEKEY>`
- Server/DC: `https://<host>/<contextpath>/display/<SPACEKEY>`

Export one small space and inspect the output before scheduling anything.

### Windows path safety

Windows caps a **whole path** at 260 characters (`MAX_PATH`). Confluence's default
export nests each page under its full ancestor breadcrumb, so a deep tree with
long titles produces paths well over 260 — and `git checkout` on Windows then
fails with `Filename too long`, breaking the clone for every Windows dev.

This is fixed **at export**, not per-developer. `scripts/sync.*` assert a flat,
Windows-safe layout on every run (self-healing against config drift):

```sh
cme config set export.page_path='{space_name}/{page_id}_{page_title}.md'
cme config set export.attachment_path='{space_name}/attachments/{attachment_file_id}{attachment_extension}'
cme config set export.filename_length=150
# NOTE: no surrounding braces — cme wraps the value in {} itself before json.loads.
# Passing {...} double-wraps, fails to parse, and silently disables ALL sanitization.
cme config set 'export.filename_encoding="<":"_",">":"_",":":"_","\"":"_","/":"_","\\":"_","|":"_","?":"_","*":"_"'
```

- **Flat layout (depth 1)** is the real fix — the ancestor breadcrumb is what blows
  `MAX_PATH`, not any single filename. `{page_id}` prefix keeps files unique, so
  two pages with the same title never collide.
- **`filename_length=150`** is a belt, not the fix: it caps one filename component
  (default is 255, the NTFS per-name limit — it never bounds total path). The
  budget: `260 − clone_prefix − space_name − separators`. 150 survives a deepish
  clone like `C:\Users\me\Documents\repos\confluence-second-brain\`. Because
  `{page_id}` guarantees uniqueness, truncation only costs readability, never
  correctness — so shorten further if your clone path is deep, or raise it if
  it's short (`C:\csb\`).
- **`filename_encoding`** maps Windows-forbidden characters (`< > : " / \ | ? *`)
  so titles containing them don't produce illegal filenames.

No `LongPathsEnabled` registry edit or `git config core.longpaths` is required on
any machine — the mirror is safe by construction.

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
  already covers `*.env` and sync logs; keep it that way. This is why
  `opencode.jsonc` reads every credential through `{env:...}` and contains no
  literal values.
- **Internal hostnames are also disclosure.** On Server/Data Center the wiki
  URL is usually internal infrastructure. Keep it in your environment, not in a
  committed config — especially if your fork of this template is public.
- **A Server/DC PAT inherits your full read scope.** It is not a scoped app
  grant, and it bypasses SSO. Anything the mirror job can read, the token
  holder can read. Use a least-privilege service account for shared mirrors,
  set token expiry, and revoke on role change.
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
scripts/env.example.sh    Confluence credential template (copy outside the repo)
scripts/sync.ps1          mirror export + commit, Windows
scripts/sync.sh           mirror export + commit, Linux/macOS
ci-examples/              scheduled central sync sketches (GitHub Actions, GitLab CI)
```

## License

MIT. See [LICENSE](LICENSE).
