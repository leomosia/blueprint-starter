#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# 📊 STATS - Blueprint Dashboard Generator
# ============================================================
# Generates a dashboard for:
#   - todosys  (stories: s-YYNNN_*)
#   - inputsys (content: c-YYNNN_*)
#   - outputsys (content: c-YYNNN_*)
#
# Output:
#   _/stats/dashboard.md
#   _/stats/exports/dashboard.json
#
# Optional:
#   stats.sh --snapshot   # writes _/stats/snapshots/YYYY-MM-DD.md
# ============================================================

# ---------- Parse Arguments ---------------------------------
SNAPSHOT="no"
if [[ "${1:-}" == "--snapshot" ]]; then
  SNAPSHOT="yes"
fi

# ---------- Helpers -----------------------------------------
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

is_stage_dir() {
  [[ "$1" =~ ^[0-9]+_.+ ]]
}

count_items_in_stage() {
  local stage_path="$1"
  local prefix_regex="$2"  # e.g. '^s-' or '^c-'
  [[ -d "$stage_path" ]] || { echo 0; return; }

  if [[ "$(basename "$stage_path")" == "01_inbox" && -d "${stage_path}/contentitems_inbox" ]]; then
    find "${stage_path}/contentitems_inbox" -mindepth 1 -maxdepth 2 -type d -printf '%f\n' 2>/dev/null \
      | awk -v r="$prefix_regex" '$0 ~ r { c++ } END { print c+0 }'
    return 0
  fi

  find "$stage_path" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null \
    | awk -v r="$prefix_regex" '$0 ~ r { c++ } END { print c+0 }'
}

list_stages_sorted() {
  local system_root="$1"
  [[ -d "$system_root" ]] || return 0
  find "$system_root" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null \
    | awk '$0 ~ /^[0-9]+_/ { print }' \
    | sort -t_ -k1,1n
}

sum_counts() {
  awk '{ s+=$2 } END { print s+0 }'
}

