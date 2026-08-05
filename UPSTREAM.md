# Upstream And Fork Maintenance

Research With Coding Agents keeps explicit upstream relationships for its two core component sources. The first public distribution intentionally uses vendored, maintained source snapshots under `components/` instead of Git submodules so a normal clone contains the full project.

## Markplane

- Upstream: `https://github.com/zerowand01/markplane`
- Local path: `components/markplane`
- License: Apache-2.0

Markplane changes are reviewed against the vendored maintained source first. This product repository records the shipped source state and provenance. If a public fork is later created, record its URL and reviewed upstream base here and in `THIRD_PARTY_NOTICES.md`; keep the component vendored unless a separate migration explicitly updates installer, CI, release, and contributor behavior.

## Superpowers

- Upstream: `https://github.com/obra/superpowers`
- Local path: `components/superpowers`
- License: MIT

Superpowers changes are reviewed in `components/superpowers/skills` first. Runtime integrations must prefer the bundled Research With Coding Agents copy over any standard or foreign Superpowers copy.

## Update Rule

Automated checks may report upstream changes, but they must not merge or repin component commits automatically. Each component update is a separate reviewable change.

## Vendored Snapshot Rule

The authoritative shipped sources are the directories in this repository:

- `components/markplane`
- `components/superpowers`

Do not replace either directory with a network download during installation, repair, release packaging, or agent setup. Submodules are not required for normal use.
