# Experiment Provenance

A result is only as trustworthy as the record of how it was produced. The
goal is that any run can be reproduced — or at least fully audited —
from its manifest alone, without asking the author "how did you get
this number?".

## Required Fields

Every run manifest (see
[../templates/experiment-manifest.yaml](../templates/experiment-manifest.yaml))
must record:

| Field | What it captures | Why it matters |
|---|---|---|
| `commit` | Exact git commit hash `code/` was at | Code changes silently between runs otherwise |
| `config` | Path (and ideally hash) of the config/parameters used | Config drift is the most common source of "irreproducible" results |
| `seed` | Random seed(s) controlling stochastic behavior | Without it, stochastic results can't be re-derived |
| `dataset_version` | Version/hash/snapshot identifier of the input data | `data/processed/` and external data can change over time |
| `environment` | Lockfile hash, container image tag, or equivalent | Library version drift changes numeric results |
| `command` | The literal command used to launch the run | Removes ambiguity about entry point and flags |

Optional but recommended: `author`, `timestamp`, `hardware` (GPU/CPU
type, relevant for timing or numeric precision), `results_path`, `notes`.

## Capturing the Fields

- **commit** — `git rev-parse HEAD` at launch time, captured
  automatically by the run script rather than typed by hand.
- **config** — copy or symlink the actual config file used into the
  run's `experiments/<run-id>/` folder rather than only recording a path
  that might later change.
- **seed** — set explicitly in code (don't rely on an unset/default
  seed); record every seed if multiple RNGs are involved (numpy, torch,
  python `random`, etc.).
- **dataset_version** — a content hash (e.g. `sha256` of the file, or a
  DVC/LFS object hash) is stronger than a filename, which can be reused
  for different content.
- **environment** — a lockfile hash (`requirements.lock`,
  `environment.yml` resolved, `poetry.lock`, `uv.lock`) or a container
  image digest, not just "Python 3.11".
- **command** — capture `sys.argv` / the shell invocation automatically
  in the run script; don't reconstruct it from memory afterward.

Prefer automating manifest creation inside the run script itself over
asking a human (or an agent) to fill it in after the fact — manifests
written after the run are the ones most likely to be wrong.

## Verifying Reproducibility

Periodically (and always before a result is used in a paper, report, or
downstream decision):

1. Check out the recorded `commit`.
2. Reconstruct or restore the recorded `environment`.
3. Re-run the recorded `command` with the recorded `config` and `seed`
   against the recorded `dataset_version`.
4. Compare output to the original within an expected tolerance (exact
   match for deterministic code; documented tolerance for anything with
   residual nondeterminism, e.g. GPU nondeterminism).
5. If it doesn't reproduce, treat that as a bug in the pipeline or the
   manifest, not as an acceptable result — fix the underlying issue
   before trusting either the original or the rerun.

## Runs Without a Manifest

A run with no manifest, or an incomplete one, is not evidence — treat it
as exploratory/disposable. Do not cite it, publish it, or build further
experiments on top of it until it either gets a complete manifest and is
re-verified, or is discarded.

## Relationship to Migration/Restructuring (Rule 5)

Changing where manifests live, their schema, or the experiment folder
convention is itself a structural change to the repository and goes
through the migration-and-sign-off process described in `SKILL.md`
(Rule 5) — it is not something to change opportunistically while adding
a single experiment.
