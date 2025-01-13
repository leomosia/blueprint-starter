#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# 🚚 MOVE - Universal Stage Mover
# ============================================================
# Moves items between stages. Now with enhanced search that
# checks 01_inbox/contentitems_inbox/00_seeding/ first, then falls back to normal.
#
#   - todosys/   (stories: s-YYNNN_*)
#   - inputsys/  (content: c-YYNNN_*)
#   - outputsys/ (content: c-YYNNN_*)
#
# Usage:
#   move.sh <item>                 # next
#   move.sh <item> next
#   move.sh <item> prev
#   move.sh <item> <NN_stageName>  # jump by folder name, e.g. 05_live
#   move.sh <item> <NN>            # jump by numeric prefix, e.g. 05
#
# Special law:
#   If content is in inputsys/08_sharing and you do next,
#   it MUST handoff via output (move to outputsys/01_intake).
# ============================================================

usage() {
  cat <<EOF
Usage:
  move.sh <item> [next|prev|<NN>|<NN_stageName>]

Examples:
  move.sh 26001                     # next (automatically adds c- prefix)
  move.sh c-26001_fix-login next    # explicit next
  move.sh 26001 prev                # previous stage
  move.sh 26001 05_live             # jump by full stage name
  move.sh 26001 05                  # jump by stage number
EOF
}

# ---------- Validation ----------------------------------------
if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

RAW_QUERY="$1"
ACTION="${2:-next}"   # default next

# Auto-add c- prefix if it's just a number
if [[ "$RAW_QUERY" =~ ^[0-9]+$ ]]; then
  QUERY="c-${RAW_QUERY}"
  echo "🔍 Searching for: $QUERY (auto-added c- prefix)"
else
  QUERY="$RAW_QUERY"
fi

# ---------- Helpers ------------------------------------------
find_blueprint_root() {
  local dir="$PWD"
  while [[ "$dir" != "/" ]]; do
    if [[ -d "$dir/_/systems/todosys" || -d "$dir/_/systems/inputsys" || -d "$dir/_/systems/outputsys" ]]; then
      echo "$dir"; return 0
    fi
    dir="$(dirname "$dir")"
  done
  return 1
}

