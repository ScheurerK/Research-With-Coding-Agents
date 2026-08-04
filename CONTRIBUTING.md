# Contributing

## Setup

Clone the repository:

```powershell
git clone https://github.com/<owner>/research-with-coding-agents.git
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
Invoke-Pester .\installer\windows\tests,.\tests
cargo test --manifest-path .\components\markplane\Cargo.toml
npm --prefix .\components\markplane\crates\markplane-web\ui test
```

The local Pester version in this workspace is 3.4.0, so use `Invoke-Pester <paths>` unless a newer runner is installed.

## Contribution Paths

Product integration changes belong in this repository. Markplane behavior changes belong in the maintained Markplane source and are then recorded in provenance. Superpowers behavior changes belong in `components/superpowers/skills` first, because installer integrations must prefer this bundled copy. Local extension examples belong under `extensions/`.

Do not flatten or replace the component histories when public forks/submodules are attached. Do not replace the bundled Superpowers distribution from the network during install, repair, or release packaging.