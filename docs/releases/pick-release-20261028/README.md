# Production mobile picking OTA — 2026-10-28

All patches below were read back from Shorebird and verified on the stable track, not rolled back.

| Platform | Installed release | Patch |
|---|---|---|
| android | 1.62.4+5 | 26 |
| ios | 1.62.4+6 | 13 |
| android | 1.62.5+7 | 4 |
| android | 1.62.6+8 | 3 |
| android | 1.62.7+9 | 2 |
| android | 1.62.8+10 | 1 |

Includes continuous scanning, persisted queue status, submitter/team remaining-quantity notices, picking completion behavior, actual picked-pallet details, removal of the obsolete item-list link and history loading. Unpicked pallets leave the current list; audit history remains on the server. Luggage keeps its legacy mobile picking route and its backend was not changed.

Colton and Fay backend capability checks passed before stable promotion. Mobile full suite: 310 tests passed. Android baseline comparisons found no native differences and no missing font glyphs. iOS native compatibility passed; its font glyph set is a subset of the exact original release. Asset-diff acknowledgements cover only compatible existing glyph subsets; no native-diff bypass was used.

The iOS linker reported 47.6% Dart-code sharing with the original installed release. This is a performance caveat for older iOS installations; simulator functional checks do not establish real-device OTA performance. The server-side picking improvements remain enabled independently.

`production-dart.patch` reproduces the production Dart variant from mobile commit `3eea627`: it excludes test-only Line Clearance and retains compatible icons for installed packages. For Android 1.62.5+7 and 1.62.6+8, map `Icons.check_rounded` to existing `Icons.check` as recorded by their baselines. Build against each release's unchanged native project/dependency baseline. Factory endpoints and company configuration must be supplied privately through dart defines; they are not in this archive.
