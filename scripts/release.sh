#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/release.sh <version>

Example:
  scripts/release.sh mvp.2024.7.2.3

Requires:
  - git
  - GitHub CLI: gh
  - a local tag matching <version>
  - release notes at releases/<version>.md
USAGE
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

version="${1:-}"

if [ -z "$version" ]; then
  usage
  exit 1
fi

notes_file="releases/${version}.md"

if [ ! -f "$notes_file" ]; then
  echo "Missing release notes: ${notes_file}" >&2
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "Missing dependency: gh" >&2
  exit 1
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "This script must be run inside a Git repository." >&2
  exit 1
fi

if [ -n "$(git status --porcelain)" ]; then
  echo "Worktree is dirty. Commit or stash changes before releasing." >&2
  exit 1
fi

if ! git rev-parse -q --verify "refs/tags/${version}" >/dev/null; then
  echo "Missing local tag: ${version}" >&2
  exit 1
fi

stage="${version%%.*}"
prerelease_flag=""

case "$stage" in
  mvp|alpha|beta|rc*)
    prerelease_flag="--prerelease"
    ;;
esac

git push origin HEAD
git push origin "$version"

if gh release view "$version" >/dev/null 2>&1; then
  gh release edit "$version" \
    --title "$version" \
    --notes-file "$notes_file" \
    $prerelease_flag
else
  gh release create "$version" \
    --title "$version" \
    --notes-file "$notes_file" \
    $prerelease_flag
fi

echo "Published GitHub Release: ${version}"
