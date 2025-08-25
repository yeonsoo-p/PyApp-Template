# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains two Python applications that can be built into standalone Windows executables using PyApp:

1. **fileviewer** - A tkinter-based GUI application for browsing and viewing file contents
2. **userprocessor** - A CLI tool for processing CSV files (legacy, being phased out)

The project uses PyApp (a Rust-based Python application bundler) to create self-contained executables with embedded Python runtime.

## Development Environment

- Python 3.8+ required (3.13 recommended)
- Uses `uv` for package management and building
- Windows PowerShell for build scripts
- Virtual environment: `venv313`

## Common Commands

### Running Applications

```bash
# Run fileviewer GUI (main application)
python -m fileviewer
# Or directly
python fileviewer/app.py

# Run userprocessor CLI (legacy)
python -m userprocessor
python -m userprocessor path/to/file.csv --stats --format fancy_grid
```

### Building and Installation

```bash
# Install in development mode
uv pip install -e .

# Build Python wheel
uv build --wheel --out-dir dist

# Build standalone Windows executable with icon
.\build_exe.ps1
# Or with custom options
.\build_exe.ps1 -OutputName fileviewer -PythonVersion 3.13
```

### Code Quality

```bash
# Linting and formatting with ruff
ruff check .
ruff format .
```

## Architecture

### FileViewer Application

The main GUI application located in `fileviewer/`:
- **app.py** - Main tkinter application with FileViewerApp class
  - Directory browsing with tree view
  - File content display with syntax detection
  - Icon embedding support (fileviewer/icon.ico)
- **__main__.py** - Entry point that calls app.main()
- Runs as standalone Python or can be built into exe

### Build System

**build_exe.ps1** - Sophisticated PyApp build script that:
1. Checks/installs prerequisites (uv, cargo, git, rcedit)
2. Auto-downloads rcedit from GitHub for icon embedding
3. Clones PyApp repository fresh for each build
4. Builds Python wheel using uv
5. Configures PyApp environment variables
6. Compiles to exe using Rust/Cargo
7. Embeds icon using rcedit post-build
8. Cleans build artifacts and PyApp cache from AppData

Key build configuration:
- `PYAPP_IS_GUI = "true"` for GUI applications
- `PYAPP_PIP_EXTERNAL = "true"` for external pip
- `PYAPP_FULL_ISOLATION = "true"` for clean environment
- Uses python-build-standalone for embedded Python

### Icon Embedding

Icons are embedded into executables using rcedit:
- Place icon at `{package_name}/icon.ico`
- Build script automatically downloads rcedit if not present
- Post-build embedding into the compiled exe

## Project Configuration

**pyproject.toml** defines:
- Package metadata (name, version, dependencies)
- Build system (setuptools)
- Ruff linting configuration
- Entry points for console scripts

## Important Notes

- The build script performs aggressive cleanup of PyApp runtime directories in AppData
- Each build clones a fresh PyApp to avoid cache issues
- Icon must be in .ico format for Windows executables
- The fileviewer app uses only Python standard library (tkinter)