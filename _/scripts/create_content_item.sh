#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# create_content_item
# Creates a new content_item folder with ID c-YYNNN and slug name.
# ID allocation scans all stages in inputsys and outputsys
# to avoid collisions across the entire blueprint lifecycle.
# Birth stage is _/systems/inputsys/01_inbox/contentitems_inbox.
# ============================================================

PREFIX="c"
COUNTER_WIDTH="3"   # locked: 001..999

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
      echo "Error: BLUEPRINT_DATE must use YYYY-MM-DD format." >&2
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
      echo "Error: BLUEPRINT_DATE must use YYYY-MM-DD format." >&2
      exit 1
    fi
    echo "$BLUEPRINT_DATE"
  else
    date +%F
  fi
}

find_blueprint_root() {
  # Walk up from PWD until we find a directory containing inputsys.
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

pad_counter() {
  local n="$1"
  local width="$2"
  printf "%0*d" "$width" "$n"
}

next_counter() {
  local blueprint_root="$1"
  local yy="$2"
  local width="$3"
  
  local max=0
  local current

  # Scan all stages in inputsys.
  if [[ -d "${blueprint_root}/_/systems/inputsys" ]]; then
    while IFS= read -r current; do
      if [[ -n "$current" ]]; then
        # Remove leading zeros to avoid octal interpretation
        current="${current#"${current%%[!0]*}"}"
        # If empty after removing zeros, it was all zeros (value 0)
        current="${current:-0}"
        if [[ "$current" -gt "$max" ]]; then
          max="$current"
        fi
      fi
    done < <(
      find "${blueprint_root}/_/systems/inputsys" -type d -name "${PREFIX}-${yy}[0-9]*" -printf '%f\n' 2>/dev/null \
        | sed -nE "s/^${PREFIX}-${yy}([0-9]{${width}})_.*/\1/p"
    )
  fi

  # Scan all stages in outputsys.
  if [[ -d "${blueprint_root}/_/systems/outputsys" ]]; then
    while IFS= read -r current; do
      if [[ -n "$current" ]]; then
        # Remove leading zeros to avoid octal interpretation
        current="${current#"${current%%[!0]*}"}"
        # If empty after removing zeros, it was all zeros (value 0)
        current="${current:-0}"
        if [[ "$current" -gt "$max" ]]; then
          max="$current"
        fi
      fi
    done < <(
      find "${blueprint_root}/_/systems/outputsys" -type d -name "${PREFIX}-${yy}[0-9]*" -printf '%f\n' 2>/dev/null \
        | sed -nE "s/^${PREFIX}-${yy}([0-9]{${width}})_.*/\1/p"
    )
  fi

  if [[ "$max" -eq 0 ]]; then
    echo 1
  else
    echo $((max + 1))
  fi
}

write_meta() {
  local meta_path="$1"

  cat > "$meta_path" <<'EOF'
# Content Item — Metadata

## 1. Identity & Lineage
content_id:
fieldnote_id:
title:
subtitle:      
slug:   

status:   
inputsys_stage:    
outputsys_stage:   

domain:    
layer:     
content_type:     
content_subtype:     

topic:      
subtopics:      

tags:      
keywords:    

series:     

language:     
original_language:      
translation_of:     

author:      
contributors: []    

parent_item:       
child_items: []    

ownership:      

## 2. Intent & Meaning
intent:    
core_thesis:    
key_questions: []     

audience:   
reader_state:    
outcome:    

values_embedded: []    


## 3. Content Characteristics
tone:    
style:    
voice:    
stance:     

depth_level: surface | mid | deep | canonical    
complexity: low | medium | high    
timelessness: evergreen | semi-evergreen | time-bound     


## 4. Structural Metadata
structure:    
  format: text | audio | video | mixed      
  length:   
  sections: []    
  assets: []    
  references: []    
  assumptions: []     
  dependencies: []     
 

## 5. Lifecycle & State
status: idea | draft | refined | final | archived      
revision: v0.1    
confidence_level: tentative | tested | hardened     

created_at:
last_updated:
review_cycle: none | quarterly | annual     
expiry_logic: never | review-by-date | context-bound     
 

## 6. System & Workflow
origin:     
input_type: raw | processed | synthesized     
processing_stage: inbox | processed | analyzed | transformed     

linked_notes: []     
related_frameworks: []    
decision_relevance: reference | guiding | operational      
automation_ready: yes | no     


## 7. Distribution & Exposure
distribution:    
  primary_channel:     
  secondary_channels: []    
  distribution_status: unpublished | scheduled | live | retired    
  publish_date:     
  cta:     
  repurposable: yes | no    
  derivative_formats: []     


## 8. Feedback & Performance
performance:   
  qualitative_feedback: []     
  engagement_signals: []     
  insight_yield:    
  downstream_impact: []    
  follow_up_items: []    


## 9. Governance & Risk
governance:     
  sensitivity: public | private | restricted     
  legal_risk: none | low | medium | high    
  reputation_risk: none | low | medium | high     
  misinterpretation_risk: low | medium | high     
  context_required: yes | no    
  do_not_detach_from: []   


## 10. Archival & Memory    
canonical: yes | no     
superseded_by:    
historical_value: low | medium | high    
reason_to_keep:    
archive_location:    
future_review_note:    

EOF
}

inject_meta_fields() {
  local meta_path="$1"
  local content_id="$2"
  local title="$3"
  local slug="$4"
  local today="$5"

  # Use perl for robust in-place edits
  perl -0777 -i -pe \
    "s/^content_id:\\s*\$/content_id: ${content_id}/m;
     s/^title:\\s*\$/title: ${title}/m;
     s/^slug:\\s*\$/slug: ${slug}/m;
     s/^created_at:\\s*\$/created_at: ${today}/m;
     s/^last_updated:\\s*\$/last_updated: ${today}/m;" \
    "$meta_path"
}

# ---------- main ---------------------------------------------
BLUEPRINT_ROOT="$(find_blueprint_root || true)"
if [[ -z "$BLUEPRINT_ROOT" ]]; then
  echo "Error: could not locate blueprint root. Run this from inside your blueprint repo (needs _/systems/inputsys)." >&2
  exit 1
fi

INPUTSYS_ROOT="${BLUEPRINT_ROOT}/_/systems/inputsys"
OUTPUTSYS_ROOT="${BLUEPRINT_ROOT}/_/systems/outputsys"
BIRTH_STAGE="${INPUTSYS_ROOT}/01_inbox/contentitems_inbox"

if [[ ! -d "$INPUTSYS_ROOT" ]]; then
  echo "Error: inputsys not found at: $INPUTSYS_ROOT" >&2
  exit 1
fi

mkdir -p "$BIRTH_STAGE"

read -r -p "Content name: " CONTENT_NAME
if [[ -z "${CONTENT_NAME// }" ]]; then
  echo "Error: content name cannot be empty." >&2
  exit 1
fi

SLUG="$(slugify "$CONTENT_NAME")"
YY="$(year_suffix)"

# Scan ALL stages in both systems for existing IDs
echo "🔍 Scanning all stages in inputsys and outputsys for existing IDs..."
N="$(next_counter "$BLUEPRINT_ROOT" "$YY" "$COUNTER_WIDTH")"
NNN="$(pad_counter "$N" "$COUNTER_WIDTH")"

CONTENT_ID="${PREFIX}-${YY}${NNN}"
FOLDER_NAME="${CONTENT_ID}_${SLUG}"
TARGET_DIR="${BIRTH_STAGE}/${FOLDER_NAME}"

if [[ -e "$TARGET_DIR" ]]; then
  echo "Error: target already exists: $TARGET_DIR" >&2
  exit 1
fi

echo ""
echo "📁 Creating new content item: ${CONTENT_NAME}"
echo "========================================"
echo "  ID:       ${CONTENT_ID}"
echo "  Slug:     ${SLUG}"
echo "  Location: ${TARGET_DIR}"
echo "========================================"

mkdir -p "$TARGET_DIR"/{assets,notes,derivatives,archive}

# Add .gitkeep to assets, derivatives, archive
for dir in assets derivatives archive; do
    touch "$TARGET_DIR/$dir/.gitkeep"
done
echo "✅ Created folders: assets, derivatives, archive (with .gitkeep)"

# Prompt for notes.md
echo ""
echo "📝 Notes setup:"
read -p "Do you want to add an entry note? (yes/no): " add_note

if [[ "$add_note" == "y" || "$add_note" == "yes" ]]; then
    echo "✏️  Enter your note text (press Ctrl+D when finished):"
    cat > "$TARGET_DIR/notes/notes.md"
    echo "✅ notes.md created with your entry."
else
    echo "⏭️  Skipping entry note."
    
    echo ""
    read -p "Do you want to move an existing markdown file to notes/? (yes/no): " move_file

    if [[ "$move_file" == "y" || "$move_file" == "yes" ]]; then
        echo ""
        read -p "🔍 Enter the filename to search for (e.g., testing.md): " filename
        
        if [[ -n "$filename" ]]; then
            echo "Searching for '$filename'..."
            found_file=$(find . -type f -name "$filename" 2>/dev/null | head -1)
            
            if [[ -n "$found_file" ]]; then
                mv "$found_file" "$TARGET_DIR/notes/"
                echo "✅ Moved: $found_file"
                echo "   → to: $TARGET_DIR/notes/"
            else
                echo "❌ File '$filename' not found."
                echo "📌 Creating .gitkeep in notes folder instead."
                touch "$TARGET_DIR/notes/.gitkeep"
            fi
        else
            echo "❌ No filename entered."
            echo "📌 Creating .gitkeep in notes folder instead."
            touch "$TARGET_DIR/notes/.gitkeep"
        fi
    else
        echo "⏭️  No file will be moved."
        echo "📌 Creating .gitkeep in notes folder instead."
        touch "$TARGET_DIR/notes/.gitkeep"
    fi
fi

# meta.md
echo ""
echo "📄 Creating metadata file..."
META_PATH="${TARGET_DIR}/meta.md"
write_meta "$META_PATH"

TODAY="$(today)"
inject_meta_fields "$META_PATH" "$CONTENT_ID" "$CONTENT_NAME" "$SLUG" "$TODAY"
echo "✅ meta.md created"

# Create draft.md, final.md and seed.md
echo ""
echo "📄 Creating placeholder files..."
cat > "${TARGET_DIR}/draft.md" <<'EOF'
<!-- RAW DRAFT — NO STRUCTURE ON PURPOSE -->
EOF
echo "✅ draft.md created"

cat > "${TARGET_DIR}/final.md" <<'EOF'
<!-- FINAL CONTENT GOES HERE -->
EOF
echo "✅ final.md created"

cat > "${TARGET_DIR}/seed.md" <<'EOF'
<!-- SEED CONTENT GOES HERE -->
EOF
echo "✅ seed.md created"

echo ""
echo "========================================"
echo "✅ Content item created successfully!"
echo "========================================"
echo "  ID:     ${CONTENT_ID}"
echo "  Folder: ${TARGET_DIR}"
echo ""
echo "📂 Structure:"
echo "  ├── assets/     (with .gitkeep)"
echo "  ├── notes/      $(if [[ -f "$TARGET_DIR/notes/notes.md" ]]; then echo "(with notes.md)"; elif [[ -f "$TARGET_DIR/notes/.gitkeep" ]]; then echo "(with .gitkeep)"; fi)"
echo "  ├── derivatives/(with .gitkeep)"
echo "  ├── archive/    (with .gitkeep)"
echo "  ├── meta.md"
echo "  ├── draft.md"
echo "  ├── seed.md"
echo "  └── final.md"
echo "========================================"
echo ""
echo "🌱 Next step: Use 'seed.sh ${CONTENT_ID}' to move to seeding folder"
echo "   or 'move.sh ${CONTENT_ID} next' to start processing"
echo "========================================"
