# Quickstart: Governance v2.5 Representative

Use [`contracts/validation-and-sonar-contract.md`](contracts/validation-and-sonar-contract.md) as the canonical source for validation ownership, representative validation, regression scope, Sync Impact completion, SonarQube applicability requirements, and the only authoritative governance execution lifecycle.

## Targeted Validation commands

### Build and unit testing

```bash
# Targeted command to verify build or unit behavior
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests test
```

### Integration testing

```bash
# Targeted command to verify integrated components
echo 'No dedicated integration tests'
```

### UI testing

```bash
# Targeted command to verify user-visible flows
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests test
```

## Final Regression command

```bash
# Full regression command used only at completion or release gates
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' test
```

## Contracts & Sonar Completion

- Use `contracts/validation-and-sonar-contract.md` to record validation evidence.
- Record SonarQube Project Health Gate passing results there.
- Close Sync Impact items.
- Complete Constitution update steps.
