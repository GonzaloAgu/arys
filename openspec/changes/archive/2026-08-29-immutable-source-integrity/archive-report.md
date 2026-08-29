# Archive Report: immutable-source-integrity

**Archived on**: 2026-08-29
**Artifact store mode**: openspec (light layout: `openspec/changes/` + `sdd-init-arys.json` only)
**Source of truth**: `openspec/specs/{domain}/spec.md` (created during this archive)

## Final State

The change **immutable-source-integrity** is COMPLETE and VERIFIED. It protects course source
material — `bibliografia/` (original PDFs) and `apuntes/` (derived Markdown) — with a SHA-256
append-only manifest (`integrity/manifest.sha256`) enforced by a pre-commit hook
(`.githooks/pre-commit` → `tools/integrity/verify.ps1`).

### Gate results at close

| Gate | Result |
|------|--------|
| Verification verdict | PASS WITH WARNINGS (verify-report.md) |
| Critical findings | 0 |
| Blockers | 0 |
| Requirements | 14/14 compliant |
| Scenarios | 27/27 compliant |
| Harness tests | 51/51 passed (two consecutive runs, exit 0) |
| Tasks (persisted `tasks.md`) | 26/26 checked, 0 unchecked |
| Native review gate | Absent (receipt-driven development not active for this change) |

### Final-State Authority notes

Final numbers are drawn from the highest-ranked available sources and agree: the orchestrator's
launch status (all_done, verify PASS WITH WARNINGS, 27/27 scenarios, 51/51 tests, taskProgress
26/26) matches the persisted `verify-report.md` (51/51 tests, 27/27 scenarios, verdict
PASS WITH WARNINGS) and matches the actual task list (26/26 checkboxes `[x]` in the archived
`tasks.md`). No contradiction required reconciliation.

`verify-report.md` carries one WARNING (WARNING-1: `.gitattributes` does not pin
`tools/integrity/tests/*.ps1` because the D3 pattern `tools/integrity/*.ps1` matches only one
directory level). This is a non-spec-breaking design-deviation warning on dev tooling; no spec
scenario requires it and no test fails. It does not block archive (no CRITICAL). The orchestrator
may apply a one-line fix (`tools/integrity/tests/*.ps1 text eol=lf`) at its discretion.

## Specs Synced (delta → main source of truth)

The three delta specs were greenfield (no `openspec/specs/` existed before archive), so each
delta is a full spec and was copied mechanically (never routed through model Read/Write) into the
main spec tree:

| Domain | Action | Requirements carried |
|--------|--------|---------------------|
| protected-source-layout | Created | 3 (Canonical protected source dir, Sibling Markdown layer, Byte-stability attributes) |
| source-manifest | Created | 4 (Manifest format/encoding, Entry identity, Append-only registration, Deletion sole exception, Strict bootstrap) |
| integrity-pre-commit-hook | Created | 4 (Versioned hook, Verification over staged blobs, Blocking conditions, Bootstrap readiness, Fail-closed, Bypass disclosure) |

Main spec files:
- `openspec/specs/protected-source-layout/spec.md`
- `openspec/specs/source-manifest/spec.md`
- `openspec/specs/integrity-pre-commit-hook/spec.md`

## Archive Move

Change folder moved (mechanical `git mv`) to:
- `openspec/changes/archive/2026-08-29-immutable-source-integrity/`

The active changes directory `openspec/changes/` now contains only `archive/`.

### Archive contents (8 files, byte-identical to pre-move snapshot)
- `exploration.md`
- `proposal.md`
- `design.md`
- `tasks.md` (26/26 complete)
- `verify-report.md`
- `specs/protected-source-layout/spec.md`
- `specs/source-manifest/spec.md`
- `specs/integrity-pre-commit-hook/spec.md`

### Readback evidence
Recursive SHA-256 tree comparison of the archived folder against a pre-move snapshot:
**EMPTY (0 differences, 8 files identical)**. The three spec copies into `openspec/specs/`
also verified byte-identical (EMPTY diff). This `archive-report.md` is additive and excluded from
the comparison (it did not exist in the source snapshot).

## Audit Constraints Respected

- Protected content (`bibliografia/`, `apuntes/`, `integrity/`, `.githooks/`, `.gitattributes`)
  was NOT touched.
- Original delta specs inside the change were NOT modified (moved verbatim via `git mv`).
- No new change was created.
- Active hooks ignored all archived/spec paths (outside protected roots), so the preparatory
  `verify-report.md` commit and this archive moved cleanly.

## Next Steps

- Orchestrator to initiate the next change (none started by this phase).
- Optional: apply WARNING-1 one-line fix and SUGGESTION-2 automated EOL regression if desired.
