# Data Model: NextPaste Visual Identity & Design System

This feature introduces design-system and presentation entities. Unless explicitly noted, these are SwiftUI/UI-layer concepts, not new persisted SwiftData models.

## Entity: DesignTokenSet

**Purpose**: Central source of reusable visual decisions for the app.

| Field | Type | Required | Rule | Validation |
|-------|------|----------|------|------------|
| `colors` | Semantic color roles | Yes | Includes canvas, surface, card, text, border, accent, success, hover, selection, and pinned roles | Components must consume roles rather than hard-coded colors. |
| `spacing` | Numeric scale | Yes | Provides 4, 8, 12, 16, 24, 32, 48, and 96 units | Component spacing must use the scale unless an exception is documented. |
| `typography` | Text style roles | Yes | Provides display, title, body, metadata, badge, and feedback roles | Display uses Inter Medium intent; body uses Inter Regular intent with native sizing. |
| `radius` | Numeric radius roles | Yes | Buttons 12, cards 16, dialogs 24, pills fully rounded | Components must not invent unrelated radii. |
| `motion` | Duration and curve roles | Yes | Micro 120-200ms, row 180-250ms, copy visibility about 1.5s | Decorative animation roles are not defined. |

### Relationships

- Consumed by `AppTheme`, `AppToolbar`, `SearchBar`, `Badge`, `ClipboardRowPresentation`, `ImageClipboardRowPresentation`, and `EmptyStateContent`.

### Validation Rules

- Tokens are centralized and reusable.
- No component should hard-code brand colors, radius values, major spacing values, or animation durations when a token exists.
- Tokens must support Light Mode, Dark Mode, and high-contrast roles.

## Entity: AppTheme

**Purpose**: Appearance-specific semantic mapping from design tokens to readable UI roles.

| Field | Type | Required | Rule | Validation |
|-------|------|----------|------|------------|
| `appearance` | Enum | Yes | Light, dark, high-contrast light, high-contrast dark | Must preserve warmth and readable contrast in each mode. |
| `canvas` | Color role | Yes | Full-window background | Must not be pure white in Light Mode. |
| `surface` | Color role | Yes | Toolbar/search/list containers | Must stay warm and low-glare. |
| `card` | Color role | Yes | Row/card surfaces | Must support subtle depth without heavy shadows. |
| `textPrimary` | Color role | Yes | Primary content and display text | Must meet readable contrast expectations. |
| `textSecondary` | Color role | Yes | Timestamp, metadata, helper text | Must remain legible at increased text sizes. |
| `accentPinned` | Color role | Yes | Pin markers, rails, or restrained tint | Must not create saturated full-row backgrounds. |
| `accentSuccess` | Color role | Yes | Copied/checkmark feedback | Must not be color-only; paired with text/symbol. |

### Relationships

- Wraps `DesignTokenSet` and feeds component styling.
- May map to named asset colors, computed SwiftUI colors, or both, as long as components consume semantic roles.

## Entity: HomeWindowLayout

**Purpose**: Defines the visual structure of the main app window.

| Field | Type | Required | Rule | Validation |
|-------|------|----------|------|------------|
| `mode` | Enum | Yes | Single-column default; future sidebar/detail eligible only when feature density requires it | This feature must not add a persistent sidebar or detail pane. |
| `toolbar` | `AppToolbarPresentation` | Yes | Unified top toolbar | Title/settings visible; inline search/filter placement reserved. |
| `historySurface` | `ClipboardHistorySurface` | Yes | Primary content area | Maximizes adaptive macOS width and remains visual focus. |
| `emptyState` | `EmptyStateContent?` | No | Used when history is empty | Must include friendly illustration and required text. |

### State Transitions

```text
No clips
  -> Show EmptyStateContent in the history area

One or more clips
  -> Show ClipboardHistorySurface as preview-first row list

Future feature density requires navigation/detail
  -> Sidebar/detail may be added as an extension without replacing history-first default
```

## Entity: AppToolbarPresentation

**Purpose**: Defines title and primary toolbar affordances.

