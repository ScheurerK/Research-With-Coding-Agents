---
id: TASK-u2f8k
title: Publish Research With Coding Agents repository
status: in-progress
priority: high
type: feature
effort: large
epic: null
plan: PLAN-bxt28
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
updated: 2026-08-05
---

# Publish Research With Coding Agents repository

## Description

Restructure the current local package into the public **Research With Coding
Agents** GitHub product. Preserve Markplane and Superpowers as separately licensed,
vendored maintained source snapshots linked to their upstream projects, and provide a unified,
reproducible Windows distribution that supports users from direct installation
through unrestricted source and extension development.

## Acceptance Criteria

- [x] The main GitHub repository is named Research With Coding Agents and documents
  maintained Markplane and Superpowers source trees as vendored snapshots with upstream provenance.
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

- Repair or initialize the invalid root `.git`, then settle and document the component provenance model.
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
- removed submodule checkout assumptions from CI/docs so normal clones include the full source tree.

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
- The component provenance model was still undecided during this audit; it was later settled as vendored source snapshots for the first public release.
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
## GitHub Push 2026-08-05

Published the prepared local release state to GitHub after explicit user approval:

- pushed `main` to `https://github.com/ScheurerK/Research-With-Coding-Agents.git`;
- pushed `v0.1.0` as a new remote tag;
- verified `refs/heads/main` and `refs/tags/v0.1.0` both resolve to `4195977b2cdb44ac024ccbb905a697561cb66180`.

Remaining external publication steps: wait for GitHub Actions/CI on the hosted repository, attach the `dist/` artifacts to the GitHub release if desired, and run a true clean-profile installer smoke test from the published download.
## GitHub CI Fix 2026-08-05

Investigated the first hosted GitHub Actions failures after publication. `gh` was not available locally, and the unauthenticated GitHub API returned 404 for the private/new repository, so diagnosis used the screenshot plus local workflow/test inspection.

Root cause: installer tests derived `$root` through `$MyInvocation.MyCommand.Path`, while the root-level tests already used `$PSScriptRoot`. The GitHub/Pester execution context caused the installer tests to resolve the wrong root, so basic shipped-file checks such as `Install-ClaudeCodeHooks.ps1` and the Antigravity installer files failed immediately.

Fix: changed all installer test root calculations to `$root = Split-Path -Parent $PSScriptRoot`, matching the robust pattern used by the repository-level tests.

Verification:

- `rg -n "MyInvocation\.MyCommand\.Path" installer/windows/tests tests -g "*.ps1"` found no remaining installer/root test usages.
- `Invoke-Pester ./installer/windows/tests/Install-ClaudeCodeHooks.Tests.ps1,./installer/windows/tests/Install-AntigravityIntegration.Tests.ps1` passed: 13 passed, 0 failed.
- `Invoke-Pester ./installer/windows/tests,./tests` passed: 100 passed, 0 failed.

Tag note: because the failing hosted `Windows Release` workflow is tag-triggered, publishing this fix for the already pushed `v0.1.0` release requires either moving the `v0.1.0` tag to the fix commit with explicit approval, or creating a later release tag.
## GitHub Actions Warning Cleanup 2026-08-05

Updated both GitHub Actions workflows from `actions/checkout@v4` to `actions/checkout@v6` after checking the official checkout release information. This addresses the hosted runner warning that Node.js 20 action runtimes are deprecated and avoids carrying that warning into the next release run.
## Pester 5 Root Test Fix 2026-08-05

Investigated the hosted `Repository Hygiene` failure from the attached log. GitHub discovered 14 root tests but 13 failed because `$repoRoot` and related top-level variables were `null` inside `It` blocks.

Root cause: hosted Pester runs discovery and execution in separate phases. Variables initialized at test-file top level are discovery-time state and are not reliably available during the run phase. The first test passed vacuously because its discovery-time array was unavailable during execution, while later tests failed when `Join-Path` received a null root.

Fix: moved root-level test path initialization into `BeforeAll` and stored run-time state in `script:` variables for the five repository test files discovered by the hygiene workflow.

Verification:

- `Invoke-Pester ./tests` passed: 14 passed, 0 failed.
- `Invoke-Pester ./installer/windows/tests,./tests` passed: 100 passed, 0 failed.
## Pester 5 CI Syntax Fix 2026-08-05

