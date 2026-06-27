# Contract: Image History UI

## Row display

Image clips appear in the same history list as text clips and follow the same pinned-first/newest-first ordering rules.

Each image row must show:

- A fixed design-system thumbnail area.
- The generated thumbnail displayed aspect-fit without cropping when available.
- The design-system image fallback icon only if thumbnail generation or loading failed after valid capture.
- Metadata sufficient for accessibility, including image clip identity and dimensions/type where available.

## Row actions

Image clips support the existing row actions:

- **Copy**: Copies the preserved full image back to the system clipboard and shows copied feedback only on success.
- **Delete**: Removes the image clip from history and deletes associated local image files.
- **Pin/Unpin**: Uses existing pin state and sort order behavior.

Text clip row actions must remain unchanged.

## Accessibility and UI-test identifiers

Image rows must expose stable identifiers for UI tests without replacing existing text row identifiers:

- Image row prefix: `image-clip-row-<uuid>`
- Thumbnail identifier or accessible surface: `image-clip-thumbnail`
- Copy/delete/pin buttons keep existing identifiers where shared row actions are reused.

## Design-system rules

Image row surfaces reuse existing design tokens for spacing, typography, corner radius, border, card color, accent/pinned badges, and motion. No new undocumented visual pattern is introduced for this feature.
