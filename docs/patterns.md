# Mod Manager design patterns

## Surface hierarchy

Use the rail and action dock over the game scene, with a single cool top
highlight. Use the denser card surface for descriptions and stats that need
steady contrast. Use the inset surface for repeated ingredients and the stat
surface for a single band of related values. Reserve amber outlines for the
active navigation entry, the selected result and the primary action.
The surfaces use static Slate brushes.

Use a circular icon for a familiar utility such as Refresh. Show its
text label on hover and keep the hit area fixed while the icon animates.
Load the bundled `art/ui_refresh.png` as a texture so the arrow has the
same shape with every game font. Pass it to `make_icon_button`.
Use the rail's small firefly highlights for hover and the outline for
selection. Load `art/ui_firefly.png` and pass the texture as the
`fireflies` option on rail buttons. Check hover on the row's overlay.
Orbit the label itself and measure its desired width at hover entry.
Run both effects on the existing open-panel tick. Keep page
controls in a fixed footer with the current and total page counts.

Review small labels, hints and the focused field against both dark and bright
backgrounds. Use the [materials reference](../.agents/skills/rsdw-ui-kit/references/materials.md)
for contrast targets and the live gallery checklist.

## Search, results, details and action

1. In the search view, use a clear input hint, a visible Search action and
   `focusInput = true` when the user returns to search. Enter submits the same
   search as the button. Use one muted text message for empty results.
   Keep the failed query available for editing.
2. Keep result titles readable while native icons load. A row accepts
   `title`, `value`, optional `icon`, and the boolean flags `selected`
   and `disabled` for pooled rows. Keep a stable `value` for matching
   selection across redraws.
3. Show details in a card. Put the name and description before stats. Include
   ingredient thumbnails when the selected item has a recipe. Item Spawn's
   **Back to results** reuses the last results. **Search Again** clears the
   selection and restores the search field.
4. Use the warm outline for a primary action and the graphite inset
   for secondary buttons. Declare `primary = true` on the manifest
   action that best advances the task. Use `row.action = true` for a
   one-off command among rows. Use `row.destination = true` and a
   chevron for a link to a subview. Keep Back first and size it to its
   label. Keep unavailable actions inert and suppress the native
   light-grey disabled fill. An Item Spawn quantity field keeps Enter
   from spawning items.

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
Set `preview.compact = true` for content-rich details inside a fixed panel.
It reduces card padding and artwork size and puts the stats in one
wrapping strip. Check the whole view at the target height with the action
dock visible. Keep the text, effects and ingredient tiles readable.

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
