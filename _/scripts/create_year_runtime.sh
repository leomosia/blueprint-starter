#!/bin/bash
#
# Script: create_year_runtime.sh
# Purpose: Create a YEAR runtime skeleton in the CURRENT directory (pwd),
#          assuming you are standing inside a decade folder like: 01_founding_decade/
#
# Stack:
# Decade → Year → Season → Lunar Cycle → Lunar Phase (Week Folder) → Day Files
#
# Creates:
# - decade_L5.md (in current dir, once)
# - <YEAR>/year_L5.md
# - <YEAR>/<season>/season_L5.md
# - <YEAR>/<season>/lunar_cycle_N/lunar_cycle_L5.md
# - <YEAR>/<season>/lunar_cycle_N/<phase>/phase_L5.md
# - <YEAR>/<season>/lunar_cycle_N/<phase>/day_1..day_7.md
#
# Usage:
#   create_year_runtime.sh 2026
#   create_year_runtime.sh 2026 3   # cycles per season (default 3)
#
# Tip: Put script on PATH:
# export PATH="/path/to/blueprint/_/scripts:$PATH"

set -e

# ============================================================
# 📅 YEAR RUNTIME CREATOR
# ============================================================

TARGET_DIR="$(pwd)"
YEAR="${1:-}"
CYCLES_PER_SEASON="${2:-3}"

# ---------- Validation ----------------------------------------
echo ""
echo "📅 YEAR RUNTIME CREATOR"
echo "======================="
echo "📍 Current directory: $TARGET_DIR"

if [ -z "$YEAR" ]; then
  echo "❌ Error: Year is required." >&2
  echo "   Usage: $(basename "$0") <year> [cycles_per_season]" >&2
  exit 1
fi

# Validate year
if ! echo "$YEAR" | grep -Eq '^[0-9]{4}$'; then
  echo "❌ Error: year must be a 4-digit number (e.g. 2026). Got: $YEAR" >&2
  exit 1
fi

# Validate cycles
if ! echo "$CYCLES_PER_SEASON" | grep -Eq '^[0-9]+$' || [ "$CYCLES_PER_SEASON" -lt 1 ]; then
  echo "❌ Error: cycles_per_season must be a positive integer. Got: $CYCLES_PER_SEASON" >&2
  exit 1
fi

DECADE_BASENAME="$(basename "$TARGET_DIR")"
# "01_founding_decade" -> "founding decade"
DECADE_LABEL="$(echo "$DECADE_BASENAME" | sed -E 's/^[0-9]+_//' | tr '_' ' ')"

echo ""
echo "📋 CONFIGURATION"
echo "----------------"
echo "   Year:              $YEAR"
echo "   Decade:            $DECADE_LABEL"
echo "   Lunar cycles/season: $CYCLES_PER_SEASON"
echo "   Total cycles:      $((4 * CYCLES_PER_SEASON))"
echo "   Total phases:      $((4 * CYCLES_PER_SEASON * 4))"
echo "   Total days:        $((4 * CYCLES_PER_SEASON * 4 * 7))"
echo ""
read -p "⚠️  This will create a large folder structure. Continue? (yes/no): " confirm

if [[ ! "$confirm" =~ ^(yes|y)$ ]]; then
    echo "❌ Cancelled."
    exit 0
fi

SEASONS=(01_spring 02_summer 03_autumn 04_winter)
PHASES=(01_new_moon 02_first_quarter 03_full_moon 04_last_quarter)

# --- Helpers ---
ensure_file() {
  # $1 path, $2 content
  local path="$1"
  local content="$2"
  if [ ! -f "$path" ]; then
    printf "%s" "$content" > "$path"
    echo "   ✅ Created: $(basename "$path")"
  else
    echo "   ⏭️  Skipped: $(basename "$path") (already exists)"
  fi
}

phase_to_label() {
  # Strip numeric prefix like "02_" and convert underscores to spaces.
  echo "$1" | sed -E 's/^[0-9]+_//' | tr '_' ' '
}

season_to_label() {
  # Strip numeric prefix like "01_" and convert underscores to spaces.
  echo "$1" | sed -E 's/^[0-9]+_//' | tr '_' ' '
}

l5_block() {
  cat <<'EOF'

## Define

**Intent:**

-

## Plan

**Top 1–3:**

- [ ] 
- [ ] 
- [ ] 

## Execute

**Move made:**

-

## Review

**Lesson:**

-

## Sustain

**Recovery action:**

-

EOF
}

decade_l5() {
  cat <<EOF
**Decade:** $DECADE_LABEL$(l5_block)    
EOF
}

year_l5() {
  cat <<EOF
**Year:** $YEAR    
**Decade:** $DECADE_LABEL$(l5_block)     
EOF
}

season_l5() {
  local season_raw="$1"
  local season_label="$(season_to_label "$season_raw")"
  cat <<EOF
**Season:** $season_label    
**Year:** $YEAR    
**Decade:** $DECADE_LABEL$(l5_block)     
EOF
}

lunar_cycle_l5() {
  local cycle_num="$1"
  local season_raw="$2"
  local season_label="$(season_to_label "$season_raw")"
  cat <<EOF
**Lunar Cycle:** lunar cycle $cycle_num    
**Season:** $season_label    
**Year:** $YEAR    
**Decade:** $DECADE_LABEL$(l5_block)    
EOF
}

phase_l5() {
  local phase_label="$1"
  local cycle_label="$2"
  local season_raw="$3"
  local season_label="$(season_to_label "$season_raw")"
  cat <<EOF
**Lunar Phase:** $phase_label   
**Lunar Cycle:** $cycle_label    
**Season:** $season_label    
**Year:** $YEAR   
**Decade:** $DECADE_LABEL$(l5_block)   
EOF
}

