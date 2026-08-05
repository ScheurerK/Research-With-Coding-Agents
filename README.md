<p align="center">
  <img src="assets/brand/rwca-logo.png" alt="Research With Coding Agents logo" width="560">
</p>

# Research With Coding Agents

Research With Coding Agents is a Windows-first local research workflow package for coding agents. It bundles a tested Markplane task system, a project-maintained Superpowers distribution, research skills, agent hooks, and the Markplane UI integration for VS Code and Antigravity.

Markplane is a core component, not the name of the complete product. Superpowers is shipped from this project's maintained source tree so Codex, Claude Code, and Gemini/Antigravity use the same local skills and rules instead of a standard copy from the network.

## Install On Windows

Download `ResearchWithCodingAgentsSetup-v0.1.0.exe` from a release and run it. The installer places the core under:

```text
%LOCALAPPDATA%\Programs\ResearchWithCodingAgents\
```

After installation, open a new terminal and run:

```powershell
markplane --version
```

The installer can register optional integrations for Codex, Claude Code, Gemini/Antigravity, and the Markplane UI extension. The UI extension is installed as a VSIX through the IDE CLI with `--force`; source folders are not copied into IDE extension directories.

## Clone And Build

A normal clone contains the public project structure:

```powershell
git clone https://github.com/<owner>/research-with-coding-agents.git
cd research-with-coding-agents
```

This repository is designed so contributors can work at any depth: product packaging, project skills, agent adapters, local extensions, the maintained Markplane source, or the maintained Superpowers source. Markplane and Superpowers are intentionally shipped as vendored, maintained source snapshots under `components/` so a normal clone contains the full inspectable project. Use `UPSTREAM.md` as the authority for sync and provenance.

## Local Extensions

User extensions live outside the product install directory:

```text
%USERPROFILE%\.research-with-coding-agents\extensions\<extension-name>\
```

Updates and repair operations preserve that directory. Executable extension hooks require explicit approval before activation.

## Platform Status

Windows is the supported first public release target. macOS and Linux source builds and basic Markplane operation are experimental until agent and installer parity are implemented.

## Repository Boundaries

- `components/markplane` contains the vendored maintained Markplane source linked to `zerowand01/markplane`.
- `components/superpowers/skills` is the vendored authoritative customized Superpowers skill tree used by every installer integration.
- `packages/project-skills` contains Research With Coding Agents-owned skills and packaged adapted skills.
- `packages/agent-adapters` contains Codex, Claude Code, and Gemini/Antigravity hooks and templates.
- `packages/vscode-extension/source` contains the Markplane interface extension source.
- `installer/windows` contains the current Windows installer implementation.

See `CONTRIBUTING.md`, `UPSTREAM.md`, and `THIRD_PARTY_NOTICES.md` before changing component boundaries or release packaging.