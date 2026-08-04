# Notice

This skill is derived from Microsoft's `wiki-agents-md` skill, part of the
`microsoft/skills` repository:

- Source: https://github.com/microsoft/skills/tree/main/.github/plugins/deep-wiki/skills/wiki-agents-md
- Original license: MIT, Copyright (c) Microsoft Corporation (see `LICENSE` in this directory)

The original skill generates `AGENTS.md` files with build/test/style/structure
guidance for arbitrary repositories. This derivative, `research-repo-governance`,
keeps the core mechanics — the "never overwrite an existing file" guard, the
`AGENTS.md` + `CLAUDE.md` companion pattern, and the quality-principles /
anti-patterns format — but retargets the content entirely to govern research
repositories: data immutability, experiment provenance, notebook/logic
separation, protection of generated results, migration sign-off, and
confidentiality of sensitive data and large binaries.

The original MIT license and copyright notice are preserved unmodified in
`LICENSE`, as required by the license terms.
