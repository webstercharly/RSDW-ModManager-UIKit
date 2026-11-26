# Materials and readability

## Surface and state choices

| Research | Application in this kit |
| --- | --- |
| Apple uses transparent material to separate navigation and controls from the content layer. [Apple Materials](https://developer.apple.com/design/human-interface-guidelines/materials) | Give the rail and dock more visible background and a fine cool top highlight. Use a denser, quieter surface for item and creature details. Reserve denser fills for small reading areas such as the input. |
| Xbox Accessibility Guideline 102 calls for testing the lowest-contrast part of variable backgrounds. [Xbox contrast](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/102) | Aim for 4.5:1 for standard text, including hints, and 3:1 for inactive labels. Sample the rendered text against the brightest or closest-matching patch it crosses. These are design targets and need in-game measurement. |
| Xbox Accessibility Guidelines 103 and 113 call for additional visual cues and recognizable focus. [Xbox additional cues](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/103) and [Xbox focus handling](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/113) | Pair selected or primary color with a border. Use distinct normal, hover and focused input brushes. Keep labelled controls and observable changes after Search, Back and Reset. |

## Empty and disabled states

Show an empty result as a single line of muted Graphite text. Keep disabled
controls inert with readable labels on the Graphite surface. Suppress the
native CommonUI light-grey fill and low-contrast lettering.

## Review in Dragonwilds

1. Open **UI Gallery** in a dark interior and in bright daylight. Capture the
   same sample in both scenes. Inspect small labels, search hints and the
   selected row at the user's viewport size. Contrast varies with the game
   backdrop and Slate compositing.
2. Compare the illustrated detail and the text-only card. Check the full
   title, description, stats and ingredient names. Text should remain usable
   before art resolves and when an image is unavailable.
3. Check the input before hover, during hover, and after clicking to focus.
   Type a query and submit it with Enter. Select a result, then use Reset.
   Verify that clicking the disabled row or action has no effect.
4. Review Item Spawn and another consumer of the changed component.
   Use the host's normal restart for Lua changes, then **Reload Mods**
   for theme JSON edits. Check the active theme name in the gallery.

Graphite uses static Slate brush fills and outlines. Treat a subtle edge and
spacing as the material cues in the current implementation. If a particular
background makes small text hard to read, increase the relevant surface's
fill opacity first. Measure again on the rendered scene.

## Lower-transparency override

Save this as a personal theme override or merge its surface values into
the existing file. The rest of the palette inherits Graphite.

```json
{
  "schemaVersion": 1,
  "name": "Graphite Opaque",
  "surfaces": {
    "rail": { "fill": { "A": 1 }, "highlight": 0 },
    "dock": { "fill": { "A": 1 }, "highlight": 0 },
    "card": { "fill": { "A": 1 } }
  }
}
```
