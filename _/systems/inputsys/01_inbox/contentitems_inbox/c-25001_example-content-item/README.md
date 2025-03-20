# Example Content Item

This folder was created by running:

```bash
printf 'Example Content Item\nyes\nThis is a public example note created to show how create_content_item.sh generates a content item folder.\n' | BLUEPRINT_DATE=2025-03-20 _/scripts/create_content_item.sh
```

The script created the content item ID `c-25001` from the date override and the next available counter for 2025.

## What the Script Created

- `meta.md` stores identity, lifecycle, distribution, governance, and archive metadata.
- `notes/notes.md` stores the raw note supplied during creation.
- `draft.md` is the working draft placeholder.
- `seed.md` is the seed content placeholder.
- `final.md` is the final content placeholder.
- `assets/` holds source assets.
- `derivatives/` holds repurposed or adapted versions.
- `archive/` holds old or retired material.

This example is public-safe and intentionally generic.
