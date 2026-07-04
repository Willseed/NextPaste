# Quickstart: Refactor Pin/Unpin Safety

Use [contracts/validation-and-sonar-contract.md](contracts/validation-and-sonar-contract.md) as the
canonical source for validation ownership, required evidence, sanitizer expectations, regression
scope, SonarQube requirements, and release-readiness status.

## Targeted Validation Commands

### Build

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' build
```

### Targeted Unit / Pure Logic

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests/PinStateMutationStoreTests test
```

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests/ClipHistoryTests test
```

### Targeted UI / Native Row Actions

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests/ClipRowActionsUITests test
```

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests/RowActionStressTests test
```

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests/ClipboardImageRowActionsUITests test
```

### Sanitizer Validation

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests/PinStateMutationStoreTests -enableThreadSanitizer YES test
```

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests/RowActionStressTests -enableAddressSanitizer YES test
```

## Final Regression Command

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' test
```

Full regression is a final gate because this refactor touches shared SwiftData persistence,
history-list interaction, native row actions, app launch with persisted state, and cross-cutting
Pin/Unpin behavior.

## Contracts & Completion

- Use [contracts/pin-unpin-mutation-contract.md](contracts/pin-unpin-mutation-contract.md) for the
  internal mutation and snapshot contract.
- Use [contracts/validation-and-sonar-contract.md](contracts/validation-and-sonar-contract.md) to
  record executed evidence and release-readiness status.
- Keep validation evidence out of this quickstart except command execution notes if needed.
