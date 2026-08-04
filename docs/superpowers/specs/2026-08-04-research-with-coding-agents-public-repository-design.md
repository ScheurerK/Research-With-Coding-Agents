# Research With Coding Agents Public Repository Design

**Status:** Approved design, pending written-spec review
**Markplane task:** `TASK-u2f8k`

## Context

The current workspace combines a Markplane source snapshot, two Windows
installers, a customized Superpowers distribution, project-specific research
skills, agent hooks, and a Markplane VS Code extension. It works as a local
package, but its outer directory is not a valid Git repository and its ownership,
license, build, and extension boundaries are not yet suitable for public GitHub
distribution.

The public product is named **Research With Coding Agents**. Markplane is a core
component, not the name of the complete product. The project must prioritize its
own tested Markplane and Superpowers revisions while retaining an explicit,
maintainable relationship with both upstream projects.

## Goals

- Let a Windows user install, update, repair, verify, and uninstall the complete
  product through one release installer.
- Let advanced users clone the source, inspect every shipped component, build it,
  change it, and contribute at any depth.
- Keep the customized Markplane and Superpowers revisions authoritative at runtime.
- Preserve each upstream project's history, license, attribution, and contribution
  path.
- Expose a stable local extension mechanism without allowing installers or updates
  to overwrite user extensions.
- Provide reproducible releases with exact component commits, checksums, licenses,
  an SBOM, and automated quality gates.
- Keep operation local and telemetry-free by default.

## Non-Goals

- Renaming Markplane or Superpowers inside their own fork repositories.
- Hiding fork provenance or representing modified components as official upstream
  releases.
- Downloading Markplane, Superpowers, Node.js packages, or extension sources while
  an end-user installer is running.
- Guaranteeing full macOS or Linux agent integration in the first public release.
- Automatically merging upstream changes into either maintained fork.
- Automatically executing third-party extension hooks merely because an extension
  directory exists.

## Repository Topology

The project uses three GitHub repositories:

1. `research-with-coding-agents` is the product, integration, packaging,
   documentation, and release repository.
2. `markplane` is the maintainer's GitHub fork of `zerowand01/markplane`. GitHub's
   fork relationship remains visible and the fork retains Markplane's Apache-2.0
   license and upstream history.
3. `superpowers` is the maintainer's GitHub fork of `obra/superpowers`. GitHub's
   fork relationship remains visible and the fork retains Superpowers' MIT license
   and upstream history.

The main repository pins reviewed fork commits through Git submodules:

```text
research-with-coding-agents/
|-- components/
|   |-- markplane/              # Git submodule: maintained Markplane fork
|   `-- superpowers/            # Git submodule: maintained Superpowers fork
|-- packages/
|   |-- project-skills/         # Research With Coding Agents-owned skills
|   |-- agent-adapters/         # Codex, Claude Code, Gemini/Antigravity adapters
|   `-- vscode-extension/       # Markplane interface extension source
|-- extensions/                 # Examples, manifest schema, and authoring fixtures
|-- installer/
|   `-- windows/                # Unified Inno Setup installer and scripts
|-- scripts/                    # Build, verification, release, and provenance tools
|-- tests/                      # Cross-component and distribution tests
|-- docs/                       # User, contributor, architecture, and upstream docs
|-- .github/                    # CI, release workflows, and contribution templates
|-- LICENSE                     # Apache License 2.0 for the main repository
|-- LICENSES/                   # Unmodified third-party license texts
|-- THIRD_PARTY_NOTICES.md
`-- README.md
```

Consumers clone with `git clone --recurse-submodules`. A missing or dirty submodule
is a build error for release workflows. The main repository never duplicates full
component source trees outside the submodules.

## Product Boundaries

### Required Core

Every standard installation contains:

- the Markplane CLI, MCP server, and web UI;
- the project's pinned, customized Superpowers distribution;
- Research With Coding Agents-owned research skills;
- shared hook, configuration, migration, and health-check infrastructure;
- license, provenance, update, repair, and uninstall metadata.

