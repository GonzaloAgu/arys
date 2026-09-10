#requires -Version 5.1
<#
    Sandbox harness for immutable-source-integrity: clones this repo into
    disposable temp dirs, activates core.hooksPath=.githooks, drives REAL git
    commits asserting every blocking condition, legal path, and fail-closed
    behavior of the delta specs. Worktree here is read-only; mutations stay in
    sandboxes removed before exit. ASCII TAP output ("ok N - name"). sha256sum
    resolves via the same Git walk-up fallback as production (not on PATH).
    Exit codes: 0 = pass | 1 = test failure | 2 = environment problem.
#>

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Continue'

[string]$script:RepoRoot = ''
[string]$script:ShaTool  = ''
[int]$script:PassCount   = 0
[int]$script:FailCount   = 0
[int]$script:CaseNumber  = 0

[string]$StemBase = 'unidad-01-conceptos-de-seguridad'
[string]$PdfBase  = "bibliografia/$StemBase.pdf"
[string]$MdBase   = "apuntes/$StemBase.md"

function Test-Assert {
    param([string]$Name, [bool]$Condition, [string]$Detail)
    $script:CaseNumber++
    if ($Condition) {
        $script:PassCount++
        [Console]::Out.WriteLine("ok $script:CaseNumber - $Name")
    }
    else {
        $script:FailCount++
        [Console]::Out.WriteLine("not ok $script:CaseNumber - $Name")
        if (-not [string]::IsNullOrEmpty($Detail)) { [Console]::Out.WriteLine(("#     detail: " + ($Detail -replace "`r", '' -replace "`n", ' | '))) }
    }
}

function Invoke-Git {
    param([string]$RepoDir, [string[]]$GitArgs)
    $prev = (Get-Location).Path
    Set-Location -LiteralPath $RepoDir
    try {
        $out = & git @GitArgs 2>&1
        return @{ Code = [int]$LASTEXITCODE; Output = [string[]]@($out | ForEach-Object { [string]$_ }) }
    }
    finally {
        Set-Location -LiteralPath $prev
    }
}

function Invoke-Commit { param([string]$RepoDir, [string]$Message) Invoke-Git -RepoDir $RepoDir -GitArgs @('commit', '-m', $Message) }

function Get-HeadOid {
    param([string]$RepoDir)
    $r = Invoke-Git -RepoDir $RepoDir -GitArgs @('rev-parse', 'HEAD')
    if (0 -ne $r.Code) { return '' }
    return ([string]$r.Output[0]).Trim()
}

function Reset-SandboxState {
    param([string]$RepoDir)
    $null = Invoke-Git -RepoDir $RepoDir -GitArgs @('reset', '-q', '--hard')
    $null = Invoke-Git -RepoDir $RepoDir -GitArgs @('clean', '-qfd')
}

# Rejection verdict: expected exit code AND diagnostic naming the violation
# AND (when HeadBefore given) no commit actually created.
function Assert-RejectedCommit {
    param([string]$Name, [hashtable]$Result, [int]$ExpectCode, [string]$Fragment)
    [string]$joined = ($Result.Output -join ' | ')
    [bool]$ok = ($ExpectCode -eq $Result.Code) -and $joined.Contains($Fragment)
    Test-Assert $Name $ok "exit=$($Result.Code) (want $ExpectCode); out=$joined"
}