Investigated the hosted `Invoke-Pester .\tests` failure from the attached log. Root cause: GitHub Actions was running Pester 5, which rejects the repository's existing Pester 3 legacy `Should` syntax. The local Windows suite uses Pester 3.4.0, so the hosted environment was exercising a different assertion parser.

Fix: both GitHub Actions workflows now install/import Pester 3.4.0 before invoking tests, matching the current test suite. Because Pester 3 does not reliably fail the process by exit code on its own, the workflow calls `Invoke-Pester ... -PassThru` and exits with code 1 when `FailedCount` is greater than zero. Added repository tests that assert this CI contract remains present.

Verification:

- Red check observed: `Invoke-Pester .\tests` failed 13 passed / 1 failed after adding the missing workflow-contract assertions.
- `Invoke-Pester .\tests` passed: 14 passed, 0 failed.
- `Invoke-Pester .\installer\windows\tests,.\tests` passed: 100 passed, 0 failed.
## Dependabot Security Hygiene 2026-08-05

Investigated the GitHub push warning that reported 87 Dependabot vulnerabilities on the default branch. Local npm audit identified the active npm security surface in `components/markplane/crates/markplane-web/ui`: 17 vulnerability groups before remediation, including 11 high severity groups, mostly transitive Markplane Web UI dependencies around Next.js/PostCSS/sharp/Hono/glob tooling.

Fixes:

- Added `.github/dependabot.yml` for weekly grouped updates across the active npm, Cargo, and GitHub Actions dependency manifests.
- Refreshed the Markplane Web UI npm lockfile with current semver-compatible dependency releases.
- Raised the direct Next.js runtime declaration to `next` `^16.3.0`; kept `eslint-config-next` on the prior version to avoid introducing unrelated React Compiler lint-rule churn.
- Replaced `next/font/google` in the Markplane Web UI layout with the already bundled local `geist` package so production builds do not need to fetch Google Fonts.

Verification:

- Red check observed: `Invoke-Pester .\tests\RwcaGithubWorkflow.Tests.ps1` failed before `.github/dependabot.yml` existed.
- `npm ci` passed and reported 0 vulnerabilities.
- `npm audit --audit-level=low` passed and reported 0 vulnerabilities.
- `npm run lint` passed.
- `npm run build` passed with Next.js 16.3.0; only the pre-existing export/rewrites warnings remain.
- `Invoke-Pester .\tests` passed: 15 passed, 0 failed.
- `Invoke-Pester .\installer\windows\tests,.\tests` passed: 101 passed, 0 failed.

Cargo note: local `cargo audit` is not installed on this machine, so Rust advisory status is delegated to GitHub Dependabot and the new Cargo update configuration until a Rust audit tool is added locally or in CI.
## Dependabot PR Triage 2026-08-05

After pushing the Dependabot baseline commit, GitHub created Dependabot PR branches for active manifests:

- Cargo: grouped Markplane Rust minor/patch lockfile update plus separate `tabled 0.21.0` and `tower-http 0.7.0` major-style updates.
- GitHub Actions: `actions/checkout 7` and `actions/upload-artifact 7`.
- npm: grouped Markplane UI minor/patch update plus separate major-style updates for `eslint 10.8.0`, `fractional-indexing 4.0.0`, `@types/node 26.1.2`, and `typescript 7.0.2`.

Decision: do not merge all Dependabot PRs blindly. Treat grouped minor/patch PRs as first candidates after their CI passes. Keep major-style PRs separate for compatibility review. Discarded the local uncommitted exploratory `Cargo.lock` refresh so Cargo changes remain represented by Dependabot PRs instead of being mixed into `main`.

## Blogpost Claim Review 2026-08-05

Reviewed the attached draft blogpost against the current public repo docs and tracking state. Main publication-facing corrections: describe the package as Research With Coding Agents rather than still unnamed; keep macOS/Linux framed as experimental source/basic Markplane support rather than generally available; avoid implying the Windows installer has completed a clean-profile install/repair/update/uninstall smoke test; clarify that Markplane creates persistent project state, not a temporary structure; and state that bundled Markplane/Superpowers copies are modified, licensed third-party vendored source snapshots without upstream endorsement.

