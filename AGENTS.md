# Agent entry point

This repository owns the public Dragonwilds Mod Manager UI Kit. It contains
shared presentation code, design patterns, generated UI art, and the portable
rsdw-ui-kit skill. It must not implement gameplay-changing module behavior.

Before changing UI code, read .agents/skills/rsdw-ui-kit/SKILL.md and
docs/patterns.md. Preserve the shell's game-thread, input, reload, and
click-through rules.

Run Tools/Test-PublicPackage.ps1 before handoff. It parses all Lua and JSON,
checks generated/tracked artifacts and public boundaries, verifies PNG assets,
and runs the complete unit suite. Keep live Dragonwilds observations separate
from static validation.
