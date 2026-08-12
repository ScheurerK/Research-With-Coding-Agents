---
name: research-repo-governance
description: Governs the structure and integrity of research repositories — canonical directory layout for data, code, notebooks, experiments, results, docs and artifacts; immutable raw data; reproducible experiments with full provenance (commit, config, seed, dataset version, environment, run command); no central logic in notebooks; no manual edits to generated results; migration plan and sign-off before major restructuring; protection of confidential data and large binaries; and hierarchical AGENTS.md/CLAUDE.md files. Adapted from Microsoft's wiki-agents-md skill (MIT licensed).
license: MIT
metadata:
  author: Adapted from Microsoft Corporation (wiki-agents-md, microsoft/skills)
  version: "1.0.0"
---

# Research Repository Governance

Establish and enforce the structural and procedural rules that keep a
research repository (PhD projects, lab codebases, data-science
experiments) reproducible, auditable, and safe to collaborate on. Apply
these rules when creating a new research repository, reviewing an
existing one, or generating agent-context files (`AGENTS.md`/`CLAUDE.md`)
for it.

## Why This Matters

Research repositories fail in specific, recurring ways: raw data gets
silently overwritten, a result can no longer be reproduced because nobody
recorded which commit or seed produced it, notebooks accumulate
untestable business logic, generated tables get hand-edited to "fix" a
number, reports use unexplained internal variable names, and large
restructurings break every collaborator's local checkout without warning.
Each rule below exists to close one of these failure modes.

## Canonical Repository Layout

Every research repository should have a predictable top-level structure.
See [references/repository-layout.md](references/repository-layout.md)
for the full layout, rationale per directory, and `.gitignore`/DVC/Git
LFS guidance.

```
data/           # immutable raw + versioned processed/external data
code/           # importable library code (src/ is an accepted alias)
notebooks/      # exploration only — imports from code/, no core logic
experiments/    # one subfolder per run, each with a manifest (see below)
results/        # generated output — never hand-edited
docs/           # human-facing documentation
artifacts/      # models, checkpoints, figures meant for reuse/publication
configs/        # experiment/run configuration files
environments/   # lockfiles, environment.yml, Dockerfiles
tests/          # tests for code/
```

Do not invent directories that duplicate one of these roles under a
different name (e.g. a second `output/` next to `results/`). If the
repository already has an established layout that serves the same
purposes under different names, document the mapping in the root
`AGENTS.md` rather than forcing a rename.

## Rule 1 — Raw Data Is Immutable

