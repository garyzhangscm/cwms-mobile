# Factory build configuration

Factory addresses and company codes are injected at build time. Keep the JSON
configuration file outside Git. It must define:

- `COLTON_API_URL`
- `FAY_API_URL` (shared by Fay Injection and Fay Recycle)
- `LUGGAGE_API_URL`
- `INJECTION_COMPANY_CODE`
- `LUGGAGE_COMPANY_CODE`

API URLs must end with `/api/`. Do not substitute company database IDs for codes.

Use the same local configuration for tests, local previews, APK builds and OTA:

```sh
flutter test --dart-define-from-file=/path/to/local-factory-config.json
flutter run --dart-define-from-file=/path/to/local-factory-config.json
flutter build apk --release --dart-define-from-file=/path/to/local-factory-config.json
shorebird patch android --release-version=VERSION --dart-define-from-file=/path/to/local-factory-config.json
```

OTA patches must only use icon glyphs already included in the original Android
release. Validate a patch on staging before moving it to stable.
