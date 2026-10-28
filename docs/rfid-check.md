# RFID Check (local pilot)

Work Order → RFID Check inherits the existing Produce menu access. Enter a UPC-A (12 digits), EAN-13 or GTIN-14 with a valid check digit, then tap Read RFID. On a supported Chainway handheld the scan keys also trigger RFID after leaving the UPC field. While the UPC field is focused, barcode keyboard input remains available.

The reader inventories for 1.8 seconds and compares a single unique SGTIN-96 EPC with the expected normalized GTIN. Multiple EPCs, no tags and unsupported formats are distinct non-pass states. Serial is not part of the product comparison. This does not validate whether the serial itself is commissioned or authentic. Keep other tagged products away from the reader. No inventory, production, print job or server record is created.

## Android SDK

Local dependency: `android/app/libs/DeviceAPI_ver20251103_release.aar` (ignored by Git). Obtain `API_Ver20251103.rar` from https://chainwayeurope.com/public/en/download/terminale-mobilne/c72 and extract the AAR. Direct vendor download: https://chainwayeurope.com/upload/materials/chainway-support/_shared/sdk/API_Ver20251103.rar

AAR SHA-256: `4eb338266e7abaf3078f14fc5fb78706efecfdc6d4783fdd3577f582fc2a2c7a`.

Vendor demo used to verify key codes: https://chainwayeurope.com/upload/materials/chainway-support/_shared/sdk/Demo-uhf_as.rar

SGTIN encoding reference: https://ref.gs1.org/standards/tds/2.3.0/

This native dependency requires installing a new Android APK; adding it to an existing binary through Dart OTA is not sufficient. No iPhone reader bridge is supplied. Unsupported devices display a reader-unavailable message. Close the vendor UHF demo before testing to release the reader.

## Checks

`flutter test test/rfid_check_test.dart test/rfid_check_widget_test.dart`

`flutter build apk --debug --target-platform android-arm64`

Hardware acceptance still required: valid/mismatching UPC, no tag, two different EPCs, repeated reads, barcode entry, hardware trigger, background/return, navigating away during read. Check the factory tag encoding against SGTIN-96 before rollout. Do not publish the pilot as production until these pass.

## Reader latency optimization (2026-10-21)

The native bridge initializes on page entry and reuses the reader between scans. Each completed scan stops inventory; page exit, background cancellation and errors free the reader. Foreground return prewarms again. The 1.8-second inventory window is unchanged. Epoch checks discard results from a cancelled session. `RfidTiming` logs local durations without EPC, UPC or business data. Device timing and repeated scan/background tests are still required before publishing this revision.

## RFID Pallet Scan (2026-10-21 local pilot)

Work Order → RFID Pallet Scan is a separate action. Start/stop with the on-screen button or scan key; continue keeps prior unique EPCs. New pallet asks before clearing. Leaving the page asks before discarding counts. Counts are not saved to MES. Backgrounding stops scanning and retains already received counts on the page.

A page-local catalog is loaded once from authenticated `GET /inventory/items` with current `companyId`, `warehouseId`, and `loadDetails=false`. The existing endpoint applies company/warehouse selection and overrides. Match ONLY `defaultInventoryAttribute1`; its tracking checkbox need not be enabled. Normalize valid UPC-A, EAN-13 and GTIN-14 to 14 digits; invalid/empty values cannot match. Multiple matching item IDs are displayed as a conflict. Catalog failures are distinct from an unmatched UPC and can be retried. Changing server/company/warehouse/user invalidates the page counts and catalog.

Native `scanPallet` streams new unique EPC batches approximately every 150 ms; the final result includes the complete batch as a recovery mechanism. App-side deduplication persists across stops/restarts on the page. No-tag periods do not imply a complete pallet. Mixed GTINs are separate rows. Unsupported encodings are counted separately and excluded from the item total. Only SGTIN-96 is currently decoded.

Safety bounds: each continuous read stops after five minutes or 50,000 unique tags; the operator can review/continue. App session storage is bounded at 50,000 EPCs. No inventory transactions, label printing, tag writing, or radio-power/frequency setting changes are performed. Read distance/nearby pallet rejection must be checked on hardware.

Checks: `flutter test test/rfid_check_test.dart test/rfid_check_widget_test.dart test/rfid_pallet_test.dart test/rfid_pallet_widget_test.dart`. Release builds include both ARM architectures and existing external factory defines. This pilot has not been published to the download server or OTA.

### Catalog loading optimization (2026-10-21)

Work Order prefetches the read-only Item catalog. Page entry shares an in-flight
request and reuses the normalized UPC index for up to two minutes. Only one
factory/server/company/warehouse/user-session scope is held in memory; switching
scopes evicts it. No catalog is persisted to disk. Manual Refresh item names
bypasses the cached result, so newly edited UPC mappings can be retrieved
immediately. Failed requests are not cached. This reduces repeat downloads; the
first request still depends on the existing Items API and network latency.
Cache expiry, request coalescing, forced refresh, failure retry and late responses
from old login scopes are covered by automated tests.

### Default whole-pallet power (2026-10-21)

