#requires -Version 5.1
<#
.SYNOPSIS
    State-based pre-commit integrity verifier for the protected source layers.

.DESCRIPTION
    Verifies the STAGED git index (never working-tree bytes) against the
    append-only manifest integrity/manifest.sha256:

      - recomputes SHA-256 over each staged protected blob,
      - enforces PDF<->Markdown pairing (bibliografia/a/b.pdf <=> apuntes/a/b.md),
      - enforces append-only registration and the sole atomic-deletion exception,
      - rejects registry tampering.

    Fail-closed: any plumbing failure (missing/malformed manifest, tool error,
    invocation outside a repository) aborts with exit code 2.

.NOTES
    Exit codes: 0 = pass, 1 = policy violation (files named), 2 = broken machinery.
#>

Set-StrictMode -Version 2.0
# NOTE: $ErrorActionPreference intentionally left at its default (Continue).
# PS 5.1 turns suppressed native-command stderr (2>$null) into terminating
# errors when EAP is 'Stop'; plumbing failures are handled via explicit
# $LASTEXITCODE checks instead.

[string]$script:ManifestPath     = 'integrity/manifest.sha256'
[string[]]$script:ProtectedRoots = @('bibliografia', 'apuntes')
[int]$script:MaxReported         = 20

# ---------------------------------------------------------------- console ---

function Write-Msg {
    param([string]$Text)
    [Console]::Out.WriteLine($Text)
}

function Exit-Broken {
    param([string]$Message)
    Write-Msg "[integrity] ERROR (fail-closed): $Message"
    exit 2
}

# ------------------------------------------------------------- git helpers --

function Invoke-GitLines {
    # Callers MUST wrap the result with @(...) at the call site: PS 5.1
    # unrolls single-element results on return, so this may come back as a
    # scalar string instead of an array.
    param([string[]]$GitArgs)
    $out = & git @GitArgs 2>$null
    if ($LASTEXITCODE -ne 0) { return $null }
    if ($null -eq $out) { return @() }
    return @($out)
}

function Resolve-RepoRoot {
    $lines = @(Invoke-GitLines @('rev-parse', '--show-toplevel'))
    if (0 -eq $lines.Count -or [string]::IsNullOrWhiteSpace([string]$lines[0])) {
        Exit-Broken 'not inside a git repository.'
    }
    return ([string]$lines[0]).Trim()
}

# Locate sha256sum.exe: prefer PATH, else derive from the git installation
# (Git for Windows bundles it under <git>\usr\bin). Its directory is prepended
# to PATH so the cmd-side pipeline can resolve it (D4).
function Resolve-Sha256Sum {
    $cmd = Get-Command 'sha256sum.exe' -ErrorAction SilentlyContinue
    if ($null -ne $cmd) { return $cmd.Source }

    $gitCmd = Get-Command 'git.exe' -ErrorAction SilentlyContinue
    if ($null -ne $gitCmd) {
        $dir = Split-Path -Parent $gitCmd.Source
        while ($dir -and (Test-Path -LiteralPath $dir)) {
            $candidate = Join-Path (Join-Path $dir 'usr\bin') 'sha256sum.exe'
            if (Test-Path -LiteralPath $candidate) {
                $binDir = Split-Path -Parent $candidate
                if (-not ($env:PATH -split ';' -contains $binDir)) {
                    $env:PATH = "$binDir;$env:PATH"
                }
                return $candidate
            }
            $parent = Split-Path -Parent $dir
            if ($parent -eq $dir) { break }
            $dir = $parent
        }
    }
    return $null
}

# Byte-exact blob read through cmd redirection. PowerShell native pipelines
# decode bytes into strings, so raw bytes must never cross them (D4).
function Read-BlobBytesViaCmd {
    param([string]$RevSpec)
    $tmp = [System.IO.Path]::GetTempFileName()
    try {
        $expr = 'git cat-file blob ' + $RevSpec + ' > "' + $tmp + '" 2>nul'
        & cmd /s /c ('"' + $expr + '"') | Out-Null
        if ($LASTEXITCODE -ne 0) { return $null }
        return [System.IO.File]::ReadAllBytes($tmp)
    }
    finally {
        Remove-Item -LiteralPath $tmp -ErrorAction SilentlyContinue
    }
}

