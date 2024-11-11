# Blueprint

Current release: `mvp.2024.11.3.1`

Blueprint is a local-first operating system for organising life, work, projects, research, and repeated practice using plain files. This repository starts with the smallest public form of Blueprint: a clear idea, a working philosophy, and a simple operating loop.

## What Blueprint Is

Blueprint is built from ordinary materials:

```text
Folders
Markdown files
Templates
Scripts
Operating practices
```

Folders provide the environment, Markdown files hold the working objects, templates create repeatable structures, scripts reduce manual friction, and operating practices define how work moves through the system. Together, they form a practical operating system for thought, action, review, and continuous improvement.

## Why Blueprint Exists

Work often begins informally. Ideas are captured in scattered notes, processes live inside people's heads, repeated tasks are performed manually, and lessons disappear after the work is completed. Blueprint creates a structure in which experience can become a reusable system.

```text
Experience
    |
    v
Observation
    |
    v
Pattern
    |
    v
Documentation
    |
    v
Practice
    |
    v
System
    |
    v
Improvement
```

Blueprint helps operators work while also improving how the work is performed.

## Core Operating Loop

```text
Capture
    |
    v
Define
    |
    v
Plan
    |
    v
Execute
    |
    v
Review
    |
    v
Sustain
    |
    v
Repeat
```

## L5 Structure

Blueprint now starts with the L5 lifecycle structure from the Leo Mosia Framework:

```text
define/    Clarify what matters and why.
plan/      Turn clarity into sequence, timing, and resources.
execute/   Do the work and capture what happens.
review/    Reflect on outcomes, lessons, and decisions.
sustain/   Preserve energy, continuity, and long-term rhythm.
```

The folders are intentionally light in this release. They provide a first usable operating shape without importing the full mature framework too early.

## Core Principles

### Local First

Blueprint remains usable from local files without requiring a hosted platform.

### Plain Files

Core information is stored in readable and portable formats.

### Structure Before Interface

The operating model exists independently of any graphical application.

### Repeatability

Recurring work becomes a template, script, process, module, or standard.

### Progressive Formalisation

Structure is introduced in response to real operating needs.

### Human Control

The operator remains able to inspect, understand, and modify the system.

### Continuous Improvement

Blueprint evolves through use and is never treated as permanently complete.

## Release Stage

This release is the first structural milestone after the README-only seed. Blueprint began as a personal local operating system in March 2024, became a public-facing idea in July 2024, and now introduces the first lightweight L5 folder structure.

The release number follows the Blueprint staged versioning pattern:

```text
mvp.2024.11.3.1
```

Where:

- `mvp` is the maturity stage.
- `2024` is the year.
- `11` is the month.
- `3` is the week of the month.
- `1` is the day of the week, with Monday as day 1.

## Template Direction

Blueprint is intended to become a template repository that people can use to start their own local operating system.

Future releases may add folder structures, templates, scripts, practices, and migration guidance. The goal is that users can adopt newer Blueprint structures without losing or overwriting their personal work.

## Release Notes

Blueprint keeps a permanent project history in `CHANGELOG.md`. GitHub release notes are stored as one file per release in `.releases/`, keeping release machinery separate from the visible L5 operating folders.

To publish a release from an existing local tag:

```bash
_/scripts/release.sh mvp.2024.11.3.1
```

## Getting Started

Clone the repository and read the operating idea:

```bash
git clone https://github.com/blueprint-os/blueprint.git
cd blueprint
less README.md
```

## Licence

See `LICENSE`.
