[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $Python
)

$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$mupdf = Join-Path $repo "mupdf"
$release = Join-Path $mupdf "platform\win32\x64\Release"
$pythonRoot = Split-Path -Parent $Python
$transcript = Join-Path $repo "ci-build.log"

Start-Transcript -Path $transcript -Force | Out-Null
try {

if (-not (Test-Path $mupdf)) {
    throw "MuPDF source is missing: $mupdf"
}
if (-not (Test-Path (Join-Path $mupdf "platform\win32\mupdf.sln"))) {
    throw "MuPDF Windows solution is missing"
}

New-Item -ItemType Directory -Force $release | Out-Null
$env:MUPDF_PYTHON_INCLUDE_PATH = Join-Path $pythonRoot "Include"
$env:MUPDF_PYTHON_LIBRARY_PATH = Join-Path $pythonRoot "libs"

python -m pip install --upgrade pip setuptools wheel
python -m pip install "swig==4.0.2" "pytest==6.2.5"

$msbuild = (Get-Command msbuild.exe -ErrorAction SilentlyContinue).Source
if (-not $msbuild) {
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    $installPath = & $vswhere -latest -products * -requires Microsoft.Component.MSBuild -property installationPath
    $msbuild = Join-Path $installPath "MSBuild\Current\Bin\MSBuild.exe"
}
if (-not (Test-Path $msbuild)) {
    throw "MSBuild was not found"
}

& $msbuild (Join-Path $mupdf "platform\win32\mupdf.sln") `
    /m `
    /p:Configuration=Release `
    /p:Platform=x64 `
    /p:WindowsTargetPlatformVersion=10.0
if ($LASTEXITCODE -ne 0) {
    throw "MuPDF native build failed with exit code $LASTEXITCODE"
}

$requiredLibraries = @(
    "libmupdf.lib",
    "libresources.lib",
    "libthirdparty.lib",
    "libleptonica.lib",
    "libtesseract.lib"
)
foreach ($library in $requiredLibraries) {
    $path = Join-Path $release $library
    if (-not (Test-Path $path)) {
        throw "Required native library was not produced: $path"
    }
}

Push-Location $repo
try {
    Remove-Item -Recurse -Force dist -ErrorAction SilentlyContinue
    & $Python setup.py bdist_wheel
    if ($LASTEXITCODE -ne 0) {
        throw "PyMuPDF wheel build failed with exit code $LASTEXITCODE"
    }
    $wheel = Get-ChildItem dist -Filter "*.whl" | Select-Object -First 1
    if (-not $wheel) {
        throw "No wheel was produced"
    }
    $wheel.FullName
} finally {
    Pop-Location
}
} finally {
    Stop-Transcript | Out-Null
}
