# Stage 17K-R14A — Record Manual Executor Fake-Handle Proof

## Status

Browser console proof passed.

## Baseline

R13Y deployed the R13X current backup write executor as a static asset only.

R13Z recorded that the executor asset was available but not loaded by Profile.

## Browser proof result

Console proof printed:

- PASS_R14A_MANUAL_EXECUTOR_FAKE_HANDLE_PROOF

## Expected signed-out noise

A 401 network line from `/api/me` appeared while signed out and is expected.

## Manual load proof

Verified:

- beforeLoaded false
- hasExecutorAfterManualLoad true
- executorMarker APC_LOCAL_BACKUP_CURRENT_FILE_WRITE_EXECUTOR_R13X_SOURCE_ONLY
- hasWriter true

This confirms the executor was not loaded by normal Profile page load and was only loaded manually by the proof script.

## Plan proof

Verified:

- planSelectedFileAllowed true
- planWriterPlanReady true
- planRemovedFieldCount 4
- planAfterLegacyFieldPaths []

## Refusal proof

Running the executor without explicit write enablement refused the operation.

Verified:

- refusedExecuted false
- refusedRefused true

Refusal errors included:

- Write execution refused because enableWrite is not true.
- Write execution refused because enableToken does not match.
- Write execution refused because confirmSelectedFileName does not match buddies-who-study-current.json.

## Fake-handle execution proof

Running the executor with fake in-memory handles and explicit guard token succeeded.

Verified:

- executedExecuted true
- executedWrotePrevious true
- executedWroteCurrent true
- executedReadbackVerified true
- executedReadbackLegacyFieldPaths []

## Fake previous file proof

Verified:

- previousFakeText OLD_CURRENT_BACKUP_TEXT

This proves the executor wrote the old current contents to the fake previous file before replacing the fake current file.

## Fake current file proof

Verified:

- currentHasSanitizedPrivacy true
- currentHasLegacyBackendProgress false

This proves the fake current file received sanitized local-only JSON and no legacy backendProgress field.

## Real-file safety

The browser proof used fake in-memory file handles only.

No real local file was selected, saved, replaced, merged, restored, or overwritten.

## Safety

Docs/evidence only.

No source mutation.
No frontend deploy.
No backend deploy.
No runtime mutation.
No service restart.
No DB write.
No signup change.
No Google Drive or OAuth activation.
No server private Study persistence.
No Anki source file mutation.
No Anki scheduling mutation.
No local Study restore write.
No current-file save in live UI.
No same-file write path in live UI.
No media blob persistence.
No media extraction.
No SQLite parsing execution.
No Companion model/helper call.
