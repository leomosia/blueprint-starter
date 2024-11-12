#!/bin/bash

# Script: create_L5.sh
# Purpose: Create L5 folder structure in the CURRENT directory

set -e

TARGET_DIR="$(pwd)"

echo "📁 L5 Folder Structure Creator"
echo "==============================="
echo "Target: $TARGET_DIR"
echo ""





# Confirm with user
read -p "Continue? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Cancelled."
    exit 0
fi

echo ""
echo "🔨 Creating folders..."

# Helper function
create_dir_with_gitkeep() {
    mkdir -p "$1"
    if [ ! -f "$1/.gitkeep" ]; then
        touch "$1/.gitkeep"
        echo "  ✅ $1"
    fi
}

# Create structure
echo ""
echo "📋 Define hierarchy:"
create_dir_with_gitkeep "define/01_vision"
create_dir_with_gitkeep "define/02_focus_areas"
create_dir_with_gitkeep "define/03_intentions"
create_dir_with_gitkeep "define/04_objectives"
create_dir_with_gitkeep "define/05_projects"

echo ""
echo "📋 Core folders:"
create_dir_with_gitkeep "plan"
create_dir_with_gitkeep "execute"
create_dir_with_gitkeep "review"
create_dir_with_gitkeep "sustain"

echo ""
echo "✅ Done! L5 structure created at:"
echo "   $TARGET_DIR"
