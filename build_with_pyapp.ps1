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

if (-not (Test-Command "python")) {
    Write-Host "Error: Python is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please ensure Python is installed and available in PATH" -ForegroundColor Red
    exit 1
}

$pythonVersion = python --version 2>&1
Write-Host "Found Python: $pythonVersion" -ForegroundColor Green

if (-not (Test-Command "cargo")) {
    Write-Host "Error: Rust/Cargo is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please ensure Rust is installed from https://rustup.rs/" -ForegroundColor Red
    exit 1
}

$cargoVersion = cargo --version 2>&1
Write-Host "Found Cargo: $cargoVersion" -ForegroundColor Green

if (-not (Test-Command "git")) {
    Write-Host "Error: Git is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please ensure Git is installed" -ForegroundColor Red
    exit 1
}

$gitVersion = git --version 2>&1
Write-Host "Found Git: $gitVersion" -ForegroundColor Green

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

# Clean dist directory to ensure fresh build
$distDir = Join-Path $scriptPath "dist"
if (Test-Path $distDir) {
    Write-Host "Cleaning dist directory..." -ForegroundColor Cyan
    Remove-Item -Path "$distDir/*" -Force -Recurse 2>&1 | Out-Null
}
else {
    New-Item -ItemType Directory -Path $distDir | Out-Null
}

# Install build tools if needed
Write-Host "Installing build tools..." -ForegroundColor Cyan
if (Test-Command "uv") {
    uv pip install --quiet build wheel 2>&1 | Out-Null
}
else {
    python -m pip install --quiet build wheel 2>&1 | Out-Null
}

# Build the package
Write-Host "Creating package distribution..." -ForegroundColor Cyan
Set-Location $scriptPath
python -m build --outdir $distDir 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to build Python package" -ForegroundColor Red
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

# Clear PyApp and Rust cache to ensure fresh build
Write-Host ""
Write-Host "Clearing build caches..." -ForegroundColor Yellow

# Clear entire target directory for complete rebuild
$targetDir = Join-Path $pyappDir "target"
if (Test-Path $targetDir) {
    Write-Host "  Removing target directory..." -ForegroundColor Cyan
    Remove-Item -Path $targetDir -Recurse -Force 2>&1 | Out-Null
}

# Clear Rust's global cache for this project
$cargoHome = $env:CARGO_HOME
if (-not $cargoHome) {
    $cargoHome = Join-Path $env:USERPROFILE ".cargo"
}
$registryCache = Join-Path $cargoHome "registry\cache"
if (Test-Path $registryCache) {
    Write-Host "  Clearing Cargo registry cache..." -ForegroundColor Cyan
    Get-ChildItem -Path $registryCache -Filter "*pyapp*" -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue 2>&1 | Out-Null
}

# Clear Cargo.lock to ensure fresh dependency resolution
$cargoLock = Join-Path $pyappDir "Cargo.lock"
if (Test-Path $cargoLock) {
    Write-Host "  Removing Cargo.lock..." -ForegroundColor Cyan
    Remove-Item -Path $cargoLock -Force 2>&1 | Out-Null
}

Write-Host "Cache cleared" -ForegroundColor Green

# Configure PyApp environment variables
Write-Host ""
Write-Host "Configuring PyApp..." -ForegroundColor Yellow

$env:PYAPP_PROJECT_NAME = $OutputName
$env:PYAPP_PROJECT_VERSION = "0.1.0"
$env:PYAPP_PROJECT_PATH = $wheelFile.FullName
$env:PYAPP_PYTHON_VERSION = $PythonVersion
$env:PYAPP_EXEC_MODULE = "userprocessor"
$env:PYAPP_PIP_EXTERNAL = "true"

# Set explicit Python distribution for Windows
# Using python-build-standalone releases
$pythonDistUrl = "https://github.com/astral-sh/python-build-standalone/releases/download/20241206/cpython-3.13.1+20241206-x86_64-pc-windows-msvc-install_only_stripped.tar.gz"
$env:PYAPP_DISTRIBUTION_SOURCE = $pythonDistUrl

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