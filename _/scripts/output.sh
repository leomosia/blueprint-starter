#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# 📤 OUTPUT - Move Content to Distribution Pipeline
# ============================================================
# Moves an existing content_item into outputsys/01_intake
# AND prepares a distribution bundle inside the item folder.
#
# Usage:
#   output.sh 26001
#   output.sh c-26001
#   output.sh c-26001_hello-world
# ============================================================

usage() {
  cat <<EOF
📤 OUTPUT - Move content to distribution pipeline

Usage:
  output.sh <content_id_or_folder>

Examples:
  output.sh 26001              # automatically adds c- prefix
  output.sh c-26001            # explicit prefix
  output.sh c-26001_hello-world

This will:
  • Move content from inputsys to outputsys/01_intake
  • Create a complete distribution bundle with channel packs
  • Update metadata with today's date
EOF
}

# ---------- Validation ----------------------------------------
if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

RAW_QUERY="$1"

# Auto-add c- prefix if it's just a number
if [[ "$RAW_QUERY" =~ ^[0-9]+$ ]]; then
  QUERY="c-${RAW_QUERY}"
  echo "🔍 Searching for: $QUERY (auto-added c- prefix)"
else
  QUERY="$RAW_QUERY"
fi

# ---------- Helpers ------------------------------------------
find_blueprint_root() {
  # Walk up until we find a directory containing inputsys or outputsys.
  local dir="$PWD"
  while [[ "$dir" != "/" ]]; do
    if [[ -d "$dir/_/systems/inputsys" || -d "$dir/_/systems/outputsys" ]]; then
      echo "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  return 1
}

# Locate the content folder across both systems.
# Finds content folders across inputsys and outputsys stages.
locate_content_dir() {
  local root="$1"
  local q="$2"

  local input_root="${root}/_/systems/inputsys"
  local output_root="${root}/_/systems/outputsys"

  local found=""

  if [[ -d "$input_root" ]]; then
    found="$(
      find "$input_root" -mindepth 2 -maxdepth 4 -type d -printf '%p\n' 2>/dev/null \
        | awk -v q="$q" '
            {
              base=$0; sub(/^.*\//,"",base)
              if (base == q) hit=$0
              else if (base ~ ("^" q "_")) hit=$0
            }
            END { if (hit!="") print hit }
          '
    )"
    if [[ -n "$found" ]]; then
      echo "$found"
      return 0
    fi
  fi

  if [[ -d "$output_root" ]]; then
    found="$(
      find "$output_root" -mindepth 2 -maxdepth 3 -type d -printf '%p\n' 2>/dev/null \
        | awk -v q="$q" '
            {
              base=$0; sub(/^.*\//,"",base)
              if (base == q) hit=$0
              else if (base ~ ("^" q "_")) hit=$0
            }
            END { if (hit!="") print hit }
          '
    )"
    if [[ -n "$found" ]]; then
      echo "$found"
      return 0
    fi
  fi

  return 1
}

write_if_missing() {
  local path="$1"
  local content="$2"
  if [[ -f "$path" ]]; then
    return 0
  fi
  printf "%s" "$content" > "$path"
}

patch_meta() {
  local meta_path="$1"
  local today="$2"

  [[ -f "$meta_path" ]] || return 0

  # Always bump last_updated (if present)
  perl -0777 -i -pe "s/^last_updated:.*\$/last_updated: ${today}/m;" "$meta_path" 2>/dev/null || true

  # If these fields exist but are blank, set gentle defaults
  perl -0777 -i -pe "s/^(\\s*distribution_status:\\s*)\\s*\$/\$1unpublished/m;" "$meta_path" 2>/dev/null || true
  perl -0777 -i -pe "s/^(\\s*repurposable:\\s*)\\s*\$/\$1yes/m;" "$meta_path" 2>/dev/null || true
}

prepare_distribution_bundle() {
  local item_dir="$1"

  local dist_dir="${item_dir}/distribution"
  mkdir -p "${dist_dir}/channel_packs"

  write_if_missing "${dist_dir}/brief.md" \
"# Distribution Brief

## Objective
-

## Primary channel
-

## Secondary channels
-

## Audience
-

## Hook angles
-

## CTA
-

## Constraints
- tone:
- sensitivity:
- things we will not claim/say:
"

  write_if_missing "${dist_dir}/mapping.md" \
"# Content Mapping

## Primary format (master)
-

## Derivative opportunities
-

## Channel fit notes
- X:
- LinkedIn:
- Instagram:
- YouTube:
- Newsletter:
"

  write_if_missing "${dist_dir}/atomization.md" \
"# Atomization

## 10 hooks
1.
2.
3.
4.
5.
6.
7.
8.
9.
10.

## 10 quotables
1.
2.
3.
4.
5.
6.
7.
8.
9.
10.

## Angles (reframes)
-
"

  write_if_missing "${dist_dir}/schedule.md" \
"# Schedule

## Release plan
- Date/Time:
  - Channel:
  - Asset:
  - CTA:

## Sequencing notes
-
"

  write_if_missing "${dist_dir}/publishing_log.md" \
"# Publishing Log

| Date | Channel | Link | Variant | Notes |
|---|---|---|---|---|
"

  write_if_missing "${dist_dir}/analytics.md" \
"# Analytics & Feedback

## Metrics to track
- views/impressions:
- saves/bookmarks:
- comments/replies:
- shares/retweets:
- clicks/CTR:
- subs/leads:

## Learnings
-

## Next iteration actions
-
"

  write_if_missing "${dist_dir}/channel_packs/x.md" \
"# X Pack

## Variant A
-

## Variant B
-

## Variant C
-

## Thread version (if needed)
-

## Hashtags / tags
-
"

  write_if_missing "${dist_dir}/channel_packs/linkedin.md" \
"# LinkedIn Pack

## Variant A
-

## Variant B
-

## CTA options
-
"

  write_if_missing "${dist_dir}/channel_packs/instagram.md" \
"# Instagram Pack

## Caption A
-

## Caption B
-

## Carousel outline (if needed)
-

## Reel ideas (if relevant)
-
"

  write_if_missing "${dist_dir}/channel_packs/youtube.md" \
"# YouTube Pack

## Title options
-

## Description
-

## Chapters (if long-form)
-

## Thumbnail concept
-
"

  write_if_missing "${dist_dir}/channel_packs/newsletter.md" \
"# Newsletter Pack

## Subject lines
-
-
-

## Intro
-

## CTA
-
"
}

