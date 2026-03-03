#!/usr/bin/env python3

from pathlib import Path
from datetime import datetime
import hashlib
import logging
import sys
import yaml
import argparse

# ============================================================
# HARD-CODED OUTPUT ROOT
# ============================================================
OUTPUT_FOLDER = Path("/home/anirudh/asgard_pipeline/logs")

DEFAULT_EXCLUDES = {
    "logs",
    ".git",
    "__pycache__",
    ".mypy_cache",
    ".pytest_cache",
    ".DS_Store"
}

# ============================================================
# LOGGING
# ============================================================
def setup_logging(log_path: Path):
    logger = logging.getLogger()
    logger.setLevel(logging.INFO)

    if logger.hasHandlers():
        logger.handlers.clear()

    formatter = logging.Formatter(
        "%(asctime)s | %(levelname)s | %(message)s",
        "%Y-%m-%d %H:%M:%S"
    )

    fh = logging.FileHandler(log_path)
    fh.setFormatter(formatter)
    logger.addHandler(fh)

    ch = logging.StreamHandler(sys.stdout)
    ch.setFormatter(formatter)
    logger.addHandler(ch)


# ============================================================
# UTILITIES
# ============================================================
def should_exclude(path: Path, excludes: set):
    return path.name in excludes


def count_files_and_dirs(root: Path, excludes: set):
    file_count = 0
    dir_count = 0
    for item in root.rglob("*"):
        if should_exclude(item, excludes):
            continue
        if item.is_file():
            file_count += 1
        elif item.is_dir():
            dir_count += 1
    return file_count, dir_count


def count_elements(path: Path, excludes: set):
    return len([
        x for x in path.iterdir()
        if not should_exclude(x, excludes)
        and x.name != "folder_metadata.yaml"
    ])


# ============================================================
# SIZE
# ============================================================
def get_directory_size(path: Path, excludes: set):
    total = 0
    for file in path.rglob("*"):
        if file.is_file() and not should_exclude(file, excludes):
            total += file.stat().st_size
    return total


def human_readable(size):
    for unit in ["B", "KB", "MB", "GB", "TB"]:
        if size < 1024:
            return f"{size:.2f} {unit}"
        size /= 1024
    return f"{size:.2f} PB"


# ============================================================
# HASHING
# ============================================================
def compute_structure_hash(root: Path, excludes: set):
    sha = hashlib.sha256()
    for file in sorted(root.rglob("*")):
        if file.is_file() and not should_exclude(file, excludes):
            sha.update(str(file.relative_to(root)).encode())
            sha.update(str(file.stat().st_size).encode())
    return sha.hexdigest()


def compute_content_hash(root: Path, excludes: set):
    sha = hashlib.sha256()
    for file in sorted(root.rglob("*")):
        if file.is_file() and not should_exclude(file, excludes):
            sha.update(str(file.relative_to(root)).encode())
            with file.open("rb") as f:
                for chunk in iter(lambda: f.read(8192), b""):
                    sha.update(chunk)
    return sha.hexdigest()


# ============================================================
# METADATA
# ============================================================
def read_metadata(path: Path):
    metadata_file = path / "folder_metadata.yaml"
    if metadata_file.exists():
        with metadata_file.open() as f:
            return yaml.safe_load(f)
    return None


# ============================================================
# FILE TRACKING ENFORCEMENT
# ============================================================
def enforce_file_tracking(path: Path, metadata: dict):
    enforce = metadata.get("enforce_file_tracking", False)
    if not enforce:
        return

    documented_files = set(metadata.get("files", {}).keys())
    actual_py_files = {f.name for f in path.glob("*.py")}
    undocumented = actual_py_files - documented_files

    if undocumented:
        logging.error(
            f"Undocumented scripts detected in {path.name}: {', '.join(undocumented)}"
        )
        sys.exit(1)


