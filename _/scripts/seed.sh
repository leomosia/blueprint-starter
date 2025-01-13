#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# 🌱 SEED - Move content item into _/systems/inputsys/01_inbox/contentitems_inbox/00_seeding
# ============================================================
# Usage:
#   seed.sh 26116
#   seed.sh c-26116
#   seed.sh c-26116_its-a-slow-start
#   seed.sh --list                 # List unseeded content
#   seed.sh --help                 # Show help
# ============================================================

usage() {
  cat <<EOF
🌱 SEED - Move content item into seeding folder

Usage:
  seed.sh <content_item>          # Move item to seeding stage
  seed.sh --list                   # List unseeded content items
  seed.sh --help                   # Show this help

Examples:
  seed.sh 26116                    # automatically adds c- prefix
  seed.sh c-26116                  # explicit prefix
  seed.sh c-26116_its-a-slow-start # full name
  seed.sh --list                    # show what needs seeding

The seeding folder is: _/systems/inputsys/01_inbox/contentitems_inbox/00_seeding/
EOF
}

# Fast blueprint root finder (cached)
find_blueprint_root() {
  local dir="$PWD"
  while [[ "$dir" != "/" ]]; do
    if [[ -d "$dir/_/systems/inputsys" ]]; then
      echo "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  return 1
}

# Fast content finder using direct path checks
find_content_item_fast() {
  local root="$1"
  local q="$2"
  local result=""
  
  # Strategy 1: Direct check in inbox stages (most common case)
  # Look in 01_inbox/contentitems_inbox subdirectories first
  local inbox="${root}/_/systems/inputsys/01_inbox/contentitems_inbox"
  if [[ -d "$inbox" ]]; then
    # Check for exact match in inbox
    if [[ -d "${inbox}/${q}" ]]; then
      echo "${inbox}/${q}"
      return 0
    fi
    # Check for prefix match in inbox
    local inbox_match
    inbox_match=$(find "$inbox" -mindepth 1 -maxdepth 1 -type d -name "${q}_*" 2>/dev/null | head -1)
    if [[ -n "$inbox_match" ]]; then
      echo "$inbox_match"
      return 0
    fi
    
    # Also check in seeding folder
    local seeding_path="${inbox}/00_seeding"
    if [[ -d "$seeding_path" ]]; then
      if [[ -d "${seeding_path}/${q}" ]]; then
        echo "${seeding_path}/${q}"
        return 0
      fi
      local seed_match
      seed_match=$(find "$seeding_path" -mindepth 1 -maxdepth 1 -type d -name "${q}_*" 2>/dev/null | head -1)
      if [[ -n "$seed_match" ]]; then
        echo "$seed_match"
        return 0
      fi
    fi
  fi
  
  # Strategy 2: Search in regular stages (02_processing, 03_analysis, etc.)
  local stages_root="${root}/_/systems/inputsys"
  if [[ -d "$stages_root" ]]; then
    # Search at depth 2 for items in regular stages
    local stage_match
    stage_match=$(find "$stages_root" -mindepth 2 -maxdepth 2 -type d -name "${q}_*" 2>/dev/null | head -1)
    if [[ -n "$stage_match" ]]; then
      echo "$stage_match"
      return 0
    fi
  fi
}

