# Picking display and rejection messages — 2026-10-29

Source commit: b909d66. Includes the current picked-quantity summary and picked-pallet entry before completion; Unpick refresh; consistent full-width card styling; structured backend rejection explanations with current location and a deliberate Scan Another LPN action. Unknown/legacy errors retain existing handling. Timeout or pending-confirmation recovery is not replaced by a definite rejection.

Mobile regression: 39 tests passed, including structured-error parsing, visible location/reason, clearing the scan only after acknowledgement, no automatic business POST on rejection, partial-order picked details and Unpick refresh. iPhone 16 Plus simulator build and installation passed. The backend explanation was verified by a read-only preview on Fay; its implementation is saved in cwms commit 16c2aa9.

OTA uses each existing release's unchanged native/dependency baseline and the previously verified production source variant; only the two reviewed Dart implementation files are overlaid. Map Icons.schedule to Icons.refresh_rounded as in the previous production variant, because the installed packages do not contain the schedule glyph. No new plugin, image, font or native capability is required. Do not enable native-diff bypass. Font glyph subsets and assets are checked before promotion.

Factory endpoint/company defines remain external and are not committed. The production variant excludes test-only features, as documented in ../pick-release-20261028/README.md. Keep that variant when rebuilding from source.


All six existing platform/release targets in ota-final.json were read back from Shorebird as stable and not rolled back. Existing users do not need a reinstall. Apply through the normal OTA download and close/reopen workflow, after finishing any current operation.

The user clarified that preserving installation continuity is the priority: do not require a unified native version, do not retire old OTA targets while installed devices depend on them, and do not ask employees to install a new package. A subsequently prepared Android native package is optional for new installations only; no mandatory native-upgrade policy was enabled. The iOS native migration was stopped; its ordinary OTA remains published. Do not resume native migration without a new request.
