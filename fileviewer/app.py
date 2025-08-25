"""File Viewer - A simple tkinter GUI application for browsing and viewing files."""

import tkinter as tk
from tkinter import ttk, filedialog, messagebox, scrolledtext
import os
from pathlib import Path
import mimetypes
from datetime import datetime


class FileViewerApp:
    def __init__(self, root):
        self.root = root
        self.root.title("File Viewer")
        self.root.geometry("900x600")
        
        # Set icon if on Windows
        if os.name == 'nt':
            self.root.iconbitmap(default='')
        
        # Variables
        self.current_file = None
        self.current_directory = Path.home()
        
        # Create UI
        self.create_menu()
        self.create_widgets()
        self.create_status_bar()
        
        # Bind keyboard shortcuts
        self.root.bind('<Control-o>', lambda e: self.open_file())
        self.root.bind('<Control-d>', lambda e: self.browse_directory())
        self.root.bind('<Control-q>', lambda e: self.quit_app())
        self.root.bind('<F5>', lambda e: self.refresh_directory())
        
        # Load initial directory
        self.load_directory(self.current_directory)
    
    def create_menu(self):
        """Create the application menu bar."""
        menubar = tk.Menu(self.root)
        self.root.config(menu=menubar)
        
        # File menu
        file_menu = tk.Menu(menubar, tearoff=0)
        menubar.add_cascade(label="File", menu=file_menu)
        file_menu.add_command(label="Open File...", command=self.open_file, accelerator="Ctrl+O")
        file_menu.add_command(label="Browse Directory...", command=self.browse_directory, accelerator="Ctrl+D")
        file_menu.add_separator()
        file_menu.add_command(label="Exit", command=self.quit_app, accelerator="Ctrl+Q")
        
        # View menu
        view_menu = tk.Menu(menubar, tearoff=0)
        menubar.add_cascade(label="View", menu=view_menu)
        view_menu.add_command(label="Refresh", command=self.refresh_directory, accelerator="F5")
        view_menu.add_separator()
        view_menu.add_command(label="Clear Content", command=self.clear_content)
        
        # Help menu
        help_menu = tk.Menu(menubar, tearoff=0)
        menubar.add_cascade(label="Help", menu=help_menu)
        help_menu.add_command(label="About", command=self.show_about)
    
    def create_widgets(self):
        """Create the main application widgets."""
        # Create main paned window
        paned = ttk.PanedWindow(self.root, orient=tk.HORIZONTAL)
        paned.pack(fill=tk.BOTH, expand=True)
        
        # Left panel - File browser
        left_frame = ttk.Frame(paned, relief=tk.RIDGE)
        paned.add(left_frame, weight=1)
        
        # Directory path
        path_frame = ttk.Frame(left_frame)
        path_frame.pack(fill=tk.X, padx=5, pady=5)
        
        ttk.Label(path_frame, text="Directory:").pack(side=tk.LEFT)
        self.path_var = tk.StringVar(value=str(self.current_directory))
        self.path_entry = ttk.Entry(path_frame, textvariable=self.path_var, state='readonly')
        self.path_entry.pack(side=tk.LEFT, fill=tk.X, expand=True, padx=5)
        
        ttk.Button(path_frame, text="Browse", command=self.browse_directory).pack(side=tk.RIGHT)
        
        # File list with scrollbar
        list_frame = ttk.Frame(left_frame)
        list_frame.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)
        
        # Treeview for file listing
        self.file_tree = ttk.Treeview(list_frame, columns=('size', 'modified'), show='tree headings')
        self.file_tree.heading('#0', text='Name')
        self.file_tree.heading('size', text='Size')
        self.file_tree.heading('modified', text='Modified')
        
        # Configure column widths
        self.file_tree.column('#0', width=200)
        self.file_tree.column('size', width=80)
        self.file_tree.column('modified', width=120)
        
        # Scrollbars for tree
        v_scroll = ttk.Scrollbar(list_frame, orient=tk.VERTICAL, command=self.file_tree.yview)
        h_scroll = ttk.Scrollbar(list_frame, orient=tk.HORIZONTAL, command=self.file_tree.xview)
        self.file_tree.configure(yscrollcommand=v_scroll.set, xscrollcommand=h_scroll.set)
        
        # Pack tree and scrollbars
        self.file_tree.grid(row=0, column=0, sticky='nsew')
        v_scroll.grid(row=0, column=1, sticky='ns')
        h_scroll.grid(row=1, column=0, sticky='ew')
        
        list_frame.grid_rowconfigure(0, weight=1)
        list_frame.grid_columnconfigure(0, weight=1)
        
        # Bind tree events
        self.file_tree.bind('<<TreeviewSelect>>', self.on_file_select)
        self.file_tree.bind('<Double-Button-1>', self.on_file_double_click)
        
        # Right panel - File content viewer
        right_frame = ttk.Frame(paned, relief=tk.RIDGE)
        paned.add(right_frame, weight=2)
        
        # File info
        info_frame = ttk.Frame(right_frame)
        info_frame.pack(fill=tk.X, padx=5, pady=5)
        
        self.file_info_var = tk.StringVar(value="No file selected")
        ttk.Label(info_frame, textvariable=self.file_info_var, font=('Arial', 10, 'bold')).pack(side=tk.LEFT)
        
        # Content viewer
        content_frame = ttk.Frame(right_frame)
        content_frame.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)
        
        self.content_text = scrolledtext.ScrolledText(
            content_frame,
            wrap=tk.WORD,
            width=60,
            height=20,
            font=('Consolas', 10)
        )
        self.content_text.pack(fill=tk.BOTH, expand=True)
    
    def create_status_bar(self):
        """Create the status bar at the bottom of the window."""
        self.status_bar = ttk.Label(
            self.root,
            text="Ready",
            relief=tk.SUNKEN,
            anchor=tk.W
        )
        self.status_bar.pack(side=tk.BOTTOM, fill=tk.X)
    
    def load_directory(self, path):
        """Load and display files from the specified directory."""
        try:
            self.current_directory = Path(path)
            self.path_var.set(str(self.current_directory))
            
            # Clear existing items
            for item in self.file_tree.get_children():
                self.file_tree.delete(item)
            
            # Add parent directory option if not at root
            if self.current_directory.parent != self.current_directory:
                self.file_tree.insert('', 'end', text='..', values=('', ''), tags=('parent',))
            
            # List files and directories
            items = []
            for item in self.current_directory.iterdir():
                try:
                    stat = item.stat()
                    size = self.format_size(stat.st_size) if item.is_file() else ''
                    modified = datetime.fromtimestamp(stat.st_mtime).strftime('%Y-%m-%d %H:%M')
                    items.append((item, size, modified))
                except (PermissionError, OSError):
                    continue
            
            # Sort items: directories first, then files
            items.sort(key=lambda x: (not x[0].is_dir(), x[0].name.lower()))
            
            # Add items to tree
            for item, size, modified in items:
                icon = '📁' if item.is_dir() else '📄'
                self.file_tree.insert(
                    '', 'end',
                    text=f"{icon} {item.name}",
                    values=(size, modified),
                    tags=('directory' if item.is_dir() else 'file',)
                )
            
            self.update_status(f"Loaded {len(items)} items from {self.current_directory}")
            
        except Exception as e:
            messagebox.showerror("Error", f"Failed to load directory: {str(e)}")
    
    def format_size(self, size):
        """Format file size in human-readable format."""
        for unit in ['B', 'KB', 'MB', 'GB']:
            if size < 1024.0:
                return f"{size:.1f} {unit}"
            size /= 1024.0
        return f"{size:.1f} TB"
    
    def on_file_select(self, event):
        """Handle file selection in the tree."""
        selection = self.file_tree.selection()
        if not selection:
            return
        
        item = self.file_tree.item(selection[0])
        filename = item['text'].replace('📁 ', '').replace('📄 ', '')
        
        if filename == '..':
            return
        
        file_path = self.current_directory / filename
        if file_path.is_file():
            self.display_file(file_path)
    
    def on_file_double_click(self, event):
        """Handle double-click on file/directory."""
        selection = self.file_tree.selection()
        if not selection:
            return
        
        item = self.file_tree.item(selection[0])
        filename = item['text'].replace('📁 ', '').replace('📄 ', '')
        
        if filename == '..':
            self.load_directory(self.current_directory.parent)
        else:
            file_path = self.current_directory / filename
            if file_path.is_dir():
                self.load_directory(file_path)
            else:
                self.display_file(file_path)
    
    def display_file(self, file_path):
        """Display the contents of the selected file."""
        try:
            self.current_file = file_path
            self.file_info_var.set(f"File: {file_path.name}")
            
            # Clear previous content
            self.content_text.delete(1.0, tk.END)
            
            # Check file type
            mime_type, _ = mimetypes.guess_type(str(file_path))
            
            # Try to read as text
            if mime_type and mime_type.startswith('text') or file_path.suffix in ['.txt', '.py', '.json', '.xml', '.html', '.css', '.js', '.md', '.csv', '.log']:
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                        self.content_text.insert(1.0, content)
                except UnicodeDecodeError:
                    with open(file_path, 'r', encoding='latin-1') as f:
                        content = f.read()
                        self.content_text.insert(1.0, content)
            else:
                # Show file info for binary files
                stat = file_path.stat()
                info = f"Binary file: {file_path.name}\n"
                info += f"Size: {self.format_size(stat.st_size)}\n"
                info += f"Type: {mime_type or 'Unknown'}\n"
                info += f"Modified: {datetime.fromtimestamp(stat.st_mtime)}\n"
                info += f"Created: {datetime.fromtimestamp(stat.st_ctime)}\n"
                info += f"\n[Binary content not displayed]"
                self.content_text.insert(1.0, info)
            
            self.update_status(f"Loaded: {file_path.name}")
            
        except Exception as e:
            messagebox.showerror("Error", f"Failed to read file: {str(e)}")
            self.update_status(f"Error reading file: {str(e)}")
    
    def open_file(self):
        """Open a file dialog to select a file."""
        file_path = filedialog.askopenfilename(
            initialdir=self.current_directory,
            title="Select File"
        )
        if file_path:
            file_path = Path(file_path)
            self.display_file(file_path)
            # Update directory if different
            if file_path.parent != self.current_directory:
                self.load_directory(file_path.parent)
    
    def browse_directory(self):
        """Open a directory dialog to select a directory."""
        dir_path = filedialog.askdirectory(
            initialdir=self.current_directory,
            title="Select Directory"
        )
        if dir_path:
            self.load_directory(Path(dir_path))
    
    def refresh_directory(self):
        """Refresh the current directory listing."""
        self.load_directory(self.current_directory)
    
    def clear_content(self):
        """Clear the content viewer."""
        self.content_text.delete(1.0, tk.END)
        self.file_info_var.set("No file selected")
        self.current_file = None
        self.update_status("Content cleared")
    
    def update_status(self, message):
        """Update the status bar message."""
        self.status_bar.config(text=message)
        self.root.update_idletasks()
    
    def show_about(self):
        """Show the about dialog."""
        about_text = """File Viewer
Version 0.1.0

A simple GUI application for browsing and viewing file contents.

Features:
• Browse directories
• View text file contents
• File information display
• Keyboard shortcuts

Built with Python and tkinter
Part of PyApp Template"""
        
        messagebox.showinfo("About File Viewer", about_text)
    
    def quit_app(self):
        """Quit the application."""
        if messagebox.askokcancel("Quit", "Are you sure you want to quit?"):
            self.root.quit()


def main():
    """Main entry point for the application."""
    root = tk.Tk()
    app = FileViewerApp(root)
    root.mainloop()
    return 0


if __name__ == "__main__":
    main()