# ============================================================
# TREE GENERATION
# ============================================================
def generate_tree(path: Path, notes_store: dict, excludes: set, prefix=""):

    if should_exclude(path, excludes):
        return []

    metadata = read_metadata(path)

    expand_self = True
    expand_subfolders = True

    if metadata:
        expand_self = metadata.get("expand_self", True)
        expand_subfolders = metadata.get("expand_subfolders", True)

        # Folder notes
        if "notes" in metadata and metadata["notes"]:
            notes_store.setdefault(path.name, {})
            notes_store[path.name]["notes"] = metadata["notes"]

        # File metadata
        if "files" in metadata:
            notes_store.setdefault(path.name, {})
            notes_store[path.name]["files"] = metadata["files"]

        enforce_file_tracking(path, metadata)

    lines = []

    element_count = count_elements(path, excludes)

    if not expand_self:
        lines.append(
            f"{prefix}{path.name}/ "
            f"({element_count} elements, not expanded)"
        )
        return lines

    lines.append(f"{prefix}{path.name}/ ({element_count})")

    if not expand_subfolders:
        return lines

    children = [
        x for x in sorted(path.iterdir())
        if not should_exclude(x, excludes)
        and x.name != "folder_metadata.yaml"
    ]

    for i, item in enumerate(children):
        connector = "└── " if i == len(children) - 1 else "├── "

        if item.is_dir():
            lines.extend(
                generate_tree(
                    item,
                    notes_store,
                    excludes,
                    prefix + connector
                )
            )
        else:
            lines.append(f"{prefix}{connector}{item.name}")

    return lines


# ============================================================
# MAIN
# ============================================================
def main(database_path: Path, hash_content: bool, extra_excludes: list):

    excludes = DEFAULT_EXCLUDES.union(set(extra_excludes))

    report_dir = OUTPUT_FOLDER / "folder_structures"
    log_dir = OUTPUT_FOLDER / "pipeline_logs"

    report_dir.mkdir(parents=True, exist_ok=True)
    log_dir.mkdir(parents=True, exist_ok=True)

    timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")

    report_path = report_dir / f"database_snapshot_{timestamp}.txt"
    log_path = log_dir / f"database_snapshot_{timestamp}.log"

    setup_logging(log_path)

    file_count, dir_count = count_files_and_dirs(database_path, excludes)
    total_size = get_directory_size(database_path, excludes)
    readable_size = human_readable(total_size)

    structure_hash = compute_structure_hash(database_path, excludes)

    content_hash = "SKIPPED"
    if hash_content:
        content_hash = compute_content_hash(database_path, excludes)

    notes_store = {}
    tree_lines = generate_tree(database_path, notes_store, excludes)

    with report_path.open("w") as report:

        report.write("Database Structure Report\n")
        report.write("=" * 50 + "\n\n")
        report.write(f"Time of procurement: {timestamp}\n")
        report.write(f"Database path: {database_path.resolve()}\n")
        report.write(f"Total database size: {readable_size}\n")
        report.write(f"Total files: {file_count}\n")
        report.write(f"Total directories: {dir_count}\n")
        report.write(f"Structure hash: {structure_hash}\n")
        report.write(f"Content hash: {content_hash}\n\n")

        report.write("-" * 50 + "\nTREE STRUCTURE\n" + "-" * 50 + "\n\n")
        for line in tree_lines:
            report.write(line + "\n")

        report.write("\n" + "-" * 50 + "\nNOTES\n" + "-" * 50 + "\n\n")

        for folder, content in notes_store.items():
            report.write(f"[{folder}]\n\n")

            if "notes" in content:
                report.write(str(content["notes"]) + "\n\n")

            if "files" in content:
                report.write("Files:\n")
                for filename, details in content["files"].items():

                    report.write(f"  {filename}\n")

                    if isinstance(details, str):
                        report.write(f"    - description: {details}\n\n")

                    elif isinstance(details, dict):
                        for key, value in details.items():
                            report.write(f"    - {key}: {value}\n")
                        report.write("\n")

                    else:
                        report.write("    - No valid metadata\n\n")

            report.write("\n")

    logging.info(f"Report written to: {report_path}")
    logging.info(f"Log written to: {log_path}")


# ============================================================
# CLI ENTRY
# ============================================================
if __name__ == "__main__":

    parser = argparse.ArgumentParser(description="Database snapshot tool")
    parser.add_argument("database_path", help="Path to database")
    parser.add_argument("--hash-content", action="store_true")
    parser.add_argument(
        "--exclude",
        nargs="*",
        default=[],
        help="Additional folders to exclude"
    )

    args = parser.parse_args()

    db_path = Path(args.database_path)
    if not db_path.exists():
        print("Database path does not exist.")
        sys.exit(1)

    main(db_path, args.hash_content, args.exclude)