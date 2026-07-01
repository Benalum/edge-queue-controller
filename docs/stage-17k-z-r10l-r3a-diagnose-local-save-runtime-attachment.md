# Stage 17K-Z-R10L-R3A — Diagnose Local Save Runtime Attachment

R10L and R10L-R2 deployed static source successfully, but browser testing still showed:

- `APC_LOCAL_SAVE.listDocs({ namespace: "study" })` returned `0`
- R10L-R2 patch marker was not present on the live `APC_LOCAL_SAVE` object

This checkpoint collects source and live static diagnostics and creates a browser runtime diagnostic snippet.

No deploy or source patch is performed in this stage.
