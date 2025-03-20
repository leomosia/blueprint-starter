#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# 📋 CREATE STORY
# Creates a new story folder with ID s-YYNN and slug name.
# ID allocation scans all _/systems/todosys stages to avoid collisions.
# Birth stage is _/systems/todosys/00_backlog.
# ============================================================

PREFIX="s"
COUNTER_WIDTH="2"   # locked: 01..99 per year

# ---------- helpers ------------------------------------------
slugify() {
  # lower, replace non-alnum with '-', collapse '-', trim '-'
  echo "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-+/-/g'
}

year_suffix() {
  if [[ -n "${BLUEPRINT_DATE:-}" ]]; then
    if [[ ! "$BLUEPRINT_DATE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
      echo "❌ Error: BLUEPRINT_DATE must use YYYY-MM-DD format." >&2
      exit 1
    fi
    echo "${BLUEPRINT_DATE:2:2}"
  else
    date +%y
  fi
}

today() {
  if [[ -n "${BLUEPRINT_DATE:-}" ]]; then
    if [[ ! "$BLUEPRINT_DATE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
      echo "❌ Error: BLUEPRINT_DATE must use YYYY-MM-DD format." >&2
      exit 1
    fi
    echo "$BLUEPRINT_DATE"
  else
    date +%F
  fi
}

find_blueprint_root() {
  # Walk up from PWD until we find a directory containing todosys.
  local dir="$PWD"
  while [[ "$dir" != "/" ]]; do
    if [[ -d "$dir/_/systems/todosys" ]]; then
      echo "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  return 1
}

pad_counter() {
  local n="$1"
  local width="$2"
  printf "%0*d" "$width" "$n"
}

next_counter() {
  local todosys_root="$1"
  local yy="$2"
  local width="$3"

  # Scan all stage directories under todosys for existing s-YYNN_* folders.
  # Stories are directly under each stage: todosys/<stage>/<story_folder>
  local max
  max=$(
    find "$todosys_root" -mindepth 2 -maxdepth 2 -type d -printf '%f\n' 2>/dev/null \
      | sed -nE "s/^${PREFIX}-${yy}([0-9]{${width}})_.*/\1/p" \
      | sort -n \
      | tail -n 1
  )

  if [[ -z "${max:-}" ]]; then
    echo 1
  else
    echo $((10#$max + 1))
  fi
}

write_meta() {
  local meta_path="$1"

  cat > "$meta_path" <<'EOF'
# Story — Metadata

## Identity
story_id:
title:
slug:

project:    
epic:    
owner:   

## Intent
problem:   
desired_outcome:    
customer:     

## Scope
in_scope: []     
out_of_scope: []     

## Acceptance
acceptance_criteria: []    
definition_of_done: []    

## Execution
status: backlog | next | doing | onhold | done | archived     
priority: P0 | P1 | P2 | P3     
estimate:     

planned_start:     
planned_end:      
actual_start:     
actual_end:     

created_at:
last_updated:

## Dependencies
dependencies: []     
blockers: []     

## Evidence
proof_of_done: []     
outputs: []   # e.g. content ids c-YYNNN, PR links, file paths

## Risk
risk_level: low | medium | high     
rollback_plan:      
notes_for_future:    

## Retro (fill when done)    
what_worked:   
what_failed:   
lesson:   
follow_ups: []    

EOF
}

inject_meta_fields() {
  local meta_path="$1"
  local story_id="$2"
  local title="$3"
  local slug="$4"
  local today="$5"

  perl -0777 -i -pe \
    "s/^story_id:\\s*\$/story_id: ${story_id}/m;
     s/^title:\\s*\$/title: ${title}/m;
     s/^slug:\\s*\$/slug: ${slug}/m;
     s/^created_at:\\s*\$/created_at: ${today}/m;
     s/^last_updated:\\s*\$/last_updated: ${today}/m;" \
    "$meta_path"
}

# ---------- main ---------------------------------------------
echo ""
echo "📋 STORY CREATOR"
echo "================"

BLUEPRINT_ROOT="$(find_blueprint_root || true)"
if [[ -z "$BLUEPRINT_ROOT" ]]; then
  echo "❌ Error: could not locate blueprint root." >&2
  echo "   Run this from inside your blueprint repo (needs _/systems/todosys)." >&2
  exit 1
fi
echo "📍 Blueprint root: $BLUEPRINT_ROOT"

TODOSYS_ROOT="${BLUEPRINT_ROOT}/_/systems/todosys"
BIRTH_STAGE="${TODOSYS_ROOT}/00_backlog"

if [[ ! -d "$TODOSYS_ROOT" ]]; then
  echo "❌ Error: todosys not found at: $TODOSYS_ROOT" >&2
  exit 1
fi

mkdir -p "$BIRTH_STAGE"
echo "📁 Birth stage: 00_backlog"

echo ""
echo "📝 STORY DETAILS"
echo "----------------"

read -r -p "Story name: " STORY_NAME
if [[ -z "${STORY_NAME// }" ]]; then
  echo "❌ Error: story name cannot be empty." >&2
  exit 1
fi

SLUG="$(slugify "$STORY_NAME")"
YY="$(year_suffix)"

echo "🔍 Generating unique story ID..."
N="$(next_counter "$TODOSYS_ROOT" "$YY" "$COUNTER_WIDTH")"
NNN="$(pad_counter "$N" "$COUNTER_WIDTH")"

STORY_ID="${PREFIX}-${YY}${NNN}"
FOLDER_NAME="${STORY_ID}_${SLUG}"
TARGET_DIR="${BIRTH_STAGE}/${FOLDER_NAME}"

if [[ -e "$TARGET_DIR" ]]; then
  echo "❌ Error: target already exists: $TARGET_DIR" >&2
  exit 1
fi

echo ""
echo "📁 CREATING STORY STRUCTURE"
echo "---------------------------"

mkdir -p "$TARGET_DIR"/{assets,archive}
echo "✅ Created main folders:"
echo "   ├── assets/"
echo "   └── archive/"

# Add .gitkeep to all directories
for dir in assets archive; do
    touch "$TARGET_DIR/$dir/.gitkeep"
    echo "   📌 Added .gitkeep to $dir/"
done

# meta.md
echo ""
echo "📄 Creating metadata file..."
META_PATH="${TARGET_DIR}/meta.md"
write_meta "$META_PATH"
echo "   ✅ meta.md (with template)"

TODAY="$(today)"
inject_meta_fields "$META_PATH" "$STORY_ID" "$STORY_NAME" "$SLUG" "$TODAY"
echo "   ✅ meta fields injected (ID, title, slug, dates)"

# log.md (execution log)
echo ""
echo "📄 Creating documentation files..."
cat > "${TARGET_DIR}/log.md" <<'EOF'
# Execution Log

## Entry — YYYY-MM-DD
- Move made:
- Notes:
- Blockers:
EOF
echo "   ✅ log.md (execution log template)"

# details.md (story context and details)
cat > "${TARGET_DIR}/details.md" <<'EOF'
# Story Details

## Background & Context
<!-- What led to this story? What's the bigger picture? -->

## Key Insights & Research
<!-- What do we know? What have we learned? -->

## Open Questions
<!-- What still needs to be figured out? -->

## Notes & References
<!-- Links, references, raw thoughts -->

EOF
echo "   ✅ details.md (story context and details)"

echo ""
echo "=================================================="
echo "✅ STORY CREATED SUCCESSFULLY!"
echo "=================================================="
echo ""
echo "📋 Story Summary:"
echo "   ID:     ${STORY_ID}"
echo "   Name:   ${STORY_NAME}"
echo "   Slug:   ${SLUG}"
echo "   Path:   ${TARGET_DIR}"
echo ""
echo "📂 Folder Structure:"
echo "   ${FOLDER_NAME}/"
echo "   ├── assets/     (with .gitkeep)"
echo "   ├── archive/    (with .gitkeep)"
echo "   ├── meta.md     (story metadata)"
echo "   ├── log.md      (execution log)"
echo "   └── details.md  (story context & details)"
echo ""
echo "📍 Location:"
echo "   ${BIRTH_STAGE}/"
echo ""
echo "🔄 Next steps:"
echo "   1. Edit meta.md to fill in story details"
echo "   2. Add context and background to details.md"
echo "   3. Move to appropriate stage when ready"
echo "=================================================="
