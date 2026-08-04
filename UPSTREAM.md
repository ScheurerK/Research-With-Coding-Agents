# Upstream And Fork Maintenance

Research With Coding Agents keeps explicit upstream relationships for its two core component forks.

## Markplane

- Upstream: `https://github.com/zerowand01/markplane`
- Local path: `components/markplane`
- License: Apache-2.0

Markplane changes are reviewed in the maintained fork first. This product repository then updates the pinned submodule commit and provenance record.

## Superpowers

- Upstream: `https://github.com/obra/superpowers`
- Local path: `components/superpowers`
- License: MIT

Superpowers changes are reviewed in the maintained fork first. Runtime integrations must prefer the bundled Research With Coding Agents copy over any standard or foreign Superpowers copy.

## Update Rule

Automated checks may report upstream changes, but they must not merge or repin component commits automatically. Each component update is a separate reviewable change.
