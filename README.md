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

The final App Store build requires publisher-owned signing credentials. See
`docs/APP_STORE_RELEASE.md` for the release checklist.

## URL Scheme

```text
lessdo://x-callback-url/create?list=Inbox&content=Call%20Alex&date=2026-06-14&time=14:00
lessdo://x-callback-url/open?list=Grocery
```
