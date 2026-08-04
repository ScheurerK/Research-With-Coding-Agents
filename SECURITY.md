# Security Policy

## Supported Versions

The first supported public line is `0.1.x` on Windows.

macOS and Linux operation is experimental and should not be treated as full agent or installer parity.

## Reporting

Report vulnerabilities privately through GitHub Security Advisories once the public repository is active. Until then, contact the repository maintainer directly.

Installer, hook, and extension issues are security-sensitive when they can execute code, overwrite unrelated configuration, expose prompts or research content, or replace the project-maintained Superpowers copy.

## Privacy Defaults

Managed agent sessions keep `SUPERPOWERS_DISABLE_TELEMETRY=1`. Logs stay local and must not record prompts, research content, secrets, or full environment dumps.
