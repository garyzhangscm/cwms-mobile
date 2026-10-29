# Mobile development and release rules

## Required OTA baselines (user decision, 2026-10-29)

- Android: Shorebird release `1.62.4+5`, Flutter `3.47.5`.
- iOS: Shorebird release `1.62.4+6`, Flutter `3.47.6`.
- Shorebird app: `0ff64904-5fd2-4b65-96ec-896a0e29afcc`.
- These are the only supported native release baselines. Develop the latest features and fixes, then build compatible OTA patches separately against these two baselines.
- The user prioritizes existing employees receiving updates without reinstalling. Do not create new native releases, increment installation versions, force migration/reinstallation, or resurrect deleted test releases without explicit user approval.
- If native/plugin/engine/font/asset incompatibility makes an OTA impossible, explain the exact limitation and obtain approval before changing either baseline. Never bypass native compatibility checks to force a patch.
- Use the correct original Flutter version, dependencies, native configuration and artifacts for each baseline. Verify OTA compatibility (including icon/font coverage) and test before promotion.
- Use the latest complete reviewed source. A fixed native baseline does NOT mean reverting source to an old snapshot or overwriting previously accepted features.
- Do not delete either baseline or its active OTA patches as cleanup.
- Android patch 27 and iOS patch 14 were current when this rule was written; patch numbers may advance. The fixed values above are native release versions, not patch numbers.

## Retired releases

The user explicitly deleted Android `1.62.5+7`, `1.62.6+8`, `1.62.7+9`, `1.62.8+10`, and `1.62.9+11` on 2026-10-29. Their earlier multi-baseline rollout instructions in historical release notes are superseded by this rule. The `1.62.9+11` public APK was also removed and privately backed up. Do not republish it as a download.
