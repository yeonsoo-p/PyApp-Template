"""Core processing module for user data."""

import pandas as pd
from tabulate import tabulate


def load_csv(filepath):
    """Load CSV file using pandas."""
    try:
        df = pd.read_csv(filepath, sep=";")
        return df
    except FileNotFoundError:
        print(f"Error: File '{filepath}' not found.")
        return None
    except Exception as e:
        print(f"Error reading CSV: {e}")
        return None


def process_users(filepath):
    """Process user data from CSV file."""
    df = load_csv(filepath)
    if df is None:
        return None

    df.columns = df.columns.str.strip()

    if "Identifier" in df.columns:
        df["Identifier"] = pd.to_numeric(df["Identifier"], errors="coerce")

    df = df.dropna(how="all")

    return df


def display_users(df, format="grid"):
    """Display user data in a formatted table."""
    if df is None or df.empty:
        print("No data to display.")
        return

    print("\n=== User Data ===")
    try:
        print(tabulate(df, headers="keys", tablefmt=format, showindex=False))
    except UnicodeEncodeError:
        # Fallback to simple format if unicode issues
        print(tabulate(df, headers="keys", tablefmt="simple", showindex=False))
    print(f"\nTotal users: {len(df)}")


def get_user_stats(df):
    """Get basic statistics about users."""
    if df is None or df.empty:
        return {}

    stats = {"total_users": len(df), "columns": list(df.columns), "unique_identifiers": df["Identifier"].nunique() if "Identifier" in df.columns else 0}
    return stats
