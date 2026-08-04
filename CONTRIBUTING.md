# Contributing

## Setup

Clone recursively:

```powershell
git clone --recurse-submodules https://github.com/<owner>/research-with-coding-agents.git
cd research-with-coding-agents
```

Required Windows tools for release work:

- PowerShell 5.1 or newer
- Pester
- Rust and Cargo
- Node.js and npm
- Inno Setup 6
- `npx @vscode/vsce`

## Test Commands

```powershell
Invoke-Pester .\MarkplaneInstaller\tests,.\tests
cargo test --manifest-path .\markplane-master\Cargo.toml
npm --prefix .\markplane-master\crates\markplane-web\ui test
```

The local Pester version in this workspace is 3.4.0, so use `Invoke-Pester <paths>` unless a newer runner is installed.

## Contribution Paths

Product integration changes belong in this repository. Markplane behavior changes belong in the maintained Markplane fork and are then pinned here. Superpowers behavior changes belong in the maintained Superpowers fork and are then pinned here. Local extension examples belong under `extensions/`.

Do not flatten Markplane or Superpowers history into this repository. Do not replace the bundled Superpowers distribution from the network during install, repair, or release packaging.
