# Example L5 Project

This folder was created by running:

```bash
cd _/examples/l5_project
../../scripts/create_L5.sh
```

The script creates the L5 lifecycle structure in the current directory:

- `define/` holds the shape of the work before action begins.
- `plan/` holds sequencing, resources, constraints, and decisions.
- `execute/` holds the active work.
- `review/` holds lessons, outcomes, and evidence.
- `sustain/` holds maintenance, recovery, and continuity practices.

The nested folders under `define/` move from broad direction to concrete projects:

- `01_vision/`
- `02_focus_areas/`
- `03_intentions/`
- `04_objectives/`
- `05_projects/`

Each empty folder includes a `.gitkeep` file so Git can track the structure.
