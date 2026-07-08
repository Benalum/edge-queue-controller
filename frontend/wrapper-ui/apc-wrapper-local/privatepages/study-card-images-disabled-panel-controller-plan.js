(function attachStudyCardImagesDisabledPanelControllerPlan(global) {
  "use strict";

  var MARKER = "APC_STUDY_CARD_IMAGES_DISABLED_PANEL_CONTROLLER_PLAN_R16AE_SOURCE_ONLY";
  var STAGE = "stage-17k-r16ae-study-card-images-disabled-panel-controller-source-only";

  function clone(value) {
    return JSON.parse(JSON.stringify(value));
  }

  function getSafetyFlags() {
    return Object.freeze({
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
      mediaExtractionNow: false,
      uploadsNow: false,
      writesBackupNow: false,
      writesIndexedDbNow: false,
      mutatesAnkiNow: false
    });
  }

  function createDisabledPanelControllerPlan(input) {
    var options = input && typeof input === "object" ? input : {};
    var cardId = typeof options.cardId === "string" && options.cardId.trim() ? options.cardId.trim() : "pending-card";
    var sides = Array.isArray(options.sides) && options.sides.length ? options.sides.slice() : ["question", "answer"];
    var normalizedSides = sides
      .map(function mapSide(side) { return String(side || "").toLowerCase().trim(); })
      .filter(function filterSide(side, index, arr) {
        return (side === "question" || side === "answer") && arr.indexOf(side) === index;
      });

    if (!normalizedSides.length) normalizedSides = ["question", "answer"];

    return Object.freeze({
      marker: MARKER,
      stage: STAGE,
      sourceOnly: true,
      cardId: cardId,
      mode: "disabled-panel-controller-plan",
      loadedByIndexNow: false,
      mountedNow: false,
      bindingsActiveNow: false,
      controlsEnabledNow: false,
      writePathEnabledNow: false,
      safety: clone(getSafetyFlags()),
      dependencies: Object.freeze([
        "APC_STUDY_CARD_IMAGES_LOCAL_ONLY_CONTRACT",
        "APC_STUDY_CARD_IMAGES_LOCAL_STORAGE_ADAPTER_CONTRACT",
        "APC_STUDY_CARD_IMAGES_BACKUP_MANIFEST_CONTRACT",
        "APC_STUDY_CARD_IMAGES_CARD_EDITOR_UI_PLAN",
        "APC_STUDY_CARD_IMAGES_DISABLED_RENDER_SPEC",
        "APC_STUDY_CARD_IMAGES_DISABLED_HTML_PREVIEW_RENDERER",
        "APC_STUDY_CARD_IMAGES_DISABLED_MOUNT_PLAN",
        "APC_STUDY_CARD_IMAGES_DISABLED_PANEL_BRIDGE",
        "APC_STUDY_CARD_IMAGES_PANEL_INTEGRATION_GATE",
        "APC_STUDY_CARD_IMAGES_DISABLED_PANEL_BIND_PLAN",
        "APC_STUDY_CARD_IMAGES_DISABLED_PANEL_COMPOSITION_PLAN",
        "APC_STUDY_CARD_IMAGES_DISABLED_PANEL_RENDER_SPEC",
        "APC_STUDY_CARD_IMAGES_DISABLED_PANEL_HTML_PREVIEW_RENDERER",
        "APC_STUDY_CARD_IMAGES_DISABLED_PANEL_MOUNT_TARGET"
      ]),
      sections: Object.freeze(normalizedSides.map(function toSection(side) {
        return Object.freeze({
          side: side,
          label: side === "question" ? "Question image" : "Answer image",
          state: "disabled",
          buttonText: side === "question" ? "Add question image" : "Add answer image",
          buttonDisabled: true,
          fileInputAllowedNow: false,
          previewAllowedNow: false,
          removeAllowedNow: false,
          localOnlyNotice: "Image support is being prepared. No image picker, preview, storage, backup write, upload, sync, or Anki mutation is active in this stage."
        });
      })),
      nextAllowedStage: "visible-disabled-panel-mount-after-browser-proof",
      forbiddenUntilEnabled: Object.freeze([
        "open file picker",
        "read selected file bytes",
        "create object URL",
        "write image blob to IndexedDB",
        "write image bytes into backup payload",
        "upload image bytes",
        "sync image bytes to Google Drive",
        "mutate Anki or APKG files"
      ])
    });
  }

  function validateDisabledPanelControllerPlan(plan) {
    if (!plan || typeof plan !== "object") return false;
    if (plan.marker !== MARKER) return false;
    if (plan.sourceOnly !== true) return false;
    if (plan.loadedByIndexNow !== false) return false;
    if (plan.mountedNow !== false) return false;
    if (plan.bindingsActiveNow !== false) return false;
    if (plan.controlsEnabledNow !== false) return false;
    if (plan.writePathEnabledNow !== false) return false;
    if (!Array.isArray(plan.sections) || plan.sections.length < 1) return false;
    return plan.sections.every(function checkSection(section) {
      return section &&
        section.state === "disabled" &&
        section.buttonDisabled === true &&
        section.fileInputAllowedNow === false &&
        section.previewAllowedNow === false &&
        section.removeAllowedNow === false;
    });
  }

  var api = Object.freeze({
    MARKER: MARKER,
    STAGE: STAGE,
    getSafetyFlags: getSafetyFlags,
    createDisabledPanelControllerPlan: createDisabledPanelControllerPlan,
    validateDisabledPanelControllerPlan: validateDisabledPanelControllerPlan
  });

  global.APC_STUDY_CARD_IMAGES_DISABLED_PANEL_CONTROLLER_PLAN = api;

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }
})(typeof window !== "undefined" ? window : globalThis);
