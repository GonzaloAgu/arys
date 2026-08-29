# Proposal: Immutable Source Integrity

## Intent

Course PDFs in `bibliografia/` and their derived Markdown must stay provably unmodified. Nothing enforces this today (zero commits) and `core.autocrlf=true` destabilizes text bytes across checkouts. This change ships the repo skeleton plus integrity machinery that blocks edits or silent loss of registered sources at commit time.

## Scope

### In Scope

- Layout: `bibliografia/` (PDFs) plus sibling Markdown layer `apuntes/` (name fixed at design).
- `.gitattributes`: `*.pdf binary`, `*.md text eol=lf` — byte-stability precondition.
- Append-only SHA-256 manifest, standard `sha256sum -c` format, UTF-8 no BOM.
- `.githooks/pre-commit` shim calling a PowerShell 5.1 verifier; register helper (additions only).
- Atomic bootstrap commit: sources + manifest + attributes + hooks together.
- `README.md`: per-clone activation (`git config core.hooksPath .githooks`), policy, honest `--no-verify` limitation.

### Out of Scope

- PDF→Markdown conversion tooling (manual activity; machinery enforces pairing only).
- Re-baseline/replacement flows; LFS; CI; server-side enforcement.

## Capabilities

### New Capabilities

- `protected-source-layout`: protected directories plus `.gitattributes` byte-stability rules.
- `source-manifest`: format, append-only registration, sole deletion exception (file + entry removed together in one auditable commit).
- `integrity-pre-commit-hook`: blocking conditions, PDF↔MD pairing, activation model, bypass disclosure.

### Modified Capabilities

None (greenfield).

## Approach

Committed manifest + pre-commit verifier (exploration option 1). Product decisions override exploration: no marker, no re-baseline — any content change to registered files is rejected; deletion is legal only when its manifest entry leaves in the same commit (traceability = manifest-diff history). Every PDF registered post-bootstrap requires its converted `.md` registered in that same commit; the baseline grandfathers existing sources. Verifier hashes staged index blobs, never working-tree bytes, eliminating autocrlf drift. Generated files written BOM-free via `UTF8Encoding($false)` (PS 5.1 `Out-File` defaults forbidden).

## Proposal Question Round

Exploration questions were answered upstream (binding). One assumption needs user review: bootstrap grandfathers `unidad-01-conceptos-de-seguridad.pdf` without an MD counterpart yet, since conversion is out of scope. Exact names (`apuntes/`, manifest path) are delegated to design.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `bibliografia/`, `apuntes/` | New | Protected layers |
| `.gitattributes` | New | EOL/binary pinning |
| `integrity/manifest.sha256` | New | Append-only registry |
| `.githooks/pre-commit`, `tools/integrity/*.ps1` | New | Shim + verify/register scripts |
| `README.md` | New | Setup, policy, limitations |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| `--no-verify` bypass (client-side guardrail) | Med | Disclosed; optional future CI |
| Hash drift from autocrlf | High | Attributes pinned; hash staged blobs |
| PS 5.1 UTF-16/BOM corruption | Med | BOM-free .NET writes; round-trip test |
| Fresh clones lack active hooks | High | README setup step; fail-closed errors |

## Rollback Plan

Delete `.githooks/`, `tools/integrity/`, manifest, `.gitattributes`; unset `core.hooksPath`. Nothing else depends on the machinery. Post-bootstrap, one revert restores the pristine tree; sources remain untouched on disk.

## Dependencies

Git 2.54 Windows (bundled sh + `sha256sum`), PowerShell 5.1 (`Get-FileHash`). No external runtimes.

## Success Criteria

- [ ] Bootstrap carries sources + manifest + attributes + hooks; fresh clone passes `sha256sum -c` after setup.
- [ ] Pre-commit rejects modified registered files, unregistered additions, unpaired new PDFs, deletions without manifest-entry removal.
- [ ] Manifest is BOM-free and verifiable outside git.
