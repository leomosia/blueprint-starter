#!/usr/bin/env python3
"""
split_inbox.py — STRICT whitelist-gated inbox splitter

EXPECTED CONTENT (ONLY):
  - Valid entries: "- #tag - anything..."
  - Comments: <!-- comment -->
  - Empty lines (ignored)

ANY OTHER CONTENT = ERROR and forces cleanup

Usage:
  ./_inbox_scripts/split.sh                    # Normal
  ./_inbox_scripts/split.sh --force            # Force mode (process despite invalid content)
  ./_inbox_scripts/split.sh --dry-run          # Preview only

Returns exit codes:
  0: Success (all content processed cleanly)
  1: Error (file not found, permissions, etc.)
  2: Invalid content found (user must clean inbox.md)
"""

from __future__ import annotations

import argparse
import re
import sys
import time
import os
from datetime import datetime
from pathlib import Path
from typing import List, Tuple, Dict, Optional, Set

# Accepted entry header: "- #tag - " where tag is lowercase letters only.
ENTRY_RE = re.compile(r"^\s*-\s*#([a-z]+)\s*-\s+(.*)$")

class JobLogger:
    """Simple job logger with timestamps and categories"""

    def __init__(self, job_name: str):
        self.job_name = job_name
        self.start_time = time.time()
        self.stats: Dict[str, int] = {
            "errors": 0,
            "warnings": 0,
            "valid_entries": 0,
            "invalid_lines": 0,
            "comments": 0,
            "empty_lines": 0,
            "extracted_blocks": 0
        }
        self.invalid_lines_list: List[Tuple[int, str, str]] = []

    def log(self, message: str, category: str = "INFO") -> None:
        """Log a message with timestamp"""
        timestamp = datetime.now().strftime("%H:%M:%S")
        formatted = f"[{timestamp}] [{category:^7}] {message}"
        print(formatted)

    def success(self, message: str) -> None:
        self.log(message, "SUCCESS")

    def error(self, message: str) -> None:
        self.stats["errors"] += 1
        self.log(message, "ERROR")

    def warning(self, message: str) -> None:
        self.stats["warnings"] += 1
        self.log(message, "WARNING")

    def info(self, message: str) -> None:
        self.log(message, "INFO")

    def add_invalid_line(self, line_num: int, line: str, reason: str) -> None:
        """Track an invalid line"""
        self.stats["invalid_lines"] += 1
        self.invalid_lines_list.append((line_num, line.strip(), reason))
        self.error(f"Line {line_num}: INVALID - {reason} - '{line.strip()}'")


def read_file_safe(path: Path, logger: JobLogger) -> Optional[str]:
    """Safely read a file with error handling"""
    try:
        return path.read_text(encoding="utf-8")
    except FileNotFoundError:
        logger.error(f"File not found: {path}")
        return None
    except Exception as e:
        logger.error(f"Error reading {path}: {e}")
        return None


def write_file_safe(path: Path, content: str, logger: JobLogger) -> bool:
    """Safely write a file with error handling"""
    try:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
        return True
    except Exception as e:
        logger.error(f"Error writing {path}: {e}")
        return False


def append_block_safe(path: Path, block: str, logger: JobLogger) -> bool:
    """Safely append a block to a file"""
    try:
        existing = ""
        if path.exists():
            existing_content = read_file_safe(path, logger)
            if existing_content is None:
                return False
            existing = existing_content

        if existing and not existing.endswith("\n"):
            existing += "\n"

        out = existing + "\n---\n" + block + ("" if block.endswith("\n") else "\n")
        return write_file_safe(path, out, logger)
    except Exception as e:
        logger.error(f"Error appending to {path}: {e}")
        return False


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="inbox splitter - only valid entries allowed")
    p.add_argument("--root", default=".", help="Root directory path")
    p.add_argument("--inbox", default="inbox.md", help="Inbox filename")
    p.add_argument("--whitelist", default="_inbox_scripts/whitelist.yml", help="Whitelist filename")
    p.add_argument("--mode", choices=["move", "copy"], default="move",
                   help="move = remove extracted blocks, copy = keep them")
    p.add_argument("--dry-run", action="store_true",
                   help="Show what would be done without making changes")
    p.add_argument("--force", action="store_true",
                   help="Process even with invalid content (not recommended)")
    return p.parse_args()


