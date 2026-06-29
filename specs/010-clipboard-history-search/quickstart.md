# Quickstart: Clipboard History Search Validation

**Date**: 2026-06-29  
**Spec**: [spec.md](spec.md)  
**Plan**: [plan.md](plan.md)

## Build

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' build
```

## Automated Tests

### Unit tests

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests test
```

### UI tests

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests test
```

### Full regression suite

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' test
```

## Validation References

- Validation ownership, automated coverage expectations, regression matrix, manual validation, offline validation, and SonarQube evidence requirements: [contracts/validation-and-sonar-contract.md](contracts/validation-and-sonar-contract.md)
- Search interaction behavior contract: [contracts/history-search-ui-contract.md](contracts/history-search-ui-contract.md)
