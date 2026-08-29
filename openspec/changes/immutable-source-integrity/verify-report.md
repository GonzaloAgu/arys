```yaml
schema: gentle-ai.verify-result/v1
evidence_revision: sha256:54ea7d1beafe2ec1c6159910c33e1d0855b1f0a44d5442c6c10d821dcab38e96
verdict: pass
blockers: 0
critical_findings: 0
requirements: 14/14
scenarios: 27/27
test_command: powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools/integrity/tests/run-integrity-tests.ps1
test_exit_code: 0
test_output_hash: sha256:cad25b8f7d0c245fd28fc93e545e5f300049d2633000e2865cdf9c596f80127c
build_command: powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\Users\gonza\AppData\Local\Temp\opencode\verify-evidence\parse-check.ps1
build_exit_code: 0
build_output_hash: sha256:e6f8298b9d881f522f50784cc2c4c30490b9b2b04eaf6df8fceb6e8086da575c
```

## Verification Report

**Change**: immutable-source-integrity
**Version**: N/A (greenfield delta specs)
**Mode**: Standard (Strict TDD not active)

### Completeness
| Metric | Value |
|--------|-------|
| Tasks total | 20 |
| Tasks complete | 20 |
| Tasks incomplete | 0 |

All phases (1–5) checked `[x]` in `openspec/changes/immutable-source-integrity/tasks.md`. Full verification permitted.

### Build & Tests Execution

**Tests**: ✅ 51 passed / ❌ 0 failed / ⚠️ 0 skipped (two consecutive runs)
```text
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools/integrity/tests/run-integrity-tests.ps1
Run 1: [integrity-tests] pass=51 fail=0 total=51 ; HARNESS_EXIT=0
Run 2 (hash-pinned): [integrity-tests] pass=51 fail=0 total=51 ; exit 0
Full TAP transcript preserved at C:\Users\gonza\AppData\Local\Temp\opencode\verify-evidence\harness-output.txt
```

**Build/type-check equivalent**: ✅ Passed
```text
powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\Users\gonza\AppData\Local\Temp\opencode\verify-evidence\parse-check.ps1
tools\integrity\verify.ps1 parse_errors=0
tools\integrity\register.ps1 parse_errors=0
tools\integrity\tests\run-integrity-tests.ps1 parse_errors=0
External: sha256sum -c integrity/manifest.sha256 -> both entries OK, exit 0
EOL audit: git ls-files --eol -> apuntes/*.md i/lf w/lf attr/text eol=lf ; bibliografia/*.pdf i/-text w/-text attr/-text ;
           integrity/manifest.sha256, .githooks/pre-commit, tools/integrity/*.ps1 i/lf w/lf
Transcript: C:\Users\gonza\AppData\Local\Temp\opencode\verify-evidence\build-output.txt
```

**Coverage**: ➖ Not available (PowerShell sandbox harness; no coverage instrumentation — acceptable per design Testing Strategy)

### Independent Runtime Probes (verify-phase execution, not inherited from apply)

1. **Fresh-clone E2E**: cloned to temp with `-c core.autocrlf=true`, activated hooks per README (`git config core.hooksPath .githooks`): `sha256sum -c` exit 0; compliant pair registration (`bibliografia/verify-e2e.pdf` + `apuntes/verify-e2e.md`) accepted by active hook (`[integrity] OK: 4 registered file(s)`); tamper flow rejected exit 1 naming the file; clone deleted afterwards.
2. **Live negative probe (real repo)**: appended noise to `apuntes/unidad-01-conceptos-de-seguridad.md`, staged, committed → `[integrity] COMMIT REJECTED ... content differs ... : apuntes/unidad-01-conceptos-de-seguridad.md`, exit 1, HEAD unchanged (0554fd4). Reset `--hard` + `clean`: status empty, HEAD 0554fd4, file SHA-256 byte-identical to pre-probe (B86A7786…FFF, equals its manifest entry). Worktree left exactly as found.

### Spec Compliance Matrix

protected-source-layout
| Requirement | Scenario | Test | Result |
|-------------|----------|------|--------|
| Canonical protected source directory | Source PDF lives in the canonical directory | direct `git ls-files` + harness `fresh-02` | ✅ COMPLIANT |
| Canonical protected source directory | No casing variants are tracked | `run-integrity-tests.ps1 > fresh-02 no casing variants tracked` | ✅ COMPLIANT |
| Sibling Markdown layer | Derived note is placed in the sibling layer | `legal-01 compliant paired registration commit accepted` + fresh-clone E2E | ✅ COMPLIANT |
| Sibling Markdown layer | One-to-one pairing by name | `block-03` / `block-04` symmetric rejects + `Get-MirrorPath` pairing in `legal-01` | ✅ COMPLIANT |
| Byte-stability attributes | Fresh clone preserves hashes | `fresh-01 sha256sum -c exits 0 after autocrlf clone` + verify-phase E2E clone | ✅ COMPLIANT |
| Byte-stability attributes | PDFs are never translated | `byte-01 cmd pipe equals .NET equals manifest` + `i/-text attr/-text` EOL audit | ✅ COMPLIANT |

