(function attachStudyCardImagesDisabledPanelBridge(global) {
  "use strict";

  const MARKER = "APC_STUDY_CARD_IMAGES_DISABLED_PANEL_BRIDGE_R16X_SOURCE_ONLY";
  const VERSION = "stage17k-r16x-study-card-images-disabled-panel-bridge-source-only-20260708";

  const DEFAULT_SURFACES = Object.freeze([
    "study-card-editor",
    "study-card-create",
    "study-card-edit"
  ]);

  function freezeClone(value) {
    return Object.freeze(JSON.parse(JSON.stringify(value)));
  }

  function normalizeSide(side) {
    return side === "answer" ? "answer" : "question";
  }

  function createDisabledPanelDescriptor(options) {
    const opts = options && typeof options === "object" ? options : {};
    const side = normalizeSide(opts.side);
    const label = side === "answer" ? "Answer image" : "Question image";
    return freezeClone({
      marker: MARKER,
      version: VERSION,
      sourceOnly: true,
      side,
      label,
      status: "disabled-preview-only",
      buttonText: "Add " + label.toLowerCase() + " (coming soon)",
      helperText: "Images will stay browser-local. This disabled plan does not open a file picker or save anything.",
      ariaLabel: label + " control disabled until local-only image storage is enabled",
      attributes: {
        "data-apc-study-card-image-disabled-panel": side,
        "data-apc-study-card-image-source-only": "true",
        "aria-disabled": "true"
      },
      controls: {
        addButtonEnabled: false,
        removeButtonEnabled: false,
        previewEnabled: false,
        filePickerEnabled: false,
        saveEnabled: false
      }
    });
  }

  function createPanelBridgePlan(options) {
    const opts = options && typeof options === "object" ? options : {};
    const surfaces = Array.isArray(opts.surfaces) && opts.surfaces.length
      ? opts.surfaces.map(String)
      : DEFAULT_SURFACES.slice();
    return freezeClone({
      marker: MARKER,
      version: VERSION,
      sourceOnly: true,
      mountedNow: false,
      boundNow: false,
      writePathEnabledNow: false,
      surfaces,
      panels: [
        createDisabledPanelDescriptor({ side: "question" }),
        createDisabledPanelDescriptor({ side: "answer" })
      ],
      blockedActions: [
        "open-file-picker",
        "read-file-bytes",
        "create-object-url",
        "store-blob",
        "write-indexeddb",
        "write-backup-payload",
        "upload-backend",
        "sync-google-drive",
        "mutate-anki"
      ]
    });
  }

  function createNoopMountResult(reason) {
    return freezeClone({
      marker: MARKER,
      version: VERSION,
      mounted: false,
      bound: false,
      rendered: false,
      reason: reason || "source-only bridge does not touch DOM"
    });
  }

  function getSafetyFlags() {
    return freezeClone({
      marker: MARKER,
      version: VERSION,
      sourceOnly: true,
      uiMountedNow: false,
      buttonRenderedNow: false,
      controlsEnabledNow: false,
      filePickerOpenedNow: false,
      imagePreviewRenderedNow: false,
      blobStoredNow: false,
      indexedDbWriteNow: false,
      backupPayloadWriteNow: false,
      backendUploadAllowed: false,
      serverSyncAllowed: false,
      googleDriveSyncAllowedNow: false,
      ankiMutationAllowed: false,
      originalFileMutationAllowed: false,
      mediaExtractionNow: false
    });
  }

  const api = Object.freeze({
    MARKER,
    VERSION,
    createDisabledPanelDescriptor,
    createPanelBridgePlan,
    createNoopMountResult,
    getSafetyFlags
  });

  global.APC_STUDY_CARD_IMAGES_DISABLED_PANEL_BRIDGE = api;
})(typeof window !== "undefined" ? window : globalThis);
