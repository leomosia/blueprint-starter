# inbox/

## Step 1 — Inbox

### What this folder is

`inbox/` is a **raw intake zone**.

It mirrors your mind in motion.
It is allowed to be messy.
It is allowed to be incomplete.

Nothing here is trusted.
Nothing here is finished.

The only rule: **capture first, think later**.

## Core Principle

**Inbox is for speed, not clarity.**

If you hesitate before capturing, the system has already failed you.

## How the inbox works

The inbox starts as one shared capture file:

```text
inbox.md
```

You add fast, single-line entries using this format:

```markdown
- #writing - idea for an essay about personal operating systems
- #research - collect examples of local-first tools
- #system - improve the inbox splitter
```

The tag after `#` is a routing destination. In Blueprint, a destination is usually a project, body of work, life domain, system, or workstream. It is not meant to be a loose social-media-style hashtag.

Allowed destinations live in:

```text
_inbox_scripts/whitelist.yml
```

When the splitter runs, it checks every tagged line against the whitelist. If the tag is approved, the entry is moved into a dedicated inbox:

```text
writing_inbox/writing_inbox.md
research_inbox/research_inbox.md
system_inbox/system_inbox.md
```

If the tag is not approved, the entry stays in `inbox.md`. This is intentional. The whitelist protects the system from creating random folders for every passing thought.

## How to use the whitelist

Treat `_inbox_scripts/whitelist.yml` as the list of work that is real enough to receive material.

Good whitelist entries are usually:

- active projects
- bodies of work
- life domains
- operating systems
- research streams
- content streams
- archives that deserve a named place

Keep tags short, lowercase, and folder-safe:

```yaml
tags:
  - blueprint
  - writing
  - research
  - system
```

Then capture against those destinations:

```markdown
- #blueprint - improve the public starter repo structure
- #writing - turn the inbox idea into a short essay
- #research - compare different personal knowledge systems
```

The whitelist should grow slowly. If every idea becomes a new tag, the inbox becomes chaos with extra steps.

## Running the splitter

From `_/systems/inputsys/01_inbox`, run:

```bash
./_inbox_scripts/split.sh --dry-run
```

That previews what would move without changing files.

To process valid entries:

```bash
./_inbox_scripts/split.sh
```

The script will:

- read `inbox.md`
- check each entry against `_inbox_scripts/whitelist.yml`
- create the destination inbox folder if needed
- append the entry to `tag_inbox/tag_inbox.md`
- remove moved entries from `inbox.md`
- leave invalid or malformed entries in place

## What goes into the Inbox

### 1. Digital Media & Online Content

Anything consumed digitally that may contain signal:

- **Saved Videos & Downloads**
  Social media clips, talks, lectures, long-form media.

- **Bookmarked & Read-Later Content**
  Articles, threads, essays, research links.

- **Interviews & Expert Talks**
  Notes or timestamps from podcasts, YouTube, discussions.

- **Podcasts & Audiobooks**
  Raw takeaways, quotes, time-marked ideas.

- **Online Courses & Webinars**
  Unprocessed lessons, screenshots, notes.

- **Research Papers & Industry Reports**
  Academic studies, whitepapers, market reports.

No summarization. No filtering.

### 2. Personal Notes & Journals

Fast human capture without refinement:

- **Conversation Insights**
  Lessons, quotes, realizations from discussions.

- **Quick Notes & Ideas**
  Random thoughts, sparks, half-ideas.

- **Observations & Trends**
  Patterns noticed in people, culture, behavior, environments.

- **Event & Networking Notes**
  Raw notes from conferences, meetings, or encounters.

Emotion, contradiction, and noise are allowed.

### 3. Books, Studies & Structured Knowledge

Unprocessed learning inputs:

- **Academic Learning & Textbooks**
  Notes taken without synthesis.

- **Book & Blog Notes**
  Highlights, copied quotes, raw summaries.

- **Biographies & Leadership Studies**
  Observations without conclusions.

Interpretation comes later.

### 4. Internal Documentation & Lessons

Reality captured without rewriting history:

- **Project & Work Archives**
  Raw lessons, mistakes, outcomes.

- **Feedback & Criticism Logs**
  Unfiltered critique, even when uncomfortable.

- **Team & Culture Observations**
  Notes on behavior, dynamics, performance.

Inbox does not protect ego.

### 5. Business & Market Intelligence

Unfiltered external signals:

- **Competitor & Industry Analysis**
  Moves, strategies, rumors, observations.

- **Economic & Policy Signals**
  Macro trends, regulations, shifts in power.

At this stage, accuracy is secondary to capture.

### 6. Systems & Strategic Thinking

Big-picture inputs before coherence:

- **Historical & Geopolitical Notes**
  Patterns, parallels, questions.

- **Technological Disruptions**
  Early signals, weak indicators, speculation.

Inbox allows incomplete thinking.

### 7. Self-Development & Psychological Insights

Internal data without judgment:

- **Behavioral & Psychological Notes**
  Human nature, incentives, patterns.

- **Personal Metrics & Self-Tracking**
  Habits, energy, output, failures.

- **Mentorship & High-Level Conversations**
  Raw lessons from advisors and peers.

This is self-observation, not self-branding.

## What does NOT belong in Inbox

- Polished writing
- Final decisions
- Published content
- Canonical frameworks

If it’s refined, it’s already late-stage.

## Exit Rule (Non-Negotiable)

Inbox must be **emptied through Processing**.

Anything that stays here is:

- forgotten
- untrusted
- unusable

An overflowing inbox is cognitive debt.

## Mental Model

- **Inbox** → capture without thinking
- **Processing** → think without publishing
- **Output systems** → publish without chaos

Inbox is velocity.
Processing is judgment.
Output is consequence.