function Ensure-ParentDir {
    param([string]$Path)
    [string]$parent = Split-Path -Parent $Path
    if (-not [string]::IsNullOrEmpty($parent) -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
}

function Write-SandboxBytes { param([string]$Path, [byte[]]$Bytes)
    Ensure-ParentDir -Path $Path
    [System.IO.File]::WriteAllBytes($Path, $Bytes)
}

function Write-SandboxText { # UTF-8 without BOM; caller embeds LF endings.
    param([string]$Path, [string]$Text)
    Ensure-ParentDir -Path $Path
    [System.IO.File]::WriteAllText($Path, $Text, (New-Object System.Text.UTF8Encoding($false)))
}

function Copy-RepoFileIntoSandbox {
    param([string]$TargetRoot, [string]$RelativePath)
    [string]$dst = Join-Path $TargetRoot ($RelativePath -replace '/', '\')
    Ensure-ParentDir -Path $dst
    Copy-Item -LiteralPath (Join-Path $script:RepoRoot ($RelativePath -replace '/', '\')) -Destination $dst -Force
}

function Get-ManifestRawBytes {
    param([string]$RepoDir)
    [string]$p = Join-Path $RepoDir 'integrity\manifest.sha256'
    if (-not (Test-Path -LiteralPath $p)) { return $null }
    return [System.IO.File]::ReadAllBytes($p)
}

function Get-ManifestLines {
    param([string]$RepoDir)
    [byte[]]$b = Get-ManifestRawBytes -RepoDir $RepoDir
    if ($null -eq $b) { return @() }
    return @(([System.Text.Encoding]::UTF8.GetString($b)) -split "`n" | Where-Object { $_ -ne '' })
}

function Test-OrdinalSortedLines {
    param([string[]]$Lines)
    [string]$prev = ''
    foreach ($line in $Lines) {
        [string[]]$parts = @($line -split '  ', 2)
        if ($parts.Count -lt 2) { return $false }
        if ('' -ne $prev -and [string]::CompareOrdinal($prev, $parts[1]) -ge 0) { return $false }
        $prev = $parts[1]
    }
    return $true
}

function Resolve-ShaTool {
    # Same contract as production scripts: PATH first, else Git's bundled
    # usr\bin\sha256sum.exe found by walking up from git.exe. Load-bearing here.
    $cmd = Get-Command 'sha256sum.exe' -ErrorAction SilentlyContinue
    if ($null -ne $cmd) { return $cmd.Source }

    $gitCmd = Get-Command 'git.exe' -ErrorAction SilentlyContinue
    if ($null -ne $gitCmd) {
        [string]$dir = Split-Path -Parent $gitCmd.Source
        while ($dir -and (Test-Path -LiteralPath $dir)) {
            [string]$candidate = Join-Path (Join-Path $dir 'usr\bin') 'sha256sum.exe'
            if (Test-Path -LiteralPath $candidate) { return $candidate }
            [string]$up = Split-Path -Parent $dir
            if ($up -eq $dir) { break }
            $dir = $up
        }
    }
    return ''
}

function Read-BlobBytes { # Byte-exact blob read via cmd redirection (D4 discipline).
    param([string]$RepoDir, [string]$RevSpec)
    [string]$tmp = [System.IO.Path]::GetTempFileName()
    $prev = (Get-Location).Path
    Set-Location -LiteralPath $RepoDir
    try {
        $null = (& cmd /s /c ('"git cat-file blob ' + $RevSpec + ' > "' + $tmp + '" 2>nul"'))
        if (0 -ne $LASTEXITCODE) { return $null }
        return [System.IO.File]::ReadAllBytes($tmp)
    }
    finally {
        Set-Location -LiteralPath $prev
        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
    }
}

function Get-DotNetSha256 { # Independent reference hash, deliberately not sha256sum.
    param([byte[]]$Bytes)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return ([System.BitConverter]::ToString($sha.ComputeHash($Bytes))).Replace('-', '').ToLowerInvariant()
    }
    finally {
        $sha.Dispose()
    }
}

function Get-StagedPipeHash { # Mirrors D4 exactly: cmd-side pipe, never a PS pipeline.
    param([string]$RepoDir, [string]$Oid)
    $prev = (Get-Location).Path
    Set-Location -LiteralPath $RepoDir
    try {
        $out = & cmd /s /c ('"git cat-file blob ' + $Oid + ' | sha256sum"') 2>$null
        if (0 -ne $LASTEXITCODE -or $null -eq $out) { return '' }
        return [string](@((([string](@($out)[0])).Trim()) -split '\s+') | Select-Object -First 1)
    }
    finally {
        Set-Location -LiteralPath $prev
    }
}

function Get-StagedOid {
    param([string]$RepoDir, [string]$Path)
    $r = Invoke-Git -RepoDir $RepoDir -GitArgs @('ls-files', '--stage', '--', $Path)
    if (0 -ne $r.Code -or $r.Output.Count -lt 1) { return '' }
    return [string]@((([string]$r.Output[0]) -split '\s+'))[1]
}

function New-FakePdfBytes { # Deterministic binary fixture (*.pdf binary => opaque bytes).
    param([string]$Stem)
    [byte[]]$head = [System.Text.Encoding]::ASCII.GetBytes("%PDF-1.4 sandbox fixture $Stem`n%EOF`n")
    [byte[]]$body = [byte[]]((0..511) | ForEach-Object { [byte]($_ % 256) })
    return [byte[]]($head + $body)
}

function New-SandboxMarkdown { param([string]$Stem) return "# $Stem`n`nDerived sandbox counterpart for integration testing.`nSecond line.`n" }

function Add-SandboxPairFiles { # Writes deterministic pair into sandbox and stages both.
    param([string]$RepoDir, [string]$Stem)
    Write-SandboxBytes -Path (Join-Path $RepoDir "bibliografia\$Stem.pdf") -Bytes (New-FakePdfBytes -Stem $Stem)
    Write-SandboxText -Path (Join-Path $RepoDir "apuntes\$Stem.md") -Text (New-SandboxMarkdown -Stem $Stem)
    $r = Invoke-Git -RepoDir $RepoDir -GitArgs @('add', '--', "bibliografia/$Stem.pdf", "apuntes/$Stem.md")
    if (0 -ne $r.Code) { throw ("staging pair failed in ${RepoDir}: " + ($r.Output -join '; ')) }
}

function New-SandboxWebPair { # Writes a web-link source + mirror into sandbox and stages both.
    param([string]$RepoDir, [string]$Stem, [string]$Url)
    Write-SandboxText -Path (Join-Path $RepoDir "bibliografia\$Stem.txt") -Text ("$Url`n")
    Write-SandboxText -Path (Join-Path $RepoDir "apuntes\$Stem.md") -Text (New-SandboxMarkdown -Stem $Stem)
    $r = Invoke-Git -RepoDir $RepoDir -GitArgs @('add', '--', "bibliografia/$Stem.txt", "apuntes/$Stem.md")
    if (0 -ne $r.Code) { throw ("staging web pair failed in ${RepoDir}: " + ($r.Output -join '; ')) }
}

function New-SandboxWebPairBytes { # Writes a web pair with explicit raw txt bytes and stages both.
    param([string]$RepoDir, [string]$Stem, [byte[]]$TxtBytes)
    Write-SandboxBytes -Path (Join-Path $RepoDir "bibliografia\$Stem.txt") -Bytes $TxtBytes
    Write-SandboxText -Path (Join-Path $RepoDir "apuntes\$Stem.md") -Text (New-SandboxMarkdown -Stem $Stem)
    $r = Invoke-Git -RepoDir $RepoDir -GitArgs @('add', '--', "bibliografia/$Stem.txt", "apuntes/$Stem.md")
    if (0 -ne $r.Code) { throw ("staging web pair (bytes) failed in ${RepoDir}: " + ($r.Output -join '; ')) }
}

function Configure-SandboxRepo { # Identity only; EOL policy is decided per scenario.
    param([string]$RepoDir)
    $null = Invoke-Git -RepoDir $RepoDir -GitArgs @('config', 'user.name', 'Integrity Harness')
    $null = Invoke-Git -RepoDir $RepoDir -GitArgs @('config', 'user.email', 'integrity-harness@example.invalid')
    $null = Invoke-Git -RepoDir $RepoDir -GitArgs @('config', 'commit.gpgsign', 'false')
}

function Activate-SandboxHooks { # D8 activation, exactly as README documents it.
    param([string]$RepoDir)
    $r = Invoke-Git -RepoDir $RepoDir -GitArgs @('config', 'core.hooksPath', '.githooks')
    if (0 -ne $r.Code) { throw ("hooks activation failed in ${RepoDir}: " + ($r.Output -join '; ')) }
}

function New-SandboxClone {
    param([string]$ParentDir, [string]$Name, [switch]$AutocrlfTrue)
    [string]$dst = Join-Path $ParentDir $Name
    [string[]]$cloneArgs = @('clone', '-q')
    if ($AutocrlfTrue) { $cloneArgs += @('-c', 'core.autocrlf=true') } # persists in clone config
    $r = Invoke-Git -RepoDir $ParentDir -GitArgs ($cloneArgs + @($script:RepoRoot, $dst))
    if (0 -ne $r.Code) { throw ("clone failed: " + ($r.Output -join '; ')) }
    Configure-SandboxRepo -RepoDir $dst
    if (-not $AutocrlfTrue) { $null = Invoke-Git -RepoDir $dst -GitArgs @('config', 'core.autocrlf', 'false') }
    # Clone checked out under the machine default; re-sync worktree bytes to the
    # now-active EOL policy so later `git rm` is not refused by dirty-state safety.
    $null = Invoke-Git -RepoDir $dst -GitArgs @('checkout', '--', '.')
    Activate-SandboxHooks -RepoDir $dst
    return $dst
}

function New-SandboxScratch { # Empty repo (zero commits) for bootstrap scenarios.
    param([string]$ParentDir, [string]$Name)
    [string]$dst = Join-Path $ParentDir $Name
    $null = New-Item -ItemType Directory -Path $dst -Force
    $r = Invoke-Git -RepoDir $ParentDir -GitArgs @('init', '-q', $dst)
    if (0 -ne $r.Code) { throw ("init failed: " + ($r.Output -join '; ')) }
    Configure-SandboxRepo -RepoDir $dst
    $null = Invoke-Git -RepoDir $dst -GitArgs @('config', 'core.autocrlf', 'false')
    return $dst
}

function Invoke-Register {
    param([string]$RepoDir, [string]$SourcePath)
    $prev = (Get-Location).Path
    Set-Location -LiteralPath $RepoDir
    try {
        $out = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File 'tools/integrity/register.ps1' -Source $SourcePath 2>&1
        return @{ Code = [int]$LASTEXITCODE; Output = [string[]]@($out | ForEach-Object { [string]$_ }) }
    }
    finally {
        Set-Location -LiteralPath $prev
    }
}

$script:ParserChildTemplate = @'
param([Parameter(Mandatory)][string]$VerifyScript, [Parameter(Mandatory)][string]$BytesPath, [Parameter(Mandatory)][string]$FunctionName)
$tokens = $null; $errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($VerifyScript, [ref]$tokens, [ref]$errors)
if ($null -ne $errors -and $errors.Count -gt 0) { [Console]::Out.WriteLine('PARSE_ERRORS'); exit 3 }
$funcs = @($ast.FindAll({ param($a) $a -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true))
foreach ($f in $funcs) { . ([scriptblock]::Create($f.Extent.Text)) }
$map = & $FunctionName -Bytes ([System.IO.File]::ReadAllBytes($BytesPath)) -Origin 'unit-test'
[Console]::Out.WriteLine('COUNT=' + $map.Count)
exit 0
'@

function Invoke-ParserCase {
    param([string]$ChildScript, [byte[]]$Bytes, [string]$ScratchDir)
    [string]$file = Join-Path $ScratchDir ([System.IO.Path]::GetRandomFileName())
    Write-SandboxBytes -Path $file -Bytes $Bytes
    $out = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $ChildScript -VerifyScript (Join-Path $script:RepoRoot 'tools\integrity\verify.ps1') -BytesPath $file -FunctionName 'Parse-ManifestBytes' 2>&1
    Remove-Item -LiteralPath $file -Force -ErrorAction SilentlyContinue
    return @{ Code = [int]$LASTEXITCODE; Output = [string[]]@($out | ForEach-Object { [string]$_ }) }
}

function Invoke-EnvironmentProbes {
    [bool]$ok = (-not [string]::IsNullOrEmpty($script:RepoRoot)) -and (-not [string]::IsNullOrEmpty($script:ShaTool))
    Test-Assert 'env-01 repo root and sha256sum walk-up resolved' $ok "root=$script:RepoRoot tool=$script:ShaTool"
}

function Invoke-ParserUnitTests {
    param([string]$ScratchDir, [string]$ChildScript)

    [string]$hashA = ('ab' * 32)
    [string]$hashB = ('cd' * 32)
    [string]$validTwo = "$hashA  apuntes/a.md`n$hashB  bibliografia/b.pdf`n"

    $bomList = New-Object System.Collections.Generic.List[byte]
    foreach ($b in @(0xEF, 0xBB, 0xBF)) { $bomList.Add([byte]$b) }
    foreach ($b in [System.Text.Encoding]::UTF8.GetBytes($validTwo)) { $bomList.Add($b) }

    $cases = @(
        @{ Name = 'parser-01 accepts two valid lines'; Bytes = [System.Text.Encoding]::UTF8.GetBytes($validTwo); ExpectCode = 0; ExpectCount = 2 },
        @{ Name = 'parser-02 accepts empty manifest'; Bytes = [System.Text.Encoding]::UTF8.GetBytes(''); ExpectCode = 0; ExpectCount = 0 },
        @{ Name = 'parser-03 rejects short hash'; Bytes = [System.Text.Encoding]::UTF8.GetBytes((('ab' * 31) + 'a') + "  apuntes/a.md`n"); ExpectCode = 2 },
        @{ Name = 'parser-04 rejects long hash'; Bytes = [System.Text.Encoding]::UTF8.GetBytes((('ab' * 32) + 'a') + "  apuntes/a.md`n"); ExpectCode = 2 },
        @{ Name = 'parser-05 rejects uppercase hash'; Bytes = [System.Text.Encoding]::UTF8.GetBytes(('AB' * 32) + "  apuntes/a.md`n"); ExpectCode = 2 },
        @{ Name = 'parser-06 rejects single-space separator'; Bytes = [System.Text.Encoding]::UTF8.GetBytes("$hashA apuntes/a.md`n"); ExpectCode = 2 },
        @{ Name = 'parser-07 rejects CR line endings'; Bytes = [System.Text.Encoding]::UTF8.GetBytes("$hashA  apuntes/a.md`r`n$hashB  bibliografia/b.pdf`r`n"); ExpectCode = 2 },
        @{ Name = 'parser-08 rejects UTF-8 BOM'; Bytes = $bomList.ToArray(); ExpectCode = 2 },
        @{ Name = 'parser-09 rejects backslash path'; Bytes = [System.Text.Encoding]::UTF8.GetBytes("$hashA  apuntes\a.md`n"); ExpectCode = 2 },
        @{ Name = 'parser-10 rejects unsorted entries'; Bytes = [System.Text.Encoding]::UTF8.GetBytes("$hashB  bibliografia/b.pdf`n$hashA  apuntes/a.md`n"); ExpectCode = 2 },
        @{ Name = 'parser-11 rejects duplicate entry'; Bytes = [System.Text.Encoding]::UTF8.GetBytes("$hashA  apuntes/a.md`n$hashA  apuntes/a.md`n"); ExpectCode = 2 },
        @{ Name = 'parser-12 rejects non-manifest text'; Bytes = [System.Text.Encoding]::UTF8.GetBytes("not a manifest line`n"); ExpectCode = 2 }
    )

    foreach ($case in $cases) {
        $r = Invoke-ParserCase -ChildScript $ChildScript -Bytes $case.Bytes -ScratchDir $ScratchDir
        [bool]$ok = ($case.ExpectCode -eq $r.Code)
        [string]$detail = "exit=$($r.Code); out=$($r.Output -join ' | ')"
        if ($ok -and $case.ContainsKey('ExpectCount')) {
            [string]$countLine = [string](@($r.Output | Where-Object { $_.StartsWith('COUNT=') }) | Select-Object -First 1)
            $ok = ($countLine -eq ('COUNT=' + $case.ExpectCount))
        }
        Test-Assert $case.Name $ok $detail
    }
}

$script:MirrorChildTemplate = @'
param([Parameter(Mandatory)][string]$VerifyScript, [Parameter(Mandatory)][string]$Path)
$tokens = $null; $errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($VerifyScript, [ref]$tokens, [ref]$errors)
if ($null -ne $errors -and $errors.Count -gt 0) { [Console]::Out.WriteLine('PARSE_ERRORS'); exit 3 }
$funcs = @($ast.FindAll({ param($a) $a -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true))
foreach ($f in $funcs) { . ([scriptblock]::Create($f.Extent.Text)) }
$kind = Get-SourceKind -Path $Path
if ($null -eq $kind) { [Console]::Out.WriteLine('KIND=null') } else { [Console]::Out.WriteLine('KIND=' + $kind) }
$cands = @(Get-MirrorCandidates -Path $Path)
[Console]::Out.WriteLine('CANDIDATES=' + ($cands -join ','))
exit 0
'@

function Invoke-MirrorCase {
    param([string]$ChildScript, [string]$Path)
    $out = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $ChildScript -VerifyScript (Join-Path $script:RepoRoot 'tools\integrity\verify.ps1') -Path $Path 2>&1
    return @{ Code = [int]$LASTEXITCODE; Output = [string[]]@($out | ForEach-Object { [string]$_ }) }
}

function Invoke-MirrorUnitTests {
    param([string]$ChildScript)

    $cases = @(
        @{ Name = 'mirror-01 pdf source maps to apuntes/<stem>.md'; Path = 'bibliografia/unidad-01-conceptos-de-seguridad.pdf'; Kind = 'pdf'; Cand = 'apuntes/unidad-01-conceptos-de-seguridad.md' },
        @{ Name = 'mirror-02 txt source maps to apuntes/<stem>.md'; Path = 'bibliografia/unidad-01-teoria-web.txt'; Kind = 'txt'; Cand = 'apuntes/unidad-01-teoria-web.md' },
        @{ Name = 'mirror-03 apuntes/<stem>.md maps to all source candidates'; Path = 'apuntes/unidad-01-teoria-web.md'; Kind = 'null'; Cand = 'bibliografia/unidad-01-teoria-web.pdf,bibliografia/unidad-01-teoria-web.txt,bibliografia/unidad-01-teoria-web.md' },
        @{ Name = 'mirror-04 non-pairable path maps to empty set'; Path = 'apuntes/extra-notes.txt'; Kind = 'null'; Cand = '' }
    )
    foreach ($case in $cases) {
        $r = Invoke-MirrorCase -ChildScript $ChildScript -Path $case.Path
        $kindLine = [string](@($r.Output | Where-Object { $_.StartsWith('KIND=') }) | Select-Object -First 1)
        $candLine = [string](@($r.Output | Where-Object { $_.StartsWith('CANDIDATES=') }) | Select-Object -First 1)
        [bool]$ok = ($null -ne $kindLine -and $kindLine -eq ('KIND=' + $case.Kind)) -and ($candLine -eq ('CANDIDATES=' + $case.Cand))
        Test-Assert $case.Name $ok "exit=$($r.Code); out=$(($r.Output -join ' | '))"
    }
}

function Invoke-WebCategoryTests {
    param([string]$ParentDir)

    # NOTE: this sandbox stem deliberately differs from the real registered web
    # pair (unidad-01-teoria-web) so a New-SandboxClone of the current repo does
    # not already contain it, keeping web-01's registration non-colliding.
    $webStem  = 'webdemo'
    $webTxt   = "bibliografia/$webStem.txt"
    $webMd    = "apuntes/$webStem.md"
    $webUrl   = 'https://bzappellini.github.io/ARyS/unidades/u01-conceptos-seguridad/teoria.md'

    # Committed web-pair base: register via -Source and commit (hook accepts). This
    # clone also hosts the web-05..09 scenarios via Reset-SandboxState between them.
    $sbW = New-SandboxClone -ParentDir $ParentDir -Name 'webpair'
    [string[]]$baseline = @(Get-ManifestLines -RepoDir $sbW)
    New-SandboxWebPair -RepoDir $sbW -Stem $webStem -Url $webUrl
    $r1 = Invoke-Register -RepoDir $sbW -SourcePath $webTxt
    [string[]]$after = @(Get-ManifestLines -RepoDir $sbW)
    [bool]$intact = $true
    foreach ($line in $baseline) { if (@($after) -cnotcontains $line) { $intact = $false } }
    [byte[]]$raw = Get-ManifestRawBytes -RepoDir $sbW
    [bool]$hygiene = ($after.Count -eq ($baseline.Count + 2)) -and $intact -and (Test-OrdinalSortedLines -Lines $after) -and (-not (@($raw) -contains 13)) -and ($raw[$raw.Length - 1] -eq 10)
    $null = Invoke-Git -RepoDir $sbW -GitArgs @('add', '--', 'integrity/manifest.sha256')
    $c1 = Invoke-Commit -RepoDir $sbW -Message 'register web pair base'
    [string]$c1out = ($c1.Output -join ' | ')
    Test-Assert 'web-01 register web pair via -Source ok, prior lines byte-identical, ordinal' ((0 -eq $r1.Code) -and (0 -eq $c1.Code) -and $hygiene -and $c1out.Contains('[integrity] OK:')) "reg=$($r1.Code); commit=$($c1.Code); lines=$($after.Count); out=$c1out"

    # web-02: link with no URL rejected; manifest untouched.
    $sb2 = New-SandboxClone -ParentDir $ParentDir -Name 'web02'
    [string]$base2 = [Convert]::ToBase64String((Get-ManifestRawBytes -RepoDir $sb2))
    New-SandboxWebPair -RepoDir $sb2 -Stem 'web-nourl' -Url ''
    $r2 = Invoke-Register -RepoDir $sb2 -SourcePath 'bibliografia/web-nourl.txt'
    [bool]$ok2 = (1 -eq $r2.Code) -and ((($r2.Output -join ' | ')).Contains('REFUSED')) -and ($base2 -eq [Convert]::ToBase64String((Get-ManifestRawBytes -RepoDir $sb2)))
    Test-Assert 'web-02 link without URL rejected, manifest untouched' $ok2 "exit=$($r2.Code); out=$(($r2.Output -join ' | '))"

    # web-03: link with a non-http URL rejected; manifest untouched.
    $sb3 = New-SandboxClone -ParentDir $ParentDir -Name 'web03'
    [string]$base3 = [Convert]::ToBase64String((Get-ManifestRawBytes -RepoDir $sb3))
    New-SandboxWebPair -RepoDir $sb3 -Stem 'web-badurl' -Url 'ftp://example.com/x'
    $r3 = Invoke-Register -RepoDir $sb3 -SourcePath 'bibliografia/web-badurl.txt'
    [bool]$ok3 = (1 -eq $r3.Code) -and ((($r3.Output -join ' | ')).Contains('REFUSED')) -and ($base3 -eq [Convert]::ToBase64String((Get-ManifestRawBytes -RepoDir $sb3)))
    Test-Assert 'web-03 link with invalid (non-http) URL rejected, manifest untouched' $ok3 "exit=$($r3.Code); out=$(($r3.Output -join ' | '))"

    # web-04: unpaired web link blocked (manifest carries the txt line, no md staged).
    $sb4 = New-SandboxClone -ParentDir $ParentDir -Name 'web04'
    Write-SandboxText -Path (Join-Path $sb4 'bibliografia\web-solo.txt') -Text "https://example.com/solo`n"
    $null = Invoke-Git -RepoDir $sb4 -GitArgs @('add', '--', 'bibliografia/web-solo.txt')
    [string]$h4 = Get-DotNetSha256 -Bytes (Read-BlobBytes -RepoDir $sb4 -RevSpec (Get-StagedOid -RepoDir $sb4 -Path 'bibliografia/web-solo.txt'))
    [string[]]$base4 = @(Get-ManifestLines -RepoDir $sb4)
    Write-SandboxText -Path (Join-Path $sb4 'integrity\manifest.sha256') -Text ($base4[0] + "`n" + $base4[1] + "`n" + "$h4  bibliografia/web-solo.txt`n")
    $null = Invoke-Git -RepoDir $sb4 -GitArgs @('add', '--', 'integrity/manifest.sha256')
    Assert-RejectedCommit -Name 'web-04 unpaired web link blocked' -Result (Invoke-Commit -RepoDir $sb4 -Message 'stage lone web link') -ExpectCode 1 -Fragment 'unpaired web link'

    # web-05: tampered registered link blocked.
    [System.IO.File]::AppendAllText((Join-Path $sbW ($webTxt -replace '/', '\')), "tampered`n")
    $null = Invoke-Git -RepoDir $sbW -GitArgs @('add', '--', $webTxt)
    Assert-RejectedCommit -Name 'web-05 modified registered link blocked' -Result (Invoke-Commit -RepoDir $sbW -Message 'tamper registered link') -ExpectCode 1 -Fragment 'content differs'
    Reset-SandboxState -RepoDir $sbW

    # web-06: tampered registered web markdown blocked.
    [System.IO.File]::AppendAllText((Join-Path $sbW ($webMd -replace '/', '\')), "`nTampered note.`n")
    $null = Invoke-Git -RepoDir $sbW -GitArgs @('add', '--', $webMd)
    Assert-RejectedCommit -Name 'web-06 modified web markdown blocked' -Result (Invoke-Commit -RepoDir $sbW -Message 'tamper registered web note') -ExpectCode 1 -Fragment 'content differs'
    Reset-SandboxState -RepoDir $sbW

    # web-07: half-pair web deletion (link removed along with its manifest line;
    # keeps the markdown + its line => check 5+6b "half-pair deletion").
    $null = Invoke-Git -RepoDir $sbW -GitArgs @('rm', '-q', '--', $webTxt)
    [string]$kept7 = (@(Get-ManifestLines -RepoDir $sbW) | Where-Object { -not $_.EndsWith($webTxt) }) -join "`n"
    Write-SandboxText -Path (Join-Path $sbW 'integrity\manifest.sha256') -Text ($kept7 + "`n")
    $null = Invoke-Git -RepoDir $sbW -GitArgs @('add', '--', 'integrity/manifest.sha256')
    Assert-RejectedCommit -Name 'web-07 half-pair web deletion (link) blocked' -Result (Invoke-Commit -RepoDir $sbW -Message 'half web deletion link') -ExpectCode 1 -Fragment 'half-pair deletion'
    Reset-SandboxState -RepoDir $sbW

    # web-08: half-pair web deletion (markdown removed + its line dropped;
    # keeps the link + its line => reverse-direction "half-pair deletion").
    $null = Invoke-Git -RepoDir $sbW -GitArgs @('rm', '-q', '--', $webMd)
    [string]$kept8 = (@(Get-ManifestLines -RepoDir $sbW) | Where-Object { -not $_.EndsWith($webMd) }) -join "`n"
    Write-SandboxText -Path (Join-Path $sbW 'integrity\manifest.sha256') -Text ($kept8 + "`n")
    $null = Invoke-Git -RepoDir $sbW -GitArgs @('add', '--', 'integrity/manifest.sha256')
    Assert-RejectedCommit -Name 'web-08 half-pair web deletion (markdown) blocked' -Result (Invoke-Commit -RepoDir $sbW -Message 'half web deletion md') -ExpectCode 1 -Fragment 'half-pair deletion'
    Reset-SandboxState -RepoDir $sbW

    # web-09: atomic web-pair deletion ok, baseline restored.
    $null = Invoke-Git -RepoDir $sbW -GitArgs @('rm', '-q', '--', $webTxt, $webMd)
    [string]$kept9 = (@(Get-ManifestLines -RepoDir $sbW) | Where-Object { -not ($_.EndsWith($webTxt) -or $_.EndsWith($webMd)) }) -join "`n"
    Write-SandboxText -Path (Join-Path $sbW 'integrity\manifest.sha256') -Text ($kept9 + "`n")
    $null = Invoke-Git -RepoDir $sbW -GitArgs @('add', '--', 'integrity/manifest.sha256')
    $res9 = Invoke-Commit -RepoDir $sbW -Message 'atomic deletion of web pair'
    Test-Assert 'web-09 atomic web-pair deletion ok, baseline restored' ((0 -eq $res9.Code) -and ($baseline.Count -eq @(Get-ManifestLines -RepoDir $sbW).Count)) "exit=$($res9.Code); lines=$(@(Get-ManifestLines -RepoDir $sbW).Count)"

    # web-10: duplicate stem blocked by the hook when a sibling source is registered.
    $sb10 = New-SandboxClone -ParentDir $ParentDir -Name 'web10'
    Write-SandboxText -Path (Join-Path $sb10 "bibliografia\$StemBase.txt") -Text "https://example.com/dup`n"
    $null = Invoke-Git -RepoDir $sb10 -GitArgs @('add', '--', "bibliografia/$StemBase.txt")
    Assert-RejectedCommit -Name 'web-10 duplicate stem blocked (hook)' -Result (Invoke-Commit -RepoDir $sb10 -Message 'stage duplicate-stem link') -ExpectCode 1 -Fragment 'duplicate source stem'

    # helper-04: register refuses a duplicate stem ("one source per stem").
    $sbH = New-SandboxClone -ParentDir $ParentDir -Name 'helper4'
    Write-SandboxText -Path (Join-Path $sbH "bibliografia\$StemBase.txt") -Text "https://example.com/dup`n"
    $null = Invoke-Git -RepoDir $sbH -GitArgs @('add', '--', "bibliografia/$StemBase.txt")
    [string]$baseH = [Convert]::ToBase64String((Get-ManifestRawBytes -RepoDir $sbH))
    $rH = Invoke-Register -RepoDir $sbH -SourcePath "bibliografia/$StemBase.txt"
    [bool]$okH = (1 -eq $rH.Code) -and ((($rH.Output -join ' | ')).Contains('one source per stem')) -and ($baseH -eq [Convert]::ToBase64String((Get-ManifestRawBytes -RepoDir $sbH)))
    Test-Assert 'helper-04 register refuses duplicate stem one source per stem' $okH "exit=$($rH.Code); out=$(($rH.Output -join ' | '))"
}

function Invoke-EOLLinkTest {
    param([string]$ParentDir)

    # eol-01: .txt CRLF working-tree bytes normalize to LF in the staged blob.
    $sb = New-SandboxClone -ParentDir $ParentDir -Name 'eol01'
    [byte[]]$crlfBytes = [System.Text.Encoding]::UTF8.GetBytes("https://example.com/eol`r`n")
    New-SandboxWebPairBytes -RepoDir $sb -Stem 'eol-link' -TxtBytes $crlfBytes
    [string]$txtOid = Get-StagedOid -RepoDir $sb -Path 'bibliografia/eol-link.txt'
    [byte[]]$blobBytes = Read-BlobBytes -RepoDir $sb -RevSpec $txtOid
    [bool]$noCr = ($null -ne $blobBytes) -and (-not (@($blobBytes) -contains 13))
    [byte[]]$lfFixture = [System.Text.Encoding]::UTF8.GetBytes("https://example.com/eol`n")
    [bool]$hashEq = ($null -ne $blobBytes) -and ((Get-DotNetSha256 -Bytes $blobBytes) -ceq (Get-DotNetSha256 -Bytes $lfFixture))
    Test-Assert 'eol-01 .txt CRLF normalized to LF in staged blob' ($noCr -and $hashEq) "noCr=$noCr hashEq=$hashEq"
}

function Invoke-SortAppendTests {
    param([string]$ParentDir)

    $sb = New-SandboxClone -ParentDir $ParentDir -Name 'sortappend'
    [string[]]$baseline = @(Get-ManifestLines -RepoDir $sb)
    Test-Assert 'sort-01 baseline manifest has paired entries' (($baseline.Count -ge 2) -and (0 -eq ($baseline.Count % 2))) "count=$($baseline.Count)"

    Add-SandboxPairFiles -RepoDir $sb -Stem 'aaaa-second'
    $r = Invoke-Register -RepoDir $sb -SourcePath 'bibliografia/aaaa-second.pdf'
    Test-Assert 'sort-02 register new pair exits 0' (0 -eq $r.Code) ($r.Output -join ' | ')

    [string[]]$afterFirst = @(Get-ManifestLines -RepoDir $sb)
    [bool]$intact = $true
    foreach ($line in $baseline) { if (@($afterFirst) -cnotcontains $line) { $intact = $false } }
    [byte[]]$raw = Get-ManifestRawBytes -RepoDir $sb
    [bool]$hygiene = (($afterFirst.Count -eq ($baseline.Count + 2)) -and $intact -and (Test-OrdinalSortedLines -Lines $afterFirst) -and (($raw[0] -ge 48 -and $raw[0] -le 57) -or ($raw[0] -ge 97 -and $raw[0] -le 102)) -and (-not (@($raw) -contains 13)) -and ($raw[$raw.Length - 1] -eq 10))
    Test-Assert 'sort-03 append: +2 lines, prior byte-identical, ordinal-sorted' $hygiene "lines=$($afterFirst.Count)"

    Add-SandboxPairFiles -RepoDir $sb -Stem 'zzz-third'
    $r = Invoke-Register -RepoDir $sb -SourcePath 'bibliografia/zzz-third.pdf'
    Test-Assert 'sort-04 register second pair exits 0' (0 -eq $r.Code) ($r.Output -join ' | ')

    [string[]]$afterSecond = @(Get-ManifestLines -RepoDir $sb)
    [bool]$intact2 = $true
    foreach ($line in $afterFirst) { if (@($afterSecond) -cnotcontains $line) { $intact2 = $false } }
    Test-Assert 'sort-05 re-append stable: prior intact, still sorted' (($afterSecond.Count -eq ($afterFirst.Count + 2)) -and $intact2 -and (Test-OrdinalSortedLines -Lines $afterSecond)) "lines=$($afterSecond.Count)"
}

function Copy-MachineryIntoScratch {
    param([string]$ScratchDir)
    foreach ($rel in @('.gitattributes', '.githooks/pre-commit', 'tools/integrity/verify.ps1', 'tools/integrity/register.ps1', 'README.md')) {
        Copy-RepoFileIntoSandbox -TargetRoot $ScratchDir -RelativePath $rel
    }
    $null = Invoke-Git -RepoDir $ScratchDir -GitArgs @('add', '--', '.gitattributes', '.githooks', 'tools', 'README.md')
}

function Invoke-BootstrapTests {
    param([string]$ParentDir)

    # boot-01: strict bootstrap â€” compliant initial commit accepted on empty HEAD.
    $sb = New-SandboxScratch -ParentDir $ParentDir -Name 'boot-ok'
    Copy-MachineryIntoScratch -ScratchDir $sb
    Add-SandboxPairFiles -RepoDir $sb -Stem 'alpha-guide'
    $reg = Invoke-Register -RepoDir $sb -SourcePath 'bibliografia/alpha-guide.pdf'
    $null = Invoke-Git -RepoDir $sb -GitArgs @('add', '--', 'integrity/manifest.sha256')
    Activate-SandboxHooks -RepoDir $sb
    $r = Invoke-Commit -RepoDir $sb -Message 'bootstrap compliant pair'
    [string]$joined = ($r.Output -join ' | ')
    [bool]$ok = (0 -eq $reg.Code) -and (0 -eq $r.Code) -and $joined.Contains('[integrity] OK:') -and (2 -eq @(Get-ManifestLines -RepoDir $sb).Count)
    Test-Assert 'boot-01 compliant initial commit accepted' $ok "reg=$($reg.Code); exit=$($r.Code); out=$joined"

    # boot-02: first commit registering a PDF without its Markdown is rejected.
    $sb2 = New-SandboxScratch -ParentDir $ParentDir -Name 'boot-bad'
    Copy-MachineryIntoScratch -ScratchDir $sb2
    Write-SandboxBytes -Path (Join-Path $sb2 'bibliografia\beta-solo.pdf') -Bytes (New-FakePdfBytes -Stem 'beta-solo')
    $null = Invoke-Git -RepoDir $sb2 -GitArgs @('add', '--', 'bibliografia/beta-solo.pdf')
    [string]$h = Get-DotNetSha256 -Bytes (Read-BlobBytes -RepoDir $sb2 -RevSpec (Get-StagedOid -RepoDir $sb2 -Path 'bibliografia/beta-solo.pdf'))
    Write-SandboxText -Path (Join-Path $sb2 'integrity\manifest.sha256') -Text "$h  bibliografia/beta-solo.pdf`n"
    $null = Invoke-Git -RepoDir $sb2 -GitArgs @('add', '--', 'integrity/manifest.sha256')
    Activate-SandboxHooks -RepoDir $sb2
    Assert-RejectedCommit -Name 'boot-02 unpaired bootstrap blocked' -Result (Invoke-Commit -RepoDir $sb2 -Message 'bootstrap unpaired source') -ExpectCode 1 -Fragment 'unpaired PDF'
}

function Invoke-BlockingTests {
    param([string]$ParentDir)

    $sb = New-SandboxClone -ParentDir $ParentDir -Name 'blocking'

    # block-01 (condition 1): modified registered source names the file.
    [System.IO.File]::AppendAllText((Join-Path $sb 'apuntes\unidad-01-conceptos-de-seguridad.md'), "`nTampered paragraph.`n")
    $null = Invoke-Git -RepoDir $sb -GitArgs @('add', '--', $MdBase)
    Assert-RejectedCommit -Name 'block-01 modified registered source' -Result (Invoke-Commit -RepoDir $sb -Message 'tamper registered note') -ExpectCode 1 -Fragment 'content differs'
    Reset-SandboxState -RepoDir $sb

    # block-02 (condition 2): unregistered protected addition.
    Write-SandboxText -Path (Join-Path $sb 'apuntes\extra-notes.txt') -Text "stray protected file`n"
    $null = Invoke-Git -RepoDir $sb -GitArgs @('add', '--', 'apuntes/extra-notes.txt')
    Assert-RejectedCommit -Name 'block-02 unregistered protected addition' -Result (Invoke-Commit -RepoDir $sb -Message 'sneak unregistered file') -ExpectCode 1 -Fragment 'unregistered protected file'
    Reset-SandboxState -RepoDir $sb

    # block-03 (condition 3a): new PDF without its Markdown counterpart.
    Write-SandboxBytes -Path (Join-Path $sb 'bibliografia\beta-lecture.pdf') -Bytes (New-FakePdfBytes -Stem 'beta-lecture')
    $null = Invoke-Git -RepoDir $sb -GitArgs @('add', '--', 'bibliografia/beta-lecture.pdf')
    Assert-RejectedCommit -Name 'block-03 unpaired new pdf' -Result (Invoke-Commit -RepoDir $sb -Message 'stage lone pdf') -ExpectCode 1 -Fragment 'unpaired PDF'
    Reset-SandboxState -RepoDir $sb

    # block-04 (condition 3b, symmetric): orphan Markdown without its PDF source.
    Write-SandboxText -Path (Join-Path $sb 'apuntes\gamma-notes.md') -Text (New-SandboxMarkdown -Stem 'gamma-notes')
    $null = Invoke-Git -RepoDir $sb -GitArgs @('add', '--', 'apuntes/gamma-notes.md')
    Assert-RejectedCommit -Name 'block-04 orphan markdown note' -Result (Invoke-Commit -RepoDir $sb -Message 'stage lone md') -ExpectCode 1 -Fragment 'orphan Markdown note'
    Reset-SandboxState -RepoDir $sb

    # block-05 (conditions 4+5): delete one member while keeping the entry.
    $null = Invoke-Git -RepoDir $sb -GitArgs @('rm', '-q', '--', $MdBase)
    Assert-RejectedCommit -Name 'block-05 half-pair deletion (md)' -Result (Invoke-Commit -RepoDir $sb -Message 'half deletion md') -ExpectCode 1 -Fragment 'together with its pair'
    Reset-SandboxState -RepoDir $sb

    # block-06 (conditions 4+5, symmetric): delete the other member only.
    $null = Invoke-Git -RepoDir $sb -GitArgs @('rm', '-q', '--', $PdfBase)
    Assert-RejectedCommit -Name 'block-06 half-pair deletion (pdf)' -Result (Invoke-Commit -RepoDir $sb -Message 'half deletion pdf') -ExpectCode 1 -Fragment 'together with its pair'
    Reset-SandboxState -RepoDir $sb

    # block-07 (condition 6a): existing line modified = registry tampering.
    [string]$tamperedText = ''
    foreach ($line in @(Get-ManifestLines -RepoDir $sb)) {
        if ($line.EndsWith($MdBase)) { $tamperedText += (('ff' * 32)) + '  ' + $MdBase + "`n" } else { $tamperedText += $line + "`n" }
    }
    Write-SandboxText -Path (Join-Path $sb 'integrity\manifest.sha256') -Text $tamperedText
    $null = Invoke-Git -RepoDir $sb -GitArgs @('add', '--', 'integrity/manifest.sha256')
    Assert-RejectedCommit -Name 'block-07 manifest line modified (tampering)' -Result (Invoke-Commit -RepoDir $sb -Message 'rewrite registry entry') -ExpectCode 1 -Fragment 'registry tampering'
    Reset-SandboxState -RepoDir $sb

    # block-08 (condition 6b): line removed while its file stays staged.
    [string]$keptText = (@(Get-ManifestLines -RepoDir $sb) | Where-Object { -not $_.EndsWith($PdfBase) }) -join "`n"
    Write-SandboxText -Path (Join-Path $sb 'integrity\manifest.sha256') -Text ($keptText + "`n")
    $null = Invoke-Git -RepoDir $sb -GitArgs @('add', '--', 'integrity/manifest.sha256')
    Assert-RejectedCommit -Name 'block-08 manifest line removed while file staged' -Result (Invoke-Commit -RepoDir $sb -Message 'drop registry entry') -ExpectCode 1 -Fragment 'removed while its file is still staged'
}

function Invoke-FreshCloneTests {
    param([string]$ParentDir)

    $sb = New-SandboxClone -ParentDir $ParentDir -Name 'freshcrlf' -AutocrlfTrue

    # fresh-01: external verification passes right after an autocrlf=true clone.
    Push-Location -LiteralPath $sb
    $out = & $script:ShaTool -c 'integrity/manifest.sha256' 2>&1
    [int]$code = $LASTEXITCODE
    Pop-Location
    [bool]$autocrlfActive = ('true' -eq [string](Invoke-Git -RepoDir $sb -GitArgs @('config', 'core.autocrlf')).Output[0])
    Test-Assert 'fresh-01 sha256sum -c exits 0 after autocrlf clone' ((0 -eq $code) -and $autocrlfActive) "exit=$code; autocrlf=$autocrlfActive; out=$(($out | ForEach-Object { [string]$_ }) -join ' | ')"

    # fresh-02: no casing variants of the protected directories are tracked.
    $ls = Invoke-Git -RepoDir $sb -GitArgs @('ls-files')
    [string[]]$protected = @($ls.Output | Where-Object { $_.StartsWith('bibliografia/') -or $_.StartsWith('apuntes/') })
    [bool]$allLowercase = ($protected.Count -gt 0)
    foreach ($p in $protected) { if ($p -cne $p.ToLowerInvariant()) { $allLowercase = $false } }
    Test-Assert 'fresh-02 no casing variants tracked' $allLowercase ($ls.Output -join ', ')

    # fresh-03: every manifest entry matches its committed blob (.NET reference).
    [bool]$entriesMatch = $true
    [string]$entryDetail = ''
    foreach ($line in @(Get-ManifestLines -RepoDir $sb)) {
        [string[]]$hp = @($line -split '  ', 2)
        [byte[]]$blob = Read-BlobBytes -RepoDir $sb -RevSpec ('HEAD:' + $hp[1])
        if (($null -eq $blob) -or ((Get-DotNetSha256 -Bytes $blob) -cne $hp[0])) { $entriesMatch = $false; $entryDetail = "hash mismatch or unreadable: $($hp[1])"; break }
    }
    Test-Assert 'fresh-03 entries match committed blobs' $entriesMatch $entryDetail

    # byte-01: cmd-pipe hashing equals an independent .NET reference and the manifest.
    [string]$pdfOid = Get-StagedOid -RepoDir $sb -Path $PdfBase
    [string]$pipeHash = Get-StagedPipeHash -RepoDir $sb -Oid $pdfOid
    [string]$netHash = Get-DotNetSha256 -Bytes (Read-BlobBytes -RepoDir $sb -RevSpec $pdfOid)
    [string]$manifestHash = [string](@(@(Get-ManifestLines -RepoDir $sb) | Where-Object { $_.EndsWith($PdfBase) })[0] -split '  ')[0]
    [bool]$threeWay = ('' -ne $pipeHash) -and ($pipeHash -ceq $netHash) -and ($netHash -ceq $manifestHash)
    Test-Assert 'byte-01 cmd pipe equals .NET equals manifest' $threeWay "pipe=$pipeHash net=$netHash manifest=$manifestHash"

    # legal-01..03: compliant paired registration accepted on a fresh clone.
    [string[]]$legalBaseline = @(Get-ManifestLines -RepoDir $sb)
    Add-SandboxPairFiles -RepoDir $sb -Stem 'alpha-guide'
    $reg = Invoke-Register -RepoDir $sb -SourcePath 'bibliografia/alpha-guide.pdf'
    $null = Invoke-Git -RepoDir $sb -GitArgs @('add', '--', 'integrity/manifest.sha256')
    $r = Invoke-Commit -RepoDir $sb -Message 'register alpha-guide pair'
    [string]$commitOut = ($r.Output -join ' | ')
    Test-Assert 'legal-01 compliant paired registration commit accepted' ((0 -eq $r.Code) -and $commitOut.Contains('[integrity] OK:') -and (($legalBaseline.Count + 2) -eq @(Get-ManifestLines -RepoDir $sb).Count)) "exit=$($r.Code); out=$commitOut"

    # legal-04..05: atomic pair deletion with traceability accepted.
    $null = Invoke-Git -RepoDir $sb -GitArgs @('rm', '-q', '--', 'bibliografia/alpha-guide.pdf', 'apuntes/alpha-guide.md')
    [string]$keptText = (@(Get-ManifestLines -RepoDir $sb) | Where-Object { -not ($_.EndsWith('bibliografia/alpha-guide.pdf') -or $_.EndsWith('apuntes/alpha-guide.md')) }) -join "`n"
    Write-SandboxText -Path (Join-Path $sb 'integrity\manifest.sha256') -Text ($keptText + "`n")
    $null = Invoke-Git -RepoDir $sb -GitArgs @('add', '--', 'integrity/manifest.sha256')
    $r = Invoke-Commit -RepoDir $sb -Message 'atomic deletion of alpha-guide pair'
    Test-Assert 'legal-04 atomic pair deletion accepted, baseline restored' ((0 -eq $r.Code) -and ($legalBaseline.Count -eq @(Get-ManifestLines -RepoDir $sb).Count)) "exit=$($r.Code); lines=$(@(Get-ManifestLines -RepoDir $sb).Count)"
}

function Invoke-WorktreeNoiseTest {
    param([string]$ParentDir)

    $sb = New-SandboxClone -ParentDir $ParentDir -Name 'noise'
    [System.IO.File]::AppendAllText((Join-Path $sb 'apuntes\unidad-01-conceptos-de-seguridad.md'), "`nUnstaged working-tree noise.`n")
    $r = Invoke-Git -RepoDir $sb -GitArgs @('commit', '--allow-empty', '-m', 'worktree noise probe')
    [string]$joined = ($r.Output -join ' | ')
    Test-Assert 'noise-01 unstaged working-tree noise ignored' ((0 -eq $r.Code) -and $joined.Contains('[integrity] OK:')) "exit=$($r.Code); out=$joined"
}

function Invoke-FailClosedTests {
    param([string]$ParentDir)

    # closed-01: malformed staged manifest aborts with a fail-closed diagnostic.
    $sb = New-SandboxClone -ParentDir $ParentDir -Name 'closed-a'
    # Git itself always exits 1 on hook failure, so exit-code semantics of the
    # 0/1/2 contract are proven at shim level in closed-05 below.
    [string]$headBefore = Get-HeadOid -RepoDir $sb
    Write-SandboxText -Path (Join-Path $sb 'integrity\manifest.sha256') -Text "deadbeef  apuntes/unidad-01-conceptos-de-seguridad.md`n"
    $null = Invoke-Git -RepoDir $sb -GitArgs @('add', '--', 'integrity/manifest.sha256')
    Assert-RejectedCommit -Name 'closed-01 malformed manifest aborts commit' -Result (Invoke-Commit -RepoDir $sb -Message 'corrupt registry') -ExpectCode 1 -Fragment 'fail-closed'
    Test-Assert 'closed-02 no commit created on broken machinery' ((Get-HeadOid -RepoDir $sb) -eq $headBefore) 'HEAD advanced despite fail-closed abort'

    # closed-05: shim contract â€” verifier exit code passes through exec unchanged
    # (2 here); git maps any hook failure to its own exit 1 (see closed-01).
    if (-not (Get-Command 'sh.exe' -ErrorAction SilentlyContinue)) { throw 'sh.exe unavailable for shim probe' }
    Push-Location -LiteralPath $sb
    $out = & sh.exe '.githooks/pre-commit' 2>&1
    [int]$shimCode = $LASTEXITCODE
    Pop-Location
    [string]$shimJoined = (@($out | ForEach-Object { [string]$_ }) -join ' | ')
    Test-Assert 'closed-05 shim propagates exit 2 on broken machinery' ((2 -eq $shimCode) -and $shimJoined.Contains('malformed')) "exit=$shimCode; out=$shimJoined"

    # closed-03: missing verifier fails closed (broken machinery class).
    $sb2 = New-SandboxClone -ParentDir $ParentDir -Name 'closed-b'
    Remove-Item -LiteralPath (Join-Path $sb2 'tools\integrity\verify.ps1') -Force
    [string]$headBefore2 = Get-HeadOid -RepoDir $sb2
    $r = Invoke-Commit -RepoDir $sb2 -Message 'verify machinery gone'
    Test-Assert 'closed-03 missing verifier aborts commit' ((0 -ne $r.Code) -and ((Get-HeadOid -RepoDir $sb2) -eq $headBefore2)) "exit=$($r.Code); out=$(($r.Output -join ' | '))"

    # closed-04: verifier invoked outside any repository aborts with exit 2.
    [string]$raw = Join-Path $ParentDir 'outside-repo'
    New-Item -ItemType Directory -Path $raw -Force | Out-Null
    Push-Location -LiteralPath $raw
    $out = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $script:RepoRoot 'tools\integrity\verify.ps1') 2>&1
    [int]$code = $LASTEXITCODE
    Pop-Location
    [string]$joinedOut = (@($out | ForEach-Object { [string]$_ }) -join ' | ')
    Test-Assert 'closed-04 verifier outside repo exits 2' ((2 -eq $code) -and $joinedOut.Contains('not inside')) "exit=$code; out=$joinedOut"

    # closed-06 (task 4.7): corrupted registry DATA fails closed. A plain CRLF
    # edit cannot reach the index (the eol=lf pin normalizes on add â€” verified),
    # so plant CR bytes directly via plumbing, the filter-bypassing tamper path.
    $sb3 = New-SandboxClone -ParentDir $ParentDir -Name 'closed-c'
    [string]$headBefore3 = Get-HeadOid -RepoDir $sb3
    [string]$crlfPath = Join-Path $ParentDir 'crlf-manifest.bin'
    Write-SandboxText -Path $crlfPath -Text ((@(Get-ManifestLines -RepoDir $sb3) -join "`r`n") + "`r`n")
    $h = Invoke-Git -RepoDir $sb3 -GitArgs @('hash-object', '-w', '--no-filters', '--', $crlfPath)
    Remove-Item -LiteralPath $crlfPath -Force -ErrorAction SilentlyContinue
    if (0 -ne $h.Code) { throw ('hash-object failed: ' + ($h.Output -join '; ')) }
    $null = Invoke-Git -RepoDir $sb3 -GitArgs @('update-index', '--add', '--cacheinfo', ('100644,' + [string]$h.Output[0] + ',integrity/manifest.sha256'))
    Assert-RejectedCommit -Name 'closed-06 CRLF-corrupted staged manifest fails closed' -Result (Invoke-Commit -RepoDir $sb3 -Message 'crlf-corrupted manifest probe') -ExpectCode 1 -Fragment 'CR byte found'
}

function Invoke-HelperRefusalTests {
    param([string]$ParentDir)

    $sb = New-SandboxClone -ParentDir $ParentDir -Name 'helper'
    [string]$baselineB64 = [Convert]::ToBase64String((Get-ManifestRawBytes -RepoDir $sb))

    # helper-01/02: unstaged inputs refused; manifest bytes untouched.
    Write-SandboxBytes -Path (Join-Path $sb 'bibliografia\epsilon-five.pdf') -Bytes (New-FakePdfBytes -Stem 'epsilon-five')
    Write-SandboxText -Path (Join-Path $sb 'apuntes\epsilon-five.md') -Text (New-SandboxMarkdown -Stem 'epsilon-five')
    $r = Invoke-Register -RepoDir $sb -SourcePath 'bibliografia/epsilon-five.pdf'
    [bool]$ok = (1 -eq $r.Code) -and ((($r.Output -join ' | ')).Contains('is not staged')) -and ($baselineB64 -eq [Convert]::ToBase64String((Get-ManifestRawBytes -RepoDir $sb)))
    Test-Assert 'helper-01 unstaged inputs refused, manifest untouched' $ok "exit=$($r.Code); out=$(($r.Output -join ' | '))"

    # helper-03/04: already-registered paths refused (append-only, no mutation).
    $r = Invoke-Register -RepoDir $sb -SourcePath "bibliografia/$StemBase.pdf"
    [bool]$ok2 = (1 -eq $r.Code) -and ((($r.Output -join ' | ')).Contains('append-only')) -and ($baselineB64 -eq [Convert]::ToBase64String((Get-ManifestRawBytes -RepoDir $sb)))
    Test-Assert 'helper-02 registered-path mutation refused, manifest untouched' $ok2 "exit=$($r.Code); out=$(($r.Output -join ' | '))"

    # helper-05: PDF staged but its Markdown missing from staging refused.
    Write-SandboxBytes -Path (Join-Path $sb 'bibliografia\zeta-six.pdf') -Bytes (New-FakePdfBytes -Stem 'zeta-six')
    $null = Invoke-Git -RepoDir $sb -GitArgs @('add', '--', 'bibliografia/zeta-six.pdf')
    $r = Invoke-Register -RepoDir $sb -SourcePath 'bibliografia/zeta-six.pdf'
    [bool]$ok3 = (1 -eq $r.Code) -and ((($r.Output -join ' | ')).Contains('is not staged'))
    Test-Assert 'helper-03 unpaired staged pdf refused' $ok3 "exit=$($r.Code); out=$(($r.Output -join ' | '))"
}

function Invoke-RollbackRehearsal {
    # Task 5.3: rehearse README's documented rollback exactly as written:
    # remove machinery paths, unset core.hooksPath â€” plain-source tree restored.
    param([string]$ParentDir)

    $sb = New-SandboxClone -ParentDir $ParentDir -Name 'rollback'
    [string]$headBefore = Get-HeadOid -RepoDir $sb

    $rm = Invoke-Git -RepoDir $sb -GitArgs @('rm', '-r', '-q', '--', '.githooks', 'tools/integrity', 'integrity', '.gitattributes')
    $unset = Invoke-Git -RepoDir $sb -GitArgs @('config', '--unset', 'core.hooksPath')
    # README order removes pre-commit from disk BEFORE the commit runs, so git
    # finds no hook: the removal commit passes WITHOUT --no-verify and without
    # any integrity output. That silence is the honest rollback behavior.
    $r = Invoke-Commit -RepoDir $sb -Message 'remove integrity machinery (documented rollback)'
    [string]$joined = ($r.Output -join ' | ')
    [bool]$ok = (0 -eq $rm.Code) -and (0 -eq $unset.Code) -and (0 -eq $r.Code) -and (-not $joined.Contains('[integrity]'))
    Test-Assert 'rb-01 documented rollback commit accepted silently' $ok "rm=$($rm.Code); unset=$($unset.Code); exit=$($r.Code); out=$joined"

    [bool]$machineryGone = $true
    foreach ($rel in @('.githooks', 'tools\integrity', 'integrity', '.gitattributes')) {
        if (Test-Path -LiteralPath (Join-Path $sb $rel)) { $machineryGone = $false }
    }
    $ls = Invoke-Git -RepoDir $sb -GitArgs @('ls-files')
    foreach ($p in $ls.Output) {
        if ($p.StartsWith('.githooks/') -or $p.StartsWith('tools/integrity/') -or $p.StartsWith('integrity/') -or ($p -eq '.gitattributes')) { $machineryGone = $false }
    }
    [bool]$sourcesIntact = (Test-Path -LiteralPath (Join-Path $sb 'bibliografia')) -and (Test-Path -LiteralPath (Join-Path $sb 'apuntes')) -and (Test-Path -LiteralPath (Join-Path $sb 'README.md'))
    Test-Assert 'rb-02 plain-source tree restored (worktree, index, sources)' ($machineryGone -and $sourcesIntact) "tracked=$($ls.Output -join ', ')"

    $r = Invoke-Git -RepoDir $sb -GitArgs @('commit', '--allow-empty', '-m', 'post-rollback probe')
    [string]$probeJoined = ($r.Output -join ' | ')
    Test-Assert 'rb-03 follow-up commit silent (hook gone)' ((0 -eq $r.Code) -and (-not $probeJoined.Contains('[integrity]'))) "exit=$($r.Code); out=$probeJoined"
    Test-Assert 'rb-04 HEAD advanced past baseline exactly once' ((Get-HeadOid -RepoDir $sb) -ne $headBefore) 'HEAD did not advance'
}

function Invoke-DisclosureProbes {
    [string]$readme = [System.IO.File]::ReadAllText((Join-Path $script:RepoRoot 'README.md'))
    Test-Assert 'doc-01 README documents activation command' ($readme.Contains('core.hooksPath .githooks')) 'activation command missing'
    Test-Assert 'doc-02 README documents --no-verify bypass' ($readme.Contains('--no-verify')) 'bypass disclosure missing'
    Test-Assert 'doc-03 README states not-a-security-boundary' ($readme.Contains('NOT a security boundary')) 'limitation statement missing'
}

# ------------------------------------------------------------------ main ----

$script:RepoRoot = ([string](& git rev-parse --show-toplevel 2>$null)).Trim()
if (0 -ne $LASTEXITCODE -or [string]::IsNullOrEmpty($script:RepoRoot)) {
    [Console]::Out.WriteLine('[integrity-tests] ERROR: not inside the arys git repository.')
    exit 2
}
Set-Location -LiteralPath $script:RepoRoot

foreach ($required in @('tools/integrity/verify.ps1', 'tools/integrity/register.ps1', '.githooks/pre-commit')) {
    if (-not (Test-Path -LiteralPath (Join-Path $script:RepoRoot ($required -replace '/', '\')))) {
        [Console]::Out.WriteLine("[integrity-tests] ERROR: required machinery missing: $required")
        exit 2
    }
}

$script:ShaTool = Resolve-ShaTool
if ([string]::IsNullOrEmpty($script:ShaTool)) {
    [Console]::Out.WriteLine('[integrity-tests] ERROR: sha256sum.exe not found even via Git walk-up fallback.')
    exit 2
}
# cmd.exe children (D4 pipe probe) resolve sha256sum from PATH, unlike git -C.
$env:PATH = (Split-Path -Parent $script:ShaTool) + ';' + $env:PATH

[int]$harnessExit = 1
[string]$tmpRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('integtests-' + [System.Guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Path $tmpRoot -Force | Out-Null

try {
    Invoke-EnvironmentProbes
    [string]$childScript = Join-Path $tmpRoot 'parser-child.ps1'
    Write-SandboxText -Path $childScript -Text $script:ParserChildTemplate

    Invoke-ParserUnitTests -ScratchDir $tmpRoot -ChildScript $childScript

    [string]$mirrorChild = Join-Path $tmpRoot 'mirror-child.ps1'
    Write-SandboxText -Path $mirrorChild -Text $script:MirrorChildTemplate
    Invoke-MirrorUnitTests -ChildScript $mirrorChild
    Invoke-WebCategoryTests -ParentDir $tmpRoot
    Invoke-EOLLinkTest -ParentDir $tmpRoot

    Invoke-SortAppendTests -ParentDir $tmpRoot
    Invoke-BootstrapTests -ParentDir $tmpRoot
    Invoke-BlockingTests -ParentDir $tmpRoot
    Invoke-FreshCloneTests -ParentDir $tmpRoot
    Invoke-WorktreeNoiseTest -ParentDir $tmpRoot
    Invoke-FailClosedTests -ParentDir $tmpRoot
    Invoke-HelperRefusalTests -ParentDir $tmpRoot
    Invoke-RollbackRehearsal -ParentDir $tmpRoot
    Invoke-DisclosureProbes
    if ($script:FailCount -gt 0) { $harnessExit = 1 } else { $harnessExit = 0 }
}
catch {
    [Console]::Out.WriteLine("[integrity-tests] HARNESS ERROR (environment failure): $($_.Exception.Message)")
    $harnessExit = 2
}
finally {
    Set-Location -LiteralPath $script:RepoRoot
    # One retry: read-only handles from finished child processes release quickly.
    Remove-Item -LiteralPath $tmpRoot -Recurse -Force -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $tmpRoot) { Start-Sleep -Milliseconds 300; Remove-Item -LiteralPath $tmpRoot -Recurse -Force -ErrorAction SilentlyContinue }
}

[Console]::Out.WriteLine("[integrity-tests] pass=$script:PassCount fail=$script:FailCount total=$script:CaseNumber")
exit $harnessExit