The core is installed under
`%LOCALAPPDATA%\Programs\ResearchWithCodingAgents\`. It is versioned as one tested
product even though component versions and commits remain separately visible.

### Optional Integrations

Installer options connect the core to environments already present on the user's
machine:

- Codex;
- Claude Code;
- Gemini/Antigravity;
- the Markplane VS Code/Antigravity interface.

An integration can be omitted or added later without changing the core package.
Omitting an integration means only that its agent configuration, lifecycle hooks,
or IDE extension are not registered. The bundled skills and shared runtime remain
installed.

## Authoritative Component Policy

The exact Markplane and Superpowers commits pinned by the main repository are the
only versions copied into a release. Installation and repair use these local
payloads and never replace them from the network.

Managed Codex, Claude Code, and Gemini/Antigravity instructions identify the
Research With Coding Agents copy as authoritative. This rule is always installed;
it resolves a real conflict when another Superpowers copy was installed before or
is installed later. Foreign copies are reported but not deleted.

Each release records:

- the main repository tag and commit;
- both submodule commit IDs and upstream repository URLs;
- component versions;
- source and binary hashes;
- test and platform status.

## Licensing And Provenance

The main repository uses Apache License 2.0. Files copied or adapted from another
project retain applicable notices and are not silently relicensed.

- Markplane remains Apache-2.0 and names `zerowand01/markplane` as upstream.
- Superpowers remains MIT, includes its complete MIT license and copyright notice,
  and names `obra/superpowers` as upstream.
- The modified Superpowers distribution is described as a project-maintained fork,
  not as an official upstream release, and no upstream endorsement is implied.
- Research repository governance material and every other third-party component
  retain their own license and attribution.

`THIRD_PARTY_NOTICES.md` maps each bundled component to its upstream URL, pinned
commit, local path, modifications, copyright, and license file. `LICENSES/`
contains the corresponding unmodified license texts. The source archive, portable
archive, and Windows installer include these files. CI fails when a shipped
component lacks provenance, a license mapping, or a resolvable pinned commit.

## Windows Distribution

The first public release publishes:

```text
ResearchWithCodingAgentsSetup-v0.1.0.exe
ResearchWithCodingAgentsPortable-v0.1.0-win-x64.zip
SHA256SUMS.txt
SBOM.spdx.json
```

The setup executable is the single supported Windows installer. The existing
separate Markplane and agent installers become internal build inputs or are removed
once equivalent behavior is covered. The portable archive supports inspection and
manual use without claiming full automatic agent registration.

The release build:

1. checks out both submodules recursively at pinned commits;
2. builds the Markplane CLI, MCP server, and web UI;
3. validates and packages the customized Superpowers tree and project skills;
4. packages the interface extension as a VSIX in the controlled build environment;
5. runs Rust, UI, PowerShell, extension, installer, license, and provenance tests;
6. builds the unified Inno Setup executable;
7. produces checksums and an SPDX SBOM;
8. publishes only when all required Windows gates pass.

Early releases may be unsigned but must publish checksums and clearly report that
status. The pipeline supports adding code signing without changing artifact names
or installation semantics.

## Installation, Update, Repair, And Uninstall

The installer performs preflight detection for supported agents, IDE CLIs, existing
managed installations, conflicting Superpowers copies, and prerequisites. It shows
optional integrations based on detected environments while allowing explicit user
selection.

Installation is transactional at the product level:

- payloads are staged before replacing the active version;
- only clearly delimited managed configuration blocks are edited;
- previous managed files are backed up until verification succeeds;
- a failed installation restores the prior working product and managed blocks;
- component-specific diagnostics are written to a local installation log.

Updates use the same path and preserve local extensions. Repair reinstalls pinned
core files, reconciles managed integration blocks, and re-registers selected IDE
extensions without touching unrelated configuration.

The Markplane interface is packaged as a VSIX and installed only through official
IDE CLIs using `--install-extension <vsix> --force`. Antigravity uses
`antigravity-ide.cmd`; VS Code uses `code`. A successful command is verified by
extension ID. Direct extension-folder copying is not a fallback. Users with an
open IDE are told to run `Developer: Reload Window` after successful registration.

Uninstall removes the product directory, managed agent blocks, project-owned
global hooks, and the IDE extension through each available IDE CLI. It preserves
project `.markplane` directories, user-authored local extensions, unrelated agent
configuration, and foreign Superpowers installations. An explicit separate option
may remove product-level caches and settings, but never project research data.

## Local Extension Model

User extensions live outside the installation directory:

```text
%USERPROFILE%\.research-with-coding-agents\extensions\<extension-name>\
|-- extension.yaml
|-- skills/
|-- adapters/
|-- hooks/
|-- README.md
`-- LICENSE
```

`extension.yaml` declares a stable extension name, version, author, license,
compatible product version range, provided skills/adapters/hooks, and any explicit
core replacements. Empty capability directories may be omitted.

The extension manager supports list, validate, enable, disable, and health-check
operations. Installation and product updates never overwrite this directory.

Bundled core skills are authoritative. An extension may add new names without
special approval. Replacing a core name requires an explicit `replaces` declaration
and a visible user approval. Executable hooks also require explicit approval before
their first activation; cloning or extracting an extension never executes code.
Health checks report duplicate names, missing licenses, unsupported product
versions, invalid manifests, and unapproved hooks.

The repository includes two maintained examples: one minimal skill-only extension
and one complete adapter extension. Extension interfaces and compatibility rules
are versioned and documented so users can grow from local customization to a
separately maintained extension repository.

