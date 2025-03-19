#!/usr/bin/env bash
set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."  # Go up to the 01_inbox directory

# Default paths
ROOT="."
INBOX="inbox.md"
WHITELIST="_inbox_scripts/whitelist.yml"

# Pass all arguments to the Python script
python3 _inbox_scripts/split_inbox.py \
  --root "$ROOT" \
  --inbox "$INBOX" \
  --whitelist "$WHITELIST" \
  --mode "move" \
  "$@"

EXIT_CODE=$?

# Handle exit codes
case $EXIT_CODE in
  0)
    echo ""
    echo "✅ Job completed successfully"
    ;;
  2)
    echo ""
    echo "⚠️  Job completed with warnings - some content was invalid"
    echo "   Run './_inbox_scripts/split.sh --force' to process anyway"
    ;;
  *)
    echo ""
    echo "❌ Job failed with errors (exit code: $EXIT_CODE)"
    exit $EXIT_CODE
    ;;
esac
