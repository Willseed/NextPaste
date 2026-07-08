# Contract: Design Tokens and Theme Roles

## Token Ownership

- All brand colors, spacing values, typography roles, radius values, and animation durations must be defined in a centralized design-system location.
- Feature views must consume semantic tokens or theme roles instead of hard-coding brand hex values, spacing scale values, radii, or animation timings.
- New future UI surfaces for Image Clips, OCR, AI Analysis, and CloudKit Sync must reuse the same token contracts unless a later spec explicitly extends the design system.

## Color Roles

Required Light Mode roles:

| Role | Required value or intent |
|------|--------------------------|
| `ink` | `#0A0A0A` for primary text intent |
| `canvas` | `#FFFAF0` cream canvas intent; never pure white full-screen |
| `surfaceSoft` | `#FAF5E8` soft cream surface intent |
| `surfaceCard` | `#F5F0E0` card cream surface intent |
| `accentPink` | Restrained highlight/category/illustration use |
| `accentLavender` | Restrained highlight/category/illustration use |
| `accentPeach` | Restrained highlight/category/illustration use |
| `accentOchre` | Pinned/category/illustration use |
| `accentMint` | Success/category/illustration use |
| `accentDeepTeal` | Secondary accent/category/illustration use |

Dark Mode and high-contrast variants must map to semantic roles that preserve warmth and readable contrast. They do not need to reuse the exact Light Mode hex values.

## Accent Rules

- Accent colors are reserved for highlights, clipboard categories, pinned states, onboarding, empty states, feedback, and illustrations.
- Populated clipboard rows must not use colorful category backgrounds.
- Pinned clips use a filled pin plus a small marker, rail, or restrained tint.
- Success feedback uses text plus a checkmark and may use a success accent; it must not rely on color alone.

## Spacing Roles

The spacing scale is fixed at:

```text
4 / 8 / 12 / 16 / 24 / 32 / 48 / 96
```

Components should compose from this scale:

- 4-8 for small icon/text gaps and badge padding.
- 12-16 for row internal rhythm and toolbar control grouping.
- 24-32 for section padding and empty-state grouping.
- 48-96 for large empty-state and onboarding breathing room.

## Radius Roles

| Component type | Radius rule |
|----------------|-------------|
| Buttons | 12 |
| Cards/rows | 16 |
| Dialogs | 24 |
| Pills/badges | Fully rounded |

## Typography Roles

- Display/title roles use Inter Medium (500) intent, large title sizing, and slight negative tracking where appropriate.
- Body roles use Inter Regular intent with native macOS sizing.
- Metadata roles are secondary, readable, and must scale without clipping row state indicators.
- If Inter is unavailable, fallback typography must preserve hierarchy, weight intent, and native accessibility scaling.

## Motion Roles

| Role | Duration target |
|------|-----------------|
| Hover/selection micro-interaction | 120-200ms |
| Pin toggle | 120-200ms |
| Copy feedback entrance/fade | 120-200ms |
| Row insertion | 180-250ms |
| Delete collapse/fade | 180-250ms |
| Copy feedback visible duration | About 1.5 seconds |

Decorative motion roles are intentionally absent.
