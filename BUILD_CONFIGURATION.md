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

## Validated test builds

Use the checked wrapper to prevent test packages with empty factory addresses:

```sh
python3 tools/build_factory_app.py --config /path/to/local-factory-config.json ios --simulator --debug --no-pub
python3 tools/build_factory_app.py --config /path/to/local-factory-config.json apk --debug --no-pub
python3 tools/build_factory_app.py --config /path/to/local-factory-config.json ipa --release --export-method development --no-pub
```

Use `--flutter /path/to/flutter` before the target when Flutter is not in PATH.
The wrapper verifies every required URL and company code and passes the file to
Flutter. It never copies the configuration into Git or prints its values.

On 2026-10-15, the initial QC test artifacts omitted the define file. They were
rebuilt with the existing approved local configuration. The iPhone 16 Plus
simulator then reached the Colton login page; its mobile discovery endpoint
returned HTTP 200 / result 0. This was a packaging omission, with no backend or
network configuration change required.
