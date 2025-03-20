# Body Of Work Inbox Example

This folder was created by running:

```bash
cd _/systems/inputsys/01_inbox
./_inbox_scripts/split.sh
```

The splitter found this entry in `inbox.md`:

```markdown
- #bodyofwork - seed
```

Because `bodyofwork` exists in `_inbox_scripts/whitelist.yml`, the script created this routed inbox and moved the entry into `bodyofwork_inbox.md`.

The text is preserved exactly as entered. The splitter routes content; it does not rewrite it.
