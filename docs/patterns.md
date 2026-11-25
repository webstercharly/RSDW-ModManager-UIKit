# Mod Manager design patterns

## Surface hierarchy

Use the rail and action dock over the game scene, with a single cool top
highlight. Use the denser card surface for descriptions and stats that need
steady contrast. Use the inset surface for repeated ingredients and the stat
surface for a single band of related values. Reserve amber outlines for the
active navigation entry, the selected result and the primary action.
The surfaces use static Slate brushes.

Review small labels, hints and the focused field against both dark and bright
backgrounds. Use the [materials reference](../.agents/skills/rsdw-ui-kit/references/materials.md)
for contrast targets and the live gallery checklist.

## Search, results, details and action

1. In the search view, use a clear input hint, a visible Search action and
   `focusInput = true` when the user returns to search. Enter submits the same
   search as the button. Use a disabled row to explain empty results.
2. Keep result titles readable while native icons load. A row accepts
   `title`, `value`, optional `icon`, and the boolean flags `selected`
   and `disabled` for pooled rows. Keep a stable `value` for matching
   selection across redraws.
3. Show details in a card. Put the name and description before stats. Include
   ingredient thumbnails when the selected item has a recipe. Item Spawn's
   **Back to results** reuses the last results. **Search Again** clears the
   selection and restores the search field.
4. Make the current primary action clear with `primary = true` in its
   manifest entry. Show secondary actions alongside it. Set
   `disabled = true` when an action is visible but unavailable. An Item
   Spawn quantity field keeps Enter from spawning items.

## View contract

Module `activate(state)` can supply `rows` with `poolRows = true` for
small lists, `inputValue`, `focusInput`, and `actionIds` to order and show a
subset of declared actions. A preview requires a `title`. Each optional
`stats` element has a `label` and `value`. Each optional `ingredients`
element has a `title`, `count` and optional symbolic game texture `icon`.
Use `benefits` for plain-text on-use effects. Keep weight and stack limit
in `stats`, and use line breaks to separate immediate effects from perks.
Use `recipe` as a text fallback for the grid and `footnote` for supporting
information. A card with no artwork expands to fill the available width.

The host creates a kit with `new(host)`, supplying `valid`, `construct`,
`sized`, `pad`, `new_text`, `load_class`, `make_game_button`,
`set_visible`, `text_class` and an optional `warn` callback. It gives
`prepare_row_icon` and `render_preview` the active panel context, then
handles the image requests with its existing queue. Apply a resolved theme
with `set_theme` before constructing a fresh panel. Pass `"rail"` or
`"dock"` to `surface_with_shadow` to render the configured top highlight.

## Dragonwilds native UI

For a new HUD card, use the game's `WBP_Panel` as the host, its
`WBP_DomTextBlock` for game-scale text, and
`glass.mount_panel(frame, content, valid, theme)` for the Graphite backing.
Keep the outer panel's placement and mouse behavior under the caller's
control. The wrapper adds no padding to the native content, so the caller
still owns sizing. It attaches to the original panel when a Border cannot
be created.

Use the game's CommonUI buttons for clickable controls. Reuse the kit's
button label styling if a separate HUD must configure buttons in a staged
layout pass. For decorative text, arrows and backings, use hit-test-invisible
widgets so they leave mouse input to the underlying interface. Retain the
gameplay signals in combat warnings, navigation and map marker states.

Use a shared component for recurring layouts. If a new layout is useful
to more than one mod, add the presentation primitive to the kit and keep
the gameplay state and callbacks in the mod. Keep vendored kit files in
sync with the public source.