# Staged-blob SHA-256 via cmd pipe (D4). sha256sum prints "<hex>  -".
function Get-StagedBlobHash {
    param([string]$Oid)
    if ($Oid -notmatch '^[0-9a-f]{40}$') { Exit-Broken "invalid blob oid '$Oid'." }
    $out = & cmd /s /c ('"git cat-file blob ' + $Oid + ' | sha256sum"') 2>$null
    if ($LASTEXITCODE -ne 0 -or $null -eq $out) {
        Exit-Broken "sha256sum pipeline failed for blob $Oid."
    }
    $first = ([string](@($out)[0])).Trim()
    $hash = (@($first -split '\s+') | Select-Object -First 1)
    if ($hash -notmatch '^[0-9a-f]{64}$') {
        Exit-Broken "unexpected sha256sum output for blob $Oid."
    }
    return $hash
}

# ------------------------------------------------------------ manifest ------

function Parse-ManifestBytes {
    # Standard `sha256sum -c` format: <64-lowercase-hex><SP><SP><path>, LF-only,
    # UTF-8 without BOM, forward slashes, ordinal-sorted, no duplicates.
    param([byte[]]$Bytes, [string]$Origin)

    if ($null -eq $Bytes) { Exit-Broken "$Origin is unreadable." }
    if ($Bytes.Length -ge 3 -and $Bytes[0] -eq 0xEF -and $Bytes[1] -eq 0xBB -and $Bytes[2] -eq 0xBF) {
        Exit-Broken "${Origin}: UTF-8 BOM detected; BOM-free encoding required."
    }
    foreach ($b in $Bytes) {
        if ($b -eq 13) { Exit-Broken "${Origin}: CR byte found; LF line endings required." }
    }

    $decoder = New-Object System.Text.UTF8Encoding($false, $true)
    $text = $decoder.GetString($Bytes)
    if ($text.Length -eq 0) { return New-Object System.Collections.Specialized.OrderedDictionary }

    $lines = @($text -split "`n")
    if ($lines[$lines.Count - 1] -eq '') { $lines = @($lines[0..($lines.Count - 2)]) }

    $map = New-Object System.Collections.Specialized.OrderedDictionary
    $prevPath = ''
    foreach ($line in $lines) {
        if ($line -notmatch '^([0-9a-f]{64})  (.+)$') {
            Exit-Broken "${Origin}: malformed line '$line' (expected '<64-hex>  <path>')."
        }
        $hash = $Matches[1]
        $path = $Matches[2]
        if ($path.Contains('\')) { Exit-Broken "${Origin}: backslash in path '$path'; forward slashes required." }
        if ($map.Contains($path)) { Exit-Broken "${Origin}: duplicate entry for '$path'." }
        if ('' -ne $prevPath -and [string]::CompareOrdinal($prevPath, $path) -ge 0) {
            Exit-Broken "${Origin}: entries are not ordinally sorted at '$path'."
        }
        $map[$path] = $hash
        $prevPath = $path
    }
    return $map
}

# --------------------------------------------------------------- pairing ----

# bibliografia/a/b.pdf <=> apuntes/a/b.md ; returns $null for non-pairable paths.
function Get-MirrorPath {
    param([string]$Path)
    if ($Path.StartsWith('bibliografia/') -and $Path.EndsWith('.pdf')) {
        return 'apuntes/' + $Path.Substring(13, $Path.Length - 17) + '.md'
    }
    if ($Path.StartsWith('apuntes/') -and $Path.EndsWith('.md')) {
        return 'bibliografia/' + $Path.Substring(8, $Path.Length - 11) + '.pdf'
    }
    return $null
}

# ------------------------------------------------------------------ main ----

$repoRoot = Resolve-RepoRoot
Set-Location -LiteralPath $repoRoot

$shaTool = Resolve-Sha256Sum
if ($null -eq $shaTool) {
    Exit-Broken 'sha256sum.exe was not found (needed for staged-blob hashing).'
}

# --- enumerate the staged index over the protected roots --------------------
$index = New-Object System.Collections.Specialized.OrderedDictionary  # path -> oid
$lsOut = Invoke-GitLines @('ls-files', '--stage', '--', 'bibliografia', 'apuntes')
if ($null -eq $lsOut) { Exit-Broken 'git ls-files failed.' }

foreach ($entryLine in $lsOut) {
    $parts = ([string]$entryLine) -split "`t", 2
    if ($parts.Count -ne 2) { Exit-Broken "unexpected ls-files output '$entryLine'." }
    $meta = ($parts[0] -split '\s+')
    if ($meta.Count -lt 3) { Exit-Broken "unexpected ls-files metadata '$($parts[0])'." }
    if ([int]$meta[2] -ne 0) { Exit-Broken 'unresolved merge-conflict entries in the index; commit aborted.' }
    $oid = $meta[1]
    if ($oid -notmatch '^[0-9a-f]{40}$') { Exit-Broken "unexpected blob oid '$oid'." }
    $path = $parts[1]
    if ($path.StartsWith('"')) { Exit-Broken "unsupported quoted path from git: '$path'." }
    $index[$path] = $oid
}

# --- staged manifest (must exist; its absence is broken machinery) ----------
$stagedBytes = Read-BlobBytesViaCmd (':' + $script:ManifestPath)
if ($null -eq $stagedBytes) {
    Exit-Broken "staged manifest '$($script:ManifestPath)' is missing; commit aborted."
}
$stagedMap = Parse-ManifestBytes -Bytes $stagedBytes -Origin 'Staged manifest'

# --- HEAD manifest (empty map on the initial commit) -------------------------
$null = & git rev-parse --verify --quiet HEAD 2>$null
$hasHead = (0 -eq $LASTEXITCODE)
if ($hasHead) {
    $headBytes = Read-BlobBytesViaCmd ('HEAD:' + $script:ManifestPath)
    if ($null -eq $headBytes) { Exit-Broken 'HEAD manifest exists but is unreadable.' }
    $headMap = Parse-ManifestBytes -Bytes $headBytes -Origin 'HEAD manifest'
}
else {
    $headMap = New-Object System.Collections.Specialized.OrderedDictionary
}

# --- hash every staged protected blob exactly once ---------------------------
$hashByPath = New-Object System.Collections.Specialized.OrderedDictionary
foreach ($p in $index.Keys) { $hashByPath[$p] = Get-StagedBlobHash $index[$p] }

# --- blocking checks ----------------------------------------------------------
$violations = New-Object System.Collections.Generic.List[string]

# Checks 1+2: every staged protected file is registered and unmodified.
foreach ($p in $index.Keys) {
    if (-not $stagedMap.Contains($p)) {
        $violations.Add("unregistered protected file (register it via tools/integrity/register.ps1): $p")
        continue
    }
    if ($stagedMap[$p] -ne $hashByPath[$p]) {
        $violations.Add("content differs from its registered manifest entry: $p")
    }
}

# Check 3: PDF<->Markdown pairing (both staged AND both registered).
foreach ($p in $index.Keys) {
    $mirror = Get-MirrorPath $p
    if ($null -eq $mirror) { continue }
    if (-not $index.Contains($mirror)) {
        if ($p.EndsWith('.pdf')) {
            $violations.Add("unpaired PDF (missing staged Markdown counterpart '$mirror'): $p")
        }
        else {
            $violations.Add("orphan Markdown note (missing staged PDF source '$mirror'): $p")
        }
    }
    elseif (-not ($stagedMap.Contains($p) -and $stagedMap.Contains($mirror))) {
        $violations.Add("pair members must both carry manifest lines in the same commit: $p <-> $mirror")
    }
}

# Check 4: a manifest line survives while its file is absent from the index
# (covers deletions that keep their entry, and lines for nonexistent files).
foreach ($p in $stagedMap.Keys) {
    if (-not $index.Contains($p)) {
        $violations.Add("manifest line kept for a file that is not staged (delete the entry together with its pair): $p")
    }
}

# Check 6a: an existing line was modified -- registry tampering, no re-baseline exists.
foreach ($p in $headMap.Keys) {
    if ($stagedMap.Contains($p) -and $stagedMap[$p] -ne $headMap[$p]) {
        $violations.Add("registry tampering: manifest line modified for already-registered file: $p")
    }
}

# Checks 5+6b: a line removed vs HEAD is legal ONLY inside an atomic pair
# deletion -- the partner line and both files must leave together.
foreach ($p in $headMap.Keys) {
    if (-not $stagedMap.Contains($p)) {
        if ($index.Contains($p)) {
            $violations.Add("manifest line removed while its file is still staged: $p")
            continue
        }
        $mirror = Get-MirrorPath $p
        if ($null -ne $mirror -and ($stagedMap.Contains($mirror) -or $index.Contains($mirror))) {
            $violations.Add("half-pair deletion ('$mirror' is still present): $p")
        }
    }
}

# --- verdict ------------------------------------------------------------------
if ($violations.Count -gt 0) {
    Write-Msg '[integrity] COMMIT REJECTED. Protected-source violations:'
    $shown = 0
    foreach ($v in $violations) {
        if ($shown -ge $script:MaxReported) {
            Write-Msg ("  ... and " + ($violations.Count - $shown) + " more.")
            break
        }
        Write-Msg "  - $v"
        $shown++
    }
    Write-Msg '[integrity] Sources are immutable; register new material with tools/integrity/register.ps1.'
    exit 1
}

Write-Msg "[integrity] OK: $($stagedMap.Count) registered file(s) verified against staged blobs."
exit 0
