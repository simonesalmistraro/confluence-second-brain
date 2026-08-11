# Team notes

Writable knowledge layer. Everything here is indexed by Basic Memory alongside
the Confluence mirror.

Conventions:

- **One topic per file**, kebab-case filename (`payment-retry-logic.md`). Small
  files merge cleanly in git; one big file guarantees conflicts.
- **Link related notes** with `[[wikilinks]]`. Basic Memory turns these into
  graph relations.
- **Optional structure** Basic Memory understands (plain markdown works too):

  ```markdown
  ---
  title: Payment retry logic
  tags: [payments, runbook]
  ---

  # Payment retry logic

  ## Observations
  - [decision] Retries capped at 3 to avoid duplicate-charge risk
  - [gotcha] The queue redelivers on consumer timeout, not on nack

  ## Relations
  - relates_to [[payment-service-overview]]
  ```

- **Pull before a session, push after.** Plain git is the sync mechanism;
  do not build anything fancier until this actually hurts.
- **No secrets.** Ever. This folder is shared and indexed.
