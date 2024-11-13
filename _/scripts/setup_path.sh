#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  _/scripts/setup_path.sh [--print|--install]

Options:
  --print     Print the export command only.
  --install   Add the export command to your shell profile if missing.

Examples:
  _/scripts/setup_path.sh --print
  _/scripts/setup_path.sh --install
USAGE
}

mode="${1:---print}"

if [ "$mode" = "-h" ] || [ "$mode" = "--help" ]; then
  usage
  exit 0
fi

if [ "$mode" != "--print" ] && [ "$mode" != "--install" ]; then
  usage >&2
  exit 1
fi

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
export_line="export PATH=\"${script_dir}:\$PATH\""

if [ "$mode" = "--print" ]; then
  printf '%s\n' "$export_line"
  exit 0
fi

shell_name="$(basename "${SHELL:-}")"

case "$shell_name" in
  zsh)
    profile_file="${HOME}/.zshrc"
    ;;
  bash)
    profile_file="${HOME}/.bashrc"
    ;;
  *)
    profile_file="${HOME}/.profile"
    ;;
esac

touch "$profile_file"

if grep -Fq "$script_dir" "$profile_file"; then
  echo "Blueprint scripts are already on PATH in ${profile_file}"
  exit 0
fi

{
  printf '\n'
  printf '# Blueprint scripts\n'
  printf '%s\n' "$export_line"
} >> "$profile_file"

echo "Added Blueprint scripts to PATH in ${profile_file}"
echo "Restart your terminal or run:"
echo "  source ${profile_file}"
