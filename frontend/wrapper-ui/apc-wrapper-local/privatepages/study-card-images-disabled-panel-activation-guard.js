(function attachStudyCardImagesDisabledPanelActivationGuard(global) {
  "use strict";

  var MARKER = "APC_STUDY_CARD_IMAGES_DISABLED_PANEL_ACTIVATION_GUARD_R16AF_SOURCE_ONLY";
  var STAGE = "stage-17k-r16af-study-card-images-disabled-panel-activation-guard-source-only";

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

  function normalizeProofs(proofs) {
    if (!Array.isArray(proofs)) return [];
    return proofs
      .map(function toText(item) { return String(item || "").trim(); })
      .filter(function keepText(item, index, arr) { return item && arr.indexOf(item) === index; });
  }

  function createDisabledPanelActivationGuard(input) {
    var options = input && typeof input === "object" ? input : {};
    var proofs = normalizeProofs(options.proofs);
    var requiredProofs = Object.freeze([
      "PASS_R16V_DISABLED_MOUNT_PLAN_LOADED_NO_UI_NO_BINDING",
      "R16W_RECORDED_DISABLED_MOUNT_PLAN_LOADED_BROWSER_PROOF",
      "R16X_DISABLED_PANEL_BRIDGE_SOURCE_ONLY",
      "R16Y_PANEL_INTEGRATION_GATE_SOURCE_ONLY",
      "R16Z_DISABLED_PANEL_BIND_PLAN_SOURCE_ONLY",
      "R16AA_DISABLED_PANEL_COMPOSITION_SOURCE_ONLY",
      "R16AB_DISABLED_PANEL_RENDER_SPEC_SOURCE_ONLY",
      "R16AC_DISABLED_PANEL_HTML_PREVIEW_RENDERER_SOURCE_ONLY",
      "R16AD_DISABLED_PANEL_MOUNT_TARGET_SOURCE_ONLY",
      "R16AE_DISABLED_PANEL_CONTROLLER_SOURCE_ONLY"
    ]);
    var missingProofs = requiredProofs.filter(function missing(proof) {
      return proofs.indexOf(proof) === -1;
    });

    return Object.freeze({
      marker: MARKER,
      stage: STAGE,
      sourceOnly: true,
      canActivateVisibleDisabledPanelNow: false,
      canEnableControlsNow: false,
      canOpenFilePickerNow: false,
      canRenderImagePreviewNow: false,
      canStoreBlobNow: false,
      canWriteBackupPayloadNow: false,
      canUploadNow: false,
      canSyncNow: false,
      canMutateAnkiNow: false,
      requiredProofs: requiredProofs,
      providedProofs: Object.freeze(proofs),
      missingProofs: Object.freeze(missingProofs),
      safety: clone(getSafetyFlags()),
      nextAllowedStep: "deploy-and-load-panel-planning-assets-still-no-ui",
      explanation: "This guard keeps the study-card image panel inactive until a later explicit visible-disabled-panel stage."
    });
  }

  function evaluateActivationRequest(input) {
    var guard = createDisabledPanelActivationGuard(input);
    return Object.freeze({
      marker: MARKER,
      stage: STAGE,
      approved: false,
      reason: "R16AF is a source-only activation guard. It does not approve UI mounting, file picking, preview rendering, storage, backup writing, upload, sync, or Anki mutation.",
      canActivateVisibleDisabledPanelNow: guard.canActivateVisibleDisabledPanelNow,
      missingProofs: guard.missingProofs,
      safety: guard.safety
    });
  }

  function validateDisabledPanelActivationGuard(guard) {
    if (!guard || typeof guard !== "object") return false;
    if (guard.marker !== MARKER) return false;
    if (guard.sourceOnly !== true) return false;
    if (guard.canActivateVisibleDisabledPanelNow !== false) return false;
    if (guard.canEnableControlsNow !== false) return false;
    if (guard.canOpenFilePickerNow !== false) return false;
    if (guard.canRenderImagePreviewNow !== false) return false;
    if (guard.canStoreBlobNow !== false) return false;
    if (guard.canWriteBackupPayloadNow !== false) return false;
    if (guard.canUploadNow !== false) return false;
    if (guard.canSyncNow !== false) return false;
    if (guard.canMutateAnkiNow !== false) return false;
    if (!Array.isArray(guard.requiredProofs) || guard.requiredProofs.length < 1) return false;
    if (!Array.isArray(guard.missingProofs)) return false;
    return true;
  }

  var api = Object.freeze({
    MARKER: MARKER,
    STAGE: STAGE,
    getSafetyFlags: getSafetyFlags,
    createDisabledPanelActivationGuard: createDisabledPanelActivationGuard,
    evaluateActivationRequest: evaluateActivationRequest,
    validateDisabledPanelActivationGuard: validateDisabledPanelActivationGuard
  });

  global.APC_STUDY_CARD_IMAGES_DISABLED_PANEL_ACTIVATION_GUARD = api;

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }
})(typeof window !== "undefined" ? window : globalThis);
