---
id: TASK-u2f8k
title: Publish Research With Coding Agents repository
status: in-progress
priority: high
type: feature
effort: large
epic: null
plan: null
depends_on: []
blocks: []
related: []
assignee: scheurer
tags:
- github
- distribution
- licensing
position: aU
created: 2026-08-04
updated: 2026-08-04
---

# Publish Research With Coding Agents repository

## Description

Restructure the current local package into the public **Research With Coding
Agents** GitHub product. Preserve Markplane and Superpowers as separately licensed,
officially linked forks pinned by the main repository, and provide a unified,
reproducible Windows distribution that supports users from direct installation
through unrestricted source and extension development.

## Acceptance Criteria

- [ ] The main GitHub repository is named Research With Coding Agents and pins the
  maintained Markplane and Superpowers forks as submodules.
- [ ] One tested Windows setup executable installs, repairs, updates, verifies, and
  uninstalls the required core plus optional agent and IDE integrations.
- [x] The bundled customized Superpowers revision is authoritative for Codex,
  Claude Code, and Gemini/Antigravity without deleting foreign installations.
- [x] Markplane UI deployment uses a build-produced VSIX and official IDE CLI
  installation, with no source-folder copy fallback.
- [ ] Public source, extension interfaces, build instructions, contribution paths,
  licenses, provenance, checksums, and an SBOM are complete and verified by CI.
- [ ] Windows behavior is fully tested and macOS/Linux support is explicitly marked
  experimental where parity is not implemented.
## Notes

The design is approved in conversation and awaiting review as a written spec. The
current workspace root contains an invalid/empty `.git` directory, so the design
cannot be committed until the public repository is initialized or restored.

## References

- `docs/superpowers/specs/2026-08-04-research-with-coding-agents-public-repository-design.md`
- `docs/superpowers/specs/2026-08-04-antigravity-superpowers-parity-design.md`
## Progress 2026-08-04

Implemented the local public repository foundation and unified Windows release path:

