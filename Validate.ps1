param(
    [string]$Compiler = 'C:\Program Files\PureBasic\Compilers\pbcompiler.exe'
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $Compiler -PathType Leaf)) {
    throw "PureBasic ASM compiler not found: $Compiler"
}

function Invoke-Compiler {
    param([string[]]$CompilerArguments)
    & $Compiler @CompilerArguments
    if ($LASTEXITCODE -ne 0) {
        throw "PureBasic failed with exit code $LASTEXITCODE"
    }
}

Push-Location $PSScriptRoot
try {
    New-Item -ItemType Directory -Path Binaries -Force | Out-Null
    Write-Host 'Checking application source...'
    Invoke-Compiler -CompilerArguments @('EldarianOdyssey.pb', '/CHECK')
    Write-Host 'Building Windows x64 release...'
    Invoke-Compiler -CompilerArguments @('EldarianOdyssey.pb', '/OUTPUT', 'Binaries\EldarianOdyssey-x64.exe', '/ICON', 'Resources\icons\EO_Icon.ico', '/RESOURCE', 'Resources\EO_Version_Release.rc', '/XP', '/USER')
    Write-Host 'Building Windows x64 with debugger...'
    Invoke-Compiler -CompilerArguments @('EldarianOdyssey.pb', '/OUTPUT', 'Binaries\EldarianOdyssey-x64-Debug.exe', '/ICON', 'Resources\icons\EO_Icon.ico', '/RESOURCE', 'Resources\EO_Version_Debug.rc', '/XP', '/USER', '/DEBUGGER')
    Write-Host 'Building and running parser/state regressions...'
    Invoke-Compiler -CompilerArguments @('RegressionTests.pb', '/OUTPUT', 'Binaries\RegressionTests.exe', '/CONSOLE', '/LINENUMBERING')
    & .\Binaries\RegressionTests.exe
    if ($LASTEXITCODE -ne 0) {
        throw "Regression tests failed with exit code $LASTEXITCODE"
    }
    Write-Host 'Validation passed. The graphical game was not launched by this script.'
}
finally {
    Pop-Location
}
