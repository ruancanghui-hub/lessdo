# LessDo 1.0 App Store Release Checklist

## Software Release Candidate Verification

Verified on June 17, 2026:

- [x] `./tool/run.sh` launches on iPhone simulator.
- [x] Large-text theme no longer crashes on `TextTheme.apply` (regression test in
  `test/theme/lessdo_theme_test.dart`).
- [x] App Store Connect copy pack in `docs/app_store_connect/`.
- [x] Upload readiness script: `./tool/prepare_app_store_upload.sh`.

Verified on June 16, 2026 (reconfirmed after merge to `feature/lessdo-ios-1.0`):

- [x] Unit and widget suite: **188** tests passed.
- [x] Clean Release rebuild removes stale `in_app_purchase` frameworks (20.6 MB).
- [x] Publisher contact can be applied from `docs/publisher_contact.yaml` via
  `./tool/apply_publisher_contact.sh`.
- [x] Repeatable release gate script: `./tool/verify_ios_release.sh`.

Previously verified on June 14, 2026:

- [x] Dart formatting and localization generation complete.
- [x] Flutter analysis reports no issues.
- [x] Unit and widget suite passes, including iPad accessibility text and
  dark-theme quick-add contrast regressions.
- [x] Four end-to-end simulator journeys pass with real SQLite persistence.
- [x] iPhone 17 Pro on iOS 26.5 launches, completes onboarding, creates and
  completes a task, and restores state.
- [x] iPad Pro 13-inch (M5) on iOS 26.5 launches with adaptive navigation and
  readable portrait layout.
- [x] iPad dark mode at the largest accessibility text size keeps the date
  visible and the quick-add field readable.
- [x] Unsigned iOS Release build succeeds and produces a 20.6 MB app bundle.
- [x] Release bundle reports version `1.0.0` build `1`, minimum iOS `16.0`,
  iPhone/iPad support, and English/Simplified Chinese localizations.
- [x] Release bundle contains the app and plugin privacy manifests, declares
  no tracking or collected data, and contains no forbidden upgrade/cloud
  marketing strings or `example.com`.
- [x] iPad landscape layout verified by widget test
  (`test/pages/accessibility_layout_test.dart`).
- [ ] Capture manual iPad landscape screenshots for App Store evidence if
  desired beyond automated layout checks.

This is a software release candidate, not yet ready to submit. Every publisher
and physical-device gate below must pass first.

## Submission Blockers

- [ ] **PUBLISHER REQUIRED:** fill `docs/publisher_contact.yaml` and run
  `./tool/apply_publisher_contact.sh`.
- [x] **PUBLISHER REQUIRED:** provide a public support URL and public privacy
  policy URL in App Store Connect.
- [ ] **PUBLISHER REQUIRED:** confirm the Apple Developer Team, signing
  certificate, distribution profile, legal seller name, and bundle ID
  `com.nightelf.lessdo`.
- [ ] Remove the `DRAFT` marker only after the public policy is reachable.
- [x] Public policy and support URLs return HTTP 200 (GitHub Pages).

Do not submit while any item above remains incomplete.

## App Store Connect upload

Follow `docs/APP_STORE_CONNECT_UPLOAD.md`. Run `./tool/prepare_app_store_upload.sh`
before Archive upload. Paste metadata from `docs/app_store_connect/`.

## GitHub Pages (privacy and support URLs)

1. The public site is served from `ruancanghui-hub/ruancanghui-hub.github.io`
   under `lessdo/`.
2. Confirm these URLs return HTTP 200:
   - `https://ruancanghui-hub.github.io/lessdo/privacy.html`
   - `https://ruancanghui-hub.github.io/lessdo/support.html`
3. Optional: create a separate `lessdo` repository for the Flutter source code.
4. Update `support_email` in `docs/publisher_contact.yaml` if needed, keep
   `policy_published: true`, then run `./tool/apply_publisher_contact.sh`.

## App Store Connect

- [ ] Version is `1.0.0`; build number is greater than every uploaded build.
- [ ] Price is Free and there are no paid features in version 1.0.
- [ ] Primary category is Productivity; secondary category is Utilities.
- [ ] English and Simplified Chinese metadata match
  `docs/APP_STORE_METADATA.md`.
- [ ] App Privacy answers match `docs/APP_STORE_METADATA.md`, including Google
  AdMob third-party advertising disclosure.
- [ ] Age rating answers match the metadata worksheet.
- [ ] Review notes explain local reminders, optional biometric lock, and URL
  scheme testing.
- [ ] One to ten current screenshots are uploaded for the largest required
  iPhone and iPad display sizes in each supported language.

## Build And Compliance

- [x] Unsigned Release app uses iOS 16.0 as the minimum deployment target.
- [x] `PrivacyInfo.xcprivacy` is present in the unsigned Runner app bundle.
- [x] Only `NSFaceIDUsageDescription` is present among protected-resource
  usage descriptions in the unsigned Runner app.
- [ ] Release archive uses iOS 16.0 as the minimum deployment target.
- [ ] Encryption/export-compliance answers are reviewed against the final
  archive; LessDo contains no custom encryption.
- [ ] Archive validation reports no privacy-manifest or required-reason API
  errors.
- [ ] The final TestFlight build is installed from App Store Connect rather
  than directly from Xcode.

## Physical Device Checks

- [ ] Fresh install starts with onboarding and an empty Inbox.
- [ ] Create, edit, complete, reorder, and delete tasks and lists.
- [ ] Approve and deny notification permission; verify reminder retry.
- [ ] Verify reminder delivery after force quit, device lock, time-zone change,
  and device restart.
- [ ] Verify Face ID or Touch ID enable, cancel, failure, lockout, and recovery.
- [ ] Verify all focus modes across backgrounding and relaunch.
- [ ] Verify sharing and diagnostic export contain only expected content.
- [ ] Open the documented create and open-list deep links.
- [ ] Test English and Simplified Chinese, large text, rotation, iPhone, and
  iPad layouts.
- [ ] Confirm no unexpected network traffic during normal use.

## Final Evidence

- [x] Simulator models and OS versions recorded above.
- [ ] Physical test device models and OS versions recorded.
- [ ] TestFlight build number recorded.
- [ ] Archive validation log retained.
- [ ] App Store screenshots reviewed against the submitted build.
- [ ] Product owner signs off the exact metadata and privacy answers.