## Fork/Submodule Clarification 2026-08-05

Confirmed that the GitHub upload published the main Research With Coding Agents repository, but no Git submodules are configured (`git submodule status` is empty). Option A was selected: Markplane and Superpowers remain shipped as vendored source snapshots under `components/`, with upstream provenance documented instead of requiring submodule checkout.

## Vendored Snapshot Decision 2026-08-05

Implemented Option A as the public component model. The root README, CONTRIBUTING guide, component README, upstream policy, third-party notices, and provenance test now describe Markplane and Superpowers as vendored maintained source snapshots. Submodules are no longer a required acceptance criterion for the first public release; any future conversion must update installer, CI, release packaging, and contributor docs in the same change.

## Dependabot Batch Resolution 2026-08-05

Created a local Dependabot batch branch and merged the compatible updates: GitHub Actions `checkout@v7` and `upload-artifact@v7`, Cargo Markplane Rust minor/patch plus `tabled 0.21` and `tower-http 0.7`, npm Markplane UI minor/patch, `fractional-indexing 4`, and `@types/node 26`. Tested npm major PRs for `typescript 7` and `eslint 10`; both are incompatible with the current Next/eslint-config-next/typescript-eslint toolchain, so they were excluded and future semver-major Dependabot PRs for those packages were ignored.

## Dependabot Batch Push 2026-08-05

Merged the tested `rwca/dependabot-batch` branch into `main` and pushed `65694fc` to GitHub. Eight Dependabot branch heads are now ancestors of `main`: GitHub Actions checkout/upload-artifact, Cargo minor/patch plus tabled/tower-http, npm UI minor/patch, fractional-indexing, and @types/node. The ESLint 10 and TypeScript 7 branches remain intentionally unmerged because local verification showed incompatibilities with the current Next/eslint-config-next/typescript-eslint stack.

## Brand Logo Assets 2026-08-05

Added the project-owner-provided Research With Coding Agents logo as repository brand assets under `assets/brand/`: primary README logo, transparent line-art variant, and square icon. README now displays the primary logo and distribution-readiness tests assert that the referenced brand files exist.

## GitHub Release Publish Enablement 2026-08-05

