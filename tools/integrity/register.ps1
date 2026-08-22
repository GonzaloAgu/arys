#requires -Version 5.1
<#
.SYNOPSIS
    Additions-only registration of a PDF + Markdown pair into the source manifest.

.DESCRIPTION
    Workflow (stage -> register -> stage):
      1. Stage BOTH files:   git add bibliografia/<stem>.pdf apuntes/<stem>.md
      2. Register the pair:  powershell -NoProfile -ExecutionPolicy Bypass `
                                -File tools/integrity/register.ps1 `
                                -Pdf bibliografia/<stem>.pdf
      3. Restage manifest:   git add integrity/manifest.sha256
      4. Commit.

    Refuses to run unless:
      - the given PDF is staged under bibliografia/ with a [a-z0-9-]+ stem,
      - its mirrored Markdown apuntes/<same-stem>.md is also staged,
      - neither path is already registered (append-only; no mutation, no re-baseline).

    Hashes are taken from STAGED blob oids only (never working-tree bytes), so
    editor line-ending settings cannot diverge from what gets committed.

.NOTES
    Exit codes: 0 = registered | 1 = policy refusal | 2 = broken machinery.
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$Pdf
)

Set-StrictMode -Version 2.0
# NOTE: $ErrorActionPreference intentionally left at its default (Continue).
# PS 5.1 turns suppressed native-command stderr (2>$null) into terminating
# errors when EAP is 'Stop'; failures are handled via explicit
# $LASTEXITCODE checks instead.

[string]$script:ManifestPath = 'integrity/manifest.sha256'

function Write-Msg {
    param([string]$Text)
    [Console]::Out.WriteLine($Text)
}

function Exit-Broken {
    param([string]$Message)
    Write-Msg "[register] ERROR: $Message"
    exit 2
}

function Exit-Refuse {
    param([string]$Message)
    Write-Msg "[register] REFUSED: $Message"
    exit 1
}

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

