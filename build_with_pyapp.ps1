# PowerShell script to build Python package with PyApp
# This script clones PyApp and builds the userprocessor package into an executable

param(
    [string]$OutputName = "userprocessor",
    [string]$PythonVersion = "3.13"
)

Write-Host "=== PyApp Build Script ===" -ForegroundColor Cyan
Write-Host ""

# Function to check if a command exists
function Test-Command {
    param([string]$Command)
    $null = Get-Command $Command -ErrorAction SilentlyContinue
    return $?
}

# Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Yellow

# Check for uv (required)
if (-not (Test-Command "uv")) {
    Write-Host "Error: uv is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Install uv with: powershell -ExecutionPolicy ByPass -c `"irm https://astral.sh/uv/install.ps1 | iex`"" -ForegroundColor Yellow
    Write-Host "Or visit: https://docs.astral.sh/uv/getting-started/installation/" -ForegroundColor Yellow
    exit 1
}
$uvVersion = uv --version 2>&1
Write-Host "[OK] Found uv: $uvVersion" -ForegroundColor Green

# Check for cargo (required)
if (-not (Test-Command "cargo")) {
    Write-Host "Error: Rust/Cargo is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Install Rust from: https://rustup.rs/" -ForegroundColor Yellow
    exit 1
}
$cargoVersion = cargo --version 2>&1
Write-Host "[OK] Found Cargo: $cargoVersion" -ForegroundColor Green

# Check for git (required)
if (-not (Test-Command "git")) {
    Write-Host "Error: Git is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Install Git from: https://git-scm.com/downloads" -ForegroundColor Yellow
    exit 1
}
$gitVersion = git --version 2>&1
Write-Host "[OK] Found Git: $gitVersion" -ForegroundColor Green

# Check for Python (optional - uv can manage it)
if (Test-Command "python") {
    $pythonVersion = python --version 2>&1
    Write-Host "[OK] Found Python: $pythonVersion" -ForegroundColor Green
}
else {
    Write-Host "Note: Python not found in PATH, will use uv to manage Python" -ForegroundColor Yellow
}

# Set working directory
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrEmpty($scriptPath)) {
    $scriptPath = Get-Location
}
Set-Location $scriptPath
Write-Host ""
Write-Host "Working directory: $scriptPath" -ForegroundColor Cyan

# Clone or update PyApp
$pyappDir = Join-Path $scriptPath "pyapp"
Write-Host ""
Write-Host "Setting up PyApp..." -ForegroundColor Yellow

if (Test-Path $pyappDir) {
    Write-Host "PyApp directory exists, removing for fresh clone..." -ForegroundColor Cyan
    Remove-Item -Path $pyappDir -Recurse -Force 2>&1 | Out-Null
}

Write-Host "Cloning PyApp from GitHub..." -ForegroundColor Cyan
git clone https://github.com/ofek/pyapp.git $pyappDir 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to clone PyApp repository" -ForegroundColor Red
    exit 1
}

# Checkout specific version for compatibility
$pyappVersion = "v0.28.0"  # Specify the version to use
Write-Host "Checking out PyApp version $pyappVersion for compatibility..." -ForegroundColor Cyan
Push-Location $pyappDir
git checkout $pyappVersion 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Warning: Could not checkout version $pyappVersion, using latest" -ForegroundColor Yellow
}
Pop-Location

Write-Host "PyApp ready" -ForegroundColor Green

# Build the Python package
Write-Host ""
Write-Host "Building Python package..." -ForegroundColor Yellow

# Clean build artifacts to ensure fresh build
Write-Host "Cleaning build artifacts..." -ForegroundColor Cyan

# Clean dist directory
$distDir = Join-Path $scriptPath "dist"
if (Test-Path $distDir) {
    Remove-Item -Path "$distDir/*" -Force -Recurse -ErrorAction SilentlyContinue 2>&1 | Out-Null
}
else {
    New-Item -ItemType Directory -Path $distDir | Out-Null
}

# Clean other build directories created by pyproject build
$buildDir = Join-Path $scriptPath "build"
if (Test-Path $buildDir) {
    Remove-Item -Path $buildDir -Recurse -Force -ErrorAction SilentlyContinue 2>&1 | Out-Null
}

$eggInfo = Get-ChildItem -Path $scriptPath -Filter "*.egg-info" -Directory -ErrorAction SilentlyContinue
if ($eggInfo) {
    foreach ($dir in $eggInfo) {
        Remove-Item -Path $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue 2>&1 | Out-Null
    }
}

# Clean PyApp runtime directories (created when the exe runs)
# PyApp creates directories like .pyapp_XXXXXX in the local directory
$pyappDirs = Get-ChildItem -Path $scriptPath -Filter ".pyapp_*" -Directory -ErrorAction SilentlyContinue
if ($pyappDirs) {
    Write-Host "Cleaning local PyApp runtime directories..." -ForegroundColor Cyan
    foreach ($dir in $pyappDirs) {
        Remove-Item -Path $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue 2>&1 | Out-Null
    }
}

# Clean PyApp data from AppData directories
$appDataLocal = [Environment]::GetFolderPath('LocalApplicationData')
$appDataRoaming = [Environment]::GetFolderPath('ApplicationData')

