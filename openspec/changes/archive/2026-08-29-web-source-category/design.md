# Design: Web Source Category

## Technical Approach

Extension-based kind dispatch with zero manifest-format change. `bibliografia/{stem}.txt` (web link) joins `bibliografia/{stem}.pdf` as a protected source kind; both mirror 1:1 to `apuntes/{stem}.md`. The reverse direction (md → source) resolves against the new cross-kind invariant **at most one source per stem**, which is enforced at registration and verification. URL content is validated once at registration (policy); the verifier stays pure-hash exactly as before (spec `integrity-pre-commit-hook`).

## Architecture Decisions

| # | Decision | Options | Tradeoff | Choice |
|---|----------|---------|----------|--------|
| D1 | Kind dispatch | Extension classifier vs `-Kind` flag vs marker files vs per-kind manifest sections | Flag/markers change CLI + manifest format (migration); extension classifier is inert for existing entries | **Classifier: `.pdf`/`.txt` under `bibliografia/`** — single function `Get-SourceKind`, both 4-char extensions so the existing `Substring(13, Len-17)` stem cut is unchanged |
| D2 | Reverse mirror resolution | Scan directory vs candidate list + invariant | Directory scan reads worktree (violates staged-blob discipline); candidate list is pure index | **`Get-MirrorCandidates` returns both `bibliografia/{stem}.pdf|.txt`; callers pick the unique staged one** — invariant makes it exact |
| D3 | Register CLI | `-Source` rename, no alias vs keep `-Pdf` + add `-Source` | `-Pdf` would lie for `.txt` inputs; alias doubles docs/tests | **`-Source` only**; harness + README call sites updated in the same change |
| D4 | URL validation site | Register-only (policy) vs verifier also checks | Verifier URL checks add fetch/parse surface and break pure-hash (spec mandates it stays pure-hash) | **Register-only, over the staged blob** (never worktree bytes) |
| D5 | Duplicate-stem enforcement | Register + verifier vs verifier only | Register-only leaves a window (hook never fires if `--no-verify`); verifier-only lets bad pairs be committed in that window... both cheap | **Both** — register refuses early; verifier check 8 blocks the commit |
| D6 | `.txt` EOL | `*.txt text eol=lf` vs binary vs `eol=crlf` | binary skips normalization (editor CRLF drift); crlf breaks determinism | **`*.txt text eol=lf`** matching the `*.md` pin |

## Data Flow

```
bibliografia/X.pdf ─┐                 ┌─► apuntes/X.md
                    ├─ Get-SourceKind ┘        │  (reverse, invariant-based)
bibliografia/X.txt ─┘        'pdf'|'txt'       │  candidates = {X.pdf, X.txt}
                                               ▼  exactly ONE staged ⇒ pair
commit ─► pre-commit ─► verify.ps1: index oids ─► staged-blob hash ─► manifest compare
register: git add pair ─► register.ps1 -Source bibliografia/X.txt
           ├─ staged-blob URL check (txt only): 1 line, ^https?://\S+$
           ├─ cross-kind stem check (pdf sibling: registered OR staged ⇒ refuse)
           └─ deterministic ordinal rewrite (existing lines byte-identical) ─► git add manifest
```

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `tools/integrity/verify.ps1` | Modify | Kind classifier, generalized pairing (check 3), new check 8 (duplicate stem), multi-candidate reverse in checks 5+6b |
| `tools/integrity/register.ps1` | Modify | `-Source` param, kind dispatch, staged-blob URL validation, cross-kind stem refusal |
| `tools/integrity/tests/run-integrity-tests.ps1` | Modify | `Invoke-Register -PdfPath` → `-SourcePath`; new `web-*`, `mirror-*`, `eol-*`, `helper-04` cases |
| `.gitattributes` | Modify | Add `*.txt text eol=lf` |
| `bibliografia/unidad-01-teoria-web.txt` | Create | Single absolute URL line (see rollout) |
| `apuntes/unidad-01-teoria-web.md` | Create | Appendix A verbatim (see rollout) |
| `integrity/manifest.sha256` | Modify | +2 lines via register; lines 1–2 byte-identical |
| `README.md` | Modify | Web category, `-Source` register flow, web delete flow, URL-rot disclosure |

## Interfaces / Contracts

### verify.ps1 — kind dispatch (replaces `Get-MirrorPath`)

