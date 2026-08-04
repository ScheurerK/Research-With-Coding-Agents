# Local Extension Model

User extensions live under:

```text
%USERPROFILE%\.research-with-coding-agents\extensions\<extension-name>\
```

Each extension has an `extension.yaml` manifest and may provide `skills/`, `adapters/`, or `hooks/`. Product updates never overwrite this directory. Executable hooks require explicit approval before activation.
