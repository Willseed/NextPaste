# Quickstart: iOS 原生體驗與前景剪貼簿匯入

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
```

## Targeted Unit Tests

```bash
# iOS foreground lifecycle、generation、dedup/cancellation/result mapping
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

# Deterministic foreground import/fallback integration (not system prompt evidence)
xcodebuild -project NextPaste.xcodeproj -scheme NextPasteCI -testPlan NextPaste \
  -only-test-configuration UI \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:NextPasteUITests/IOSClipboardImportUITests test

# Native settings and editor flows
xcodebuild -project NextPaste.xcodeproj -scheme NextPasteCI -testPlan NextPaste \
  -only-test-configuration UI \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:NextPasteUITests/IOSSettingsUITests \
  -only-testing:NextPasteUITests/CreateTextClipUITests test
```

UI execution必須serialized；不得parallel啟動共享 simulator pasteboard/store測試。

## Manual Simulator Workflow

```bash
# Find/boot the simulator and open Simulator UI.
xcrun simctl list devices available
open -a Simulator

# Put text on the booted simulator pasteboard.
printf '%s' 'NextPaste iOS foreground import' | xcrun simctl pbcopy booted

# Install and launch using the build product path reported by xcodebuild.
xcrun simctl install booted /path/to/NextPaste.app
xcrun simctl launch booted com.nextpaste.NextPaste
```

首次 programmatic paste若顯示 iOS system prompt，依 Validation Contract 分別驗證 Allow、deny與
Settings撤銷。`simctl pbcopy`＋launch只建立操作條件，不能單獨證明匯入或權限行為成功。

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

此功能改變 app launch、navigation、clipboard acquisition與shared persistence input，因此完成時
必須執行完整 gate。保留第一份大型 log/result bundle並依 contract記錄實際結果；不得只為取回
輸出而無理由重跑。