function Parse-ManifestBytes {
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
$map = New-Object System.Collections.Specialized.OrderedDictionary
if ($text.Length -eq 0) { return $map }

$lines = @($text -split "`n")
if ($lines[$lines.Count - 1] -eq '') { $lines = @($lines[0..($lines.Count - 2)]) }

$prevPath = ''
foreach ($line in $lines) {
        if ($line -notmatch '^([0-9a-f]{64})  (.+)$') {
            Exit-Broken "${Origin}: malformed line '$line'."
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

# ------------------------------------------------------------------ main ----

$repoRoot = Resolve-RepoRoot
Set-Location -LiteralPath $repoRoot

$shaTool = Resolve-Sha256Sum
if ($null -eq $shaTool) { Exit-Broken 'sha256sum.exe was not found.' }

# --- normalize and validate the requested PDF path ---------------------------
$pdfPath = ($Pdf -replace '\\', '/').Trim()
while ($pdfPath.StartsWith('./')) { $pdfPath = $pdfPath.Substring(2) }

if (-not $pdfPath.StartsWith('bibliografia/') -or -not $pdfPath.EndsWith('.pdf')) {
    Exit-Refuse "source must be a staged PDF under bibliografia/: '$pdfPath'."
}
$stem = $pdfPath.Substring(13, $pdfPath.Length - 17)   # strip bibliografia/ and .pdf
foreach ($segment in ($stem -split '/')) {
    if ($segment -notmatch '^[a-z0-9-]+$') {
        Exit-Refuse "invalid stem '$segment' in '$pdfPath'; allowed characters are [a-z0-9-]."
    }
}
$mdPath = 'apuntes/' + $stem + '.md'

Write-Msg "[register] Pair: $pdfPath <-> $mdPath"

# --- enumerate staged index over the protected roots -------------------------
$index = New-Object System.Collections.Specialized.OrderedDictionary  # path -> oid
$lsOut = Invoke-GitLines @('ls-files', '--stage', '--', 'bibliografia', 'apuntes')
if ($null -eq $lsOut) { Exit-Broken 'git ls-files failed.' }
foreach ($entryLine in $lsOut) {
    $parts = ([string]$entryLine) -split "`t", 2
    if ($parts.Count -ne 2) { Exit-Broken "unexpected ls-files output '$entryLine'." }
    $meta = ($parts[0] -split '\s+')
    if ($meta.Count -lt 3) { Exit-Broken "unexpected ls-files metadata '$($parts[0])'." }
    if ([int]$meta[2] -ne 0) { Exit-Broken 'unresolved merge-conflict entries in the index.' }
    $index[$parts[1]] = $meta[1]
}

# --- both members must already be staged -------------------------------------
foreach ($required in @($pdfPath, $mdPath)) {
    if (-not $index.Contains($required)) {
        Exit-Refuse "'$required' is not staged. Stage both files first: git add '$pdfPath' '$mdPath'"
    }
}

# --- load the base manifest: staged version, else HEAD, else bootstrap-empty --
$baseMap = $null
$stagedManifest = Read-BlobBytesViaCmd (':' + $script:ManifestPath)
if ($null -ne $stagedManifest) {
    $baseMap = Parse-ManifestBytes -Bytes $stagedManifest -Origin 'Staged manifest'
}
else {
    $headManifest = Read-BlobBytesViaCmd ('HEAD:' + $script:ManifestPath)
    if ($null -ne $headManifest) {
        $baseMap = Parse-ManifestBytes -Bytes $headManifest -Origin 'HEAD manifest'
    }
    else {
        $baseMap = New-Object System.Collections.Specialized.OrderedDictionary
    }
}

# --- append-only guarantee: both lines must be absent ------------------------
foreach ($existing in @($pdfPath, $mdPath)) {
    if ($baseMap.Contains($existing)) {
        Exit-Refuse "'$existing' already has a manifest entry; the registry is append-only."
    }
}

# --- hash the STAGED blobs (D6) ------------------------------------------------
$pdfHash = Get-StagedBlobHash $index[$pdfPath]
$mdHash = Get-StagedBlobHash $index[$mdPath]

# --- rebuild the manifest deterministically -----------------------------------
$newMap = New-Object System.Collections.Specialized.OrderedDictionary
foreach ($key in $baseMap.Keys) { $newMap[$key] = $baseMap[$key] }
$newMap[$pdfPath] = $pdfHash
$newMap[$mdPath] = $mdHash

# Append-only guarantee: every pre-existing entry must be carried over verbatim.
foreach ($key in $baseMap.Keys) {
    if ($newMap[$key] -ne $baseMap[$key]) {
        Exit-Broken "internal error: existing entry for '$key' would change; aborting."
    }
}

# Deterministic ordinal (byte-wise) sort of the path set.
$sortedPaths = [string[]]@($newMap.Keys)
[System.Array]::Sort($sortedPaths, [System.StringComparer]::Ordinal)

$sb = New-Object System.Text.StringBuilder
foreach ($p in $sortedPaths) {
    [void]$sb.Append($newMap[$p])
    [void]$sb.Append('  ')
    [void]$sb.Append($p)
    [void]$sb.Append("`n")
}

$manifestDiskPath = Join-Path $repoRoot ('integrity\manifest.sha256')
$manifestDir = Split-Path -Parent $manifestDiskPath
if (-not [System.IO.Directory]::Exists($manifestDir)) {
    [void][System.IO.Directory]::CreateDirectory($manifestDir)
}
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($manifestDiskPath, $sb.ToString(), $utf8NoBom)

$restage = & git add -- $script:ManifestPath 2>&1
if ($LASTEXITCODE -ne 0) {
    Exit-Broken "failed to restage manifest: $restage"
}

Write-Msg "[register] Appended 2 manifest line(s):"
Write-Msg "[register]   $pdfHash  $pdfPath"
Write-Msg "[register]   $mdHash  $mdPath"
Write-Msg "[register] Manifest rewritten ($($newMap.Count) entries, ordinal-sorted, LF, no BOM) and restaged."
exit 0