## Security And Privacy

- `SUPERPOWERS_DISABLE_TELEMETRY=1` remains the default for managed Codex and Claude
  Code sessions.
- The installer does not start the visual Superpowers companion in a way that loads
  external branding or telemetry assets.
- Runtime installation, repair, and health checks do not fetch executable code.
- Third-party extension hooks are disabled until approved and remain individually
  revocable.
- Logs stay local and avoid recording prompts, research content, secrets, or full
  environment dumps.
- Release artifacts publish checksums and an SBOM; code signing can be added later.
- `SECURITY.md` defines private vulnerability reporting and supported versions.

## CI And Release Governance

Pull requests run recursive submodule validation, formatting, linting, unit tests,
integration tests, extension schema tests, VSIX packaging tests, PowerShell parser
and Pester tests, and an isolated installer smoke test. Repository hygiene checks
reject tracked build outputs, dependency directories, secrets, large unintended
binaries, missing notices, and inconsistent product naming.

Release workflows run only from a version tag through an explicit release gate.
They rebuild all artifacts from source and record exact component commits. A clean
temporary Windows profile verifies install, health check, repair, update behavior,
VSIX registration through fake or isolated IDE CLIs, and uninstall isolation.

Windows is fully supported in the first public release. macOS and Linux source
builds and basic Markplane operation are documented as experimental; their CI may
verify portable source components but must not claim complete agent or installer
parity.

Automated jobs may report new upstream Markplane and Superpowers commits, but never
merge them. Maintainers review and test changes in the relevant fork first. The
main repository then receives a separate pull request updating one submodule
pointer and its provenance record.

## Documentation And Contribution Flow

The root `README.md` starts with the shortest supported Windows installation and
verification path, then links to deeper material. Public documentation includes:

- getting started and first health check;
- integration behavior for Codex, Claude Code, and Gemini/Antigravity;
- update, repair, and uninstall behavior;
- local extension authoring and compatibility rules;
- architecture and repository boundaries;
- reproducible source builds and release verification;
- fork synchronization and contributing changes back upstream.

`CONTRIBUTING.md` gives recursive clone, prerequisite, build, test, and pull request
commands. `UPSTREAM.md` documents remotes and the review process for both forks.
`SECURITY.md`, a code of conduct, issue templates, and pull request templates cover
normal public collaboration. Contributors can work only in the main repository,
only in one component fork, or across all three without flattening their histories.

## Error Handling

- Missing or uninitialized submodule: fail with the exact path and recursive clone
  command.
- Dirty or unrecorded component state in a release: fail before building artifacts.
- Missing license or provenance record: fail CI and identify the component.
- Existing foreign Superpowers copy: warn, preserve it, and keep the pinned project
  copy authoritative.
- Missing agent or IDE CLI: skip only that optional integration and continue with
  the selected supported components.
- VSIX CLI failure or missing registered extension ID: fail that integration and
  preserve its previous working registration.
- Invalid foreign configuration: stop before overwriting and retain the original
  file with an actionable diagnostic.
- Invalid local extension: keep it disabled and report manifest, compatibility, or
  approval failures without blocking the core product.
- Failed update: restore the previous core and managed configuration, preserve the
  log, and return a nonzero exit status.

## Acceptance Criteria

- GitHub presents one clearly named Research With Coding Agents product repository
  with Markplane and Superpowers pinned as official fork submodules.
- A new Windows user can install the required core and selected integrations from
  one offline setup executable and pass the health check.
- Codex, Claude Code, and Gemini/Antigravity use the bundled customized Superpowers
  version even when another copy exists, without deleting that copy.
- The Markplane interface is packaged during release and registered through VSIX
  CLI installation, never by direct folder copy.
- Update and repair preserve user extensions and unrelated configuration; uninstall
  preserves project `.markplane` data and removes only managed integration state.
- A contributor can clone recursively, build, test, modify, and propose changes at
  the product, Markplane fork, Superpowers fork, or local extension level.
- Every binary release includes component provenance, complete applicable licenses,
  checksums, and an SPDX SBOM.
- CI detects missing provenance, license omissions, component drift, installer
  regressions, extension conflicts, and unintended generated or secret files.
- Windows support is explicit and tested; macOS/Linux limitations are explicit and
  not overstated.

## References

- Markplane upstream: https://github.com/zerowand01/markplane
- Superpowers upstream: https://github.com/obra/superpowers
- Superpowers MIT license: https://github.com/obra/superpowers/blob/main/LICENSE
- GitHub releases: https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases
- VS Code extension CLI: https://code.visualstudio.com/docs/configure/command-line
- VSIX packaging: https://code.visualstudio.com/api/working-with-extensions/publishing-extension
