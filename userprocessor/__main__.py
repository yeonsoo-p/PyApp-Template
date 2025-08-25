"""Main entry point for the userprocessor package."""

import sys
import argparse
from pathlib import Path
from .processor import process_users, display_users, get_user_stats


def main():
    """Main function for CLI execution."""
    parser = argparse.ArgumentParser(description="Process and display user data from CSV")
    parser.add_argument("csv_file", nargs="?", default="username.csv", help="Path to CSV file (default: username.csv)")
    parser.add_argument("--format", choices=["grid", "plain", "simple", "github", "fancy_grid"], default="grid", help="Table format for display (default: grid)")
    parser.add_argument("--stats", action="store_true", help="Show statistics about the data")

    args = parser.parse_args()

    csv_path = Path(args.csv_file)
    if not csv_path.is_absolute():
        csv_path = Path.cwd() / csv_path

    print(f"Processing file: {csv_path}")

    df = process_users(csv_path)

    if df is not None:
        display_users(df, format=args.format)

        if args.stats:
            stats = get_user_stats(df)
            print("\n=== Statistics ===")
            for key, value in stats.items():
                print(f"{key}: {value}")

        return 0
    else:
        return 1


if __name__ == "__main__":
    sys.exit(main())