day_md() {
  local day_num="$1"
  local phase_label="$2"
  local cycle_label="$3"
  local season_raw="$4"
  local season_label="$(season_to_label "$season_raw")"
  cat <<EOF
**Day Type:** day $day_num  
**Lunar Phase:** $phase_label   
**Lunar Cycle:** $cycle_label    
**Season:** $season_label    
**Year:** $YEAR    
**Decade:** $DECADE_LABEL$(l5_block)  
EOF
}

# ---------- Creation Process ---------------------------------
echo ""
echo "🔨 CREATING STRUCTURE"
echo "---------------------"

# --- Create decade L5 once ---
echo "📁 Decade level:"
ensure_file "$TARGET_DIR/decade_L5.md" "$(decade_l5)"

# --- Create year skeleton ---
echo ""
echo "📁 Year level ($YEAR):"
YEAR_PATH="$TARGET_DIR/$YEAR"
mkdir -p "$YEAR_PATH"
echo "   ✅ Created folder: $YEAR/"
ensure_file "$YEAR_PATH/year_L5.md" "$(year_l5)"

GLOBAL_CYCLE=1  # keep lunar_cycle numbering continuous across seasons
SEASON_COUNT=0

for season in "${SEASONS[@]}"; do
  SEASON_COUNT=$((SEASON_COUNT + 1))
  echo ""
  echo "📁 Season $SEASON_COUNT/4: $season"
  
  SEASON_PATH="$YEAR_PATH/$season"
  mkdir -p "$SEASON_PATH"
  echo "   ✅ Created folder: $season/"
  ensure_file "$SEASON_PATH/season_L5.md" "$(season_l5 "$season")"

  for cycle_in_season in $(seq 1 "$CYCLES_PER_SEASON"); do
    CYCLE_DIR="lunar_cycle_$GLOBAL_CYCLE"
    CYCLE_PATH="$SEASON_PATH/$CYCLE_DIR"
    mkdir -p "$CYCLE_PATH"
    echo "   📁 Cycle $GLOBAL_CYCLE/$((4 * CYCLES_PER_SEASON)): $CYCLE_DIR/"

    CYCLE_LABEL="lunar cycle $GLOBAL_CYCLE"
    ensure_file "$CYCLE_PATH/lunar_cycle_L5.md" "$(lunar_cycle_l5 "$GLOBAL_CYCLE" "$season")"

    PHASE_COUNT=0
    for phase in "${PHASES[@]}"; do
      PHASE_COUNT=$((PHASE_COUNT + 1))
      PHASE_PATH="$CYCLE_PATH/$phase"
      mkdir -p "$PHASE_PATH"
      echo "      📁 Phase $PHASE_COUNT/4: $(basename "$phase")/"

      PHASE_LABEL="$(phase_to_label "$phase")"
      ensure_file "$PHASE_PATH/phase_L5.md" "$(phase_l5 "$PHASE_LABEL" "$CYCLE_LABEL" "$season")"

      # days (7)
      for d in 1 2 3 4 5 6 7; do
        ensure_file "$PHASE_PATH/day_$d.md" "$(day_md "$d" "$PHASE_LABEL" "$CYCLE_LABEL" "$season")"
      done
      echo "         ✅ Days 1-7 created"
    done
    GLOBAL_CYCLE=$((GLOBAL_CYCLE + 1))
  done
done

# ---------- Summary ------------------------------------------
echo ""
echo "=================================================="
echo "✅ YEAR RUNTIME CREATED SUCCESSFULLY!"
echo "=================================================="
echo ""
echo "📋 Summary:"
echo "   Year:              $YEAR"
echo "   Decade:            $DECADE_LABEL"
echo "   Seasons:           4 (01_spring, 02_summer, 03_autumn, 04_winter)"
echo "   Cycles/season:     $CYCLES_PER_SEASON"
echo "   Total cycles:      $((4 * CYCLES_PER_SEASON))"
echo "   Total phases:      $((4 * CYCLES_PER_SEASON * 4))"
echo "   Total day files:   $((4 * CYCLES_PER_SEASON * 4 * 7))"
echo ""
echo "📂 Root location:"
echo "   $TARGET_DIR"
echo ""
echo "📂 Structure created:"
echo "   $DECADE_BASENAME/"
echo "   ├── decade_L5.md"
echo "   └── $YEAR/"
echo "       ├── year_L5.md"
echo "       ├── 01_spring/"
echo "       │   ├── season_L5.md"
echo "       │   └── lunar_cycle_1..$CYCLES_PER_SEASON/"
echo "       │       ├── lunar_cycle_L5.md"
echo "       │       ├── 01_new_moon/"
echo "       │       │   ├── phase_L5.md"
echo "       │       │   └── day_1..7.md"
echo "       │       ├── 02_first_quarter/"
echo "       │       ├── 03_full_moon/"
echo "       │       └── 04_last_quarter/"
echo "       ├── 02_summer/"
echo "       ├── 03_autumn/"
echo "       └── 04_winter/"
echo ""
echo "🔄 Next steps:"
echo "   1. Navigate to $YEAR/"
echo "   2. Start filling in L5 files with your intentions"
echo "   3. Use day files for daily logging"
echo "=================================================="

# Optional: Show tree if available
if command -v tree &> /dev/null; then
  echo ""
  echo "🌳 Quick preview (first 3 levels):"
  tree -L 3 "$YEAR_PATH" | head -20
fi
