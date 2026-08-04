# AGENTS.md

Global bootstrap remains authoritative: main agents load `using-superpowers` before actions; this file only adds repository-specific rules.

Use Markplane when `.markplane/` is present. Keep `TASK-u2f8k` updated for the public Research With Coding Agents repository work.

Respect these boundaries:

- Always preserve project `.markplane` directories and user extensions under `%USERPROFILE%\.research-with-coding-agents\extensions\`.
- Ask before major repository moves, deleting generated artifacts that might be user-owned, or changing component fork history.
- Never overwrite unrelated agent configuration, delete foreign Superpowers installations, or install the Markplane UI by copying extension folders.

The public product is Research With Coding Agents. Markplane and Superpowers are core components with their own upstreams, histories, and licenses.
