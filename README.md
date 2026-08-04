# Research With Coding Agents

Research With Coding Agents is a Windows-first local research workflow package for coding agents. It bundles a tested Markplane task system, a project-maintained Superpowers distribution, research skills, agent hooks, and the Markplane UI integration for VS Code and Antigravity.

Markplane is a core component, not the name of the complete product. Superpowers is shipped from this project's maintained fork so Codex, Claude Code, and Gemini/Antigravity use the same local skills and rules instead of a standard copy from the network.

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

Use a recursive clone so the pinned component forks are present:

```powershell
git clone --recurse-submodules https://github.com/<owner>/research-with-coding-agents.git
cd research-with-coding-agents
```

This repository is designed so contributors can work at any depth: product packaging, project skills, agent adapters, local extensions, the maintained Markplane fork, or the maintained Superpowers fork.

## Local Extensions

User extensions live outside the product install directory:

```text
%USERPROFILE%\.research-with-coding-agents\extensions\<extension-name>\
```

Updates and repair operations preserve that directory. Executable extension hooks require explicit approval before activation.

## Platform Status

Windows is the supported first public release target. macOS and Linux source builds and basic Markplane operation are experimental until agent and installer parity are implemented.

## Repository Boundaries

- `components/markplane` is the maintained fork of `zerowand01/markplane`.
- `components/superpowers` is the maintained fork of `obra/superpowers`.
- `packages/project-skills` contains Research With Coding Agents-owned skills.
- `packages/agent-adapters` contains Codex, Claude Code, and Gemini/Antigravity adapters.
- `packages/vscode-extension` contains the Markplane interface extension source.
- `MarkplaneInstaller` contains the current Windows installer implementation.

See `CONTRIBUTING.md`, `UPSTREAM.md`, and `THIRD_PARTY_NOTICES.md` before changing component boundaries or release packaging.
