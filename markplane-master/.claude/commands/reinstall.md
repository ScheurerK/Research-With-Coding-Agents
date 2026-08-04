---
description: Rebuild markplane-cli and reinstall the local markplane binary (cargo install --path crates/markplane-cli)
---

Reinstall the local `markplane` binary from this checkout so CLI/MCP changes
take effect for every project using it:

```
cargo install --path crates/markplane-cli --features embed-ui --force
```

Run from the repo root. If it fails with a file-in-use / access-denied error
on Windows, `markplane.exe mcp` server processes from other open editor
sessions are holding the binary locked — list them (e.g. `Get-Process
markplane`) and confirm with the user before stopping any, then retry the
install. After a successful reinstall, `markplane --version` should still
report a working binary.
