# Archive Report: web-source-category

**Archived on**: 2026-08-29
**Artifact store mode**: hybrid — OpenSpec filesystem (`openspec/changes/` + `openspec/specs/`) with verification evidence persisted to Engram (`sdd/web-source-category/verify-report`, observation id 32); this archive report is persisted both in-tree and to Engram (`sdd/web-source-category/archive-report`).
**Source of truth**: `openspec/specs/{domain}/spec.md` (created/updated during this archive)

## Goal

The integrity system only understood physical sources: `bibliografia/X.pdf` ↔ `apuntes/X.md`. This change added a second fully protected source category — **web sources**: a plain-text link file `bibliografia/{stem}.txt` holding one absolute `http(s)://` URL, paired with a verbatim Markdown mirror `apuntes/{stem}.md`, both registered immutable in the append-only SHA-256 manifest and enforced by the pre-commit hook exactly like PDFs, without touching a single pre-existing manifest entry or the PDF category.

## What Shipped

- **`bibliografia/unidad-01-teoria-web.txt`** — link file, single line: `https://bzappellini.github.io/ARyS/unidades/u01-conceptos-seguridad/teoria.md` (BOM-free, LF).
- **`apuntes/unidad-01-teoria-web.md`** — verbatim mirror, 193 lines, byte-identical to proposal Appendix A lines 105–297 (the fetched `teoria.md` content, no provenance header).
- **`integrity/manifest.sha256`** — 4 lines; the 2 pre-existing lines byte-identical; ordinal order `apuntes/unidad-01-conceptos-de-seguridad.md`, `apuntes/unidad-01-teoria-web.md`, `bibliografia/unidad-01-conceptos-de-seguridad.pdf`, `bibliografia/unidad-01-teoria-web.txt`.
- **`tools/integrity/verify.ps1`** — kind dispatch generalized (`Get-SourceKind`, `Get-MirrorCandidates`), web checks, duplicate-stem check; stays pure-hash over staged index blobs (no URL/freshness fetching).
- **`tools/integrity/register.ps1`** — `-Pdf` → `-Source`, kind from extension, registration-time URL validation (single absolute `http(s)://` line, over the staged blob), cross-kind single-source-per-stem refusal, append-only unchanged.
- **`.gitattributes`** — `*.txt text eol=lf` added.
- **Test harness** — web-*, mirror-*, eol-*, helper-04 cases; baseline-agnostic runner (67 cases).
- **`README.md`** — web-source layout row, `-Source` register flow, web delete flow, URL-rot disclosure.

## Commits (7 on main)

| Commit | Message |
|--------|---------|
| `6932914` | feat: generalize integrity system to web source category |
| `abc3c0d` | fix: run cross-kind stem check before append-only in register |
| `8e61fb3` | test: add web-category cases to integrity harness |
| `9e8ae39` | test: fix web half-pair deletion cases to drop the removed line |
| `b834f03` | feat: register unit-1 web theory pair |
| `8693efe` | test: make harness baseline-agnostic and complete web-source apply docs |
| `3dc56d6` | docs: mark task 6.3 verified (22/22 scenarios covered) |

Plus this archive commit: `docs: archive web-source-category change`.

## Verification Evidence (final state at close)

Verification is **COMPLETE** — `sdd/web-source-category/verify-report` (Engram observation id 32), validator-accepted envelope:

| Gate | Result |
|------|--------|
| Verdict | `pass_with_warnings` |
| Blockers | 0 |
| Critical findings | 0 |
| Requirements | 9/9 |
| Scenarios | 22/22 |
| Harness tests at verify time | `pass=67 fail=0 total=67` (exit 0) — validator `test_hash sha256:a4879fb0…`, `build_hash sha256:d55b1bfa…` |
| Manifest gate | `sha256sum -c integrity/manifest.sha256` → 4x OK, exit 0 |
| Tasks (persisted `tasks.md`, archived) | 27/27 checked, 0 unchecked (incl. 6.1, 6.2, 6.3) |
| Native review gate | Absent (receipt-driven development not active for this change) |

Final-State Authority notes: the launch-time final-state facts (harness re-ran to 67/67, manifest 4x OK, tasks 6.1–6.3 all checked) agree with the persisted `verify-report` (observation 32) and with the archived `tasks.md` (27/27 `[x]`). No contradiction required reconciliation. The verify-time completeness snapshot in observation 32 ("21/22 tasks, 1 incomplete — 6.3 resolved below by this verify") predates commit `3dc56d6` which marks 6.3 checked; the archived tasks artifact is the terminal record.

### Scenario coverage (22/22 delta scenarios, 0 gaps)