- Nothing under `data/raw/` (or the repository's equivalent) is ever
  edited, reformatted, or deleted in place once committed or ingested.
- Corrections or reprocessing produce a **new** file or a new versioned
  entry (`data/processed/`, `data/external/`) with its own provenance —
  they never overwrite the original.
- Raw data is read-only in practice: scripts that touch `data/raw/`
  should only read from it, never write to it.
- If raw data must be corrected upstream (e.g. a sensor recalibration),
  record the change as a new dated snapshot, not an edit of the old one.

## Rule 2 — Reproducible Experiments Require Full Provenance

Every experiment run must be reproducible from its recorded metadata
alone. At minimum, record:

- **Commit** — the exact git commit hash the run was executed at
- **Config** — the configuration file or parameter set used
- **Seed** — the random seed(s) controlling stochastic behavior
- **Dataset version** — which version/hash of the input data was used
- **Environment** — the exact environment (lockfile hash, container
  image tag, or equivalent) the run executed in
- **Command** — the literal command used to launch the run

See [references/experiment-provenance.md](references/experiment-provenance.md)
for how to capture and verify these fields, and
[templates/experiment-manifest.yaml](templates/experiment-manifest.yaml)
for a manifest template to drop into each `experiments/<run-id>/` folder.

A run without a manifest is not a reproducible result — treat it as
disposable, not as evidence for a paper or report.

## Rule 3 — No Central Logic in Notebooks

- Notebooks are for exploration, visualization, and narrating a result —
  not for defining the logic the project depends on.
- Any function, transformation, or model definition used by more than one
  notebook, or needed for a reproducible run, belongs in `code/` and is
  imported into the notebook, not pasted or redefined there.
- A notebook should read roughly as: import from `code/`, load data, call
  functions, plot/report. If a notebook cell contains more than a few
  lines of non-trivial logic, that logic likely belongs in `code/`
  instead.
- Notebooks are not a dependency of `code/` in either direction except
  through explicit, versioned imports — `code/` must never import from a
  notebook.

## Rule 4 — Never Manually Edit Generated Results

- Anything under `results/` (or produced by a pipeline/experiment run) is
  regenerated by rerunning the producing code — it is never edited by
  hand to fix a wrong number, typo, or formatting issue.
- If a result is wrong, fix the code or config that produced it and
  rerun; do not patch the output file directly.
- Generated files should be treated as build artifacts: safe to delete
  and regenerate at any time. If deleting a result file and being unable
  to regenerate it would be a problem, the provenance in Rule 2 is
  incomplete.

## Rule 5 — Generated Reports and Tables Are Self-Contained

Reports, tables, and other publication-facing outputs must explain what
they show without relying on private project context or internal variable
names. A reader should be able to copy the table into a paper draft and
understand the represented quantities from the table title, labels, and
notes alone.

- Replace internal variable names with reader-facing labels, and provide
  variable definitions for every displayed measure, coefficient, flag, or
  statistic.
- State units, scaling, transformations, and sign conventions where they
  affect interpretation (for example percentages versus basis points,
  log values, winsorization, or standardized coefficients).
- Identify the sample, filters, time period, data source, and aggregation
  level used to produce the table.
- Include Table Notes for every generated table intended for reports,
  papers, presentations, or external review. Notes define variables,
  abbreviations, sample construction, statistical conventions, and any
  caveats needed to interpret the table on its own.
- If a report cannot name or define a displayed quantity, treat the
  output as incomplete: fix the producing code/config and regenerate it
  instead of patching labels or notes by hand.

## Rule 6 — Migration Plan and Sign-off Before Major Restructuring

Before a restructuring that moves, renames, or deletes a significant
number of files (directory reorganizations, splitting/merging modules,
changing the canonical layout):

1. Write a short migration plan: what moves where, what breaks (import
   paths, CI, external references, collaborators' local branches), and
   how the change will be validated.
2. Get explicit sign-off from the repository owner(s) or maintainers
   before executing it — do not restructure opportunistically as a side
   effect of an unrelated task.
3. Execute the migration as its own isolated change, not mixed into a
   feature or bugfix commit.
4. After migration, update any `AGENTS.md`/`CLAUDE.md` files whose
   described layout is now stale.

Small, local reorganizations (e.g. splitting one file into two within the
same directory) do not require this process — use judgment on "major."

## Rule 7 — Protect Confidential Data and Large Binaries

- Never commit credentials, API keys, participant-identifiable data, or
  other confidential material to the repository, including in notebook
  outputs, logs, or example configs.
- Treat any dataset containing personal, proprietary, or otherwise
  sensitive information as confidential by default; store it outside the
  git history (encrypted storage, access-controlled bucket, institutional
  data repository) and reference it by path/ID, not by committing it.
- Large binaries (datasets, model checkpoints, media) do not belong in
  plain git history — use Git LFS, DVC, or an external artifact store,
  and commit only the pointer/reference.
- Add and maintain `.gitignore` entries for local caches, credentials
  files, and large generated artifacts so they cannot be committed by
  accident.
- If confidential data or a large binary is discovered already committed,
  treat it as an incident: stop, flag it to the repository owner, and do
  not silently rewrite history without their sign-off (history rewrites
  affect every collaborator's clone).

## Hierarchical AGENTS.md and CLAUDE.md Files

Maintain per-folder `AGENTS.md` files (with matching `CLAUDE.md`
companions) that encode the rules above in terms specific to that folder,
using the same discipline as upstream AGENTS.md generation:

### Global Bootstrap Preservation

Repo-specific `AGENTS.md`/`CLAUDE.md` files are additive local deltas, not replacements for global agent instructions. When generating or auditing them:

- Preserve the global main-agent bootstrap: load `using-superpowers` before task actions.
- Do not weaken, remove, or contradict globally installed Markplane/Superpowers/router/privacy rules.
- Include a short pointer instead of copying the full global block: "Global bootstrap remains authoritative: main agents load `using-superpowers` before actions; this file only adds repository-specific rules."
- If an existing local file conflicts with global bootstrap, report it as an audit finding; do not silently rewrite it unless asked.
- Keep the subagent exemption: narrow subagents use compact task contracts unless their task explicitly triggers skills.
### Critical Guard: Only Generate If Missing

**Never overwrite an existing `AGENTS.md` or `CLAUDE.md`.**

Before generating for any folder:

```bash
ls AGENTS.md 2>/dev/null
ls CLAUDE.md 2>/dev/null
```

- If `AGENTS.md` exists → skip and report: `"AGENTS.md already exists at
  <path> — skipping"`.
- If it does not exist → generate it, then check `CLAUDE.md` under the
  same guard.

### Where to Generate

- **Repository root** — always.
- `data/`, `code/` (or `src/`), `notebooks/`, `experiments/`, `results/`
  — generate if the folder exists and has enough content to warrant
  folder-specific guidance.
- Skip generated/vendored/cache directories (`__pycache__/`, `.venv/`,
  `node_modules/`, `.git/`, build output).

### What Each AGENTS.md Should Cover

Tailor to the folder — omit sections that don't apply, never invent
content:

- **Overview** — what this folder is for and how it fits the six rules
  above.
- **Layout** — the folder's own subdirectories and what belongs where.
- **Provenance requirements** — for `experiments/`, restate Rule 2 in
  concrete terms (where the manifest lives, what fields are required).
- **Immutability / no manual edits** — for `data/` and `results/`,
  restate Rules 1 and 4 explicitly; agents frequently need this
  reminder before they "fix" a file directly.
- **Self-contained outputs** — for `results/`, require readable variable
  labels, variable definitions, units, sample/time-period/source
  information, and Table Notes for publication-facing tables.
- **Notebook boundary** — for `notebooks/`, restate Rule 3: what may live
  in a notebook and what must move to `code/`.
- **Boundaries** — three-tier: ✅ always do / ⚠️ ask first / 🚫 never do,
  populated from the governance rules plus anything folder-specific (e.g.
  "⚠️ ask first: adding a new top-level data source").

### CLAUDE.md Companion File

Whenever an `AGENTS.md` is generated in a folder, also generate a
`CLAUDE.md` in the same folder — only if `CLAUDE.md` does not already
exist. Its content is always exactly:

```markdown
# CLAUDE.md

<!-- Generated for research-repository governance. Do not edit directly. -->

Before beginning work in this repository, read `AGENTS.md` and follow all
scoped AGENTS guidance, including the repository's data, provenance, and
notebook rules.
```

Same guard applies: check if `CLAUDE.md` exists before writing it.

## Generation / Audit Process

1. **Check existence** of `AGENTS.md`/`CLAUDE.md` per folder — skip if
   present.
2. **Scan the folder** against the canonical layout in
   [references/repository-layout.md](references/repository-layout.md);
   note deviations.
3. **Check experiment folders** for a manifest matching
   [templates/experiment-manifest.yaml](templates/experiment-manifest.yaml);
   flag runs missing one.
4. **Check for raw-data mutation risk** — scripts that open `data/raw/`
   paths in a write mode.
5. **Check for confidential data or large binaries** committed directly
   instead of via LFS/DVC or external storage.
6. **Compose** the folder's `AGENTS.md` (and `CLAUDE.md` companion) using
   only the sections that apply.
7. **Report** findings (missing manifests, raw-data writes, oversized
   committed files, layout deviations) without silently fixing them —
   structural fixes go through Rule 6's migration process.

## Quality Principles

| Principle | Good | Bad |
|-----------|------|-----|
| **Specific** | "Raw data lives in `data/raw/xetra/`, one CSV per trading day" | "data folder" |
| **Executable** | Manifest fields named exactly as the schema requires | "record how you ran it" |
| **Grounded** | Point to a real `experiments/<run-id>/manifest.yaml` | Describe provenance in the abstract |
| **Self-contained** | "Table Notes: `retail_share` is retail-flagged volume divided by total lit volume; sample is Xetra continuous trading, March 2026." | "retail_share" |
| **Honest** | Omit the experiments section if the folder has none | Invent one anyway |
| **Reversible-aware** | Flag a large restructuring for sign-off | Restructure silently mid-task |
| **Concise** | 30–80 lines for most folder `AGENTS.md` files | 300+ lines of prose |

## Anti-Patterns to Avoid

- ❌ **Editing `data/raw/` in place** — always version forward, never
  overwrite.
- ❌ **A result with no manifest** — not reproducible, not evidence.
- ❌ **Core logic pasted into a notebook** — untestable, unreusable,
  invisible to `code/`'s tests.
- ❌ **Hand-editing a generated table or figure** — fix the pipeline,
  rerun it.
- ❌ **Publishing tables with unexplained variable names** — generated
  reports need reader-facing labels, variable definitions, units, sample,
  time period, source, and Table Notes.
- ❌ **Restructuring the repo as a side effect of an unrelated task** —
  needs its own migration plan and sign-off.
- ❌ **Committing a credential, participant-identifiable record, or
  multi-hundred-MB binary directly to git** — use LFS/DVC/external
  storage and `.gitignore`.
- ❌ **Overwriting an existing `AGENTS.md`/`CLAUDE.md`** — if it exists,
  leave it alone.
- ❌ **Rewriting git history to remove a leaked secret without owner
  sign-off** — flag the incident instead.
