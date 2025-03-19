<!--
INBOX RULES — READ BEFORE ADDING ENTRIES
======================================

PURPOSE
- This file is a RAW CAPTURE ZONE.
- Everything here is unprocessed input.
- The goal is to eventually EMPTY this file via automated or manual routing.

HOW ROUTING WORKS
- Each tag points to an approved destination from _inbox_scripts/whitelist.yml.
- A destination is usually a project, body of work, life domain, system, or workstream.
- When the splitter runs, a line tagged #writing is moved into:

  writing_inbox/writing_inbox.md

- The script creates that destination inbox when it does not exist.
- Tags are intentionally controlled so the inbox does not create random folders from every passing thought.

ACCEPTED ENTRY FORMAT (AUTO-ROUTABLE)
- Each routable entry MUST be a single top-level bullet:

  - #tag - your text goes here

- Requirements:
  - Must start with: "- #"
  - Tag must exist in _inbox_scripts/whitelist.yml
  - Tag is case-insensitive (input is normalized)
  - Text after "- #tag -" can be anything
  - Spacing after "-" and around "-" matters

EXAMPLES (VALID)
  - #writing - write about the role of structure in creative work
  - #system - automate inbox splitting
  - #research - collect examples of local-first personal systems

NON-ROUTABLE (WILL STAY IN INBOX)
- Missing tag:
  - write about my next project idea

- Unknown tag:
  - #random - this will not move

- Malformed format:
  - #writing essay idea
  - #writing- essay idea
  - - writing - essay idea

- Multi-line or paragraph entries
- Headings, notes, or free text

SUB-BULLETS
- Sub-bullets are ignored by the system
- They are allowed for human thinking only
- Example:

  - #writing - essay about creative discipline
    - capture rough examples
    - decide later if it becomes a draft

AUTOMATION BEHAVIOR
- Only whitelisted tags are routed
- No new tags are auto-created
- A whitelisted tag becomes a destination inbox folder
- The whitelist should be edited deliberately as your projects or bodies of work become real
- Rejected or malformed entries remain here by design
- This file is NEVER force-cleaned

DISCIPLINE
- If it doesn't move, FIX IT or ACCEPT IT
- Inbox chaos is a signal, not a bug
- Manual thinking is intentional friction

-->
