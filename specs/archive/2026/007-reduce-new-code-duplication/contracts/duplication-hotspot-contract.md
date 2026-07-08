# Contract: Duplication Hotspot Resolution

## Baseline hotspots

| File | Baseline duplication | Duplicated lines | Required disposition |
|------|----------------------|------------------|----------------------|
| `NextPasteUITests/ClipboardRobot.swift` | 29.3% | 103 | Back image generation with shared fixture factory. |
| `NextPasteTests/ImageTestFixtures.swift` | 29.1% | 103 | Back fixture constants with shared fixture factory. |
| `NextPaste/DesignSystem/Components/ImageClipboardRow.swift` | 27.4% | 52 | Use shared row presentation/action group. |
| `NextPaste/DesignSystem/Components/ClipboardRow.swift` | 24.6% | 52 | Use shared row presentation/action group. |
| `NextPaste/ClipboardWriter.swift` | 20.0% | 35 | Own shared pasteboard snapshot and writer preflight helper. |
| `NextPasteTests/ClipboardWriterTests.swift` | 13.3% | 35 | Use production snapshot/test support instead of copied helper. |

## Resolution rules

- Each hotspot must map to a shared abstraction, helper, or explicit rationale.
- Suppressing duplicate-code rules, excluding hotspot files, or weakening thresholds is not an acceptable disposition.
- Remaining similar code is acceptable only when sharing would hide a real behavior difference and the Sonar quality gate still passes.
- Public APIs and user-facing behavior must be preserved.
- Any target-membership change must be mechanical and limited to shared test-support source inclusion.

## Traceability record required at completion

For each hotspot, record:

1. baseline duplicated block/root cause,
2. helper/component introduced or reused,
3. files mechanically updated,
4. targeted tests run,
5. Sonar evidence source/run proving the gate passes.
