# Markplane for VS Code

This extension adds a Markplane activity-bar view to VS Code.

It can:

- initialize Markplane in the current workspace
- start `markplane serve` automatically
- choose a project-specific local port so each VS Code window shows its own workspace
- show the Markplane graph view inside VS Code
- run Markplane sync and check commands

The extension expects `markplane` to be available on PATH. The Markplane installers in this folder configure that automatically.

By default, the activity-bar view is focused when a VS Code window starts. Set `markplane.showOnStartup` to `false` to keep it hidden until opened manually.