- Added root public docs, Apache-2.0 main license, third-party notices, license files, component/package/extension docs, GitHub workflows, and issue/PR templates.
- Renamed the primary Inno installer identity to Research With Coding Agents and changed the output to `ResearchWithCodingAgentsSetup-v0.1.0.exe` under `%LOCALAPPDATA%\Programs\ResearchWithCodingAgents\`.
- Made the bundled customized Superpowers authority explicit for Codex, Claude Code, and Gemini/Antigravity while preserving foreign Superpowers copies.
- Verified Markplane UI extension deployment remains VSIX-only through official IDE CLIs with `--install-extension <vsix> --force`.
- Added machine-readable provenance, distribution-readiness checks, release artifact builder, SHA-256 checksums, and SPDX SBOM generation.
- Built the real installer at `MarkplaneInstaller\Output\ResearchWithCodingAgentsSetup-v0.1.0.exe` and generated `dist\ResearchWithCodingAgentsSetup-v0.1.0.exe`, `dist\ResearchWithCodingAgentsPortable-v0.1.0-win-x64.zip`, `dist\SHA256SUMS.txt`, and `dist\SBOM.spdx.json`.

Verification:

- `Invoke-Pester .\MarkplaneInstaller\tests, .\tests` passed: 97 passed, 0 failed.
- `markplane sync` passed.
- `markplane check` passed.
- `.\MarkplaneInstaller\Build-Installer.ps1` passed after sandbox escalation to access Inno Setup.
- `.\scripts\Build-RwcaRelease.ps1 -SkipInstallerBuild` passed.

Remaining before closing this task:

- Repair or initialize the invalid root `.git`, then create/pin the real GitHub fork submodules.
- Run a true clean-profile install/repair/update/uninstall smoke test against the generated setup executable.
- Push to GitHub and let the workflows run on the real repository.
## Git Publication Progress 2026-08-04

Initialized the workspace as a valid local Git repository on branch `main`, staged non-ignored project files, created initial commit `5a7093a` (`Initial Research With Coding Agents package`), and added local tag `v0.1.0`.

`gh` is not installed on this machine, so GitHub repository creation and authenticated push cannot be completed automatically through the GitHub CLI in this session. Next step is to create an empty GitHub repository named `research-with-coding-agents`, add it as `origin`, then push `main` and `v0.1.0`.

## Restructure Progress 2026-08-04

Restructured the repository so GitHub users see the intended source layout directly in a normal clone:

- moved Markplane source from `markplane-master/` to `components/markplane/`;
- moved the authoritative customized Superpowers tree from `MarkplaneInstaller/skills/` to `components/superpowers/skills/`;
- moved Windows packaging from `MarkplaneInstaller/` to `installer/windows/`;
- moved Markplane UI extension source to `packages/vscode-extension/source/`;
- moved agent hooks and MCP templates to `packages/agent-adapters/`;
- moved packaged project skill source to `packages/project-skills/`;
- updated README, CONTRIBUTING, upstream/provenance docs, workflows, release scripts, tests, and specs for the new layout;
- removed current submodule checkout assumptions from CI/docs until public fork remotes are attached.

Verification after restructure:

- `Invoke-Pester .\installer\windows\tests,.\tests` passed: 98 passed, 0 failed.
- `.\installer\windows\Build-Installer.ps1` passed after sandbox escalation to access Inno Setup and produced `installer\windows\Output\ResearchWithCodingAgentsSetup-v0.1.0.exe`.
- `.\scripts\Build-RwcaRelease.ps1 -SkipInstallerBuild` passed and refreshed `dist\ResearchWithCodingAgentsSetup-v0.1.0.exe`, portable ZIP, checksums, and SBOM.

Remaining blockers before marking this task done: create/attach the real GitHub remote, push, let CI run, and perform a true clean-profile installer install/repair/update/uninstall smoke test.
## Cross-Repo Markplane Smoke 2026-08-04

Verified the global Markplane CLI in an isolated directory outside this repository:

- created `C:\tmp\rwca-markplane-other-repo-smoke-de55c6fd26c64729951a667757abc8e9`;
- ran `markplane init --name OtherRepo --empty`;
- ran `markplane sync`;
- ran `markplane check`;
- result: all commands passed, then the temporary directory was removed.

This confirms the normal Markplane call still works for another initialized project. The agent integrations remain project-scoped: Antigravity workspace MCP uses `markplane mcp --project <project-root>` with `cwd` set to that root, and hooks discover the nearest `.markplane` root from the event `cwd`.

## Publication Readiness Audit 2026-08-04

Fresh audit result: not ready for a clean public release yet, but close for a local/private handoff.

Verified:

- `markplane sync` passed.
- `markplane check` passed.
- `Invoke-Pester .\installer\windows\tests,.\tests` passed: 98 passed, 0 failed.
- README, UPSTREAM, and THIRD_PARTY_NOTICES describe the Research With Coding Agents identity and component provenance.
- Release artifacts exist in `dist\`: setup exe, portable zip, checksums, and SPDX SBOM.

Blocking before public release:

- No GitHub remote is configured, so CI has not run on GitHub and the package has not been pushed.
- Worktree is dirty: `.markplane/backlog/items/TASK-u2f8k.md` has uncommitted tracking updates.
- `.agents/mcp_config.json` is tracked and contains local absolute paths under `<repo-root>\...`, including the old `MarkplaneInstaller` path. This must not ship as public repo config.
- `components/markplane/.markplane/` and `components/markplane/.claude/` are tracked from the embedded upstream source tree. Decide whether to keep them intentionally as upstream project metadata or remove them from the product source snapshot before public release.
- The acceptance criterion for real public fork/submodule pinning is still unresolved: current docs say source snapshot until public fork remote is attached.
- A true clean-profile install/repair/update/uninstall smoke test against the generated setup executable is still outstanding.

Non-blocking cleanup:

- `installer/windows/Output` still contains old ignored Markplane-named setup outputs next to the new Research With Coding Agents setup output.
- Some historical plan/task notes contain local absolute paths; not runtime-breaking, but noisy for a public repo.


## Public Repo Hygiene Cleanup 2026-08-04

Removed files that should not be published as part of the public Research With Coding Agents repository:

- root `.agents/mcp_config.json` with local absolute Antigravity MCP paths;
- embedded `components/markplane/.markplane/` upstream working state;
- embedded `components/markplane/.claude/` local Claude helper state;
- embedded `components/markplane/.github/` upstream workflow/release metadata that is not active inside this monorepo;
- obsolete tracked `components/markplane/Install-MarkplaneForCodex.ps1` in favor of `installer/windows/Install-MarkplaneForCodex.ps1`;
- local ignored build/bootstrap artifacts under `components/markplane/target`, `components/markplane/rustup-init.exe`, `components/markplane/.DS_Store`, and `installer/windows/Output`.

Additional cleanup:

- added `.gitignore` guards for root `.agents/` and embedded component `.markplane`, `.claude`, and `.github` directories;
- translated both `research-checkpoint-commits` README copies to English;
- changed Windows installer default install paths and hook state roots from `Programs\Markplane` / `%LOCALAPPDATA%\Markplane` to `ResearchWithCodingAgents` paths;
- added distribution-readiness checks that reject the removed local metadata, generated artifacts, and local absolute machine paths in public files.

Verification:

- `Invoke-Pester .\tests\RwcaDistributionReadiness.Tests.ps1` passed: 6 passed, 0 failed.
- `Invoke-Pester .\installer\windows\tests,.\tests` passed: 100 passed, 0 failed.

## Follow-Up Hygiene Audit 2026-08-04

Additional read-only audit after the local-path cleanup:

- no large tracked files over 1 MiB remain in the working tree;
- no credential-like patterns were found, except the expected local variable name `token` in UI source code;
- the remaining `markplane-master` strings are distribution-readiness guard patterns, not real local paths;
- the deleted `.agents`, embedded `.markplane`, embedded `.claude`, embedded `.github`, and obsolete component installer paths still appear in `git ls-files --deleted` until the cleanup commit is made, but the files/directories no longer exist in the working tree;
- corrected three stale macOS installer comments that still referenced the old `MarkplaneInstaller` path;
- added `.sh text eol=lf` to `.gitattributes` so macOS shell scripts remain LF-normalized.

Verification:

- `git diff --check` passed.
- `Invoke-Pester .\tests\RwcaDistributionReadiness.Tests.ps1` passed: 6 passed, 0 failed.
- `markplane sync` and `markplane check` passed.
## Final Local Publication Prep 2026-08-04

Prepared the local repository state for publication handoff:

- refreshed release artifacts with `./scripts/Build-RwcaRelease.ps1 -SkipInstallerBuild` after the final installer build;
- removed the regenerated local `installer/windows/Output` build directory so the public working tree stays clean;
- verified the distribution-readiness guard rejects local metadata, build artifacts, and local absolute machine paths;
- verified the full installer/project Pester suite.

Final verification:

- `git diff --check` passed.
- `Invoke-Pester ./tests/RwcaDistributionReadiness.Tests.ps1` passed: 6 passed, 0 failed.
- `./scripts/Test-RwcaDistributionReadiness.ps1` passed.
- `Invoke-Pester ./installer/windows/tests,./tests` passed: 100 passed, 0 failed.

Release artifact hashes in `dist/`:

- `ResearchWithCodingAgentsSetup-v0.1.0.exe`: `385A50D2F5D4159BC7CD6A05A6952CC68F3FBD2F6C46623B90020142E291B4F2`
- `ResearchWithCodingAgentsPortable-v0.1.0-win-x64.zip`: `64D5E5454505BE9D7C26E4BF2B2333E2816D8E97C5138770AEC9FF129A245D80`
- `SBOM.spdx.json`: `F86A2EA7207D4632403594BDA9A02C3BB0BC4A00F31DE5D8C6CB44A7F9315EBF`

Remaining external publication steps: push the final local commit/tag to the configured GitHub remote, let CI run there, attach/upload the `dist/` release artifacts, and perform a true clean-profile setup/repair/update/uninstall smoke test on the published installer.
