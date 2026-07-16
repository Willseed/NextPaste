# Quickstart: iOS 原生體驗與明確貼上

**Feature**: 026-ios-native-clipboard
**Spec**: [spec.md](./spec.md)
**Validation Contract**: [contracts/validation-and-sonar-contract.md](./contracts/validation-and-sonar-contract.md)

本文件只提供執行指令。驗證矩陣、manual scope、performance budget、evidence lifecycle與release
readiness由 [Validation Contract](./contracts/validation-and-sonar-contract.md)唯一擁有。

## Prerequisites

- 完整 Xcode 26.5 或相容版本。
- 已安裝 `rg` 與 `actionlint`（完整 gate 需要）。
- 可用的 iPhone simulator；範例使用 `iPhone 17`，若本機名稱不同，先用
  `xcrun simctl list devices available` 選擇同等 iPhone。
- 無 package/bootstrap 或第三方 dependency install。

## Static Checks

```bash
git diff --check
Scripts/check-test-hygiene.sh
Scripts/verify.sh --dry-run
```

Dry run只驗證 configuration，不能當作 build/test pass。

## Targeted Build

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste \
  -destination 'generic/platform=iOS Simulator' build

# Platform-isolation compile check; requires the matching visionOS runtime installed in Xcode.
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste \
  -destination 'generic/platform=visionOS Simulator' build
```

## Targeted Unit Tests

```bash
# iOS explicit request ownership、dedup/cancellation/result mapping
xcodebuild -project NextPaste.xcodeproj -scheme NextPasteCI -testPlan NextPaste \
  -only-test-configuration Unit \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:NextPasteTests/IOSClipboardImportCoordinatorTests test

# NSItemProvider text/image selection and invalid/unsupported representations
xcodebuild -project NextPaste.xcodeproj -scheme NextPasteCI -testPlan NextPaste \
  -only-test-configuration Unit \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:NextPasteTests/IOSPasteboardClientTests test

# Existing capture/dedup/image regressions
xcodebuild -project NextPaste.xcodeproj -scheme NextPasteCI -testPlan NextPaste \
  -only-test-configuration Unit -destination 'platform=macOS' \
  -only-testing:NextPasteTests/ClipboardCaptureTests \
  -only-testing:NextPasteTests/ClipboardImageCaptureTests test
```

## Targeted iOS UI Tests

```bash
# Native home, one search, filters, stable rows, empty states, hit targets
xcodebuild -project NextPaste.xcodeproj -scheme NextPasteCI -testPlan NextPaste \
  -only-test-configuration UI \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:NextPasteUITests/IOSNativeHomeUITests test

# Simulator pasteboard setup + user-triggered system PasteButton integration;
# this is not complete system prompt/settings manual evidence.
xcodebuild -project NextPaste.xcodeproj -scheme NextPasteCI -testPlan NextPaste \
  -only-test-configuration UI \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:NextPasteUITests/IOSExplicitPasteUITests test

# Native settings and editor flows
xcodebuild -project NextPaste.xcodeproj -scheme NextPasteCI -testPlan NextPaste \
  -only-test-configuration UI \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:NextPasteUITests/IOSSettingsUITests \
  -only-testing:NextPasteUITests/CreateTextClipUITests test
```

UI execution必須serialized；不得parallel啟動共享 simulator pasteboard/store測試。
目前shared test targets仍含macOS-only test sources；若iOS destination在compile phase遇到既有
platform-only source錯誤，targeted evidence可用command-line source filtering隔離所選suite，但不得
把被排除的source視為已在iOS通過。generic iOS product build必須保持unfiltered。

## Manual Simulator Workflow

```bash
# Find/boot the simulator and open Simulator UI.
xcrun simctl list devices available
open -a Simulator

# Put text on the booted simulator pasteboard.
printf '%s' 'NextPaste iOS explicit paste' | xcrun simctl pbcopy booted

# Install and launch using the build product path reported by xcodebuild.
xcrun simctl install booted /path/to/NextPaste.app
xcrun simctl launch booted dev.pylot.NextPaste
```

launch後先確認未點Paste前沒有新row或由programmatic read造成的system prompt，再實際點擊可見
`PasteButton`並確認只新增一筆。`simctl pbcopy`＋launch只建立操作條件，不能單獨證明system
control、匯入或隱私行為成功。

## macOS Regression Spot Checks

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPasteCI -testPlan NextPaste \
  -only-test-configuration Unit -destination 'platform=macOS' \
  -only-testing:NextPasteTests test

xcodebuild -project NextPaste.xcodeproj -scheme NextPasteCI -testPlan NextPaste \
  -only-test-configuration UI -destination 'platform=macOS' \
  -only-testing:NextPasteUITests/AdaptiveToolbarUITests \
  -only-testing:NextPasteUITests/SearchAccessibilityUITests \
  -only-testing:NextPasteUITests/SettingsUITests \
  -only-testing:NextPasteUITests/ClipboardAutoCaptureUITests test
```

## Final Regression Gate

```bash
Scripts/verify.sh
```

此功能改變app launch、navigation、explicit clipboard acquisition與shared persistence input，因此完成時
必須執行完整 gate。保留第一份大型 log/result bundle並依 contract記錄實際結果；不得只為取回
輸出而無理由重跑。
