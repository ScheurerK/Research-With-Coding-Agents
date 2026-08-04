---
id: TASK-k8h9q
title: Bind VS Code graph view to each workspace project
status: done
priority: high
type: bug
effort: medium
epic: null
plan: null
depends_on: []
blocks: []
related: []
assignee: scheurer
tags: []
position: a7
created: 2026-07-20
updated: 2026-07-20
---

# Bind VS Code graph view to each workspace project

## Description

The VS Code extension used a fixed `markplane.port` value and embedded `http://127.0.0.1:<port>` in every workspace view. Multiple VS Code windows could therefore point at the same Markplane server and show the wrong project's graph/UI.

## Implementation

- Added workspace-bound server state in `MarkplaneInstaller/vscode-extension/extension.js`.
- Added deterministic project-specific port selection from the configured base port, scanning the next 100 ports for availability.
- Changed sidebar and full webviews to embed `/graph` on the actual server port.
- Added startup focusing via `markplane.showOnStartup` so each VS Code window shows the Markplane graph view by default.
- Updated `package.json` setting descriptions and the extension README.
- Reinstalled the local VS Code extension into `C:\Users\scheurer\.vscode\extensions\local.markplane-vscode-0.1.2`.

## Verification

- `node --check MarkplaneInstaller\vscode-extension\extension.js`
- `node -e "JSON.parse(require('fs').readFileSync('MarkplaneInstaller/vscode-extension/package.json','utf8'))"`
- `markplane check`

## References