# Enhanced item finder that checks 00_seeding first
find_item_in_system() {
  local system_root="$1" q="$2"
  [[ -d "$system_root" ]] || return 1

  # For inputsys, check 00_seeding first
  if [[ "$system_root" == *"/_/systems/inputsys"* ]]; then
    local seeding_path="${system_root}/01_inbox/contentitems_inbox/00_seeding"
    
    # First check in seeding folder
    if [[ -d "$seeding_path" ]]; then
      # Check for exact match in seeding
      if [[ -d "${seeding_path}/${q}" ]]; then
        echo "${seeding_path}/${q}"
        return 0
      fi
      
      # Check for prefix match in seeding (q_*)
      local seed_match
      seed_match=$(find "$seeding_path" -mindepth 1 -maxdepth 1 -type d -name "${q}_*" 2>/dev/null | head -1)
      if [[ -n "$seed_match" ]]; then
        echo "$seed_match"
        return 0
      fi
    fi
    
    # Then check in main inbox content items folder
    local inbox_path="${system_root}/01_inbox/contentitems_inbox"
    if [[ -d "$inbox_path" ]]; then
      # Check for exact match in inbox
      if [[ -d "${inbox_path}/${q}" ]]; then
        echo "${inbox_path}/${q}"
        return 0
      fi
      
      # Check for prefix match in inbox
      local inbox_match
      inbox_match=$(find "$inbox_path" -mindepth 1 -maxdepth 1 -type d -name "${q}_*" 2>/dev/null | head -1)
      if [[ -n "$inbox_match" ]]; then
        echo "$inbox_match"
        return 0
      fi
    fi
  fi

  # Then fall back to regular search everywhere
  # Search at depths 2, 3, and 4 for inputsys to catch items in all stages
  if [[ "$system_root" == *"/_/systems/inputsys"* ]]; then
    # Search at depths 2, 3, and 4
    for depth in 2 3 4; do
      local result
      result=$(find "$system_root" -mindepth "$depth" -maxdepth "$depth" -type d -printf '%p\n' 2>/dev/null \
        | awk -v q="$q" '
            {
              base=$0; sub(/^.*\//,"",base)
              if (base == q) { print $0; exit }
              else if (base ~ ("^" q "_")) { print $0; exit }
            }
          ')
      if [[ -n "$result" ]]; then
        echo "$result"
        return 0
      fi
    done
  else
    # For other systems, just search at depth 2
    find "$system_root" -mindepth 2 -maxdepth 2 -type d -printf '%p\n' 2>/dev/null \
      | awk -v q="$q" '
          {
            base=$0; sub(/^.*\//,"",base)
            if (base == q) hit=$0
            else if (base ~ ("^" q "_")) hit=$0
          }
          END { if (hit!="") print hit }
        '
  fi
}
list_sorted_stages() {
  local system_root="$1"
  
  # For inputsys, stages are at the root level (siblings of 01_inbox)
  if [[ "$system_root" == *"/_/systems/inputsys"* ]]; then
    # List all numbered stages (02_*, 03_*, etc.) from the inputsys root
    # Explicitly exclude 01_inbox since we add it separately
    find "$system_root" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null \
      | grep '^[0-9][0-9]_' \
      | grep -v '^01_inbox$' \
      | sort -t_ -k1,1n
  else
    # For other systems, list stages as before
    find "$system_root" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null \
      | grep '^[0-9]' \
      | sort
  fi
}

stage_prefix() {
  echo "$1" | sed -nE 's/^([0-9]+)_.*/\1/p'
}

stage_suffix() {
  echo "$1" | sed -nE 's/^[0-9]+_(.*)$/\1/p'
}

write_if_missing() {
  local path="$1" content="$2"
  [[ -f "$path" ]] && return 0
  printf "%s" "$content" > "$path"
}

# Stage-specific initialization hooks
init_for_stage() {
  local system="$1" stage="$2" item_dir="$3"

  # Only outputsys has real “distribution pipeline” artifacts
  if [[ "$system" == "outputsys" ]]; then
    local dist="${item_dir}/distribution"
    mkdir -p "$dist"

    case "$stage" in
      01_intake)
        mkdir -p "${dist}/channel_packs"
        write_if_missing "${dist}/brief.md" "# Distribution Brief\n\n## Objective\n-\n"
        write_if_missing "${dist}/mapping.md" "# Content Mapping\n\n## Primary format (master)\n-\n"
        ;;
      02_atomization)
        write_if_missing "${dist}/atomization.md" "# Atomization\n\n## 10 hooks\n1.\n"
        ;;
      03_platform)
        write_if_missing "${dist}/optimization.md" "# Optimization\n\n## Platform-specific adjustments\n-\n"
        ;;
      04_publishing)
        write_if_missing "${dist}/publishing.md" "# Publishing\n\n## Schedule\n-\n"
        write_if_missing "${dist}/publishing_log.md" "# Publishing Log\n\n| Date | Channel | Link | Variant | Notes |\n|---|---|---|---|---|\n"
        ;;
      07_analytics)
        write_if_missing "${dist}/analytics.md" "# Analytics & Feedback\n\n## Learnings\n-\n"
        ;;
    esac
  fi
}

patch_meta() {
  local system="$1" stage="$2" item_dir="$3" today="$4"
  local meta="${item_dir}/meta.md"
  [[ -f "$meta" ]] || return 0

  perl -0777 -i -pe "s/^last_updated:.*\$/last_updated: ${today}/m;" "$meta" 2>/dev/null || true

  if [[ "$system" == "todosys" ]]; then
    # Normalize story meta status to stage suffix
    local suf
    suf="$(stage_suffix "$stage")"
    case "$suf" in
      backlog) new_status="backlog" ;;
      next) new_status="next" ;;
      doing|inprogress|in_progress) new_status="doing" ;;
      onhold|blocked) new_status="onhold" ;;
      done) new_status="done" ;;
      archive|archived) new_status="archived" ;;
      *) new_status="" ;;
    esac
    [[ -n "${new_status:-}" ]] && perl -0777 -i -pe "s/^status:.*\$/status: ${new_status}/m;" "$meta" 2>/dev/null || true
  fi

  if [[ "$system" == "inputsys" ]]; then
    perl -0777 -i -pe "s/^processing_stage:.*\$/processing_stage: ${stage}/m;" "$meta" 2>/dev/null || true
  fi

  if [[ "$system" == "outputsys" ]]; then
    perl -0777 -i -pe "s/^(\\s*distribution_status:\\s*).*\$/\$1${stage}/m;" "$meta" 2>/dev/null || true
  fi
}

