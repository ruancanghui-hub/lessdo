# LessDo

LessDo is a local-first Flutter task manager for iPhone and iPad. Version 1.0
includes lists, grocery mode, smart date input, time-based reminders, notes,
subtasks, sharing, themes, biometric protection, deep links, and
Pomodoro/count-up/countdown focus timers.

## Supported Release

LessDo 1.0 targets iPhone and iPad on iOS/iPadOS 16 or later. It is a free,
local-first release with no account, analytics, advertising, cloud sync, or
in-app purchases.

## Run

```bash
./tool/run.sh
```

Targets:

```bash
./tool/run.sh iphone
./tool/run.sh ipad
./tool/run.sh macos
```

Manual:

```bash
flutter pub get
flutter gen-l10n
flutter run
```

## Verify

```bash
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
flutter test integration_test
flutter build ios --release --no-codesign
```

The final App Store build requires publisher-owned signing credentials. Fill
`docs/publisher_contact.yaml`, run `./tool/apply_publisher_contact.sh`, then see
`docs/APP_STORE_RELEASE.md` for the release checklist.

Optional full gate: `./tool/verify_ios_release.sh`

App Store upload prep: `./tool/prepare_app_store_upload.sh` — see
`docs/APP_STORE_CONNECT_UPLOAD.md`.

## URL Scheme

```text
lessdo://x-callback-url/create?list=Inbox&content=Call%20Alex&date=2026-06-14&time=14:00
lessdo://x-callback-url/open?list=Grocery
```
