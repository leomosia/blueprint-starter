# Blueprint TodoSys

TodoSys is the execution visibility side of Blueprint. It exists to show what work is actionable, what is next, what is active, what is paused, what is done, and what has become historical memory.

TodoSys does not own the actual work. It does not replace L5, InputSys, or OutputSys. It simply provides a lightweight movement layer for tasks, stories, cards, or pointers to work that exists elsewhere in the system.

## Flow

```text
00_backlog
    |
    v
01_next
    |
    v
02_doing
    |
    v
03_onhold
    |
    v
04_done
    |
    v
99_archive
```

## Stages

### 00 Backlog

Work you are aware of but have not chosen to act on yet. It is known, but not active.

### 01 Next

Work you have deliberately selected to do next. It should be clear enough and small enough to move into action.

### 02 Doing

Work that currently has your attention. This stage should stay limited so focus and quality do not collapse.

### 03 On Hold

Work that is paused by choice or circumstance. It is waiting on time, clarity, energy, a decision, or an external dependency.

### 04 Done

Work that is complete and no longer requires action. It has met its definition of done.

### 99 Archive

Historical record only. This is no longer part of active attention, but it may still hold reference or learning value.

## Principle

L5 governs direction. TodoSys governs movement. If something exists in TodoSys, it should be actionable or directly tied to action.
