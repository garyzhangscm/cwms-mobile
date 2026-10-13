# Android OTA update rules

The Android release remains `1.62.4+5`. This feature adds a pure-Dart Shorebird
client and does not introduce native plugins, a second release or automatic
native relaunch.

## Employee behavior

- Check on startup, foreground resume, and every 15 minutes while foregrounded.
  Login/server changes are detected within 30 seconds.
- Download patches in the background. An unavailable runtime (including a normal
  debug build) does not show an update prompt.
- Normal update: **App update ready**, with **Later** (30 minutes) and
  **Close and reopen**.
- Required update: once the minimum patch has downloaded, finish the current
  production action and review any result/error dialog, then block new UI work.
  Background requests cannot remove an already enforced update barrier.
- Closing requires explicit confirmation that the last operation was checked.
  Unsaved input is not preserved. The Android process closes; the employee taps
  the app icon to reopen and apply the patch. This is not a Flutter hot restart.
- No automatic process exit during a request, production submission, printing
  request, loading popup, or error/result review popup.
- A failed download never locks a device. Checks retry on resume or the next
  scheduled check. MES policy failures do not prevent Shorebird downloads.
- Patch rollbacks are not treated as mandatory forward upgrades. Clear/lower the
  server minimum before rolling back a required patch.

The first installation of this manager still requires one manual restart to
receive the bootstrap patch. It cannot change how already running old code works.
The iOS update path is not enabled by this Android change.

## Server rule

Resource exposes a read-only GET endpoint:

`/rf-app-version/ota-policy?releaseVersion=1.62.4%2B5`

Through the API gateway, use the `/resource` prefix and the existing Bearer token
and company ID. No new anonymous gateway permission or write endpoint is added.
Responses use the existing JSON response wrapper and `Cache-Control: no-store`.

Resource reads the file specified by `rf.ota.policy-file` (environment variable
`RF_OTA_POLICY_FILE`). Default: `/usr/local/reports/ota-policy.json`. Mount it as a
persistent file or a ConfigMap directory; avoid a ConfigMap `subPath` if live
updates are needed. No database migration is required.

Example file (ordinary updates only):

```json
{
  "android": {
    "1.62.4+5": {
      "minimumPatch": 0,
      "message": "Close and reopen the app to apply the update."
    }
  }
}
```

After publishing and validating an important patch, replace `minimumPatch` with
its actual stable Shorebird patch number. Employees below this number must
restart once that patch, or a newer one, has downloaded. Never set a minimum
before publishing/validating it. Keep `minimumPatch` at the last required patch
when publishing a newer ordinary patch; do not reset it to zero inadvertently.

Rules are isolated by exact release version, read dynamically, and have no
business data or login credentials. Missing, malformed, negative or oversized
configuration returns an ordinary policy. A pending patch below the configured
minimum does not block employees, because the necessary patch is not ready yet.

## Release checklist

1. Validate the Resource endpoint behind the existing gateway with the actual
   login token and company ID. Mount the policy file with `minimumPatch: 0`.
2. Validate an Android patch against the existing baseline using
   `shorebird patch android --release-version=1.62.4+5 --dry-run` and the existing
   local factory defines. Do not override native/asset compatibility checks.
3. Preview on a scanner before promoting a patch to stable. Test a normal prompt,
   required prompt, in-flight Confirm Defective and close/reopen on the device.
4. For the bootstrap patch, ask staff to manually close/reopen once. Subsequent
   updates use these in-app rules.
5. For important patches, raise the file's minimum only after successful publish.
   For rollback, first lower/clear the minimum, then roll back Shorebird.

Actual deployment configuration and validation logs belong in local backups,
not in source control. Implementing this feature does not itself publish a patch
or change a production policy.
