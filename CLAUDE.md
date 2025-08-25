# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Python package called `userprocessor` that processes and displays user data from CSV files. The project uses PyApp for building standalone executables from the Python package.

## Development Environment

- Python 3.8+ required (3.13 recommended)
- Uses `uv` for package management
- Virtual environment: `venv313`

## Common Commands

### Installation and Setup
```bash
# Install package in development mode using uv
uv pip install -e .

# Install dependencies
uv pip install pandas tabulate
```

### Running the Application
```bash
# Run with default username.csv
python -m userprocessor

# Run with specific CSV file
python -m userprocessor path/to/file.csv

# Run with statistics
python -m userprocessor --stats

# Run with different table format
python -m userprocessor --format fancy_grid
```

### Code Quality
```bash
# Run ruff for linting and formatting
ruff check .
ruff format .
```

### Building Standalone Executable
```bash
# Build executable using PyApp (Windows PowerShell)
.\build_with_pyapp.ps1

# Build with custom output name
.\build_with_pyapp.ps1 -OutputName myapp -PythonVersion 3.13
```

## Architecture

### Package Structure
- `userprocessor/` - Main package directory
  - `__main__.py` - CLI entry point, handles argument parsing
  - `processor.py` - Core functionality for CSV processing
  - `__init__.py` - Package initialization

### Key Components
1. **CSV Processing**: Uses pandas to read semicolon-delimited CSV files with automatic data type conversion for "Identifier" column
2. **Display System**: Uses tabulate library for formatted table output with multiple format options
3. **CLI Interface**: Argparse-based command-line interface with optional statistics display
4. **PyApp Integration**: PowerShell build script that packages the Python application into a standalone Windows executable using PyApp and Rust

### Build System
The project includes a sophisticated PyApp build system (`build_with_pyapp.ps1`) that:
- Clones PyApp from GitHub
- Builds Python wheel distribution
- Configures PyApp environment variables
- Compiles to standalone executable using Rust/Cargo
- Embeds Python runtime using python-build-standalone releases