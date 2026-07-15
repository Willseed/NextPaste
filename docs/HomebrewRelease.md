# Homebrew 發布

在 NextPaste 達到官方 `homebrew/cask` 儲存庫的知名度門檻之前，會透過專案自有的 Homebrew tap
發布。初始安裝指令為：

```bash
brew install --cask willseed/tap/nextpaste
```

該 Cask 會從具版本號的 GitHub Release ZIP 檔安裝已簽署並經公證的通用版 `NextPaste.app`。
請勿發布未簽署的建置版本、可變動的下載網址，或未通過 Gatekeeper 評估的產物。

## 一次性 Apple 設定

1. 在登入鑰匙圈中為 Apple Developer 團隊安裝 `Developer ID Application` 憑證。該憑證必須包含
   私鑰。
2. 在 Xcode 中登入該團隊，並確認 `NextPaste` target 可以使用預期的 bundle ID。
3. 為 `notarytool` 建立鑰匙圈設定檔（profile）。例如，使用 App Store Connect API 金鑰：

   ```bash
   xcrun notarytool store-credentials NextPaste-notary \
     --key /absolute/path/to/AuthKey_KEYID.p8 \
     --key-id KEYID \
     --issuer ISSUER_UUID
   ```

4. 在不外洩私密資料的情況下確認上述兩項前置條件：

   ```bash
   security find-identity -v -p codesigning
   xcrun notarytool history --keychain-profile NextPaste-notary
   ```

## 打包發布版本

從一個乾淨的 `main` 工作目錄開始，其不可變的 commit 必須已通過 `Scripts/verify.sh` 以及對應的
GitHub `Verify` workflow。設定 Apple 團隊與公證設定檔，然後執行：

```bash
DEVELOPMENT_TEAM=TEAMID \
NOTARY_PROFILE=NextPaste-notary \
Scripts/package-homebrew-release.sh
```

此腳本會從 Release 建置設定中讀取版本號、建置編號、bundle ID 與最低 macOS 版本需求，接著會：

1. 使用 Developer ID 簽署進行封存（archive）與匯出；
2. 驗證套件（bundle）中繼資料、通用架構、簽章與 Hardened Runtime；
3. 將 ZIP 提交給 Apple，等待公證完成，並貼上（staple）公證票證；
4. 執行 `codesign`、`stapler` 與 Gatekeeper 驗證；
5. 產出 `NextPaste-<version>.zip`、其 SHA-256 值，以及完整的 `Casks/nextpaste.rb`。

所有產生的產物皆會寫入儲存庫外部。若偏好使用固定的外部路徑，可設定 `RELEASE_OUTPUT_DIR`。

## 依序發布

1. 記錄已驗證通過的確切 commit SHA，並確認 `origin/main` 仍指向該 commit。
2. 建立指向該 SHA 的帶注解 `v<version>` 標籤（tag）；切勿覆蓋既有的標籤。
3. 建立 GitHub Release，並上傳打包腳本產出的、經過公證的確切 `NextPaste-<version>.zip` 檔案。
4. 建立公開儲存庫 `Willseed/homebrew-tap`，並將產出的檔案複製到 `Casks/nextpaste.rb`。
5. 在 tap 儲存庫中，推送前先執行以下檢查：

   ```bash
   brew style Casks/nextpaste.rb
   brew audit --new --cask Casks/nextpaste.rb
   brew install --cask ./Casks/nextpaste.rb
   brew uninstall --cask nextpaste
   ```

6. 在乾淨的機器上測試公開安裝路徑：

   ```bash
   brew install --cask willseed/tap/nextpaste
   spctl --assess --type execute --verbose=4 /Applications/NextPaste.app
   ```

請保持 GitHub Release 產物不可變動。對於後續版本，請重新打包新的產物、發布新的標籤與 Release，
然後僅更新 tap 中 Cask 的 `version` 與 `sha256`。
