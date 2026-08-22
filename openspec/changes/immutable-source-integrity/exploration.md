# Exploration: Immutable Source Integrity for arys Study Repository

Topic (user intent, ES): repository to study "Administración de Redes y Seguridad"; `Bibliografia/` holds PDFs as the single source of truth; sources translated to Markdown for efficient querying; BOTH layers immutable; deterministic verification that no source was modified from its original state, enforced via a git pre-commit hook.

## Current State

- Greenfield repo at `C:\Users\gonza\arys`: git initialized on `main` with **zero commits**; everything untracked (`.atl/`, `bibliografia/`, `openspec/`). No application code, no build config, no tests (confirmed by `openspec/sdd-init-arys.json`).
- `bibliografia/` already exists containing one source PDF: `unidad-01-conceptos-de-seguridad.pdf` (~320 KB). On-disk name is lowercase; user intent says `Bibliografia`.
- Environment: Windows, PowerShell 5.1.26100.9168, Git 2.54.0.windows.1 (ships POSIX sh + coreutils `sha256sum`).
- `core.autocrlf=true`; `core.hooksPath` unset (hooks resolve to unversioned `.git/hooks/`).
- Artifact store: openspec (`openspec/sdd-init-arys.json`); conventional `config.yaml`/`specs/`/`changes/` tree not yet materialized.

## Affected Areas (all prospective — nothing exists yet)

- `bibliografia/` — protected layer #1 (PDFs, single source of truth). Casing must be decided before the first commit.
- Markdown layer location TBD (inside `bibliografia/` vs sibling directory) — open question for proposal.
- `.gitattributes` (new) — byte-stability prerequisite: pin `*.pdf binary`, pin EOL policy for `*.md`.
- Manifest file (new, e.g. `integrity/manifest.sha256` or JSON) — canonical SHA-256 registry of every immutable file.
- Hook assets (new): versioned `.githooks/pre-commit` shim + verification script (PowerShell) + register/re-baseline commands; activated via `git config core.hooksPath .githooks`.
- `README.md` (new) — bootstrap instructions and immutability policy.

## Approaches

1. **Committed hash manifest + pre-commit verifier** — a committed manifest records SHA-256 of every PDF and derived Markdown; the hook recomputes hashes of staged protected files and rejects the commit on any mismatch, missing entry, or unregistered addition.
   - Pros: deterministic and verifiable *anytime* (not only at commit), independent of git plumbing (`certutil`/`sha256sum -c` work outside git); manifest doubles as human-readable audit artifact; natural home for PDF↔MD traceability pairs; matches the user's stated mental model.
   - Cons: one extra maintained file; bootstrap ordering (first commit must carry sources + manifest together); still bypassable with `--no-verify`.
   - Effort: Medium.

2. **Git-native diff guard (no manifest)** — hook inspects `git diff --cached --name-status HEAD` for protected paths and blocks `M`/`D` unless the commit message carries an authorization marker (e.g. `[source-replace]`).
   - Pros: zero extra artifacts — git blob IDs already are content identity; simplest bootstrap (nothing to generate); immune to EOL drift (diff compares normalized blobs).
   - Cons: policy buried in hook logic; no standalone verification artifact; awkward first-commit edge case (no `HEAD`); weak audit/query story ("what is the canonical hash of X?" unanswerable without git archaeology); does not match user's stated "deterministic verification" framing as directly.
   - Effort: Low-Medium.

3. **Third-party tooling (pre-commit framework, husky, Git LFS)** — adopt an ecosystem manager for hooks or large-file handling.
   - Pros: cross-platform configs; managed hook installation.
   - Cons: requires Python/Node runtime on a dependency-free study repo; LFS adds smudge/clean filters and server requirements for ~MB-scale PDFs (unnecessary); opaque for a learning-focused repo.
   - Effort: Medium-High. Rejected for dependency weight.

## Recommendation

Approach 1 (committed manifest + pre-commit verifier), with these design anchors:

- **Hashing**: SHA-256 via `Get-FileHash` (PS 5.1 built-in) or Git-bundled `sha256sum`; manifest in `sha256sum -c`-compatible format (`<hash>␣␣<relative/path/with/forward/slashes>`).
- **Hook shape**: versioned `.githooks/pre-commit` (thin POSIX-sh shim, since Git executes hooks under sh) calling `powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools/integrity/verify.ps1`. Activation: `git config core.hooksPath .githooks` — one documented command per clone.
- **Byte stability**: `.gitattributes` pins `*.pdf binary` (or `-text`) and fixes the Markdown EOL policy (e.g. `*.md text eol=lf`), neutralizing the current `core.autocrlf=true` so hashes are stable across machines/checkouts. Hashes are computed over working-tree bytes only after normalization is guaranteed.
- **Bootstrap**: first commit establishes the baseline atomically — PDFs + generated manifest + `.gitattributes` + hooks land together; manifest generation is idempotent (`register` command adds/updates entries for declared source paths only).
- **Immutable ≠ never replaced**: a deliberate `re-baseline` command regenerates a file's manifest entry and appends a provenance record (old hash → new hash, date, reason). Unauthorized edits are rejected; replacements are audited events.
- **Traceability**: each Markdown file mirrors its PDF name and declares `source_pdf` + `source_sha256` (front matter or manifest pairing), so later queries can cite back to the authoritative PDF.
- **Scope boundary**: translation of PDFs into Markdown is a recurring authoring activity, not part of this change; this change delivers the structure + integrity machinery that registers whatever Markdown exists.

## Risks

- **`--no-verify` bypass**: client-side hooks are a guardrail, not a security boundary. Threat model here is accidental modification; acceptable residual risk for a single-user repo. If a remote is added later, a CI job running the same verify script closes the gap.
- **CRLF/hash instability**: with `core.autocrlf=true`, text-layer working-tree bytes vary by checkout config; without `.gitattributes` pinning, hashes break across machines. Highest-priority design constraint.
- **PowerShell 5.1 encoding traps**: `Out-File` defaults to UTF-16LE with BOM, which corrupts `sha256sum -c` formats; manifest and scripts must be written ASCII/UTF-8-without-BOM.
- **Directory casing**: disk shows `bibliografia`, intent says `Bibliografia`. Free to fix now (zero commits); painful after history exists on case-sensitive filesystems. Decide before first commit.
- **Hook activation is per-clone manual config** (`core.hooksPath` cannot be enforced by git itself — bootstrap chicken-and-egg). Mitigate with a README one-liner setup section.
- **Binary size growth**: fine at course scale (current PDF 320 KB); plain git preferred over LFS; watch GitHub's 100 MB hard limit only if the repo is ever pushed.
- **Untracked-source gap**: the hook can only judge staged files; sources must be registered (manifest entry) in the same commit they are added — enforce "new file in protected path ⇒ must appear in updated manifest".

## Ready for Proposal

Yes. Proposal should resolve these open questions with the user:
1. Canonical directory casing: `bibliografia` (as on disk) vs `Bibliografia` (as stated in intent)?
2. Where does the Markdown layer live — inside `bibliografia/` (e.g. `bibliografia/md/`) or a sibling top-level directory?
3. Confirm scope split: this change = repo skeleton + integrity machinery; PDF→Markdown translation happens per-unit afterwards and simply registers into the manifest.
