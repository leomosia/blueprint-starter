# Stats Example

This folder was created by running:

```bash
BLUEPRINT_DATE=2025-03-20 _/scripts/stats.sh
```

The script scans Blueprint systems and generates:

- `dashboard.md` for a readable Markdown summary.
- `exports/dashboard.json` for a machine-readable export.
- `snapshots/` for optional dated dashboard snapshots.

This example currently counts:

- one story in TodoSys
- one content item in InputSys
- zero content items in OutputSys

Run this again whenever you want the dashboard to reflect the current repository state.