# Call sibling output script if present; else fail with instruction
handoff_to_output() {
  local blueprint_root="$1" item_query="$2"
  local output_script="${blueprint_root}/_/scripts/output.sh"
  if [[ -x "$output_script" ]]; then
    "$output_script" "$item_query"
    return 0
  fi
  echo "❌ Cannot handoff automatically: missing executable script at ${output_script}" >&2
  echo "   Fix: place output script at blueprint/_/scripts/output.sh and chmod +x it." >&2
  exit 1
}

# ---------- Main ---------------------------------------------
echo ""
echo "🚚 MOVE ITEM"
echo "============"

BLUEPRINT_ROOT="$(find_blueprint_root || true)"
if [[ -z "$BLUEPRINT_ROOT" ]]; then
  echo "❌ Error: not inside blueprint repository." >&2
  echo "   Could not find todosys, inputsys, or outputsys." >&2
  exit 1
fi
echo "📍 Blueprint root: $BLUEPRINT_ROOT"

TODOSYS="${BLUEPRINT_ROOT}/_/systems/todosys"
INPUTSYS="${BLUEPRINT_ROOT}/_/systems/inputsys"
OUTPUTSYS="${BLUEPRINT_ROOT}/_/systems/outputsys"
TODAY="$(date +%F)"

# Find the item in exactly one system
echo "🔍 Searching for: $QUERY"
found=()
p="$(find_item_in_system "$TODOSYS" "$QUERY" || true)"; [[ -n "$p" ]] && found+=("todosys::$p")
p="$(find_item_in_system "$INPUTSYS" "$QUERY" || true)"; [[ -n "$p" ]] && found+=("inputsys::$p")
p="$(find_item_in_system "$OUTPUTSYS" "$QUERY" || true)"; [[ -n "$p" ]] && found+=("outputsys::$p")

# If not found with c- prefix and it was auto-added, try without the prefix as a fallback
if [[ "${#found[@]}" -eq 0 && "$RAW_QUERY" =~ ^[0-9]+$ ]]; then
  echo "⚠️  Not found with c- prefix, trying without..."
  p="$(find_item_in_system "$TODOSYS" "$RAW_QUERY" || true)"; [[ -n "$p" ]] && found+=("todosys::$p")
  p="$(find_item_in_system "$INPUTSYS" "$RAW_QUERY" || true)"; [[ -n "$p" ]] && found+=("inputsys::$p")
  p="$(find_item_in_system "$OUTPUTSYS" "$RAW_QUERY" || true)"; [[ -n "$p" ]] && found+=("outputsys::$p")
fi

if [[ "${#found[@]}" -eq 0 ]]; then
  echo "❌ Error: item not found in any system: $QUERY" >&2
  exit 1
fi
if [[ "${#found[@]}" -gt 1 ]]; then
  echo "❌ Error: ambiguous match. Found in multiple systems:" >&2
  for x in "${found[@]}"; do
    system="${x%%::*}"
    path="${x#*::}"
    echo "   - $system: $path" >&2
  done
  echo "   Fix: ensure the item exists in only one system+stage at a time." >&2
  exit 1
fi

SYSTEM="${found[0]%%::*}"
SRC_DIR="${found[0]#*::}"
SRC_STAGE_DIR="$(dirname "$SRC_DIR")"
SRC_STAGE="$(basename "$SRC_STAGE_DIR")"
ITEM_NAME="$(basename "$SRC_DIR")"