# ---------- Main ---------------------------------------------
echo ""
echo "📤 OUTPUT - DISTRIBUTION PIPELINE"
echo "=================================="

BLUEPRINT_ROOT="$(find_blueprint_root || true)"
if [[ -z "$BLUEPRINT_ROOT" ]]; then
  echo "❌ Error: not inside blueprint repository." >&2
  echo "   Could not find inputsys or outputsys." >&2
  exit 1
fi
echo "📍 Blueprint root: $BLUEPRINT_ROOT"

echo "🔍 Searching for content: $QUERY"
SRC_DIR="$(locate_content_dir "$BLUEPRINT_ROOT" "$QUERY" || true)"

# If not found with c- prefix and it was auto-added, try without the prefix as a fallback
if [[ -z "$SRC_DIR" && "$RAW_QUERY" =~ ^[0-9]+$ ]]; then
  echo "⚠️  Not found with c- prefix, trying without..."
  SRC_DIR="$(locate_content_dir "$BLUEPRINT_ROOT" "$RAW_QUERY" || true)"
fi

if [[ -z "$SRC_DIR" ]]; then
  echo "❌ Error: could not find content_item matching: $QUERY" >&2
  echo "   Looked in: inputsys/ and outputsys/" >&2
  exit 1
fi

echo "📍 Found: $SRC_DIR"

OUTPUT_INTAKE="${BLUEPRINT_ROOT}/_/systems/outputsys/01_intake"
mkdir -p "$OUTPUT_INTAKE"

TODAY="$(date +%F)"

# If already in outputsys, keep it there; else move into intake.
DEST_DIR="$SRC_DIR"
if [[ "$SRC_DIR" != *"/_/systems/outputsys/"* ]]; then
  BASE_NAME="$(basename "$SRC_DIR")"
  TARGET="${OUTPUT_INTAKE}/${BASE_NAME}"

  if [[ -e "$TARGET" ]]; then
    echo "❌ Error: destination already exists: $TARGET" >&2
    exit 1
  fi

  echo "📦 Moving content to outputsys..."
  mv "$SRC_DIR" "$TARGET"
  DEST_DIR="$TARGET"
  echo "   ✅ Moved to: $DEST_DIR"
else
  echo "⏭️  Content already in outputsys (no move needed)"
fi

# Prepare distribution bundle
echo ""
echo "📁 Creating distribution bundle..."
prepare_distribution_bundle "$DEST_DIR"

DIST_DIR="${DEST_DIR}/distribution"
echo "   ✅ Created: $DIST_DIR/"
echo "   📄 Files created:"
echo "      ├── brief.md"
echo "      ├── mapping.md"
echo "      ├── atomization.md"
echo "      ├── schedule.md"
echo "      ├── publishing_log.md"
echo "      ├── analytics.md"
echo "      └── channel_packs/"
echo "          ├── x.md"
echo "          ├── linkedin.md"
echo "          ├── instagram.md"
echo "          ├── youtube.md"
echo "          └── newsletter.md"

# Patch meta.md
echo ""
echo "📝 Updating metadata..."
patch_meta "${DEST_DIR}/meta.md" "$TODAY"
echo "   ✅ last_updated: $TODAY"
echo "   ✅ distribution_status: unpublished"
echo "   ✅ repurposable: yes"

echo ""
echo "=================================================="
echo "✅ OUTPUT READY FOR DISTRIBUTION!"
echo "=================================================="
echo ""
echo "📋 Content Summary:"
echo "   ID:     $(basename "$DEST_DIR")"
echo "   Path:   $DEST_DIR"
echo ""
echo "📂 Distribution bundle:"
echo "   $DIST_DIR/"
echo "   ├── brief.md        - Distribution strategy"
echo "   ├── mapping.md      - Channel mapping"
echo "   ├── atomization.md  - Hooks & quotables"
echo "   ├── schedule.md     - Release timeline"
echo "   ├── publishing_log.md - Track publishes"
echo "   ├── analytics.md    - Performance tracking"
echo "   └── channel_packs/  - Platform-specific content"
echo "       ├── x.md"
echo "       ├── linkedin.md"
echo "       ├── instagram.md"
echo "       ├── youtube.md"
echo "       └── newsletter.md"
echo ""
echo "🔄 Next steps:"
echo "   1. Edit files in distribution/ to plan your content"
echo "   2. Use move.sh to progress through stages:"
echo "      move.sh $(basename "$DEST_DIR") next"
echo "=================================================="
