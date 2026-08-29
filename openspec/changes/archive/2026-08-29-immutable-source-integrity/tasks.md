# Tasks: Immutable Source Integrity

## Review Workload Forecast

Estimated changed lines: 700–1,300 (≈570–900 machinery/harness/docs + 100–400 conversion).

```text
Decision needed before apply: Yes
Chained PRs recommended: Yes
Chain strategy: pending
400-line budget risk: High
```

Strict bootstrap keeps PR 1 atomic; user must accept its size before apply.

### Suggested Work Units

| Unit | Goal | Likely PR | Focused test command | Runtime harness | Rollback boundary |
|------|------|-----------|----------------------|-----------------|-------------------|
| 1 | Machinery + atomic bootstrap commit | PR 1 | `tools/integrity/verify.ps1` exits 0 | First commit accepted by active hook | Delete `.githooks/`, `tools/integrity/`, `integrity/`, `.gitattributes`; unset `core.hooksPath` |
| 2 | Sandbox harness proving spec scenarios | PR 2 | `tools/integrity/tests/run-integrity-tests.ps1` | Real commits in temp sandbox clones | Delete `tools/integrity/tests/` |

## Phase 1: Prerequisite Gate & Foundation

- [x] 1.1 HARD GATE (manual): `apuntes/unidad-01-conceptos-de-seguridad.md` exists; stop apply if absent — no grandfathering.
- [x] 1.2 Create `.gitattributes`: `*.pdf binary`; `*.md text eol=lf`; `integrity/manifest.sha256`, `.githooks/pre-commit`, `tools/integrity/*.ps1` pinned `text eol=lf`. Stage first.
- [x] 1.3 Stage PDF + MD; verify `git ls-files --eol`: MD `i/lf`, PDF binary passthrough.

## Phase 2: Core Machinery

- [x] 2.1 Create `.githooks/pre-commit`: sh shim exec'ing `powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools/integrity/verify.ps1` (D5).
- [x] 2.2 Build `verify.ps1` plumbing: repo-root resolve (outside repo ⇒ exit 2); staged manifest via `git cat-file blob :integrity/manifest.sha256`; HEAD manifest empty on #1; index enumeration `git ls-files --stage -- bibliografia apuntes`; staged-blob hashing via `cmd /c "git cat-file blob <oid> | sha256sum"` (D4); malformed/missing manifest ⇒ exit 2.
- [x] 2.3 Implement six blocking checks (design mapping), initial-commit branch, exit codes 0/1/2, ASCII messages naming files.
- [x] 2.4 Create `register.ps1 -Pdf <path>`: refuse unless PDF+MD staged and mirrored (`bibliografia/a/b.pdf` ⇔ `apuntes/a/b.md`), stem `[a-z0-9-]+`, lines absent; hash staged oids only (D6); ordinal-sorted rewrite, prior lines byte-identical, `[IO.File]::WriteAllText` + `UTF8Encoding($false)`; restage manifest.
- [x] 2.5 Create `README.md`: activation `git config core.hooksPath .githooks`, policy, manual atomic deletion steps, `--no-verify` / not-a-security-boundary disclosure.
- [x] 2.6 Fail-closed proof: no manifest ⇒ exit 2 + diagnostic; `PSParser` check both scripts.

## Phase 3: Atomic Bootstrap Commit (after Phases 1–2)

- [x] 3.1 Run `register.ps1 -Pdf bibliografia/unidad-01-conceptos-de-seguridad.pdf`; manifest has 2 ordinal-sorted LF lines, hex first byte.
- [x] 3.2 Stage `integrity/manifest.sha256` — completes stage→register→stage.
- [x] 3.3 Activate hooks: `git config core.hooksPath .githooks`.
- [x] 3.4 Negative probe: unstage MD, attempt commit ⇒ rejected exit 1; restage MD.
- [x] 3.5 Bootstrap commit #1 (all seven files) accepted by active hook on empty HEAD.
- [x] 3.6 Sanity: `sha256sum -c integrity/manifest.sha256` exits 0; root commit has all seven.

## Phase 4: Sandbox Test Harness (after 3.5; under `tools/integrity/tests/`)

- [x] 4.1 Create `run-integrity-tests.ps1`: temp sandbox clones, active hooks, stage/commit helpers capturing exit codes.
- [x] 4.2 Unit tests: parser accepts `<hex64>␣␣<path>`, rejects malformed; ordinal-sort determinism; BOM-free LF round-trip.
- [x] 4.3 Blocking tests (exit 1): modified registered source names file; unregistered protected addition; unpaired new PDF + orphan-MD symmetric check.
- [x] 4.4 Blocking tests (exit 1): deletion keeping entry; half-pair deletion; manifest-line tampering (modified/removed).
- [x] 4.5 Bootstrap tests: compliant initial commit accepted; initial commit missing counterpart rejected.
- [x] 4.6 Behavior tests: paired-registration exits 0; worktree noise ignored; malformed manifest ⇒ 2; missing verifier ⇒ 2; outside-repo aborts.
- [x] 4.7 Integrity tests: cmd-pipe PDF hash matches reference byte-for-byte; CRLF-corrupted verifier fails closed.
- [x] 4.8 Helper tests: appends exactly two lines, prior lines byte-identical; refuses unpaired PDF, registered-path mutation, unstaged inputs.

## Phase 5: E2E Verification

- [x] 5.1 Fresh clone (`core.autocrlf=true`): README steps activate hooks; compliant commit passes; `sha256sum -c` exits 0; no casing variants; entries match blobs.
- [x] 5.2 Map every delta-spec Given/When/Then scenario to passing evidence; log gaps for sdd-verify.
- [x] 5.3 Sandbox rollback rehearsal: remove machinery paths, unset `core.hooksPath` → plain-source tree restored.
