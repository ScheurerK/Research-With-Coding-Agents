# Canonical Research Repository Layout

A predictable top-level structure so agents (and humans) can find data,
code, and results without guessing, and so tooling (`.gitignore`, CI,
DVC/Git LFS) can be written once and apply consistently.

```
repo-root/
├── AGENTS.md               # repo-wide agent context (see SKILL.md)
├── CLAUDE.md                # redirects to AGENTS.md
├── README.md                 # human-facing overview
├── data/
│   ├── raw/                  # immutable — see "data/raw/" below
│   ├── processed/             # derived data, versioned, regeneratable
│   └── external/               # third-party data, with source + license noted
├── code/                        # importable library code ("src/" is an accepted alias)
│   └── <package>/
├── notebooks/                     # exploration/reporting only, no core logic
├── experiments/                     # one subfolder per run
│   └── <run-id>/
│       ├── manifest.yaml               # see templates/experiment-manifest.yaml
│       ├── config.yaml (or equivalent)   # the config actually used
│       └── output/                         # this run's raw output, if not in results/
├── results/                                  # generated, never hand-edited
├── artifacts/                                  # models, checkpoints, figures for reuse/publication
├── configs/                                      # reusable experiment/run configuration files
├── environments/                                   # lockfiles, environment.yml, Dockerfiles
├── docs/                                             # architecture notes, decisions, methodology
└── tests/                                              # tests for code/
```

## `data/raw/` — Immutable

- Write-once. Nothing under `data/raw/` is edited or deleted after it
  lands. Ingestion scripts open it read-only.
- If the source data is corrected upstream, add a new dated subfolder or
  file rather than overwriting; keep the old snapshot unless the
  repository owner explicitly approves removing it.
- Large raw datasets are tracked via Git LFS/DVC or referenced by path to
  external storage — not committed as plain blobs (see Rule 7 in
  `SKILL.md`).

## `data/processed/` and `data/external/`

- `processed/` holds anything derived from `raw/` by a documented,
  rerunnable transformation (ideally with the producing script/commit
  noted, same spirit as experiment provenance).
- `external/` holds third-party data with its source and license
  recorded (a sibling `SOURCE.md` or a note in the folder's `AGENTS.md`
  is enough).

## `code/` (or `src/`)

- The only place core logic lives. Notebooks and experiment scripts
  import from here; this directory never imports from a notebook.
- Has its own `tests/` coverage where feasible.

## `notebooks/`

- Exploration, visualization, narrating a result. See Rule 3 in
  `SKILL.md` — logic used more than once, or needed for a reproducible
  run, moves to `code/`.
- Naming convention (recommended): `NN-short-description.ipynb`, ordered
  by when they were created or by narrative sequence, so the folder
  reads top-to-bottom.

## `experiments/<run-id>/`

- One subfolder per run, named for traceability (timestamp, short hash,
  or a descriptive slug plus date).
- Must contain a `manifest.yaml` (see
  [experiment-provenance.md](experiment-provenance.md) and
  [../templates/experiment-manifest.yaml](../templates/experiment-manifest.yaml)).
- Run-specific output can live here under `output/`, or in `results/`
  keyed by `run-id` — pick one convention per repository and note it in
  the root `AGENTS.md`.

## `results/`

- Generated only. Regeneratable from `experiments/` + `code/` at any
  time. Never hand-edited (Rule 4).

## `artifacts/`

- Larger reusable outputs meant to be consumed elsewhere: trained model
  weights, publication-ready figures, exported datasets. Tracked via
  LFS/DVC if large.

## `configs/` and `environments/`

- `configs/` holds reusable configuration files referenced by
  `experiments/<run-id>/manifest.yaml`.
- `environments/` holds whatever pins the runtime environment
  (`environment.yml`, `requirements*.txt` + lockfile, `Dockerfile`,
  `Pipfile.lock`) so a run's environment field in its manifest is
  actually reproducible.

## Adapting an Existing Layout

If a repository already has an established structure that fulfills these
roles under different names (e.g. `analysis/` instead of `notebooks/`,
`runs/` instead of `experiments/`), do not force a rename. Document the
mapping explicitly in the root `AGENTS.md` so agents know which local
folder plays which role, and apply the immutability/provenance/no-manual-edit
rules to the folders that actually play those roles. Renaming an
established layout to match this document is itself a major
restructuring — it goes through the migration/sign-off process (Rule 6).
