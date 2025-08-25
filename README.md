# PyApp-Template

A template for building standalone Windows executables from Python applications using PyApp.

## File Viewer

A tkinter-based GUI application for browsing and viewing file contents, packaged as a standalone executable.

### Features

- **Directory Browser**: Navigate folders with a tree view interface
- **File Viewer**: Display text file contents with syntax highlighting support
- **File Information**: Show file size, modification date, and type
- **Keyboard Shortcuts**: Quick navigation with Ctrl+O, Ctrl+D, F5, etc.
- **Icon Support**: Custom application icon embedded in the executable
- **Standalone Executable**: No Python installation required for end users

### Screenshots

The application provides a dual-pane interface:
- Left pane: Directory tree for navigation
- Right pane: File content viewer

## Installation

### For Development

Using uv (recommended):
```bash
uv pip install -e .
```

Using pip:
```bash
pip install -e .
```

### Running the Application

```bash
# Run as Python module
python -m fileviewer

# Or run directly
python fileviewer/app.py
```

## Building Standalone Executable

### Prerequisites

The build script will automatically check for and download these if needed:
- **uv**: Package manager (install with: `powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"`)
- **Rust/Cargo**: For compiling PyApp (install from https://rustup.rs/)
- **Git**: For cloning PyApp repository
- **rcedit**: For embedding icons (auto-downloaded if not present)

### Build Process

```powershell
# Build with default settings (reads name from pyproject.toml)
.\build_exe.ps1

# Build with custom Python version
.\build_exe.ps1 -PythonVersion 3.13

# Build with custom output name
.\build_exe.ps1 -OutputName MyFileViewer
```

The build script will:
1. Check and install prerequisites
2. Build a Python wheel package
3. Clone and configure PyApp
4. Compile to native Windows executable
5. Embed application icon
6. Output: `fileviewer.exe` (~30-40 MB)

### Icon Customization

To use a custom icon:
1. Place your `.ico` file at `fileviewer/icon.ico`
2. Run the build script - it will automatically embed the icon

## Project Structure

```
PyApp-Template/
├── fileviewer/          # Main application package
│   ├── __init__.py
│   ├── __main__.py      # Entry point
│   ├── app.py           # GUI application
│   └── icon.ico         # Application icon
├── build_exe.ps1        # PyApp build script
├── pyproject.toml       # Package configuration
└── README.md
```

## Requirements

- **Development**: Python 3.8+ (3.13 recommended)
- **Runtime**: None (standalone executable includes Python runtime)
- **Dependencies**: None (uses only Python standard library - tkinter)

## Technical Details

### PyApp Integration

This project uses [PyApp](https://github.com/ofek/pyapp) to create standalone executables:
- Embeds Python runtime using python-build-standalone
- Creates fully self-contained executable
- Manages virtual environment automatically
- Supports GUI applications with `PYAPP_IS_GUI=true`

### Build Configuration

Key PyApp environment variables used:
- `PYAPP_IS_GUI`: Enables GUI mode (no console window)
- `PYAPP_FULL_ISOLATION`: Clean environment for each run
- `PYAPP_PIP_EXTERNAL`: Uses external pip for packages
- `PYAPP_PYTHON_VERSION`: Specifies Python version to embed

## License

MIT License - See LICENSE file for details

## Author

Yeonsoo Park (yeonsoopark315@gmail.com)

## Legacy Components

The repository also contains `userprocessor`, a CLI tool for processing CSV files, which is being phased out in favor of the GUI application.