User noticed a `v0.1.0` tag existed on GitHub but no Release with the installer `.exe` was attached. Root cause: `windows-release.yml` only uploaded `dist\` as a transient Actions artifact via `actions/upload-artifact`; no step ever created a GitHub Release or attached assets to it, despite `README.md` explicitly telling users to "Download `ResearchWithCodingAgentsSetup-v0.1.0.exe` from a release."

Fix (commit `e59ca92`, pushed to `main`): added `contents: write` job permission and a `softprops/action-gh-release@v2` step guarded to `v*` tag pushes that attaches all of `dist/*` (setup exe, portable zip, SBOM, checksums) with auto-generated release notes.

Moved the `v0.1.0` tag to `e59ca92` and force-pushed it to re-trigger the workflow on the fixed definition. The hosted run then failed at the pre-existing test step (98 passed, 3 failed), so the release step never executed.

## GitHub Actions Release Test Fix 2026-08-05

Investigated the 3 test failures from the hosted `Windows Release` run using the attached CI log. Reproduced and verified each root cause locally on Windows PowerShell 5.1 (Pester 3.4.0) before changing anything:

- `installer\windows\markplane.exe` is a prebuilt binary intentionally excluded from git (matches this repo's own "no committed build artifacts" governance test) and was never provisioned in CI, so the two Antigravity hook contract tests that shell out to it failed with "The system cannot find the file specified." Fix: added a `windows-release.yml` step that downloads the official `zerowand01/markplane` `v0.1.2` Windows release zip, verifies its SHA256 against the published `checksums-sha256.txt`, and extracts `markplane.exe` into `installer\windows\` before tests and the installer build run.
- `Invoke-MarkplaneAntigravityHook.Tests.ps1`'s test helper redirected the native `powershell.exe` subprocess's stderr with `2> $stderrPath`. Confirmed by direct reproduction: Windows PowerShell 5.1 wraps native stderr lines in `NativeCommandError` records, and under `$ErrorActionPreference = "Stop"` (GitHub Actions' default for `shell: powershell` steps, also reproduced directly) that turns even expected diagnostic stderr output into a terminating exception instead of plain text in the redirect file. Fix: wrap the native call with `$ErrorActionPreference = "Continue"` / restore, matching the existing pattern already used in `Install-VSCodeExtension.ps1`.
- `Install-MarkplaneAgentSkills.Tests.ps1`'s idempotency test passed `-SkipTelemetry` to the installer call (to avoid touching the real `HKCU` registry during tests) but not to the following health-check call, so the health check's telemetry-env-var assertion only passed on machines that already had `SUPERPOWERS_DISABLE_TELEMETRY=1` set globally (true on the dev machine per its own global Claude Code instructions, false on a clean CI runner). Fix: pass `-SkipTelemetry` to the health check too, matching the installer call's scope.

Verification:

- Reproduced all three failures standalone before fixing (missing-exe exception, EAP=Stop turning expected stderr into a terminating RemoteException, and the telemetry env-var assertion depending on ambient machine state).
- Downloaded and SHA256-verified the real `markplane-v0.1.2-x86_64-pc-windows-msvc.zip` and ran the two Antigravity hook scenarios against it standalone with the EAP fix applied: all assertions passed.
- `Invoke-Pester .\installer\windows\tests,.\tests` passed: 101 passed, 0 failed (default `$ErrorActionPreference`).
- Re-ran the same full suite under `$ErrorActionPreference = "Stop"` (mirroring GitHub Actions' PowerShell step default) to validate against the exact failure mode observed in CI: 101 passed, 0 failed.

Committed as `900d90a` on `main`, then moved `v0.1.0` to `900d90a` and force-pushed the tag to re-trigger the hosted `Windows Release` workflow with the fixes.

Remaining: confirm the hosted run now passes end-to-end and that the GitHub Release for `v0.1.0` is created with `ResearchWithCodingAgentsSetup-v0.1.0.exe` and the other `dist/` assets attached.

**Correction (see "Vendored Fork Correction" below): the `markplane.exe` fetch step described above downloaded the unmodified upstream binary. That is wrong for this repository, which ships a modified fork — see below.**

## Antigravity Visual Panel 404 Root Cause 2026-08-05

User relayed a bug report from a colleague (different machine, `schwarze` user) who used this project's installer with Antigravity: the Markplane visual panel/webview loaded blank. The colleague's own agent diagnosed it correctly: `markplane.exe serve` returns HTTP 404 for `/` and `/graph` because the binary was built without embedding the web UI (`crates/markplane-web/ui/out` not compiled in via the `embed-ui` Cargo feature), so the IDE's iframe has nothing to load. CLI/task-tracking/MCP functionality is unaffected — this is scoped to the visual panel only.

Reproduced directly:

- The official upstream `zerowand01/markplane` `v0.1.2` Windows release binary: `Serving embedded UI from binary`, `GET /` and `GET /graph` both `200`.
- This machine's existing local `installer\windows\markplane.exe` (untracked, used to package any locally-built installer): `Serving static UI from crates/markplane-web/ui/out/`, both routes `404` — exact match for the colleague's bug. Confirms it was built via a plain `cargo install --path crates/markplane-cli` without `--features embed-ui`.
- No test in the 100+ test Pester suite ever called `markplane serve` or checked its HTTP responses — a real coverage gap that let this ship unnoticed.
- `installer/windows/README.md` documents `markplane.exe` as a prerequisite ("prebuilt Markplane binary with embedded web UI") but never states *how* to build one, which is how a plain `cargo install` (the simpler of the two commands documented in `components/markplane/CLAUDE.md`) could end up there.

## Vendored Fork Correction 2026-08-05

While proposing a CI fix for the above, the user pointed out that this repository does **not** ship stock upstream Markplane — `components/markplane` is their own lightly modified fork (confirmed: real independent dependency-version history via Dependabot, e.g. `tabled 0.21.0`/`tower-http 0.7.0`, diverging from whatever upstream `v0.1.2` pinned). `UPSTREAM.md`'s own "Vendored Snapshot Rule" already states network downloads must not replace the vendored source at install/repair/release-packaging time.

This means the earlier same-day fix (downloading the official `zerowand01/markplane` `v0.1.2` release binary in CI to unblock the test suite) was solving the immediate CI failure but shipping the **wrong binary** — unmodified upstream instead of this repo's own fork. The currently published `v0.1.0` GitHub Release (created earlier today from that CI run) therefore ships upstream's unmodified `markplane.exe`, not this project's fork.

Fix: replaced the CI "download prebuilt exe" step with a real build-from-source step in `.github/workflows/windows-release.yml`:

- `actions/setup-node@v4` (Node 20, npm-cached) + `npm ci && npm run build` in `components/markplane/crates/markplane-web/ui` to produce the static export.
- `Swatinem/rust-cache@v2` for the Cargo build cache.
- `rustup update stable` (workspace MSRV is `1.93.0`) then `cargo build --release --features embed-ui -p markplane-cli` from `components/markplane`, copying the resulting `target\release\markplane.exe` to `installer\windows\markplane.exe` before tests and installer packaging run.

Verified locally end-to-end (real build, not simulated): `npm ci` + `npm run build` produced `out/` including `/graph`; `cargo build --release --features embed-ui -p markplane-cli` finished in ~2m34s; the resulting binary reported `Serving embedded UI from binary` and returned `200` for both `/` and `/graph`.

Added a regression test, `installer/windows/tests/MarkplaneWebUi.Tests.ps1`, that starts `markplane.exe serve` on an ephemeral port against a scratch project and asserts `/` and `/graph` both return `200`. Verified RED/GREEN in isolated sandboxes: fails (404) against the known-broken local exe, passes (200) against the properly-built one — so CI will now catch this regression class going forward. Per explicit user decision, the local untracked `installer\windows\markplane.exe` dev artifact on this machine was left as-is (not replaced), so the local full Pester run now shows 102 passed / 1 failed (only this new test, expected); it will pass in CI, which builds a fresh embed-ui binary before running tests.

**Outstanding**: the live `v0.1.0` GitHub Release currently ships the wrong (unmodified upstream) `markplane.exe` built by the now-superseded CI step. Needs a re-run of the fixed workflow (move+push the `v0.1.0` tag again, or cut a new tag) to publish a release built from this repo's actual fork before this is safe to point real users at.

Committed the build-from-source fix, the new `MarkplaneWebUi.Tests.ps1` regression test, and both plan fixes as `796ac42`, pushed to `main`. Moved `v0.1.0` to `796ac42` and force-pushed the tag to rebuild and republish the release from this repo's actual fork. This run is slower than prior ones (real `npm ci`/`npm run build`/`cargo build --release` instead of a network download), so it takes several minutes longer to complete.

Remaining: confirm the hosted run passes (now exercising the new web UI regression test too) and that the republished `v0.1.0` Release asset actually serves the embedded UI when installed.

## CI Build-Artifact Cleanup Fix 2026-08-05

The `796ac42` hosted run confirmed the new web UI regression test passes in CI (embedded UI, real 200s) but then failed two governance tests: `does not contain local workspace metadata or component build artifacts` and `passes the distribution readiness script` ("Forbidden local or generated file exists: components\markplane\target"). The `cargo build --release --features embed-ui` step now leaves a `target\` directory behind, which `scripts\Test-RwcaDistributionReadiness.ps1`'s forbidden-paths list correctly rejects — this exact issue was hit and self-resolved locally earlier the same session by deleting the directory after use.

Fix: added `Remove-Item -LiteralPath "components\markplane\target" -Recurse -Force` to the end of the "Build markplane.exe from vendored source" workflow step, right after `markplane.exe` is copied out to `installer\windows\markplane.exe`, so the forbidden path never reaches the later Pester run. Removed the `Swatinem/rust-cache@v2` step added earlier: its cache-save runs as a post-job hook at the very end of the job, after `target\` has already been deleted mid-job, so it could never actually persist anything — keeping it would have been a no-op that looked like an optimization.

Verified locally: rebuilt `components\markplane` with `--features embed-ui`, deleted `target\` the same way the new CI step does, then re-ran `tests\RwcaDistributionReadiness.Tests.ps1` and `tests\RwcaProvenance.Tests.ps1` directly (9/9 passed) and the full suite (`Invoke-Pester .\installer\windows\tests,.\tests`: 102 passed, 1 failed — only the expected local-exe web UI test, per the standing decision not to touch that untracked file).
