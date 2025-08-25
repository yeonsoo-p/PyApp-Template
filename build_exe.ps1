# PowerShell script to build Python package with PyApp
# This script clones PyApp and builds the package into an executable

param(
    [string]$OutputName = "",  # Will be read from pyproject.toml if not provided
    [string]$PythonVersion = "3.13",
    [string]$pyappVersion = ""  # Use latest version for better defaults
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

# Check for rcedit (optional but recommended for icon embedding)
$rceditPath = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "rcedit-x64.exe"
if (-not (Test-Path $rceditPath)) {
    if (-not (Test-Command "rcedit")) {
        Write-Host "rcedit not found, attempting to download..." -ForegroundColor Yellow
        try {
            $rceditUrl = "https://github.com/electron/rcedit/releases/latest/download/rcedit-x64.exe"
            $ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri $rceditUrl -OutFile $rceditPath -UseBasicParsing
            $ProgressPreference = 'Continue'
            
            if (Test-Path $rceditPath) {
                Write-Host "[OK] Downloaded rcedit-x64.exe for icon embedding" -ForegroundColor Green
            }
        }
        catch {
            Write-Host "[WARNING] Could not download rcedit (icon embedding will be skipped)" -ForegroundColor Yellow
            Write-Host "         Download manually from: https://github.com/electron/rcedit/releases" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "[OK] Found rcedit in PATH" -ForegroundColor Green
    }
}
else {
    Write-Host "[OK] Found rcedit-x64.exe" -ForegroundColor Green
}

# Set working directory
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrEmpty($scriptPath)) {
    $scriptPath = Get-Location
}
Set-Location $scriptPath
Write-Host ""
Write-Host "Working directory: $scriptPath" -ForegroundColor Cyan

# Read project metadata from pyproject.toml
$pyprojectPath = Join-Path $scriptPath "pyproject.toml"
if (Test-Path $pyprojectPath) {
    $pyprojectContent = Get-Content $pyprojectPath -Raw
    
    # Read project name if not provided
    if ([string]::IsNullOrEmpty($OutputName)) {
        if ($pyprojectContent -match 'name\s*=\s*"([^"]+)"') {
            $OutputName = $matches[1]
            Write-Host "Project name from pyproject.toml: $OutputName" -ForegroundColor Cyan
        }
        else {
            Write-Host "Error: Could not parse project name from pyproject.toml" -ForegroundColor Red
            exit 1
        }
    }
    
    # Read project version
    if ($pyprojectContent -match 'version\s*=\s*"([^"]+)"') {
        $ProjectVersion = $matches[1]
        Write-Host "Project version from pyproject.toml: $ProjectVersion" -ForegroundColor Cyan
    }
    else {
        $ProjectVersion = "0.0.0"
        Write-Host "Using default version: $ProjectVersion" -ForegroundColor Yellow
    }
}
else {
    Write-Host "Error: pyproject.toml not found" -ForegroundColor Red
    exit 1
}

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

# Checkout specific version for stability
if (-not [string]::IsNullOrEmpty($pyappVersion)) {
    Write-Host "Checking out PyApp version $pyappVersion for stability..." -ForegroundColor Cyan
    Push-Location $pyappDir
    git checkout $pyappVersion 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Warning: Could not checkout version $pyappVersion, using latest" -ForegroundColor Yellow
    }
    Pop-Location
}
else {
    Write-Host "Using latest PyApp version" -ForegroundColor Cyan
}

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

# Clean PyApp data from AppData directories
$appDataLocal = [Environment]::GetFolderPath('LocalApplicationData')
$appDataRoaming = [Environment]::GetFolderPath('ApplicationData')

