# Blueprint

Current release: `mvp.2024.7.2.3`

Blueprint is a local-first operating system for organising life, work, projects, research, and repeated practice using plain files.

This repository starts with the smallest public form of Blueprint: a clear idea, a working philosophy, and a simple operating loop.

## What Blueprint Is

Blueprint is built from ordinary materials:

```text
Folders
Markdown files
Templates
Scripts
Operating practices
```

Folders provide the environment. Markdown files hold the working objects. Templates create repeatable structures. Scripts reduce manual friction. Operating practices define how work moves through the system.

Together, they form a practical operating system for thought, action, review, and continuous improvement.

## Why Blueprint Exists

Work often begins informally.

Ideas are captured in scattered notes.

Processes live inside people's heads.

Repeated tasks are performed manually.

Lessons disappear after the work is completed.

Blueprint creates a structure in which experience can become a reusable system.

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

This is the first reconstructed public release of Blueprint.

Blueprint began as a personal local operating system in March 2024. This release reconstructs the first public-facing seed from July 2024: the moment the idea becomes a shareable repository.

The release number follows the Blueprint staged versioning pattern:

```text
mvp.2024.7.2.3
```

Where:

- `mvp` is the maturity stage.
- `2024` is the year.
- `7` is the month.
- `2` is the week of the month.
- `3` is the day of the week, with Monday as day 1.

## Template Direction

Blueprint is intended to become a template repository that people can use to start their own local operating system.

Future releases may add folder structures, templates, scripts, practices, and migration guidance. The goal is that users can adopt newer Blueprint structures without losing or overwriting their personal work.

## Release Notes

Blueprint keeps a permanent project history in `CHANGELOG.md`.

GitHub release notes are stored as one file per release in `releases/`.

To publish a release from an existing local tag:

```bash
scripts/release.sh mvp.2024.7.2.3
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