# Check LocalAppData for PyApp directories
$localPyAppPath = Join-Path $appDataLocal "pyapp"
if (Test-Path $localPyAppPath) {
    Write-Host "Cleaning PyApp data from LocalAppData..." -ForegroundColor Cyan
    Remove-Item -Path $localPyAppPath -Recurse -Force -ErrorAction SilentlyContinue 2>&1 | Out-Null
}

# Check for application-specific directories in LocalAppData
$appSpecificPath = Join-Path $appDataLocal $OutputName
if (Test-Path $appSpecificPath) {
    Write-Host "Cleaning $OutputName data from LocalAppData..." -ForegroundColor Cyan
    Remove-Item -Path $appSpecificPath -Recurse -Force -ErrorAction SilentlyContinue 2>&1 | Out-Null
}

# Check RoamingAppData for PyApp directories (less common but possible)
$roamingPyAppPath = Join-Path $appDataRoaming "pyapp"
if (Test-Path $roamingPyAppPath) {
    Write-Host "Cleaning PyApp data from RoamingAppData..." -ForegroundColor Cyan
    Remove-Item -Path $roamingPyAppPath -Recurse -Force -ErrorAction SilentlyContinue 2>&1 | Out-Null
}

# Build the package
Write-Host "Creating package distribution..." -ForegroundColor Cyan
Set-Location $scriptPath

# Build with uv (now required)
Write-Host "Building wheel with uv..." -ForegroundColor Cyan
uv build --wheel --out-dir $distDir 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to build Python package with uv" -ForegroundColor Red
    Write-Host "Make sure pyproject.toml is properly configured" -ForegroundColor Yellow
    exit 1
}
Write-Host "Package built successfully" -ForegroundColor Green

# Find the built wheel file
$wheelFile = Get-ChildItem -Path $distDir -Filter "*.whl" | Select-Object -First 1
if (-not $wheelFile) {
    Write-Host "Error: No wheel file found in dist directory" -ForegroundColor Red
    exit 1
}
Write-Host "Found wheel: $($wheelFile.Name)" -ForegroundColor Green

# No need to clear caches since we're doing a fresh clone of PyApp each time

# Configure PyApp environment variables
Write-Host ""
Write-Host "Configuring PyApp..." -ForegroundColor Yellow

$env:PYAPP_PROJECT_NAME = $OutputName
$env:PYAPP_PROJECT_VERSION = "0.1.0"
$env:PYAPP_PROJECT_PATH = $wheelFile.FullName
$env:PYAPP_PYTHON_VERSION = $PythonVersion
$env:PYAPP_EXEC_MODULE = "userprocessor"
$env:PYAPP_PIP_EXTERNAL = "true"

# PyApp will automatically download the appropriate Python distribution
# based on PYAPP_PYTHON_VERSION. You can optionally specify:
# $env:PYAPP_DISTRIBUTION_FORMAT = "install_only_stripped"  # For smaller size

# Display configuration
Write-Host "Configuration:" -ForegroundColor Cyan
Write-Host "  Project: $OutputName" -ForegroundColor White
Write-Host "  Version: 0.1.0" -ForegroundColor White
Write-Host "  Python: $PythonVersion" -ForegroundColor White
Write-Host "  Module: userprocessor" -ForegroundColor White
Write-Host "  Wheel: $($wheelFile.Name)" -ForegroundColor White

# Build with PyApp
Write-Host ""
Write-Host "Building executable with PyApp..." -ForegroundColor Yellow

Push-Location $pyappDir
# Run cargo build and capture output
Write-Host "Running: cargo build --release" -ForegroundColor Cyan
$output = cargo build --release 2>&1
$buildSuccess = $LASTEXITCODE -eq 0

# Display output
foreach ($line in $output) {
    if ($line -match "error:" -or $line -match "failed" -or $line -match "panicked") {
        Write-Host $line -ForegroundColor Red
    }
    elseif ($line -match "warning:") {
        Write-Host $line -ForegroundColor Yellow
    }
    else {
        Write-Host $line
    }
}

Pop-Location

if (-not $buildSuccess) {
    Write-Host "Error: PyApp build failed" -ForegroundColor Red
    exit 1
}

# Copy the executable to output directory
$exePath = Join-Path $pyappDir "target\release\pyapp.exe"
$outputPath = Join-Path $scriptPath "$OutputName.exe"

if (Test-Path $exePath) {
    Copy-Item $exePath $outputPath -Force
    Write-Host "Executable created: $outputPath" -ForegroundColor Green
    
    # Display file info
    $fileInfo = Get-Item $outputPath
    Write-Host ""
    Write-Host "Executable details:" -ForegroundColor Cyan
    Write-Host "  Size: $([math]::Round($fileInfo.Length / 1MB, 2)) MB" -ForegroundColor White
    Write-Host "  Path: $outputPath" -ForegroundColor White
}
else {
    Write-Host "Error: Executable not found at expected location" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== Build Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "To test the executable, run:" -ForegroundColor Cyan
Write-Host "  .\$OutputName.exe" -ForegroundColor White
Write-Host "  .\$OutputName.exe --help" -ForegroundColor White
Write-Host "  .\$OutputName.exe username.csv --stats" -ForegroundColor White
Write-Host ""