# Clean all files and directories containing $OutputName in LocalAppData
if (Test-Path $appDataLocal) {
    Write-Host "Cleaning $OutputName-related data from LocalAppData..." -ForegroundColor Cyan
    
    # Find and remove all directories containing $OutputName
    $dirsToRemove = Get-ChildItem -Path $appDataLocal -Directory -Recurse -Filter "*$OutputName*" -ErrorAction SilentlyContinue
    foreach ($dir in $dirsToRemove) {
        Remove-Item -Path $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue 2>&1 | Out-Null
    }
    
    # Find and remove all files containing $OutputName
    $filesToRemove = Get-ChildItem -Path $appDataLocal -File -Recurse -Filter "*$OutputName*" -ErrorAction SilentlyContinue
    foreach ($file in $filesToRemove) {
        Remove-Item -Path $file.FullName -Force -ErrorAction SilentlyContinue 2>&1 | Out-Null
    }
}

# Clean all files and directories containing $OutputName in RoamingAppData
if (Test-Path $appDataRoaming) {
    Write-Host "Cleaning $OutputName-related data from RoamingAppData..." -ForegroundColor Cyan
    
    # Find and remove all directories containing $OutputName
    $dirsToRemove = Get-ChildItem -Path $appDataRoaming -Directory -Recurse -Filter "*$OutputName*" -ErrorAction SilentlyContinue
    foreach ($dir in $dirsToRemove) {
        Remove-Item -Path $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue 2>&1 | Out-Null
    }
    
    # Find and remove all files containing $OutputName
    $filesToRemove = Get-ChildItem -Path $appDataRoaming -File -Recurse -Filter "*$OutputName*" -ErrorAction SilentlyContinue
    foreach ($file in $filesToRemove) {
        Remove-Item -Path $file.FullName -Force -ErrorAction SilentlyContinue 2>&1 | Out-Null
    }
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
$env:PYAPP_PROJECT_VERSION = $ProjectVersion
$env:PYAPP_PROJECT_PATH = $wheelFile.FullName
$env:PYAPP_EXEC_MODULE = $OutputName  # This will use the project name from pyproject.toml
$env:PYAPP_PIP_EXTERNAL = "true"

# Set Python version for PyApp
$env:PYAPP_PYTHON_VERSION = $PythonVersion
$env:PYAPP_IS_GUI = "true"

# Configure PyApp to use managed Python
$env:PYAPP_DISTRIBUTION_EMBED = "false"
$env:PYAPP_PIP_ALLOW_CONFIG = "true"
$env:PYAPP_FULL_ISOLATION = "true"
$env:PYAPP_SKIP_INSTALL = "false"

# Debug: Show what we're setting
Write-Host "Debug: PYAPP_PYTHON_VERSION = $($env:PYAPP_PYTHON_VERSION)" -ForegroundColor Yellow

# PyApp will automatically handle distribution format
# The pyvenv.cfg will be created at runtime in the PyApp cache directory

# Display configuration
Write-Host "Configuration:" -ForegroundColor Cyan
Write-Host "  Project: $OutputName" -ForegroundColor White
Write-Host "  Version: $ProjectVersion" -ForegroundColor White
Write-Host "  Python: $PythonVersion" -ForegroundColor White
Write-Host "  Module: $OutputName" -ForegroundColor White
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
    
    # Try to embed icon if available
    $iconPath = Join-Path $scriptPath "$OutputName\icon.ico"
    if (Test-Path $iconPath) {
        Write-Host ""
        Write-Host "Embedding icon..." -ForegroundColor Yellow
        
        # Use rcedit (already checked/downloaded at startup)
        $rceditPath = Join-Path $scriptPath "rcedit-x64.exe"
        
        if (Test-Path $rceditPath) {
            & $rceditPath $outputPath --set-icon $iconPath 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Icon embedded successfully" -ForegroundColor Green
            }
            else {
                Write-Host "Failed to embed icon with rcedit" -ForegroundColor Yellow
            }
        }
        elseif (Test-Command "rcedit") {
            rcedit $outputPath --set-icon $iconPath 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Icon embedded successfully" -ForegroundColor Green
            }
            else {
                Write-Host "Failed to embed icon with rcedit" -ForegroundColor Yellow
            }
        }
        else {
            Write-Host "rcedit not available - icon will not be embedded" -ForegroundColor Yellow
        }
    }
    
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
Write-Host ""