json_escape() {
  python3 - <<'PY'
import json,sys
print(json.dumps(sys.stdin.read())[1:-1])
PY
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

# ---------- Main --------------------------------------------
echo ""
echo "📊 BLUEPRINT STATISTICS"
echo "======================"

BLUEPRINT_ROOT="$(find_blueprint_root || true)"
if [[ -z "$BLUEPRINT_ROOT" ]]; then
  echo "❌ Error: not inside blueprint repository." >&2
  echo "   Could not find todosys, inputsys, or outputsys." >&2
  exit 1
fi
echo "📍 Blueprint root: $BLUEPRINT_ROOT"

TODAY="$(today)"
echo "📅 Date: $TODAY"

if [[ "$SNAPSHOT" == "y" || "$SNAPSHOT" == "yes" ]]; then
  echo "📸 Mode: SNAPSHOT (archiving to snapshots/)"
else
  echo "📊 Mode: DASHBOARD (updating main dashboard)"
fi
echo ""

TODOSYS="${BLUEPRINT_ROOT}/_/systems/todosys"
INPUTSYS="${BLUEPRINT_ROOT}/_/systems/inputsys"
OUTPUTSYS="${BLUEPRINT_ROOT}/_/systems/outputsys"

STATS_DIR="${BLUEPRINT_ROOT}/_/stats"
EXPORTS_DIR="${STATS_DIR}/exports"
SNAP_DIR="${STATS_DIR}/snapshots"
mkdir -p "$EXPORTS_DIR" "$SNAP_DIR"

echo "📁 Output directories:"
echo "   ├─ Dashboard: $STATS_DIR/"
echo "   ├─ Exports:   $EXPORTS_DIR/"
echo "   └─ Snapshots: $SNAP_DIR/"
echo ""

# ---------- Collect Stage Tables ----------------------------
echo "🔍 Scanning systems..."

collect_table() {
  local system_name="$1"
  local system_root="$2"
  local prefix_regex="$3"

  local rows=""
  while read -r stage; do
    local stage_path="${system_root}/${stage}"
    local n
    n="$(count_items_in_stage "$stage_path" "$prefix_regex")"
    rows+="${stage} ${n}"$'\n'
  done < <(list_stages_sorted "$system_root")

  # Print as "stage count" lines
  echo -n "$rows"
}

echo "   📋 todosys (stories)..."
TODOSYS_TABLE="$(collect_table "todosys" "$TODOSYS" '^s-')"
echo "   📋 inputsys (content formation)..."
INPUTSYS_TABLE="$(collect_table "inputsys" "$INPUTSYS" '^c-')"
echo "   📋 outputsys (distribution)..."
OUTPUTSYS_TABLE="$(collect_table "outputsys" "$OUTPUTSYS" '^c-')"

TODOSYS_TOTAL="$(echo "$TODOSYS_TABLE" | sum_counts)"
INPUTSYS_TOTAL="$(echo "$INPUTSYS_TABLE" | sum_counts)"
OUTPUTSYS_TOTAL="$(echo "$OUTPUTSYS_TABLE" | sum_counts)"

# ---------- Render Markdown Dashboard -----------------------
render_md_table() {
  local title="$1"
  local table="$2"
  local total="$3"

  echo "## ${title}"
  echo
  echo "| Stage | Count |"
  echo "|---|---:|"
  if [[ -n "${table// }" ]]; then
    while read -r stage count; do
      [[ -z "${stage:-}" ]] && continue
      echo "| \`${stage}\` | ${count} |"
    done <<< "$table"
  else
    echo "| *No items* | 0 |"
  fi
  echo "| **Total** | **${total}** |"
  echo
}

DASH_MD="${STATS_DIR}/dashboard.md"
echo ""
echo "✍️  Generating dashboard..."

{
  echo "# 📊 Blueprint Dashboard"
  echo ""
  echo "_Generated: ${TODAY}_"
  echo ""
  echo "## 📈 Summary Totals"
  echo ""
  echo "| System | Total Items |"
  echo "|---|---:|"
  echo "| Stories (todosys) | **${TODOSYS_TOTAL}** |"
  echo "| Content in formation (inputsys) | **${INPUTSYS_TOTAL}** |"
  echo "| Content in distribution (outputsys) | **${OUTPUTSYS_TOTAL}** |"
  echo "| **GRAND TOTAL** | **$((TODOSYS_TOTAL + INPUTSYS_TOTAL + OUTPUTSYS_TOTAL))** |"
  echo ""
  render_md_table "📋 todosys — Stories by Stage" "$TODOSYS_TABLE" "$TODOSYS_TOTAL"
  render_md_table "📝 inputsys — Content Formation by Stage" "$INPUTSYS_TABLE" "$INPUTSYS_TOTAL"
  render_md_table "📤 outputsys — Distribution Pipeline by Stage" "$OUTPUTSYS_TABLE" "$OUTPUTSYS_TOTAL"
} > "$DASH_MD"

echo "   ✅ Markdown dashboard: $DASH_MD"

# ---------- Render JSON Export ------------------------------
echo "   🔄 Generating JSON export..."
JSON_OUT="${EXPORTS_DIR}/dashboard.json"
python3 - <<PY
import json
data = {
  "generated": "${TODAY}",
  "totals": {
    "todosys": int("${TODOSYS_TOTAL}"),
    "inputsys": int("${INPUTSYS_TOTAL}"),
    "outputsys": int("${OUTPUTSYS_TOTAL}")
  },
  "stages": {
    "todosys": [{"stage": s.split()[0], "count": int(s.split()[1])} for s in """${TODOSYS_TABLE}""".strip().splitlines() if s.strip()],
    "inputsys": [{"stage": s.split()[0], "count": int(s.split()[1])} for s in """${INPUTSYS_TABLE}""".strip().splitlines() if s.strip()],
    "outputsys": [{"stage": s.split()[0], "count": int(s.split()[1])} for s in """${OUTPUTSYS_TABLE}""".strip().splitlines() if s.strip()],
  }
}
with open("${JSON_OUT}", "w", encoding="utf-8") as f:
  json.dump(data, f, indent=2)
PY
echo "   ✅ JSON export: $JSON_OUT"

# ---------- Snapshot (Optional) -----------------------------
if [[ "$SNAPSHOT" == "y" || "$SNAPSHOT" == "yes" ]]; then
  echo "   📸 Creating snapshot..."
  cp "$DASH_MD" "${SNAP_DIR}/${TODAY}.md"
  echo "   ✅ Snapshot saved: ${SNAP_DIR}/${TODAY}.md"
fi

# ---------- Summary Output ----------------------------------
echo ""
echo "=================================================="
echo "✅ DASHBOARD GENERATED SUCCESSFULLY!"
echo "=================================================="
echo ""
echo "📊 SUMMARY STATISTICS"
echo "---------------------"
echo "   📋 Stories (todosys):       $TODOSYS_TOTAL"
echo "   📝 Content formation (inputsys):  $INPUTSYS_TOTAL"
echo "   📤 Distribution (outputsys): $OUTPUTSYS_TOTAL"
echo "   🔢 GRAND TOTAL:              $((TODOSYS_TOTAL + INPUTSYS_TOTAL + OUTPUTSYS_TOTAL))"
echo ""
echo "📁 OUTPUT FILES"
echo "--------------"
echo "   📄 Dashboard:    $DASH_MD"
echo "   📄 JSON export:  $JSON_OUT"
if [[ "$SNAPSHOT" == "y" || "$SNAPSHOT" == "yes" ]]; then
  echo "   📸 Snapshot:     ${SNAP_DIR}/${TODAY}.md"
fi
echo ""
echo "🔄 NEXT STEPS"
echo "------------"
echo "   • View the dashboard: cat $DASH_MD"
echo "   • Open in editor:     code $DASH_MD"
echo "   • Track history:      stats.sh --snapshot (daily)"
echo "=================================================="

# Optional: Show quick preview
if command -v head &> /dev/null; then
  echo ""
  echo "📋 PREVIEW (first 10 lines)"
  echo "-------------------------"
  head -10 "$DASH_MD"
  echo "..."
fi