# Map contentitems_inbox to 01_inbox stage
if [[ "$SYSTEM" == "inputsys" && "$SRC_STAGE" == "contentitems_inbox" ]]; then
  SRC_STAGE="01_inbox"
  echo "📥 Item found in CONTENTITEMS_INBOX folder (will be treated as being in 01_inbox stage)"
fi

# Special handling: If item is in 00_seeding, treat it as being in 01_inbox stage
ACTUAL_STAGE="$SRC_STAGE"
if [[ "$SYSTEM" == "inputsys" && "$SRC_STAGE" == "00_seeding" ]]; then
  ACTUAL_STAGE="01_inbox"
  echo "🌱 Item found in SEEDING folder (will be treated as being in 01_inbox stage)"
fi

echo "📍 Found: $SYSTEM/$SRC_STAGE/$ITEM_NAME"

# Build ordered stage list for this system
SYSTEM_ROOT=""
case "$SYSTEM" in
  todosys) 
    SYSTEM_ROOT="$TODOSYS"
    SYSTEM_NAME="todosys (stories)"
    ;;
  inputsys) 
    SYSTEM_ROOT="$INPUTSYS"
    SYSTEM_NAME="inputsys (content)"
    ;;
  outputsys) 
    SYSTEM_ROOT="$OUTPUTSYS"
    SYSTEM_NAME="outputsys (content)"
    ;;
  *) echo "❌ Error: unknown system: $SYSTEM" >&2; exit 1 ;;
esac

# Get the list of stages
if [[ "$SYSTEM" == "inputsys" ]]; then
  # For inputsys, stages are: 01_inbox first, then all numbered stages from the root
  mapfile -t numbered_stages < <(list_sorted_stages "$SYSTEM_ROOT")
  # Create the stages array with 01_inbox first, then the numbered stages
  stages=("01_inbox" "${numbered_stages[@]}")
else
  mapfile -t stages < <(list_sorted_stages "$SYSTEM_ROOT")
fi

if [[ "${#stages[@]}" -eq 0 ]]; then
  echo "❌ Error: no stage folders found under: $SYSTEM_ROOT" >&2
  exit 1
fi

echo "📋 Available stages: ${stages[*]}"

# Determine current index using ACTUAL_STAGE
current_idx=-1
for i in "${!stages[@]}"; do
  if [[ "${stages[$i]}" == "$ACTUAL_STAGE" ]]; then
    current_idx="$i"
    break
  fi
done

if [[ "$current_idx" -lt 0 ]]; then
  echo "❌ Error: current stage '$ACTUAL_STAGE' not found in stage list" >&2
  echo "   Available stages: ${stages[*]}" >&2
  exit 1
fi

echo "📍 Current stage: [$((current_idx+1))/${#stages[@]}] $ACTUAL_STAGE"

# Resolve destination stage
DEST_STAGE=""

if [[ "$ACTION" == "next" ]]; then
  echo "🔄 Action: move to NEXT stage"
  
  # Special law: content in inputsys/08_sharing must handoff via output.
  if [[ "$SYSTEM" == "inputsys" && "$ACTUAL_STAGE" == "08_sharing" ]]; then
    echo "⚠️  Content in 08_sharing requires handoff to outputsys."
    handoff_to_output "$BLUEPRINT_ROOT" "$QUERY"
    exit 0
  fi

  next_idx=$((current_idx + 1))
  if [[ "$next_idx" -ge "${#stages[@]}" ]]; then
    echo "✅ Already at final stage: $ACTUAL_STAGE"
    echo "   Item: $ITEM_NAME"
    exit 0
  fi
  DEST_STAGE="${stages[$next_idx]}"
  echo "   → Destination: [$((next_idx+1))/${#stages[@]}] $DEST_STAGE"

