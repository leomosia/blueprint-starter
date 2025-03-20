# Example Story

This folder was created by running:

```bash
printf 'Example Story\n' | BLUEPRINT_DATE=2025-03-20 _/scripts/create_story.sh
```

The script created the story ID `s-2501` from the date override and the next available counter for 2025.

## What the Script Created

- `meta.md` stores story identity, scope, acceptance, status, dependencies, risk, and retro fields.
- `details.md` holds context, insights, questions, notes, and references.
- `log.md` records execution updates over time.
- `assets/` holds supporting files.
- `archive/` holds old or retired material.

Stories begin in `_/systems/todosys/00_backlog/` because they represent possible work before it is pulled into active execution.