def load_whitelist(path: Path, logger: JobLogger) -> Set[str]:
    """
    Load and validate whitelist.yml
    Returns set of valid tags
    """
    logger.info(f"Loading whitelist from: {path}")

    content = read_file_safe(path, logger)
    if content is None:
        return set()

    allowed: Set[str] = set()
    invalid_entries = []

    for line_num, raw in enumerate(content.replace("\r\n", "\n").split("\n"), 1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if line.endswith(":"):
            continue

        m = re.match(r"^-+\s+(.+)$", line)
        if not m:
            if line and not line.startswith('#'):
                invalid_entries.append((line_num, line))
            continue

        val = m.group(1).strip().strip('"').strip("'")
        if re.fullmatch(r"[a-z]+", val):
            allowed.add(val)
        else:
            invalid_entries.append((line_num, f"{line} (invalid format)"))

    logger.info(f"Found {len(allowed)} valid tags in whitelist")
    if allowed:
        logger.info(f"Valid tags: {', '.join(sorted(allowed))}")

    if invalid_entries:
        logger.warning(f"Found {len(invalid_entries)} invalid entries in whitelist")
        for line_num, entry in invalid_entries[:5]:
            logger.warning(f"  Line {line_num}: {entry}")
        if len(invalid_entries) > 5:
            logger.warning(f"  ... and {len(invalid_entries) - 5} more")

    return allowed


def is_comment_line(line: str) -> bool:
    """Check if line is part of a comment block"""
    return "<!--" in line or "-->" in line


def is_empty_line(line: str) -> bool:
    """Check if line is empty or only whitespace"""
    return not line.strip()


def validate_inbox_content(content: str, allowed_tags: Set[str], logger: JobLogger) -> Tuple[List[Tuple[str, str]], List[str], bool]:
    """
    validation - any line that's not a valid entry, comment, or empty line is an error.
    Returns: (extracted_blocks, lines_to_keep, has_invalid_content)
    """
    lines = content.split("\n")
    keep_lines: List[str] = []
    extracted: List[Tuple[str, str]] = []

    in_comment_block = False
    has_invalid_content = False

    i = 0
    while i < len(lines):
        line = lines[i]
        line_num = i + 1

        # Handle comment blocks
        if "<!--" in line:
            in_comment_block = True
            logger.stats["comments"] += 1
            keep_lines.append(line)
            i += 1
            continue
        elif "-->" in line and in_comment_block:
            in_comment_block = False
            keep_lines.append(line)
            i += 1
            continue
        elif in_comment_block:
            keep_lines.append(line)
            i += 1
            continue

        # Handle empty lines
        if is_empty_line(line):
            logger.stats["empty_lines"] += 1
            keep_lines.append(line)
            i += 1
            continue

        # Check for valid entry
        tag_match = ENTRY_RE.match(line)

        if tag_match:
            # Valid entry header found
            tag = tag_match.group(1).lower()

            # Capture the entire block
            j = i
            block_lines = [lines[j]]
            j += 1
            while j < len(lines):
                next_line = lines[j]
                # Stop at next entry or comment start
                if ENTRY_RE.match(next_line) or "<!--" in next_line:
                    break
                block_lines.append(next_line)
                j += 1

            block = "\n".join(block_lines)

            if tag in allowed_tags:
                logger.stats["valid_entries"] += 1
                extracted.append((tag, block))
                logger.info(f"  ✅ Valid entry #{logger.stats['valid_entries']}: '#{tag}'")
            else:
                # Tag not in whitelist - this is invalid content
                has_invalid_content = True
                logger.add_invalid_line(line_num, line, f"Tag '#{tag}' not in whitelist")
                keep_lines.extend(block_lines)

            i = j
        else:
            # INVALID CONTENT - not a comment, not empty, not a valid entry
            has_invalid_content = True
            logger.add_invalid_line(line_num, line, "Not a valid entry format")
            keep_lines.append(line)
            i += 1

    return extracted, keep_lines, has_invalid_content


def print_force_command(logger: JobLogger, args: argparse.Namespace) -> None:
    """Print helpful command for force mode"""
    logger.info("")
    logger.info("💡 QUICK FIXES:")
    logger.info("   Option 1: Clean up the invalid lines in inbox.md")
    logger.info("   Option 2: Use force mode to process anyway:")
    logger.info("")
    logger.info("   " + "-" * 50)
    logger.info("   📋 COPY THIS COMMAND:")

    # Build the force command based on original arguments
    cmd_parts = ["./_inbox_scripts/split.sh"]
    if args.dry_run:
        cmd_parts.append("--dry-run")
    if args.force:
        cmd_parts.append("--force")
    if args.mode != "move":
        cmd_parts.append(f"--mode {args.mode}")

    force_cmd = " ".join(cmd_parts) + " --force"
    logger.info(f"   {force_cmd}")
    logger.info("   " + "-" * 50)
    logger.info("")


def main() -> int:
    """Main function returns exit code"""
    args = parse_args()

    # Initialize job logger
    logger = JobLogger("Inbox Splitter")

    # Print job header
    logger.info("=" * 70)
    logger.info(f"🔒 INBOX SPLITTER")
    logger.info(f"Started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    logger.info("=" * 70)
    logger.info(f"Configuration:")
    logger.info(f"  Command: split_inbox.py {' '.join(sys.argv[1:])}")
    logger.info(f"  Root: {args.root}")
    logger.info(f"  Inbox: {args.inbox}")
    logger.info(f"  Whitelist: {args.whitelist}")
    logger.info(f"  Mode: {args.mode}")
    logger.info(f"  Dry run: {args.dry_run}")
    logger.info(f"  Force mode: {args.force}")
    logger.info("-" * 70)

    root = Path(args.root)
    inbox_path = root / args.inbox
    whitelist_path = root / args.whitelist

    # Check if inbox exists
    if not inbox_path.exists():
        logger.error(f"Inbox not found: {inbox_path}")
        return 1

    # Load whitelist
    allowed_tags = load_whitelist(whitelist_path, logger)
    if not allowed_tags:
        logger.warning("No valid tags found in whitelist - no blocks will be extracted")

    # Read inbox
    logger.info(f"Reading inbox: {inbox_path}")
    content = read_file_safe(inbox_path, logger)
    if content is None:
        return 1

    # STRICT validation
    logger.info("🔍 Performing validation of inbox content...")
    extracted_blocks, keep_lines, has_invalid_content = validate_inbox_content(content, allowed_tags, logger)

    # Report validation results
    logger.info("-" * 70)
    logger.info("VALIDATION RESULTS:")
    logger.info(f"  📝 Comments: {logger.stats['comments']}")
    logger.info(f"  ⬜ Empty lines: {logger.stats['empty_lines']}")
    logger.info(f"  ✅ Valid entries: {logger.stats['valid_entries']}")
    logger.info(f"  ❌ Invalid lines: {logger.stats['invalid_lines']}")

    if logger.invalid_lines_list:
        logger.error("=" * 70)
        logger.error("🚨 INVALID CONTENT FOUND - INBOX NEEDS CLEANUP:")
        logger.error("=" * 70)
        for line_num, line, reason in logger.invalid_lines_list:
            logger.error(f"  Line {line_num:3d} | {reason:30} | '{line}'")
        logger.error("=" * 70)

        if not args.force:
            logger.error("❌ Invalid content detected. Aborting.")
            print_force_command(logger, args)
            return 2
        else:
            logger.warning("⚠️  FORCE MODE: Processing despite invalid content (not recommended)")

    # Perform extraction (if not dry run)
    if not args.dry_run and extracted_blocks:
        logger.info("-" * 70)
        logger.info("📤 EXTRACTING BLOCKS:")

        extracted_count = 0
        for tag, block in extracted_blocks:
            out_dir = root / f"{tag}_inbox"
            out_file = out_dir / f"{tag}_inbox.md"

            if append_block_safe(out_file, block, logger):
                extracted_count += 1
                logger.stats["extracted_blocks"] += 1
                logger.success(f"  [{extracted_count}/{len(extracted_blocks)}] Extracted to: {out_file}")
            else:
                logger.error(f"  Failed to extract: {tag}")

        # Update inbox in move mode
        if args.mode == "move" and extracted_count > 0:
            new_inbox = "\n".join(keep_lines)
            new_inbox = re.sub(r"\n+$", "\n", new_inbox)

            if write_file_safe(inbox_path, new_inbox, logger):
                logger.success(f"✅ Updated inbox: {inbox_path} (removed {extracted_count} blocks)")
            else:
                logger.error("Failed to update inbox")

    elif args.dry_run:
        logger.info("-" * 70)
        logger.info("🔍 DRY RUN - No changes made")
        if extracted_blocks:
            logger.info(f"Would extract {len(extracted_blocks)} blocks to:")
            for tag, _ in extracted_blocks:
                logger.info(f"  - #{tag} → {tag}_inbox/{tag}_inbox.md")
    else:
        logger.info("No blocks to extract")

    # Final summary
    logger.info("=" * 70)
    logger.info("📊 FINAL JOB SUMMARY:")
    logger.info("=" * 70)
    logger.info(f"  Comments preserved:     {logger.stats['comments']:3d}")
    logger.info(f"  Empty lines kept:       {logger.stats['empty_lines']:3d}")
    logger.info(f"  Valid entries found:    {logger.stats['valid_entries']:3d}")
    logger.info(f"  Blocks extracted:       {logger.stats['extracted_blocks']:3d}")
    logger.info(f"  Invalid lines found:    {logger.stats['invalid_lines']:3d}")
    logger.info(f"  Total warnings:         {logger.stats['warnings']:3d}")
    logger.info(f"  Total errors:           {logger.stats['errors']:3d}")

    if logger.stats['invalid_lines'] > 0 and not args.force:
        logger.error("=" * 70)
        logger.error("❌ JOB FAILED: Inbox contains invalid content")
        print_force_command(logger, args)
        logger.error("=" * 70)
        return 2
    elif logger.stats['errors'] > 0:
        logger.error("=" * 70)
        logger.error("❌ JOB FAILED: System errors occurred")
        logger.error("=" * 70)
        return 1
    else:
        logger.success("=" * 70)
        logger.success("✅ JOB COMPLETED SUCCESSFULLY - All content valid")
        logger.success("=" * 70)
        return 0


if __name__ == "__main__":
    sys.exit(main())