elif [[ "$ACTION" == "prev" ]]; then
  echo "🔄 Action: move to PREVIOUS stage"
  prev_idx=$((current_idx - 1))
  if [[ "$prev_idx" -lt 0 ]]; then
    echo "✅ Already at first stage: $ACTUAL_STAGE"
    echo "   Item: $ITEM_NAME"
    exit 0
  fi
  DEST_STAGE="${stages[$prev_idx]}"
  echo "   → Destination: [$((prev_idx+1))/${#stages[@]}] $DEST_STAGE"

else
  # Jump: either "NN" or "NN_name"
  echo "🔄 Action: jump to $ACTION"
  
  if [[ "$ACTION" =~ ^[0-9]{1,2}$ ]]; then
    # numeric prefix jump
    for s in "${stages[@]}"; do
      [[ "$(stage_prefix "$s")" == "$ACTION" ]] && DEST_STAGE="$s" && break
    done
    echo "   → Looking for stage number: $ACTION"
  elif [[ "$ACTION" =~ ^[0-9]{1,2}_.+ ]]; then
    for s in "${stages[@]}"; do
      [[ "$s" == "$ACTION" ]] && DEST_STAGE="$s" && break
    done
    echo "   → Looking for stage name: $ACTION"
  else
    echo "❌ Error: invalid action: $ACTION" >&2
    usage
    exit 1
  fi

  if [[ -z "$DEST_STAGE" ]]; then
    echo "❌ Error: destination stage not found for: $ACTION" >&2
    echo "   Available stages:" >&2
    for i in "${!stages[@]}"; do 
      echo "     [$((i+1))/${#stages[@]}] ${stages[$i]}" >&2
    done
    exit 1
  fi
  echo "   → Destination found: $DEST_STAGE"
fi

# No-op if same stage (jump to current)
if [[ "$DEST_STAGE" == "$ACTUAL_STAGE" ]]; then
  echo "⏭️  No-op: already in stage $ACTUAL_STAGE"
  echo "   Item: $ITEM_NAME"
  exit 0
fi

# Construct destination path based on system and stage
if [[ "$SYSTEM" == "inputsys" ]]; then
  if [[ "$DEST_STAGE" == "01_inbox" ]]; then
    # Moving back to inbox content items folder
    DEST_DIR="${INPUTSYS}/01_inbox/contentitems_inbox/${ITEM_NAME}"
  else
    # Moving to a stage folder (02_processing, etc.) - these are siblings of 01_inbox
    DEST_DIR="${INPUTSYS}/${DEST_STAGE}/${ITEM_NAME}"
  fi
else
  DEST_DIR="${SYSTEM_ROOT}/${DEST_STAGE}/${ITEM_NAME}"
fi

echo "📦 Moving item from $SRC_DIR to $DEST_DIR"
mkdir -p "$(dirname "$DEST_DIR")"

if [[ -e "$DEST_DIR" ]]; then
  echo "❌ Error: destination already exists: $DEST_DIR" >&2
  exit 1
fi

mv "$SRC_DIR" "$DEST_DIR"
echo "   ✅ Move completed"

# Init + patch
echo "🔧 Initializing destination stage..."
init_for_stage "$SYSTEM" "$DEST_STAGE" "$DEST_DIR"
patch_meta "$SYSTEM" "$DEST_STAGE" "$DEST_DIR" "$TODAY"
echo "   ✅ Stage initialization complete"
echo "   ✅ Metadata updated (last_updated: $TODAY)"

echo ""
echo "=================================================="
echo "✅ MOVE SUCCESSFUL!"
echo "=================================================="
echo "   System: $SYSTEM_NAME"
echo "   Item:   $ITEM_NAME"
echo ""
if [[ "$SYSTEM" == "inputsys" && "$SRC_STAGE" == "00_seeding" ]]; then
  echo "   From:   00_seeding/ (seeding folder inside 01_inbox/contentitems_inbox/)"
elif [[ "$SYSTEM" == "inputsys" && "$SRC_STAGE" == "01_inbox" ]]; then
  echo "   From:   01_inbox/contentitems_inbox/"
else
  echo "   From:   $SRC_STAGE/"
fi
echo "   To:     $DEST_STAGE/"
echo ""
echo "   Path:   $DEST_DIR"
echo "=================================================="