| Field | Type | Required | Rule | Validation |
|-------|------|----------|------|------------|
| `title` | String | Yes | Window/app title or current history title | Must be visible and not compete with rows. |
| `search` | `SearchBarPresentation` | Yes | Future-ready inline control | Must be visually present/reserved without implying unsupported behavior is active. |
| `filterAction` | Action presentation | Yes | Future-ready filter affordance | Uses native symbol and label. |
| `settingsAction` | Action presentation | Yes | Settings entry point | Uses native symbol and label. |

## Entity: ClipboardRowPresentation

**Purpose**: Preview-first representation of a text clip.

| Field | Type | Required | Rule | Validation |
|-------|------|----------|------|------------|
| `id` | UUID | Yes | Mirrors `ClipItem.id` | Stable for row identity and UI tests. |
| `preview` | String | Yes | Primary row content | Preserves existing preview normalization/truncation semantics. |
| `timestamp` | Date/text | Yes | Secondary metadata | Does not crowd preview or state indicators. |
| `isPinned` | Bool | Yes | Mirrors `ClipItem.isPinned` | Pinned clips remain ordered first through existing sort descriptors. |
| `copyFeedback` | Optional state | No | Shows copied label/checkmark after successful copy | Begins within 200ms, visible about 1.5s, fades automatically. |
| `interactionState` | Enum | Yes | Normal, hover, selected/focused, deleting, inserted | Uses subtle semantic styling and tokenized animation. |

### State Transitions

```text
Normal
  -> Hovered or focused
      -> Subtle warm surface shift, border, or focus treatment

Normal
  -> Copied
      -> Show checkmark + "Copied" for about 1.5s
      -> Fade back to Normal

Normal
  -> Pinned
      -> Keep row in pinned-first order
      -> Show filled pin plus small marker/rail/tint

Normal
  -> Deleting
      -> Collapse or fade out over 180-250ms
      -> Remove row after local delete succeeds
```

## Entity: ImageClipboardRowPresentation

**Purpose**: Future-ready image clip row variant that matches text row hierarchy.

| Field | Type | Required | Rule | Validation |
|-------|------|----------|------|------------|
| `id` | UUID | Yes | Stable row identity | Compatible with future image clip models. |
| `thumbnail` | Image presentation | Yes | Primary leading content | Thumbnail leads the row without expanding into an illustration. |
| `metadata` | Text metadata | Yes | Secondary details such as dimensions or size | Does not compete with thumbnail or state indicators. |
| `isPinned` | Bool | Yes | Uses same pinned state contract as text rows | Uses same trailing state area. |
| `interactionState` | Enum | Yes | Same states as `ClipboardRowPresentation` | Uses the same motion and accent rules. |

## Entity: EmptyStateContent

**Purpose**: Friendly no-content state for the history area.

| Field | Type | Required | Rule | Validation |
|-------|------|----------|------|------------|
| `illustration` | Illustration asset/presentation | Yes | Warm, soft, rounded, handmade style | Appears only in empty/onboarding states. |
| `headline` | String | Yes | Must be `No clips yet` | Exact text required by spec. |
| `description` | String | Yes | Must be `Copy something to get started.` | Exact text required by spec. |

## Entity: BadgePresentation

**Purpose**: Reusable small status/category/pinned indicator.

| Field | Type | Required | Rule | Validation |
|-------|------|----------|------|------------|
| `label` | String | Yes | Short accessible text | Must not rely on color alone. |
| `symbolName` | String? | No | SF Symbol where helpful | Standard symbols preferred. |
| `role` | Enum | Yes | Pinned, copied, category, metadata, future sync/AI/OCR status | Uses restrained accent tokens. |

## Persistence and Migration Impact

- No new required SwiftData fields are introduced by this feature.
- `ClipItem` remains the persisted history entity for current text clips.
- Current `ClipRowView.previewText(for:)` semantics must be preserved or migrated into a reusable formatter with equivalent tests.
- Existing accessibility identifiers used by UI tests should remain stable or be intentionally mapped to replacement components.
- Future Image Clip, OCR, AI Analysis, and CloudKit Sync features can add persisted models/states later while reusing these presentation entities and visual tokens.
