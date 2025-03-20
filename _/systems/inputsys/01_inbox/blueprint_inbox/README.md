# Blueprint Inbox Example

This folder was created by running:

```bash
cd _/systems/inputsys/01_inbox
./_inbox_scripts/split.sh
```

The splitter found this entry in `inbox.md`:

```markdown
- #blueprint - seed
```

Because `blueprint` exists in `_inbox_scripts/whitelist.yml`, the script created this routed inbox and moved the entry into `blueprint_inbox.md`.
