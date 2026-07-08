# Contract: Visual States, Accessibility, and Motion

## Row State Contract

| State | Visual requirement | Accessibility requirement |
|-------|--------------------|---------------------------|
| Normal | Warm card/surface role, minimal border, no heavy shadow | Row label exposes clip preview and relevant metadata. |
| Hovered | Subtle warm surface shift or border change | No hover-only action is required for core use. |
| Focused/selected | Native-feeling focus treatment using semantic token | Keyboard users can identify focus location. |
| Pinned | Filled pin plus small marker/rail/restrained tint | State is conveyed by label/symbol, not color alone. |
| Copied | Checkmark plus `Copied` label | Feedback is announced or exposed through accessible state. |
| Inserting | Small-scale row entrance over 180-250ms | Must not delay persistence or history refresh. |
| Deleting | Collapse or fade-out over 180-250ms | Final row removal matches local delete result. |

## Animation Contract

- Hover, focus, selection, pin toggle, and copy feedback micro-interactions target 120-200ms.
- Row insertion and delete transitions target 180-250ms.
- Copy feedback becomes visible within 200ms of copy success.
- Copy feedback remains visible for about 1.5 seconds before fading automatically.
- Decorative animations, bouncy celebrations, looping motion, and motion unrelated to state changes are out of scope.
- Reduced Motion settings must be respected by reducing or disabling nonessential transitions while keeping final state changes visible.

## Accessibility Contract

- All controls and row actions must have meaningful accessible names.
- Keyboard navigation must reach toolbar controls, search/filter/settings affordances, history rows, copy actions, pin actions, delete actions, and relevant empty-state content.
- VoiceOver must expose row preview, timestamp/metadata, pinned state, and copy feedback.
- High-contrast appearances must strengthen text, border, and focus separation without introducing saturated row backgrounds.
- Dynamic Type/increased text sizes must not clip primary row preview, toolbar controls, feedback labels, or empty-state copy.
- Color must never be the only channel for pinned, copied, selected, error, or future sync/AI/OCR states.

## SF Symbols Contract

- Use SF Symbols for standard actions and states: search, filter, settings, pin, unpin, delete, copied/checkmark, clipboard, and image.
- Prefer filled symbols only when representing active state, such as `pin.fill`.
- Pair symbols with accessible labels.
- Do not import third-party icon sets for this feature.
