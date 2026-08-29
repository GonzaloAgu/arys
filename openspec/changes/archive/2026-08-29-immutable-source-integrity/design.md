# Design: Immutable Source Integrity

## Technical Approach

Committed manifest + pre-commit verifier. Verifier is **state-based**: enumerates staged index blobs, hashes blob bytes, separates legal events (paired registration, atomic deletion) from violations via staged-vs-HEAD manifest classification. Strict bootstrap, no grandfathering: manual unidad-01 conversion is a hard apply-time prerequisite.

## Architecture Decisions

| # | Decision | Options | Tradeoff | Choice |
|---|----------|---------|----------|--------|
| D1 | Markdown layer dir | `apuntes/`, `notes/`, inside `bibliografia/` | Binding #2 requires sibling; matches domain vocabulary; ASCII-safe lowercase | **`apuntes/`** |
| D2 | Manifest path/format | `integrity/manifest.sha256`; JSON | `sha256sum -c` verifiable outside git, zero tooling | **`integrity/manifest.sha256`**; `<hex64>␣␣<path>` two spaces, forward slashes, ordinal-sorted, UTF-8 no BOM, LF |
| D3 | EOL pinning | Global vs scoped patterns | Scoped risks gaps; global stabilizes README/specs too | Block below |
| D4 | Hash source | Worktree vs staged blobs | Spec mandates index blobs; worktree breaks under unstaged edits | **Staged blobs** via `cmd /c "git cat-file blob <oid> \| sha256sum"` — PS 5.1 decodes native pipelines to strings; pipe in cmd |
| D5 | Script layout | Logic in sh; sh shim + ps1 | Hooks run POSIX sh; thin shim minimizes surface | **`.githooks/pre-commit` shim → `tools/integrity/verify.ps1`** |
| D6 | Register hashing | Worktree vs staged blobs | Editor CRLF saves diverge from normalized blobs | Helper **refuses unstaged files**; reads staged oids — verifier's source |
| D7 | Deletion flow | Remove helper vs manual | Spec limits register to additions-only; deletions rare, audited | **Manual** (`git rm` both + remove both lines); hook validates atomicity |
| D8 | Activation | Versioned hooksPath vs copied hooks | Copies go stale/unversioned | **`git config core.hooksPath .githooks`**, per clone, in README |

`.gitattributes` (staged first):

```
*.pdf                      binary
*.md                       text eol=lf
integrity/manifest.sha256  text eol=lf
.githooks/pre-commit       text eol=lf
tools/integrity/*.ps1      text eol=lf
```

## Data Flow

```
git commit ─► .githooks/pre-commit (cwd = repo root)
                └─► powershell -File tools/integrity/verify.ps1
                     ├─ git ls-files --stage -- bibliografia apuntes → index {path, oid}
                     ├─ git cat-file blob :integrity/manifest.sha256 → staged manifest
                     ├─ git cat-file blob HEAD:integrity/manifest.sha256 → HEAD manifest ([] on commit #1)
                     └─ cmd /c "git cat-file blob <oid> | sha256sum"
register: stage pdf+md ► register.ps1 reads staged oids ► sorted BOM-free rewrite ► stage manifest ► commit
```

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `apuntes/unidad-01-conceptos-de-seguridad.md` | Create | Manual conversion prerequisite |
| `.gitattributes` | Create | Byte-stability pins (D3) |
| `integrity/manifest.sha256` | Create | Append-only registry; helper-written only |
| `.githooks/pre-commit` | Create | POSIX sh shim |
| `tools/integrity/verify.ps1` | Create | Verifier, fail-closed |
| `tools/integrity/register.ps1` | Create | Additions-only pair registration |
| `README.md` | Create | Setup, policy, deletion steps, `--no-verify` disclosure |

## Interfaces / Contracts

**Shim**:
```sh
#!/bin/sh
exec powershell.exe -NoProfile -ExecutionPolicy Bypass -File "tools/integrity/verify.ps1"
```

**Register CLI**: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/integrity/register.ps1 -Pdf bibliografia/<stem>.pdf`
Refuses unless: both files staged; counterpart `apuntes/<stem>.md` staged (mirror `bibliografia/a/b.pdf ⇔ apuntes/a/b.md`); stem `[a-z0-9-]+`; neither line present. Writes sorted manifest, pre-existing lines byte-identical, via `[IO.File]::WriteAllText($p,$text,[Text.UTF8Encoding]::new($false))`.

**Exit codes**: 0 pass · 1 violation (names files) · 2 broken machinery; plumbing failure/malformed line/missing manifest ⇒ fail-closed abort.

**Blocking conditions → checks**:

| Condition | Check |
|---|---|
| 1 modified registered file | Staged-blob hash ≠ manifest line ⇒ reject |
| 2 unregistered new protected file | Index path absent from staged manifest ⇒ reject |
| 3 unpaired new PDF | ∀ `bibliografia/*.pdf`: mirrored MD staged AND both lines present; symmetric orphan-MD check |
| 4 deletion keeps entry | Line present while file absent from index ⇒ reject unless full exception |
| 5 half-pair deletion | Deleted registered file ⇒ partner deleted AND both lines removed together |
| 6 line tampering | Manifest diff vs HEAD: adds legal only for new paired files; removals only in atomic pair deletion; modified ⇒ reject |

Initial commit: HEAD = empty map, same checks ⇒ strict bootstrap.

## Testing Strategy

| Layer | What | Approach |
|-------|------|----------|
| Unit | Manifest parse/sort/BOM-free round-trip | Harness functions, temp files |
| Integration | Six conditions; pass cases; fail-closed cases; worktree-noise ignored | Dependency-free PS 5.1 harness: sandbox clones asserting exit codes |
| E2E | Fresh clone + README steps → hooks active, `sha256sum -c` exits 0 | Manual checklist at verify |

## Threat Matrix

| Boundary | Applicability | Design response | RED tests |
|---|---|---|---|
| Documentation-like paths | N/A — no executable docs | — | — |
| Git repo selection | Applicable — repo-root resolution, scoped paths | Fixed protected roots; refuse outside repo | Outside-repo invocation aborts |
| Commit state | Applicable — staged/index/empty-HEAD | Index-only reads; initial-commit branch | Initial-commit; worktree-noise scenarios |
| Push state | N/A — no push automation | — | — |
| PR commands | N/A — no PR tooling | — | — |
| Shell/subprocess/exec classification | Applicable — hook→powershell, cmd pipes, `.sh`/`.ps1` assets | cmd byte pipe (D4); LF pinning; ASCII messages | Binary-hash integrity; corrupted-script rejection |

Applicable rows become unchanged RED tests.

## Migration / Rollout

Bootstrap commit #1 order:

1. **Apply gate**: convert unidad-01 PDF → `apuntes/unidad-01-conceptos-de-seguridad.md` manually; stop apply if absent.
2. Write + stage `.gitattributes`.
3. Stage PDF + MD (attributes govern normalization).
4. Write + stage shim, verify.ps1, register.ps1, README.md.
5. Run register.ps1 (hashes staged blobs; BOM-free write).
6. Stage manifest.
7. `git config core.hooksPath .githooks`.
8. Commit — hook validates pairing on empty HEAD; acceptance proves the machinery.

Rollback (proposal): remove machinery paths, unset `core.hooksPath`; sources untouched.

## Open Questions

- None blocking. Out-of-scope future: CI running verify.ps1 closes bypass gap if remote appears.
