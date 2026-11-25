# Dragonwilds Mod Manager UI Kit

Reusable Lua and UMG components for the in-game Dragonwilds Mod Manager.
Graphite uses translucent navigation and controls over the game, a denser
surface behind item details, and amber for the active module and primary action.
The rail and action dock catch a subtle cool highlight along their top edges.

| Component | Behaviour |
| --- | --- |
| Surface | Named Slate fills, outlines, rounded corners and optional shadow |
| Navigation and actions | Native game buttons with shared selected, primary and disabled styling |
| Search field | Shared editable text box styling, including hover and focus |
| Result row | Reusable row with an optional thumbnail and selected or disabled state |
| Detail card | Title, description, optional artwork, up to three stats, on-use effects and a recipe ingredient grid |
| UI Gallery | In-game examples of artwork, text-only details, filtering and unavailable controls |

Item Spawn is the reference for item details and recipes. Bestiary uses the same
detail card for creature information and spawn settings. See the
[design patterns](docs/patterns.md) for the data each view provides.
The [UI Kit skill](.agents/skills/rsdw-ui-kit/SKILL.md) gives coding agents the
same component and review workflow. Its
[materials and readability reference](.agents/skills/rsdw-ui-kit/references/materials.md)
records the research, the in-game checks and a lower-transparency theme example.

## Agent Skills

The same `rsdw-ui-kit` bundle follows the [Agent Skills specification](https://agentskills.io/specification).
Open this checkout in your agent, or copy the full
[`rsdw-ui-kit` folder](.agents/skills/rsdw-ui-kit) into another workspace's
skill directory. Keep `references/` with `SKILL.md`.

| Agent | Workspace directory | Invoke |
| --- | --- | --- |
| Codex | `.agents/skills/` | `$rsdw-ui-kit` |
| Antigravity | `.agents/skills/` | `/rsdw-ui-kit` |
| Claude Code | `.claude/skills/` | `/rsdw-ui-kit` |

This checkout includes a Claude Code entry that loads the shared bundle. For
Claude chat or Cowork, ZIP the full shared skill folder and use the
[custom skill upload](https://support.claude.com/en/articles/12512180-use-skills-in-claude).
For other Agent Skills tools, use the same bundle in their supported skill
directory.

## Theme overrides

After installing the host integration and restarting Dragonwilds once, open
**Mod Manager → UI Gallery**. Save overrides in
`%LOCALAPPDATA%\RSDWLoadoutManager\ui-theme.json` and select **Reload Mods**.
The gallery shows the active theme name. The manager keeps its previous theme
and logs a validation error if an override is invalid.

```json
{
  "schemaVersion": 1,
  "name": "Ink",
  "surfaces": {
    "rail": { "fill": { "A": 0.66 } },
    "card": { "radius": 16, "fill": { "A": 0.92 } }
  },
  "spacing": { "row": 40 }
}
```

Built-in defaults load first, followed by `Data/ui-theme.json` and then the
personal override. Omit any token to inherit its value. Colours use linear
`R`, `G`, `B`, `A` values from 0 to 1. The size and typography ranges
are defined in [rlm_ui_theme.lua](Scripts/rlm_ui_theme.lua). Theme files are
limited to 32 KiB. Set a rail or dock's `highlight` to zero to remove its
top highlight.

## Host integration

The manager vendors the three files from `Scripts/` in its Lua search path
and the default theme in `Data/`. To include the gallery, copy
`Modules/UIGallery/` and add `"UIGallery"` to the manager's module index.
The gallery requires the host integration for the shared visuals and disabled
controls. The in-game manager owns the viewport and supplies widget creation,
native button routing and texture loading.

The gallery refers to textures provided by the installed game at runtime.
The reused Mod Manager input styling carries its original
[MIT notice](LICENSES/ModManager-MIT.txt).

Run the isolated checks with Python and `lupa` installed.

```powershell
python -m unittest discover -s Tools/tests -p test_ui_kit.py
```