source-manifest
| Requirement | Scenario | Test | Result |
|-------------|----------|------|--------|
| Manifest format and encoding | External verification succeeds on a clean tree | verify-phase `sha256sum -c` exit 0 + `fresh-01` | ✅ COMPLIANT |
| Manifest format and encoding | Manifest is BOM-free | `parser-08 rejects UTF-8 BOM` + `sort-03` first-byte hex assert | ✅ COMPLIANT |
| Entry identity | Entries match committed blobs | `fresh-03 entries match committed blobs` (.NET reference vs HEAD blobs) | ✅ COMPLIANT |
| Append-only registration | Registering a new pair appends two lines | `sort-02`..`sort-05` (+2 lines, prior lines byte-identical, ordinal-sorted) | ✅ COMPLIANT |
| Append-only registration | Helper refuses unpaired PDF | `helper-03 unpaired staged pdf refused` (+ `helper-01` unstaged refusal) | ✅ COMPLIANT |
| Append-only registration | Helper refuses entry mutation | `helper-02 registered-path mutation refused` (manifest bytes untouched, b64 compare) | ✅ COMPLIANT |
| Deletion is the sole exception | Atomic pair deletion leaves together | `legal-04 atomic pair deletion accepted, baseline restored` | ✅ COMPLIANT |
| Deletion is the sole exception | Partial removal is invalid | `block-05` / `block-06` half-pair deletions rejected + `block-08` | ✅ COMPLIANT (see SUGGESTION-1) |
| Strict bootstrap without grandfathering | Bootstrap carries the initial pair fully registered | `boot-01 compliant initial commit accepted` + real root commit 1d14b4c accepted by active hook | ✅ COMPLIANT |
| Strict bootstrap without grandfathering | Unpaired bootstrap source is non-conformant | `boot-02 unpaired bootstrap blocked` | ✅ COMPLIANT |

integrity-pre-commit-hook
| Requirement | Scenario | Test | Result |
|-------------|----------|------|--------|
| Versioned hook with documented activation | Activated hook intercepts commits | every blocking case (`block-01..08`, `closed-*`) executes through the active hook | ✅ COMPLIANT |
| Versioned hook with documented activation | Setup is reproducible from README | verify-phase E2E followed README steps verbatim; compliant commit succeeded (+ `doc-01`) | ✅ COMPLIANT |
| Verification over staged index blobs | Working-tree noise does not affect verdicts | `noise-01 unstaged working-tree noise ignored` | ✅ COMPLIANT |
| Blocking conditions | Modified registered source is blocked | `block-01 modified registered source` (file named) | ✅ COMPLIANT |
| Blocking conditions | Unpaired new PDF is blocked | `block-03 unpaired new pdf` (+ symmetric `block-04`) | ✅ COMPLIANT |
| Blocking conditions | Deletion without entry removal is blocked | `block-05` / `block-06` (exit 1, "together with its pair") | ✅ COMPLIANT |
| Blocking conditions | Manifest tampering is blocked | `block-07 modified line` + `block-08 removed line while file staged` | ✅ COMPLIANT |
| Bootstrap readiness without grandfathering | Compliant bootstrap commit succeeds | `boot-01` (empty-HEAD sandbox) | ✅ COMPLIANT |
| Bootstrap readiness without grandfathering | Bootstrap missing the counterpart is blocked | `boot-02` (exit 1, "unpaired PDF") | ✅ COMPLIANT |
| Fail-closed execution | Broken machinery aborts the commit | `closed-01/02` malformed manifest, `closed-03` missing verifier, `closed-04` outside repo (exit 2), `closed-06` CRLF-corrupted manifest | ✅ COMPLIANT |
| Bypass limitation disclosed | Limitation is visible to users | `doc-01/02/03` + direct README inspection (`--no-verify`, "NOT a security boundary", activation command) | ✅ COMPLIANT |

**Compliance summary**: 27/27 scenarios compliant across 14 requirements

### Logged Gap Assessment (task 5.2 → sdd-verify)