```powershell
# 'pdf' | 'txt' | $null  — the single extension classifier (D1).
function Get-SourceKind {
    param([string]$Path)
    if ($Path.StartsWith('bibliografia/') -and $Path.EndsWith('.pdf')) { return 'pdf' }
    if ($Path.StartsWith('bibliografia/') -and $Path.EndsWith('.txt')) { return 'txt' }
    return $null
}

# Syntactic mirror mapping, both directions. Sources map 1:1 to apuntes/<stem>.md
# ('.pdf'/'.txt' are both 4 chars, so Substring(13, Len-17) is unchanged).
# Markdown maps to BOTH bibliografia candidates; the single-source-per-stem
# invariant guarantees at most one exists (D2).
function Get-MirrorCandidates {
    param([string]$Path)
    if ($null -ne (Get-SourceKind $Path)) {
        return @('apuntes/' + $Path.Substring(13, $Path.Length - 17) + '.md')
    }
    if ($Path.StartsWith('apuntes/') -and $Path.EndsWith('.md')) {
        $stem = $Path.Substring(8, $Path.Length - 11)
        return @("bibliografia/$stem.pdf", "bibliografia/$stem.txt")
    }
    return @()
}
```

### verify.ps1 — check 3 (pairing, generalized)

```powershell
foreach ($p in $index.Keys) {
    $kind = Get-SourceKind $p
    if ($null -ne $kind) {                      # source direction: 1:1 mirror
        $mirror = 'apuntes/' + $p.Substring(13, $p.Length - 17) + '.md'
        if (-not $index.Contains($mirror)) {
            if ($kind -eq 'pdf') { $violations.Add("unpaired PDF (missing staged Markdown counterpart '$mirror'): $p") }
            else                 { $violations.Add("unpaired web link (missing staged Markdown counterpart '$mirror'): $p") }
        }
        elseif (-not ($stagedMap.Contains($p) -and $stagedMap.Contains($mirror))) {
            $violations.Add("pair members must both carry manifest lines in the same commit: $p <-> $mirror")
        }
    }
    elseif ($p.StartsWith('apuntes/') -and $p.EndsWith('.md')) {   # reverse direction
        $stem = $p.Substring(8, $p.Length - 11)
        $present = @()
        foreach ($c in @("bibliografia/$stem.pdf", "bibliografia/$stem.txt")) {
            if ($index.Contains($c)) { $present += $c }
        }
        if ($present.Count -eq 0) {
            $violations.Add("orphan Markdown note (missing staged source for stem '$stem'): $p")
        }
        elseif ($present.Count -eq 1 -and -not ($stagedMap.Contains($present[0]) -and $stagedMap.Contains($p))) {
            $violations.Add("pair members must both carry manifest lines in the same commit: $($present[0]) <-> $p")
        }
        # $present.Count -gt 1 is reported by check 8; skipping avoids double-reporting.
    }
}
```

Existing fragments `unpaired PDF`, `orphan Markdown note`, `pair members must both carry` are preserved so `block-03`, `block-04` assertions still pass.

### verify.ps1 — new check 8 (duplicate stem, runs after check 3)

```powershell
$stemSources = New-Object System.Collections.Specialized.OrderedDictionary   # stem -> List[string]
foreach ($p in $index.Keys) {
    if ($null -eq (Get-SourceKind $p)) { continue }
    $stem = $p.Substring(13, $p.Length - 17)
    if (-not $stemSources.Contains($stem)) { $stemSources[$stem] = New-Object 'System.Collections.Generic.List[string]' }
    $stemSources[$stem].Add($p)
}
foreach ($stem in $stemSources.Keys) {
    if ($stemSources[$stem].Count -gt 1) {
        $violations.Add("duplicate source stem '$stem': " + [string]::Join(', ', $stemSources[$stem]) + " (all map to 'apuntes/$stem.md')")
    }
}
```

### verify.ps1 — checks 5+6b (half-pair deletion, multi-candidate reverse)

Replace `$mirror = Get-MirrorPath $p` with a loop over `Get-MirrorCandidates $p`; flag if any candidate is still present (`$stagedMap.Contains($partner) -or $index.Contains($partner)`), message unchanged: `"half-pair deletion ('$partner' is still present): $p"`. Checks 1, 2, 4, 6a are untouched.

### register.ps1 — CLI and main validation