- **web-source-layout (5)**: link file one absolute URL; mirror verbatim; duplicate stem rejected; cross-kind ≤1 source/stem; EOL stable across machines.
- **source-manifest (8)**: new pair appends two lines; web pair appends exactly two; unpaired source refused; link without URL refused; duplicate stem refused; entry mutation refused; atomic pair deletion; partial removal invalid.
- **integrity-pre-commit-hook (9)**: modified registered source blocked; unpaired new source blocked; modified registered web link blocked; half-pair web deletion blocked; duplicate-stem source blocked; deletion without entry removal blocked; manifest tampering blocked; working-tree noise ignored; complete web pair accepted.

## WARNING (non-blocking, traceable)

`verify-report` (observation 32) records one WARNING: **design.md rollout step labels the mirror range as "proposal.md lines 105–296 inclusive"** (design.md line 210; the same label appears in tasks.md task 5.2), but the actual committed range is **lines 105–297** — the design's own described endpoint ("from `# Unidad 1 — Conceptos de Seguridad` through `- Ley 25.326 (Argentina) — Protección de los Datos Personales.`") matches 105–297. This is an off-by-one **doc label only**; the deliverable is correct (committed mirror = 193 lines = Appendix A 105–297, byte-identity asserted by verify and `sha256sum -c`). Recorded here so the discrepancy is traceable; no spec scenario covers the label and no test fails. Also noted as SUGGESTION (cosmetic): register.ps1 `Parse-ManifestBytes` indentation (lines 147–151) differs from verify.ps1, semantically identical.

## Specs Synced (delta → main source of truth)

Merge followed OpenSpec delta conventions: MODIFIED requirement blocks replaced wholesale (including the authored `(Previously: …)` annotations), all non-delta requirements preserved.

| Domain | Action | Requirements carried |
|--------|--------|---------------------|
| web-source-layout | **Created** (greenfield, mechanical copy) | 5 (Link-file content contract, Verbatim Markdown mirror, Stem rules and collision avoidance, Cross-kind single source per stem, Byte-stability attributes) |
| source-manifest | **Updated** (2 MODIFIED: Append-only registration, Deletion is the sole exception) | 5 total preserved — Manifest format/encoding, Entry identity, Strict bootstrap unchanged |
| integrity-pre-commit-hook | **Updated** (2 MODIFIED: Blocking conditions, Verification over staged index blobs) | 6 total preserved — Versioned hook, Bootstrap readiness, Fail-closed, Bypass disclosure unchanged |

Main spec files:
- `openspec/specs/web-source-layout/spec.md` (new)
- `openspec/specs/source-manifest/spec.md` (merged; now 13 scenarios)
- `openspec/specs/integrity-pre-commit-hook/spec.md` (merged; now 15 scenarios)

Requirement/scenario counts after merge (5+13, 6+15, 5) reconcile with the verify report's authoritatitive 9/9 delta requirements and 22/22 delta scenarios.

## Archive Move

Change folder moved (mechanical `git mv`) to:
- `openspec/changes/archive/2026-08-29-web-source-category/`

The active changes directory `openspec/changes/` now contains only `archive/`.

### Archive contents (6 files, byte-identical to pre-move snapshot)
- `proposal.md`
- `design.md`
- `tasks.md` (27/27 complete)
- `specs/web-source-layout/spec.md`
- `specs/source-manifest/spec.md`
- `specs/integrity-pre-commit-hook/spec.md`

Verification evidence for this change lives in Engram (`sdd/web-source-category/verify-report`, observation id 32) rather than an in-tree `verify-report.md`; the prior change's in-tree `verify-report.md` predates the engram-backed verify flow.

### Readback evidence
1. **`diff -r` (POSIX, recursive)**: pre-move snapshot vs archived folder — **EMPTY (0 differences, exit 0, 6 files byte-identical)**.
2. **Recursive SHA-256 cross-check**: each archived file vs its pre-move HEAD blob (`git cat-file`) — **IDENTICAL, 0 differences**.
3. Greenfield spec copy (`web-source-layout`) hash readback: **EMPTY diff (identical SHA-256), moved into place**.

This `archive-report.md` is additive and excluded from the comparisons (it did not exist in the source snapshot).

## Audit Constraints Respected

- Protected content (`bibliografia/`, `apuntes/`, `integrity/`, `.githooks/`, `.gitattributes`) was NOT touched.
- Original delta specs inside the change were NOT modified (moved verbatim via `git mv`).
- No new change was created.
- Active hooks ignore `openspec/` paths (outside protected roots), so the archive commit moved cleanly.

## Next Steps

- Orchestrator to initiate the next change (none started by this phase).
- Optional at discretion: fix the off-by-one doc label in design.md/tasks.md (archived — cosmetic) and the register.ps1 indentation SUGGESTION.