# LessDo

LessDo is a local-first Flutter task manager for iPhone, iPad, Android, macOS,
and the web. Version 1.0 includes lists, grocery mode, smart date input,
time-based reminders, notes, subtasks, sharing, themes, biometric protection,
deep links, and Pomodoro/count-up/countdown focus timers.

## Run

```bash
flutter pub get
flutter run
```

## Verify

```bash
flutter analyze
flutter test
flutter build web
flutter build appbundle
flutter build ipa
```

The final Android and Apple store builds require publisher-owned signing
credentials. In-app purchase products must be created with these identifiers:

- `lessdo_premium_monthly`
- `lessdo_premium_yearly`

## URL Scheme

```text
lessdo://x-callback-url/create?list=Inbox&content=Call%20Alex&date=2026-06-14&time=14:00
lessdo://x-callback-url/open?list=Grocery
```

See `docs/APP_STORE_RELEASE.md` for the release checklist.