`param([Parameter(Mandatory=$true)][string]$Source)`; internal vars `$pdfPath`→`$sourcePath`, `$pdfHash`→`$sourceHash`. Exact refusal messages:

| Condition | Exact message (`[register] REFUSED: ...`) |
|---|---|
| Wrong root/ext | `source must be a staged PDF or web link under bibliografia/ (.pdf or .txt): '<path>'.` |
| Invalid stem segment | `invalid stem '<seg>' in '<path>'; allowed characters are [a-z0-9-].` (unchanged text) |
| Cross-kind: stem taken | `stem '<stem>' already has registered source '<sibling>'; one source per stem is allowed.` |
| Cross-kind: sibling staged | `stem '<stem>' collides with staged source '<sibling>'; one source per stem is allowed.` |
| Link content invalid | `'<path>' must contain exactly one line with a single absolute http(s):// URL.` |

Order of validation: normalize path → root/ext check → stem check (per `-split '/'` segment, unchanged) → both members staged (unchanged) → **cross-kind stem check (new; against `$baseMap` then `$index` for the sibling candidate)** → append-only check (unchanged) → **URL check (txt only)** → hash → deterministic rewrite (unchanged machinery).

URL check, reading the STAGED blob (D4; reuses `Read-BlobBytesViaCmd`, PS 5.1-safe):

```powershell
if ($kind -eq 'txt') {
    $linkBytes = Read-BlobBytesViaCmd $index[$sourcePath]        # staged blob ONLY
    if ($null -eq $linkBytes) { Exit-Broken "failed to read staged link blob for '$sourcePath'." }
    if ($linkBytes.Length -ge 3 -and $linkBytes[0] -eq 0xEF -and $linkBytes[1] -eq 0xBB -and $linkBytes[2] -eq 0xBF) {
        Exit-Refuse "'$sourcePath' must be BOM-free UTF-8 text; link validation failed."
    }
    foreach ($b in $linkBytes) { if ($b -eq 13) { Exit-Refuse "'$sourcePath' must use LF line endings." } }
    $text = [System.Text.Encoding]::UTF8.GetString($linkBytes)   # bytes already filtered; non-strict decode is safe
    $lines = @($text -split "`n")
    if ($lines.Count -gt 0 -and $lines[$lines.Count - 1] -eq '') { $lines = @($lines[0..($lines.Count - 2)]) }
    if ($lines.Count -ne 1 -or $lines[0] -notmatch '^https?://\S+$') {
        Exit-Refuse "'$sourcePath' must contain exactly one line with a single absolute http(s):// URL."
    }
}
```

Case: `"https://host\n"` → `["https://host",""]` → 1 line, matches. Empty file → `[""]` → regex fails. Two lines → 2 → refuse. `http://` and `https://` both accepted; no `\s` allowed in URL. Manifest write keeps `[IO.File]::WriteAllText($p, $sb.ToString(), (New-Object System.Text.UTF8Encoding($false)))` — BOM-free, LF.

### .gitattributes

```
*.pdf                      binary
*.md                       text eol=lf
*.txt                      text eol=lf
integrity/manifest.sha256  text eol=lf
.githooks/pre-commit       text eol=lf
tools/integrity/**/*.ps1    text eol=lf
```

## Testing Strategy

