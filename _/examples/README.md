# Script Examples

This folder shows small examples created by Blueprint helper scripts.

The examples are intentionally plain. Their purpose is to show the shape of the files and folders a script creates, not to prescribe real personal content.

## Examples

- `l5_project/` was created with `_/scripts/create_L5.sh`.
- `../systems/inputsys/01_inbox/contentitems_inbox/c-25001_example-content-item/` was created with `_/scripts/create_content_item.sh`.
- `../systems/todosys/00_backlog/s-2501_example-story/` was created with `_/scripts/create_story.sh`.

For historical reconstruction or repeatable demos, the content and story scripts support:

```bash
BLUEPRINT_DATE=2025-03-20 _/scripts/create_content_item.sh
BLUEPRINT_DATE=2025-03-20 _/scripts/create_story.sh
```

Without `BLUEPRINT_DATE`, the scripts use the current system date.