The pallet page activates with palletMode=true. On the serial SDK worker, read
getPower() before any change, request 20 dBm (including reducing any higher existing setting), and read it
back before reporting success or starting inventory. This is the starting value
for site testing after 30 dBm caused reads from neighboring pallets. The original setting is retained for this reader
session and restored on release; frequency/region settings are never changed.
Only measured dBm values are shown in the English/Spanish UI. RfidPower logs
contain before/target/verified power and restore status, with no tag or item data.
Physical readback and pallet coverage must be validated on the connected device;
no claim is made that a stable tag count guarantees all tags were read.

### Field-adjustable power

The page now provides a 5–30 dBm selector in 1 dBm steps. The initial default is
10 dBm; explicit successfully verified selections are saved only in the Android
app's private SharedPreferences and reused on future activation/scans. Reading,
setting and verification use the same serial worker as inventory. Native and UI
both prevent changes during inventory; the UI also prevents starting while a
change is pending. A populated count requires confirmation before changing power
and is reset only after successful verification, to avoid retaining stray reads
from a prior higher-power test. Cancellation/failure preserves the count. The
original pre-page hardware setting is still restored when the reader is released.

## Batched item lookup (2026-10-21)

The pallet page no longer prefetches `/inventory/items`. Valid scanned GTINs are coalesced for 350 ms and sent to GET `/inventory/items-query/rfid-upcs` with companyId, warehouseId and upcs. Each request contains at most 50 distinct codes. The endpoint returns only id, name (item number), description and upc (defaultInventoryAttribute1). It preserves company/warehouse and client restrictions, including warehouse overrides. Multiple matches remain ambiguous.

The app caches successful per-UPC results (including no match) for two minutes in the current login scope. Repeated EPCs do not trigger queries. New UPCs arriving during a request are queued. Refresh explicitly retries all scanned codes. Errors are not shown as an unmatched UPC. No all-item fallback is used: the selected factory must support the new endpoint. Read counts and power controls remain independent of item lookup.

Validation: eight Flutter tests passed, including no query on entry, batching different UPCs and ignoring repeat tags. Backend compiled against the existing Fay runtime dependencies. Synthetic Java checks covered UPC/GTIN zero padding, preserving packaging indicator, invalid check digits and the 50-code limit. Real-device timing still requires a scan against the deployed endpoint.

## RFID Label Check photo OCR (2026-10-21)

The single-label menu is now RFID Label Check (Spanish: Verificación de etiqueta RFID). Take Photo uses the existing on-device ML Kit OCR channel. Complete 12/13/14 digit runs with a valid GTIN check digit become candidates. Printed spaces/hyphens are removed; letters are never guessed as digits, check digits are never repaired, and separate OCR lines are never joined. Equivalent zero-padded candidates are deduplicated.

QC must review the photo and confirm Use this UPC before reading RFID. Multiple candidates require selection; no valid candidate allows manual entry or cancellation/retake. Hardware trigger and Read RFID are blocked while photographing/reviewing. A new photo clears the previous UPC/result to avoid reusing an earlier product. Captured images are processed locally, their temporary file is deleted after recognition, and no photo upload or business-data mutation occurs.

Verification: OCR parsing tests include the supplied 618842526307 label, bad check digits, ambiguous letters, multiple codes and separate lines. Widget tests verify explicit confirmation, blocked trigger during review, valid comparison, editing invalidation and background cancellation. Camera capture/recognition quality still needs a physical-device test with the actual label.

## Home QC hub (2026-10-21)

Workspace adds a local QC group derived from the existing accessible server menus and registered mobile routes. Existing entries are retained. Inbound QC, Work Order QC, QC Sampling, RFID Label Check and RFID Pallet Scan are ordered first, with other authorized inventory inspection/sampling routes included when present. Defective appears in a separate reporting section explaining inventory/work-order quantity changes. Produce-derived RFID and Defective permissions use the same helpers as the original Work Order menu. No backend menu or account permissions are changed. English, Spanish and Chinese labels are provided.

Tests cover restricted users, unsupported routes, deduplication, source-menu preservation, grouping and navigation to the existing route.

## RFID hardware-aware menus (2026-10-21)

Workspace, Work Order and QC menus now share a cached asynchronous capability check. Non-Android / missing native plugin and clearly unsupported SDK configurations hide both RFID routes. Supported device families are probed using SDK initialization and a successful power read; model identity alone does not mark hardware available. The probe never inventories tags, changes RF power, or sends business requests. It releases the reader when no RFID page is active. Previously verified hardware is remembered in device-local preferences.

An initialization failure on a never-verified device is unknown, not proof of absence: RFID entries remain hidden with a Retry RFID detection notice. Previously verified hardware that fails initialization stays visible as temporarily unavailable with retry guidance. The Dart wait is bounded at 12 seconds; other menus are not blocked. Existing route registration and permission filtering still apply.

Six automated checks cover iOS no-native-call behavior, verified/unavailable and unknown/unsupported states, menu filtering/rebuilding, original QC permissions and navigation. Physical-device validation is deferred at the user's request; do not claim a new reader model is supported without verification.