All cases in `tools/integrity/tests/run-integrity-tests.ps1` (TAP style, sandbox clones). Harness changes: `Invoke-Register` param `-PdfPath` → `-SourcePath` (calls `-Source`); new `New-SandboxWebPair($RepoDir, $Stem, $Url)` writing `bibliografia/$Stem.txt` (`"$Url`n"`, `Write-SandboxText`) and `apuntes/$Stem.md`, staging both; new `mirror-child.ps1` template (same AST dot-source technique as `parser-child.ps1`) invoking `Get-MirrorCandidates`/`Get-SourceKind` directly. Existing 51 cases keep their names/assertions.

| Case | Name | Asserts |
|---|---|---|
| 1 | `web-01` register web pair via `-Source` ok | exit 0; +2 lines; prior 2 lines byte-identical; ordinal-sorted (style of `sort-03`) |
| 2 | `web-02` link without URL rejected | register exit 1, `REFUSED`, manifest bytes untouched (helper-refusal style) |
| 3 | `web-03` link with invalid (non-http) URL rejected | same as web-02 |
| 4 | `web-04` unpaired web link blocked | stage txt only → commit exit 1, fragment `unpaired web link` |
| 5 | `web-05` modified registered link blocked | tamper txt, restage → fragment `content differs` |
| 6 | `web-06` modified web markdown blocked | tamper md, restage → fragment `content differs` |
| 7 | `web-07`/`web-08` half-pair web deletion blocked | `git rm` txt only / md only → fragment `half-pair deletion` (and `together with its pair`) |
| 8 | `web-09` atomic web-pair deletion ok | rm both + drop both lines → commit 0, count back to 2 |
| 9 | `web-10` duplicate stem blocked (hook) | stage `X.txt`+`X.md` while `X.pdf` registered → fragment `duplicate source stem`; `helper-04` variant: register refuses (`one source per stem`) |
| 10 | `mirror-01..04` reverse mirror resolves exact | unit: `.pdf`→`apuntes/X.md`; `.txt`→`apuntes/X.md`; `apuntes/X.md`→both candidates; non-pairable→empty |
| 11 | `eol-01` `.txt` LF normalization | write link with CRLF bytes, `git add`, staged blob has no `0x0D` and hashes equal to LF fixture |

## Threat Matrix

| Boundary | Applicability | Design response | RED tests |
|---|---|---|---|
| Documentation-like paths | **Applicable** — new file-class boundary: `bibliografia/*.txt` is now a protected source while `.txt` elsewhere is not | Single classifier `Get-SourceKind`; `.txt` is data, never executed/parsed as code | `block-02` (apuntes `.txt` stays `unregistered protected file`); `web-01..10` |
| Git repository selection | N/A — `Resolve-RepoRoot`/fixed protected roots unchanged | — | existing `closed-04` regression-covers |
| Commit state | **Applicable** — new staged-blob URL validation; pairing now cross-kind | Index-oid reads only; register refuses unstaged; check 8 on index set | `web-02/03` (register), `web-04..10` (hook) |
| Push state | N/A — no push automation | — | — |
| PR commands | N/A — no PR tooling | — | — |
| Shell/subprocess/exec | **Applicable** — URL validation reuses `cmd` blob-read; no new exec surface | `Read-BlobBytesViaCmd`/`Get-StagedBlobHash` unchanged; messages ASCII | `web-02/03` + `byte-01` regression |

## Migration / Rollout

No migration — manifest format unchanged; PDF entries/pairs untouched. Real-pair rollout order for the apply phase:

1. Create `bibliografia/unidad-01-teoria-web.txt` = single line `https://bzappellini.github.io/ARyS/unidades/u01-conceptos-seguridad/teoria.md` + LF, BOM-free.
2. Create `apuntes/unidad-01-teoria-web.md` = proposal.md **lines 105–296 inclusive** verbatim (from `# Unidad 1 — Conceptos de Seguridad` through `- Ley 25.326 (Argentina) — Protección de los Datos Personales.`), BOM-free, LF. Do **not** copy proposal lines 103–104 (fetch metadata). Byte-identity with the fetched `teoria.md` is the apply-time fixture; `.md eol=lf` normalizes the blob so the manifest hashes the LF form.
3. `git add .gitattributes`, then `git add bibliografia/unidad-01-teoria-web.txt apuntes/unidad-01-teoria-web.md`.
4. `powershell -NoProfile -ExecutionPolicy Bypass -File tools/integrity/register.ps1 -Source bibliografia/unidad-01-teoria-web.txt`.
5. Assert manifest: 4 lines; lines 1–2 byte-identical (`b86a77…` apuntes concepto, `93f5e0…` pdf concepto); order = `apuntes/unidad-01-conceptos-de-seguridad.md`, `apuntes/unidad-01-teoria-web.md`, `bibliografia/unidad-01-conceptos-de-seguridad.pdf`, `bibliografia/unidad-01-teoria-web.txt` (ordinal).
6. `git add integrity/manifest.sha256`; run harness; commit (hook validates).

Rollback (proposal): `git revert` of the change commit(s) removes both web files + their 2 manifest lines atomically (hook-compliant) and restores scripts, `.gitattributes`, README; PDF category and existing lines untouched.

## Open Questions

- None blocking. Verify-time note: byte-identity of `unidad-01-teoria-web.md` against the live URL is asserted once at apply; URL freshness is out of scope by decision D4.