# List unseeded content (fast)
list_unseeded() {
  local root="$1"
  local inbox="${root}/_/systems/inputsys/01_inbox/contentitems_inbox"
  local seed_stage="${inbox}/00_seeding"
  
  echo ""
  echo "📋 Unseeded content items:"
  echo "=========================="
  
  local found=0
  
  # Check items in contentitems_inbox (not in seeding)
  if [[ -d "$inbox" ]]; then
    while IFS= read -r item; do
      if [[ -d "$item" && "$item" != "$seed_stage" ]]; then
        echo "  📄 $(basename "$item")  [stage: 01_inbox/contentitems_inbox]"
        found=$((found + 1))
      fi
    done < <(find "$inbox" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | grep -v "00_seeding")
  fi
  
  # Also check other stages for items not yet seeded
  local stages_root="${root}/_/systems/inputsys"
  if [[ -d "$stages_root" ]]; then
    while IFS= read -r stage_dir; do
      stage="$(basename "$stage_dir")"
      [[ "$stage" == "01_inbox" ]] && continue
      
      while IFS= read -r item; do
        if [[ -d "$item" ]]; then
          echo "  📄 $(basename "$item")  [stage: $stage]"
          found=$((found + 1))
        fi
      done < <(find "$stage_dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | head -10)
    done < <(find "$stages_root" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)
  fi
  
  if [[ $found -eq 0 ]]; then
    echo "  ✨ No unseeded content found"
  else
    echo ""
    echo "💡 Tip: Use 'seed.sh <item>' to move any of these to seeding"
  fi
  echo "=========================="
}

# Fast path for help and list commands
if [[ $# -eq 0 ]]; then
  usage
  exit 0
fi

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
  usage
  exit 0
fi

# Handle list command
if [[ "$1" == "--list" ]]; then
  BLUEPRINT_ROOT="$(find_blueprint_root 2>/dev/null || true)"
  if [[ -z "$BLUEPRINT_ROOT" ]]; then
    echo "❌ Error: not in blueprint repository" >&2
    exit 1
  fi
  list_unseeded "$BLUEPRINT_ROOT"
  exit 0
fi

# Auto-add c- prefix if it's just a number
RAW_QUERY="$1"
if [[ "$RAW_QUERY" =~ ^[0-9]+$ ]]; then
  QUERY="c-${RAW_QUERY}"
  echo "🔍 Searching for: $QUERY (auto-added c- prefix)"
else
  QUERY="$RAW_QUERY"
fi

# Main seeding operation
echo ""
echo "🌱 SEED CONTENT ITEM"
echo "===================="

# Find blueprint root (fast)
BLUEPRINT_ROOT="$(find_blueprint_root || true)"
if [[ -z "$BLUEPRINT_ROOT" ]]; then
  echo "❌ Error: could not locate blueprint root" >&2
  echo "   Make sure you're inside a blueprint repository"
  exit 1
fi
echo "📍 Blueprint root: $BLUEPRINT_ROOT"

INPUTSYS_ROOT="${BLUEPRINT_ROOT}/_/systems/inputsys"
BIRTH_STAGE="${INPUTSYS_ROOT}/01_inbox/contentitems_inbox"
SEED_STAGE="${BIRTH_STAGE}/00_seeding"

# Quick validation
if [[ ! -d "$INPUTSYS_ROOT" ]]; then
  echo "❌ Error: inputsys not found at: $INPUTSYS_ROOT" >&2
  exit 1
fi

if [[ ! -d "$BIRTH_STAGE" ]]; then
  echo "❌ Error: 01_inbox/contentitems_inbox not found at: $BIRTH_STAGE" >&2
  exit 1
fi

# Ensure seed stage exists
mkdir -p "$SEED_STAGE"
echo "📍 Seed location: $SEED_STAGE"

# Find the content item
echo "🔍 Searching for content..."
FOUND="$(find_content_item_fast "$BLUEPRINT_ROOT" "$QUERY")"

# If not found with c- prefix and it was auto-added, try without the prefix as a fallback
if [[ -z "$FOUND" && "$RAW_QUERY" =~ ^[0-9]+$ ]]; then
  echo "⚠️  Not found with c- prefix, trying without..."
  FOUND="$(find_content_item_fast "$BLUEPRINT_ROOT" "$RAW_QUERY")"
fi

if [[ -z "$FOUND" || ! -d "$FOUND" ]]; then
  echo "❌ Error: content item not found: $QUERY" >&2
  echo ""
  echo "Quick check of items in contentitems_inbox:"
  count=0
  while IFS= read -r item; do
    if [[ -d "$item" && "$count" -lt 5 ]]; then
      echo "  📁 $(basename "$item")"
      count=$((count + 1))
    fi
  done < <(find "${BIRTH_STAGE}" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | grep -v "00_seeding" | head -5)
  
  if [[ $count -eq 0 ]]; then
    echo "  No items found in contentitems_inbox"
    echo ""
    echo "💡 Tip: Use 'seed.sh --list' to see all unseeded items"
  else
    echo "  ..."
  fi
  exit 1
fi

ITEM_NAME="$(basename "$FOUND")"
CURRENT_STAGE="$(basename "$(dirname "$FOUND")")"
DEST="${SEED_STAGE}/${ITEM_NAME}"

echo "📍 Found item: $ITEM_NAME"
echo "   Current location: $(dirname "$FOUND")"
echo "   Target stage: 00_seeding/"

# Check if already seeded
if [[ "$FOUND" == "$DEST" ]]; then
  echo "✅ Item is already in seeding folder:"
  echo "   $DEST"
  exit 0
fi

# Check for destination conflict
if [[ -e "$DEST" ]]; then
  echo "❌ Error: destination already exists:" >&2
  echo "   $DEST" >&2
  exit 1
fi

# Move it
echo "📦 Moving item to seeding..."
mv "$FOUND" "$DEST"
echo "   ✅ Move completed"

echo ""
echo "✅ SEED SUCCESSFUL!"
echo "===================="
echo "   From: $CURRENT_STAGE/"
echo "   To:   00_seeding/"
echo "   Path: $DEST"
echo ""

# Quick stats
if [[ -d "$DEST" ]]; then
  FILE_COUNT=$(find "$DEST" -type f 2>/dev/null | wc -l)
  echo "📊 Item contains: $FILE_COUNT files"
fi

echo ""
echo "🌱 Next steps:"
echo "   1. Add source materials to ${DEST}/_sources/ (if any)"
echo "   2. Document research in ${DEST}/_research/"
echo "   3. Start drafting in ${DEST}/_drafts/"
echo "   4. When ready, use 'move.sh ${ITEM_NAME} next' to continue"
echo "===================="
