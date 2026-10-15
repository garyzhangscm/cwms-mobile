# QC OTA rollout — 2026-10-15

Source: `b1b69d9e9a3d816dd3e72803b3444d7336d3d8d0`, branch `codex/ipad-layout`.
Shorebird app: `0ff64904-5fd2-4b65-96ec-896a0e29afcc`.

## Changes

Colton and Fay use persisted checkpoint preparation, explicit Yes/No answers, inline nonconformance warnings, mandatory exception notes and one final failure confirmation. The confirmed API rechecks stored standards. An uncertain network outcome requires a status lookup before another submission. The whole interaction stays protected from OTA restarts.

Mira Loma Luggage keeps its pre-existing QC endpoint and does not call the new preparation/confirmed APIs or require unsupported exception-note fields. The legacy submission method is restricted to that factory; it cannot silently bypass confirmed review for Colton/Fay.

## Compatibility and verification

- All 50 targeted QC/inbound/OTA tests passed with the complete external factory define file. Changed-code analysis reports no issues.
- The configured Colton/Fay inventory deployments were rechecked as 1/1 ready before rollout.
- No new native plugin or native-code change is included. Native-diff verification remains enabled.
- Original icon font contains 87 glyphs; this patch references 86, with no newly required codepoint. Two new radio glyph references were replaced by pre-existing check-circle glyphs. The old font remains in installed apps.
- Android's original NOTICES asset predates the pure-Dart shorebird_code_push dependency. Its exact MIT notice is included through LicenseRegistry in Dart; the immutable old asset does not drop the notice from the running app's license registry. iOS already carries that notice.
- Asset differences were explicitly allowed only after those checks. No native-diff bypass was used.
- Android arm32, arm64 and x86_64 output binaries were checked for all five factory settings and the license notice.
- Android staging Patch 13 was downloaded and activated on the dedicated emulator. Runtime logs show patches/13/dlc.vmcode; Colton factory selection reaches the login page. No production QC was submitted for QA.
- iOS functional QC was tested in the normal iPhone 16 Plus simulator build and unit tests. Simulator builds are separate from the device OTA baseline; an iPhone OTA activation is not claimed by that simulator test.

## Baselines and rollout

- Android: 1.62.4+5 / Flutter 3.47.5; previous stable patch 11. Final Patch 13 promoted to stable and independently read back active for all three architectures.
- iOS: 1.62.4+6 / Flutter 3.47.6; previous baseline had no patch. Final Patch 2 promoted to stable and independently read back active for arm64.

Earlier Android staging Patch 12 was superseded and rolled back; it was never promoted to stable. Earlier iOS staging Patch 1 was also superseded and rolled back; it was never promoted to stable.

Installed OTA-enabled users receive the patch on their matching platform/release. The patch becomes active after the download and a normal restart (or the app's explicit restart action). Independently built test APKs and simulator apps are not OTA distribution targets.

## Recovery

Record and inspect current patch state before any rollback. Android rollback target is the pre-existing stable patch 11; iOS fallback is its original 1.62.4+6 baseline. The user selected OTA publication after simulator testing; no backend deployment is part of this OTA action. Build configurations, authentication, full debug artifacts and device logs are kept outside Git.

## Final publication verification

Android Patch 13 and iOS Patch 2 were both independently read back from Shorebird as stable and active on 2026-10-15. Existing installed release/build numbers are unchanged. The complete external factory configuration was verified in both artifacts.

iOS AOT linking reported 81.8% code sharing and warned that patched code may execute slower than the baseline. No native-code mismatch was bypassed. Normal simulator functionality and unit tests passed; physical-device QC latency for the iOS OTA has not been benchmarked. Treat that as an unverified performance limit, not a measured regression.

One iOS upload attempt failed to refresh credentials after a long link step. A fresh CLI session could authenticate; the final retry completed with other CLI authentication operations kept sequential. Credentials were never printed or stored in this release record.
