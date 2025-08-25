# PyApp-Template

## User Processor

A simple Python package for processing and displaying user data from CSV files.

### Features

- Read CSV files using pandas
- Display data in formatted tables using tabulate
- Basic data statistics
- Command-line interface

### Installation

Using pip:
```bash
pip install -e .
```

Using uv (recommended):
```bash
uv pip install -e .
```

### Usage

```bash
# Process default username.csv
python -m userprocessor

# Process specific CSV file
python -m userprocessor path/to/file.csv

# Use different table format
python -m userprocessor --format fancy_grid

# Show statistics
python -m userprocessor --stats
```

### Requirements

- Python 3.8+ (3.13 recommended)
- pandas
- tabulate

### Building Standalone Executable

This project includes a PyApp build script to create standalone Windows executables:

```powershell
# Build with default settings
.\build_with_pyapp.ps1

# Build with custom options
.\build_with_pyapp.ps1 -OutputName myapp -PythonVersion 3.13
```

Prerequisites for building:
- uv (install with: `powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"`)
- Rust/Cargo (install from https://rustup.rs/)
- Git (install from https://git-scm.com/)