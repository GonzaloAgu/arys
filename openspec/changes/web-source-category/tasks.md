# Tasks: Web Source Category

## Review Workload Forecast

Estimated changed lines: 550–700 (≈360–500 authored scripts/tests/docs; ~192 Appendix A verbatim = generated golden content; +4 content/manifest lines).

```text
Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: pending
400-line budget risk: Low
```

Single PR fits the 800-line session budget. Authored lines sit near the 400-line default, but the verbatim mirror is excluded from authored risk per the review guard.

### Suggested Work Units

| Unit | Goal | Likely PR | Focused test command | Runtime harness | Rollback boundary |
|------|------|-----------|----------------------|-----------------|-------------------|
| 1 | `verify.ps1`/`register.ps1`/`.gitattributes` generalization; existing 51 cases stay green | PR 1 | `tools/integrity/tests/run-integrity-tests.ps1` | Real commits in sandbox clones | Revert commit touching scripts + `.gitattributes` only |
| 2 | Harness growth: web-*, mirror-*, eol-*, helper-04 (16 new cases) | PR 2 | Same runner, 67 cases | Real commits in sandbox clones | Revert harness commit only |
| 3 | Real web pair + manifest + README | PR 3 | `sha256sum -c integrity/manifest.sha256` + full runner | Fresh `core.autocrlf=true` clone | `git revert` removes pair + 2 manifest lines atomically |

## Phase 1: Foundation — `.gitattributes` Pin

- [x] 1.1 Add `*.txt text eol=lf` to `.gitattributes` (design D6; `web-source-layout` byte-stability requirement) and stage it first.
- [x] 1.2 EOL audit: `git ls-files --eol '*.txt'` reports `i/lf`; no CR bytes in any tracked `.txt`.

## Phase 2: Core Machinery — verify.ps1

- [x] 2.1 Add `Get-SourceKind` (`'pdf'|'txt'|$null`) and `Get-MirrorCandidates` (pdf/txt → one md; md → both candidates), replacing `Get-MirrorPath` (design D1/D2).
- [x] 2.2 Generalize check 3 to both kinds; keep exact `unpaired PDF`, `orphan Markdown note`, `pair members must both carry` fragments; add exact `unpaired web link (missing staged Markdown counterpart ...)` (design; spec condition 3).
- [x] 2.3 Add check 8 after check 3: `duplicate source stem '<stem>': <sources> (all map to 'apuntes/<stem>.md')` (design; spec condition 8).
- [x] 2.4 Rewrite checks 5+6b half-pair deletion over `Get-MirrorCandidates` loop; message unchanged (design).
- [x] 2.5 Leave checks 1/2/4/6a untouched; `block-03`/`block-04` test fragments must still pass (regression gate before Phase 3).

## Phase 3: Core Machinery — register.ps1

- [x] 3.1 Rename param `-Pdf` → `-Source` (design D3); internal `$pdfPath`→`$sourcePath`, `$pdfHash`→`$sourceHash`; kind derived from extension.
- [x] 3.2 Exact wrong-root/ext refusal: `source must be a staged PDF or web link under bibliografia/ (.pdf or .txt): '<path>'.` (stem message unchanged).
- [x] 3.3 Cross-kind stem refusal against `$baseMap` then `$index`: exact `stem '<stem>' already has registered source '<sibling>'...` and `collides with staged source '<sibling>'...` messages (design table).
- [x] 3.4 Staged-blob URL check (txt only): BOM-free, LF-only, single `^https?://\S+$` line; exact refusal messages per design (D4; `source-manifest` scenarios).

## Phase 4: Harness Growth

- [x] 4.1 Rename `Invoke-Register -PdfPath` → `-SourcePath` (calls `-Source`); existing 51 cases keep names/assertions (design).
- [x] 4.2 Add `New-SandboxWebPair($RepoDir,$Stem,$Url)` and `mirror-child.ps1` template (AST dot-source invoking `Get-SourceKind`/`Get-MirrorCandidates`).
- [x] 4.3 Add `web-01` register web pair ok (+2 lines, prior lines byte-identical, ordinal) and `mirror-01..04` reverse-resolution unit cases.
- [x] 4.4 Add `web-02`/`web-03` register refusals (no URL; non-http URL), manifest bytes untouched.
- [x] 4.5 Add `web-04..06` hook blocks: unpaired web link (`unpaired web link`), tampered registered link and mirror (`content differs`).
- [x] 4.6 Add `web-07`/`web-08`/`web-09`: half-pair web deletions blocked (`half-pair deletion`); atomic web-pair deletion ok.
- [x] 4.7 Add `web-10` duplicate stem blocked (`duplicate source stem`) and `helper-04` register refusal (`one source per stem`).
- [x] 4.8 Add `eol-01`: CRLF link bytes staged → staged blob has no `0x0D` and hash equals LF fixture (design eol-01).

## Phase 5: Real Pair Registration (Rollout)

- [x] 5.1 Create `bibliografia/unidad-01-teoria-web.txt`: single `https://bzappellini.github.io/ARyS/unidades/u01-conceptos-seguridad/teoria.md` line + LF, BOM-free (design rollout 1; link-content contract).
- [x] 5.2 Create `apuntes/unidad-01-teoria-web.md`: proposal Appendix A lines 105–296 verbatim (excluding fetch metadata), BOM-free LF; assert byte-identity with fetched `teoria.md` fixture and `git ls-files --eol` = `i/lf` (verbatim-mirror requirement).
- [x] 5.3 `git add .gitattributes`, then both files; run `tools/integrity/register.ps1 -Source bibliografia/unidad-01-teoria-web.txt` (design rollout 3–4).
- [x] 5.4 Assert manifest: 4 lines; lines 1–2 byte-identical (`b86a77…`, `93f5e0…`); ordinal order = md-concepts, md-teoria-web, pdf-concepts, txt-teoria-web (design rollout 5).
- [x] 5.5 `git add integrity/manifest.sha256`; full runner + `sha256sum -c` pass; commit under active hook (design rollout 6).

## Phase 6: Docs and Full Verification

- [x] 6.1 README: web-source layout row, `-Source` register flow, web delete flow, URL-rot disclosure (proposal risk mitigation).
- [x] 6.2 Full runner: 51 existing + 16 new = 67 pass; `sha256sum -c integrity/manifest.sha256` exits 0 on `core.autocrlf=true` fresh clone (proposal success criteria).
- [ ] 6.3 Map all 22 delta-spec scenarios (web-source-layout 5, source-manifest 8, integrity-pre-commit-hook 9) to passing evidence; log gaps for sdd-verify.