Gap under judgment: the `git ls-files --eol` pinning assertion from task 1.3 (MD `i/lf`, PDF binary passthrough) existed only as slice-1 manual evidence. **Assessment: no spec scenario is left unproven.** The spec-level observable ("Fresh clone preserves hashes" under autocrlf=true) has passing runtime coverage (`fresh-01` plus an independent verify-phase clone). This phase re-ran `git ls-files --eol` directly and confirmed `i/lf w/lf attr/text eol=lf` for the Markdown layer and `i/-text w/-text attr/-text` for the PDF — the manual evidence reproduces today. Residual improvement tracked as SUGGESTION-2.

### Correctness (Static Evidence)

| Requirement | Status | Notes |
|------------|--------|-------|
| protected-source-layout | ✅ Implemented | Lowercase `bibliografia/` + sibling `apuntes/`; `.gitattributes` pins present and effective (EOL audit above); no casing variants tracked |
| source-manifest | ✅ Implemented | 2-entry manifest, ordinal-sorted, LF, hex first byte; register.ps1 is additions-only, refuses unpaired/unstaged/mutation; no re-baseline flow exists anywhere in the codebase |
| integrity-pre-commit-hook | ✅ Implemented | verify.ps1 implements all six blocking checks over staged index blobs via cmd-side `git cat-file blob <oid> \| sha256sum` (D4); fail-closed exits 0/1/2 confirmed incl. shim passthrough (`closed-05`, exit 2 propagated) |

### Coherence (Design)

| Decision | Followed? | Notes |
|----------|-----------|-------|
| D1 `apuntes/` layer | ✅ Yes | |
| D2 manifest path/format | ✅ Yes | `integrity/manifest.sha256`, `<hex64>␣␣<path>`, ordinal-sorted, UTF-8 no BOM, LF — parser enforces all |
| D3 EOL pinning block | ⚠️ Mostly | See WARNING-1: `tools/integrity/tests/*.ps1` falls outside the `tools/integrity/*.ps1` pattern |
| D4 staged-blob hashing via cmd pipe | ✅ Yes | byte-01 three-way equality (cmd pipe == .NET == manifest) |
| D5 sh shim → ps1 verifier | ✅ Yes | shim content matches design contract; exit-code passthrough proven |
| D6 register hashes staged oids only | ✅ Yes | helper-01 refuses unstaged inputs |
| D7 manual deletion flow | ✅ Yes | README documents it; hook validates atomicity (legal-04 vs block-05/06) |
| D8 `core.hooksPath .githooks` activation | ✅ Yes | README + doc-01; exercised in E2E |

### Issues Found

**CRITICAL**: None.

**WARNING**:
1. **WARNING-1 — `.gitattributes` does not pin the test harness.** Evidence: `git ls-files --eol` shows `attr/` (no attributes) for `tools/integrity/tests/run-integrity-tests.ps1`, because design D3's pattern `tools/integrity/*.ps1` matches only one directory level and the harness lives at `tools/integrity/tests/`. Its index bytes are currently LF only because it was authored that way. No spec scenario requires the pin (specs mandate only `*.pdf binary` and `*.md eol=lf`) and no test fails, so this is a design-deviation warning, not a compliance failure. Minimal fix (one line, deferred to orchestrator to keep verification read-only): add `tools/integrity/tests/*.ps1 text eol=lf` to `.gitattributes`.

**SUGGESTION**:
1. **SUGGESTION-1 — partial-removal sub-variant lacks a dedicated runtime case.** Block-05/06 prove rejection when a registered file is deleted while its counterpart and manifest lines remain (the spec scenario's GIVEN instantiated literally). The complementary variant — delete one file AND correctly remove only its own line while keeping the partner — is handled by verify.ps1 checks 5+6b but has no named harness case. Consider adding a `block-09`.
2. **SUGGESTION-2 — convert the slice-1 manual EOL assertion into an automated regression.** Add a harness case asserting `git ls-files --eol` output (`i/lf` for pinned text, `-text` for PDF) so task 1.3's evidence stops depending on manual reproduction.
3. **SUGGESTION-3 — bootstrap commit carries more than the seven machinery files.** Root commit 1d14b4c also includes `openspec/**` and `.atl/**` planning artifacts alongside the seven required files. Harmless (outside protected roots, hook ignores them) and arguably good provenance, but it diverges literally from tasks.md 3.5's "all seven files" wording.

### Verdict
PASS WITH WARNINGS
All 20 tasks complete; 51/51 harness cases pass twice; 27/27 spec scenarios hold with runtime evidence including independent fresh-clone E2E and a live blocked-tamper probe; single warning is a non-spec-breaking `.gitattributes` coverage gap on dev tooling.
