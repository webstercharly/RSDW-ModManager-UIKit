---
name: rsdw-ui-kit
description: Build or review Dragonwilds Mod Manager views with the shared UI Kit. Use for module menus, search and selection flows, detail cards, theme tokens, or UI Gallery checks. Follow the host's game-thread and input rules.
---

# Dragonwilds UI Kit

Use the existing components in `rlm_ui_kit.lua` and defaults in
`rlm_ui_theme.lua`. Read the [design patterns](https://github.com/webstercharly/RSDW-ModManager-UIKit/blob/main/docs/patterns.md)
when changing the module view contract. In the installed manager, follow
`AGENTS.md` and `.agent/SKILLS.md` for widget lifecycle and reload guidance.

- Start from the module's manifest and `activate` view. Supply an optional
  preview, pooled result rows and visible manifest actions. Add a shared
  component only when existing ones cannot express the requested interaction.
- For separate game HUDs, use the [native UI patterns](https://github.com/webstercharly/RSDW-ModManager-UIKit/blob/main/docs/patterns.md#dragonwilds-native-ui).
  Build on the game's panel, text and button primitives and use the kit for
  the backdrop and text styling. Preserve gameplay colours and input behavior.
- Put the clearest glass treatment on the module rail and action dock. Use
  the quieter card behind text, stats and ingredient names. Tune shared
  tokens for changes that should appear across modules.
- Keep task-specific words on controls. Preserve Enter-to-search and a route
  back to the query or results. Pair selected-state color with a visible
  outline. Keep disabled actions labelled, inert and readable on Graphite.
  Suppress the native light-grey disabled fill. Show empty results as a
  single muted text message.
- Keep item art supplemental to readable text. Reuse native texture references
  and the host image queue. Compare illustrated, text-only and missing-image
  states in the gallery before changing the view contract.
- Keep inventory stats, on-use effects and ingredients distinct. Show a
  numerical benefit or duration when the item data supports it and omit
  unknown values.
- For design reviews, theme changes and visual acceptance, read
  [materials and readability](references/materials.md). Verify the result in
  the gallery over bright and dark scenes. Record syntax/tests separately
  from observed in-game behavior.
