# Contract: Apple-Native Framework and Asset Boundaries

## Required Apple-Native Boundaries

- **SwiftUI**: View composition, toolbar layout, search/filter/settings surfaces, reusable components, environment-driven theme access, animations, accessibility, previews, and SF Symbol rendering.
- **SwiftData**: Existing local `ClipItem` persistence and history query refresh remain unchanged.
- **Foundation**: Dates, identifiers, string formatting, and presentation helpers.
- **AppKit**: Existing macOS clipboard/window behavior remains where already required; the design-system feature does not add new non-native UI frameworks.
- **Asset Catalogs**: Optional home for named semantic colors and empty/onboarding illustrations.
- **SF Symbols**: Default iconography for standard actions and states.

## Prohibited for This Feature

- Third-party UI frameworks.
- Third-party icon packs.
- Animation libraries.
- Firebase, analytics SDKs, advertising SDKs, or telemetry.
- Remote UI configuration services.
- Clipboard-data transmission.
- OCR UI, AI UI, CloudKit UI, sync indicators, advanced settings, or marketing pages.

## Asset Organization Rules

- Semantic color assets may live under `Assets.xcassets/Colors/` if static named assets are chosen.
- Illustration assets may live under `Assets.xcassets/Illustrations/`.
- Illustrations are allowed only for empty/onboarding states.
- Populated clipboard history rows must use content previews, thumbnails, SF Symbols, badges, and state markers, not decorative illustrations.

## Future Compatibility Rules

- Image Clip UI reuses `ImageClipboardRow`, thumbnail rules, row state tokens, and pinned/copy feedback contracts.
- OCR UI may add badges or metadata roles later, but must not replace the clipboard-history-first row hierarchy.
- AI Analysis UI may add local/on-device analysis status later, but must respect privacy, explicit consent, and token reuse.
- CloudKit Sync UI may add optional sync/status badges later, but local SwiftData history remains the source of truth and sync indicators are out of scope for this feature.
