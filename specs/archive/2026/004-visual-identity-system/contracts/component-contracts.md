# Contract: Reusable SwiftUI Components

## AppToolbar

**Purpose**: Unified top control surface for the single-column history-first window.

Required behavior:

- Shows the window/history title.
- Provides future-ready inline search placement tied to the history list.
- Provides future-ready filter affordance using an SF Symbol and accessible label.
- Provides settings access using an SF Symbol and accessible label.
- Does not introduce a sidebar, floating command panel, or marketing-style header.
- Remains usable at compact and wide macOS window sizes.

## SearchBar

**Purpose**: Native search field surface reserved for future history filtering.

Required behavior:

- Appears inline with or directly under the unified toolbar.
- Uses semantic surface, border, typography, and focus tokens.
- Uses SF Symbols for search/clear affordances where applicable.
- Must not imply unsupported search behavior is active until search is implemented.
- Exposes accessible label and keyboard focus behavior.

## ClipboardRow

**Purpose**: Preview-first row for text clips.

Required behavior:

- Primary content is the text preview.
- Timestamp and metadata are secondary.
- Pin indicator and copy feedback occupy a trailing state area.
- Hover, focus, selected, pinned, copied, inserted, and deleting states use semantic tokens and motion rules.
- Tap/copy, swipe/delete, and swipe/pin behavior remain compatible with existing `ClipItem` history actions.
- Existing preview normalization/truncation semantics remain unchanged.
- Existing UI-test identifiers should remain stable or be mapped deliberately during migration.

## ImageClipboardRow

**Purpose**: Future-ready preview-first row for image clips.

Required behavior:

- Primary content is a leading thumbnail.
- Metadata such as dimensions, file size, or source appears as secondary text.
- Pin and copy/feedback state use the same trailing state area as text rows.
- Uses the same row rhythm, radius, hover, selection, pinned, and motion contracts as `ClipboardRow`.
- Does not use decorative illustration styling inside the populated history list.

## EmptyStateView

**Purpose**: Friendly no-content state for the history area.

Required behavior:

- Shows the exact headline `No clips yet`.
- Shows the exact description `Copy something to get started.`
- Includes a warm, soft, rounded illustration.
- Uses empty/onboarding illustration assets only; it must not appear inside populated history rows.
- Does not replace clipboard history as the primary focus when clips exist.

## Badge

**Purpose**: Reusable subtle status/category indicator.

Required behavior:

- Supports short labels and optional SF Symbol.
- Uses pill radius and restrained accent roles.
- Must be readable in Light Mode, Dark Mode, and high contrast.
- Must not rely on color alone to communicate state.
- Can represent pinned, copied, category, metadata, and future OCR/AI/CloudKit statuses.

## Compatibility Requirements

- Components must be reusable from `HomeView` and future feature surfaces.
- Components should accept data/presentation inputs rather than directly owning persistence.
- Components must not transmit clipboard data, start network work, or perform sync/AI/OCR processing.
