[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$configPath = Join-Path $PSScriptRoot 'public-package.json'
if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
    throw "Public package configuration is missing: $configPath"
}
$config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json -Depth 50

function Invoke-Checked {
    param(
        [Parameter(Mandatory)][string]$Label,
        [Parameter(Mandatory)][scriptblock]$Action
    )
    & $Action
    if ($LASTEXITCODE -ne 0) {
        throw "$Label failed with exit code $LASTEXITCODE."
    }
    Write-Output "PASS $Label"
}

$tracked = @(& git -C $root -c core.quotepath=false ls-files --cached --others --exclude-standard)
if ($LASTEXITCODE -ne 0) { throw 'Could not enumerate tracked files.' }

$forbiddenFiles = @(
    '(^|/)\.env($|\.)',
    '\.(log|sav|dmp|tmp|pyc|pyo)$',
    '(^|/)(__pycache__|Saved|Logs|screenshots?)(/|$)',
    '(^|/)LocalAppData(/|$)'
)
foreach ($pattern in $forbiddenFiles) {
    $matches = @($tracked | Where-Object { $_ -match $pattern })
    if ($matches.Count -gt 0) {
        throw "Tracked private/generated files match $pattern : $($matches -join ', ')"
    }
}
Write-Output 'PASS tracked-file boundary'

Invoke-Checked -Label 'git diff check' -Action {
    & git -C $root diff --check
}

$jsonFiles = @($tracked | Where-Object { $_ -match '\.json$' })
foreach ($relative in $jsonFiles) {
    $null = Get-Content -LiteralPath (Join-Path $root $relative) -Raw | ConvertFrom-Json -Depth 100
}
Write-Output "PASS JSON parse ($($jsonFiles.Count))"

& python (Join-Path $PSScriptRoot 'check_lua_syntax.py') --root $root
if ($LASTEXITCODE -ne 0) { throw 'Lua 5.4 compile failed.' }

$pythonFiles = @($tracked | Where-Object { $_ -match '\.py$' })
if ($pythonFiles.Count -gt 0) {
    $cacheRoot = Join-Path ([IO.Path]::GetTempPath()) ("rsdw-pycache-" + [Guid]::NewGuid().ToString('N'))
    $previousCache = $env:PYTHONPYCACHEPREFIX
    try {
        $env:PYTHONPYCACHEPREFIX = $cacheRoot
        foreach ($relative in $pythonFiles) {
            & python -m py_compile (Join-Path $root $relative)
            if ($LASTEXITCODE -ne 0) { throw "Python compile failed: $relative" }
        }
    } finally {
        $env:PYTHONPYCACHEPREFIX = $previousCache
        if (Test-Path -LiteralPath $cacheRoot) {
            Remove-Item -LiteralPath $cacheRoot -Recurse
        }
    }
}
Write-Output "PASS Python compile ($($pythonFiles.Count))"

foreach ($scanPathValue in @($config.boundaryScanPaths)) {
    $scanRoot = Join-Path $root ([string]$scanPathValue)
    if (-not (Test-Path -LiteralPath $scanRoot)) { continue }
    $runtimeFiles = @(Get-ChildItem -LiteralPath $scanRoot -Recurse -File | Where-Object {
        $_.Extension -in @('.lua', '.py', '.json', '.ps1')
    })
    foreach ($rule in @($config.forbiddenPatterns)) {
        $hits = @($runtimeFiles | Select-String -Pattern ([string]$rule.pattern))
        if ($hits.Count -gt 0) {
            $first = $hits[0]
            $relative = [IO.Path]::GetRelativePath($root, $first.Path)
            throw "Public boundary failed: $($rule.reason) at $($relative):$($first.LineNumber)"
        }
    }
}
Write-Output 'PASS runtime boundary scan'

if ($config.validatePng -eq $true) {
    $pngFiles = @($tracked | Where-Object { $_ -match '\.png$' })
    if ($pngFiles.Count -gt 0) {
        $listPath = Join-Path ([IO.Path]::GetTempPath()) ("rsdw-png-" + [Guid]::NewGuid().ToString('N') + '.txt')
        try {
            [IO.File]::WriteAllLines($listPath, @($pngFiles | ForEach-Object { Join-Path $root $_ }))
            & python -c "from PIL import Image; import pathlib,sys; files=pathlib.Path(sys.argv[1]).read_text().splitlines(); [Image.open(p).verify() for p in files]; print(f'PASS PNG verify ({len(files)})')" $listPath
            if ($LASTEXITCODE -ne 0) { throw 'PNG verification failed.' }
        } finally {
            if (Test-Path -LiteralPath $listPath) { Remove-Item -LiteralPath $listPath }
        }
    }
}

$testsPath = Join-Path $root 'Tools\tests'
if (Test-Path -LiteralPath $testsPath -PathType Container) {
    Push-Location $root
    try {
        & python -m unittest discover -s Tools/tests
        if ($LASTEXITCODE -ne 0) { throw 'Unit tests failed.' }
    } finally {
        Pop-Location
    }
    Write-Output 'PASS unit tests'
}

Write-Output "PUBLIC PACKAGE PASS $($config.id)"
