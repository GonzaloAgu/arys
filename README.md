# aryS - Course Source Material

Original course PDFs live in `bibliografia/`; their derived Markdown notes live
in `apuntes/`. Web-sourced theory companions are stored the same way: a plain-text
link file in `bibliografia/` naming the original URL, paired with its verbatim
Markdown mirror in `apuntes/`. All sources are protected by an append-only
SHA-256 manifest and a pre-commit hook that blocks unregistered or modified
sources.

## Layout

| Path | Purpose |
|------|---------|
| `bibliografia/*.pdf` | Original source PDFs (single source of truth, binary, never translated) |
| `bibliografia/*.txt` | Web-link sources: one line with a single absolute `http(s)://` URL |
| `apuntes/` | Derived Markdown notes, one per source (`X.pdf`/`X.txt` -> `X.md`) |
| `integrity/manifest.sha256` | Append-only registry: `<sha256>  <path>` per file |
| `.githooks/pre-commit` | Versioned hook shim (delegates to the verifier) |
| `tools/integrity/verify.ps1` | Pre-commit verifier over staged index blobs |
| `tools/integrity/register.ps1` | Additions-only pair registration helper |

## Setup (per clone)

```sh
git config core.hooksPath .githooks
```

That single command activates the integrity gate for this clone. It must be run
once after every fresh clone; hooks are versioned but never auto-activated.

Requirements: Git for Windows 2.x (bundles `sh` and `sha256sum`) and Windows
PowerShell 5.1. No other runtimes.

## Registering new material

Sources are immutable once registered. Adding material requires a paired
source + Markdown registration in one commit. A source is either a PDF
(`bibliografia/<stem>.pdf`) or a web link (`bibliografia/<stem>.txt`):

```sh
# 1. Put the source in bibliografia/ and its conversion in apuntes/
#    (same stem, lowercase [a-z0-9-] only), then stage BOTH:
git add bibliografia/<stem>.txt apuntes/<stem>.md

# 2. Register the pair (hashes staged blobs, rewrites the manifest sorted).
#    For a web link the .txt must be exactly one absolute http(s):// URL line:
powershell -NoProfile -ExecutionPolicy Bypass \
    -File tools/integrity/register.ps1 -Source bibliografia/<stem>.txt

# 3. Restage the rewritten manifest (completes stage -> register -> stage):
git add integrity/manifest.sha256

git commit   # verified by the pre-commit hook
```

Web-link sources (`*.txt`) are the sole provenance carrier: the link file names
the original URL, and the Markdown mirror in `apuntes/` is kept strictly
verbatim, with no added provenance header or editorial modification.

The helper refuses to run if either file is unstaged, stems are not
lowercase `[a-z0-9-]`, a link file does not hold a single absolute
`http(s)://` URL, another source (PDF or web) already uses the stem, or either
path already has a manifest entry.

## Deleting material (the sole exception)

Deletion is legal only as one atomic event, done manually. It applies the same
way to both source kinds — PDF and web link:

```sh
git rm bibliografia/<stem>.pdf apuntes/<stem>.md      # for a PDF source
git rm bibliografia/<stem>.txt apuntes/<stem>.md      # for a web-link source
# Remove BOTH matching lines from integrity/manifest.sha256,
# keeping the remaining entries sorted.
git add integrity/manifest.sha256
git commit   # history preserves files and entries leaving together
```

Partial deletions (one file without the other, or without entry removal) are
rejected by the hook. There is no update flow: to change content of a
registered source, delete the pair atomically and register a new pair.

## Verifying outside git

The manifest is standard `sha256sum -c` format (UTF-8, no BOM, LF):

```sh
sha256sum -c integrity/manifest.sha256
```

## Policy and limitations

Registered sources are expected to remain byte-stable forever. The hook hashes
staged index blobs, so local line-ending settings (`core.autocrlf`) cannot
cause drift, and unrelated working-tree noise is ignored.

**Honest disclosure:** this is a client-side guardrail against accidental
modification, NOT a security boundary. Anyone can bypass it with
`git commit --no-verify`, deactivate hooks per clone, or rewrite history.
If adversarial protection is ever needed, add server-side/CI verification.

**Web links and URL rot:** a `bibliografia/*.txt` link file is a pointer only —
its frozen snapshot lives in the paired `apuntes/*.md`, which stays independently
readable if the original URL ever changes or goes offline. Link freshness is not
monitored or verified; the immutable snapshot is the durable object of record.

## Removing the machinery (rollback)

```sh
git rm -r .githooks tools/integrity integrity .gitattributes
git config --unset core.hooksPath
```

Nothing else depends on it; sources on disk are untouched.
