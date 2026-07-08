(function attachDisabledPanelLoadOrderContract(root) {
  "use strict";

  var MARKER = "APC_STUDY_CARD_IMAGES_DISABLED_PANEL_LOAD_ORDER_CONTRACT_R16AG_SOURCE_ONLY";

  var LOAD_ORDER = Object.freeze([
    Object.freeze({ key: "localOnlyContract", file: "study-card-images-local-only-contract.js", globalName: "APC_STUDY_CARD_IMAGES_LOCAL_ONLY_CONTRACT", requiredBeforeMount: true }),
    Object.freeze({ key: "storageAdapterContract", file: "study-card-images-local-storage-adapter-contract.js", globalName: "APC_STUDY_CARD_IMAGES_LOCAL_STORAGE_ADAPTER_CONTRACT", requiredBeforeMount: true }),
    Object.freeze({ key: "backupManifestContract", file: "study-card-images-backup-manifest-contract.js", globalName: "APC_STUDY_CARD_IMAGES_BACKUP_MANIFEST_CONTRACT", requiredBeforeMount: true }),
    Object.freeze({ key: "cardEditorUiPlan", file: "study-card-images-card-editor-ui-plan.js", globalName: "APC_STUDY_CARD_IMAGES_CARD_EDITOR_UI_PLAN", requiredBeforeMount: true }),
    Object.freeze({ key: "disabledRenderSpec", file: "study-card-images-disabled-render-spec.js", globalName: "APC_STUDY_CARD_IMAGES_DISABLED_RENDER_SPEC", requiredBeforeMount: true }),
    Object.freeze({ key: "disabledHtmlPreviewRenderer", file: "study-card-images-disabled-html-preview-renderer.js", globalName: "APC_STUDY_CARD_IMAGES_DISABLED_HTML_PREVIEW_RENDERER", requiredBeforeMount: true }),
    Object.freeze({ key: "disabledMountPlan", file: "study-card-images-disabled-mount-plan.js", globalName: "APC_STUDY_CARD_IMAGES_DISABLED_MOUNT_PLAN", requiredBeforeMount: true }),
    Object.freeze({ key: "disabledPanelBridge", file: "study-card-images-disabled-panel-bridge.js", globalName: "APC_STUDY_CARD_IMAGES_DISABLED_PANEL_BRIDGE", requiredBeforeMount: false }),
    Object.freeze({ key: "panelIntegrationGate", file: "study-card-images-panel-integration-gate.js", globalName: "APC_STUDY_CARD_IMAGES_PANEL_INTEGRATION_GATE", requiredBeforeMount: false }),
    Object.freeze({ key: "disabledPanelBindPlan", file: "study-card-images-disabled-panel-bind-plan.js", globalName: "APC_STUDY_CARD_IMAGES_DISABLED_PANEL_BIND_PLAN", requiredBeforeMount: false }),
    Object.freeze({ key: "disabledPanelCompositionPlan", file: "study-card-images-disabled-panel-composition-plan.js", globalName: "APC_STUDY_CARD_IMAGES_DISABLED_PANEL_COMPOSITION_PLAN", requiredBeforeMount: false }),
    Object.freeze({ key: "disabledPanelRenderSpec", file: "study-card-images-disabled-panel-render-spec.js", globalName: "APC_STUDY_CARD_IMAGES_DISABLED_PANEL_RENDER_SPEC", requiredBeforeMount: false }),
    Object.freeze({ key: "disabledPanelHtmlPreviewRenderer", file: "study-card-images-disabled-panel-html-preview-renderer.js", globalName: "APC_STUDY_CARD_IMAGES_DISABLED_PANEL_HTML_PREVIEW_RENDERER", requiredBeforeMount: false }),
    Object.freeze({ key: "disabledPanelMountTarget", file: "study-card-images-disabled-panel-mount-target.js", globalName: "APC_STUDY_CARD_IMAGES_DISABLED_PANEL_MOUNT_TARGET", requiredBeforeMount: false }),
    Object.freeze({ key: "disabledPanelControllerPlan", file: "study-card-images-disabled-panel-controller-plan.js", globalName: "APC_STUDY_CARD_IMAGES_DISABLED_PANEL_CONTROLLER_PLAN", requiredBeforeMount: false }),
    Object.freeze({ key: "disabledPanelActivationGuard", file: "study-card-images-disabled-panel-activation-guard.js", globalName: "APC_STUDY_CARD_IMAGES_DISABLED_PANEL_ACTIVATION_GUARD", requiredBeforeMount: false })
  ]);

  function cloneEntry(entry) {
    return {
      key: entry.key,
      file: entry.file,
      globalName: entry.globalName,
      requiredBeforeMount: entry.requiredBeforeMount === true
    };
  }

  function getLoadOrder() {
    return LOAD_ORDER.map(cloneEntry);
  }

  function getExpectedFiles() {
    return LOAD_ORDER.map(function toFile(entry) {
      return entry.file;
    });
  }

  function getExpectedGlobalNames() {
    return LOAD_ORDER.map(function toGlobal(entry) {
      return entry.globalName;
    });
  }

  function validateLoadOrder(files) {
    var incoming = Array.isArray(files) ? files.slice() : [];
    var expected = getExpectedFiles();
    var errors = [];

    expected.forEach(function requireFile(file, index) {
      if (incoming.indexOf(file) === -1) {
        errors.push("missing:" + file);
        return;
      }
      var observedIndex = incoming.indexOf(file);
      if (observedIndex !== index) {
        errors.push("order:" + file + ":expected:" + index + ":actual:" + observedIndex);
      }
    });

    incoming.forEach(function rejectUnknown(file) {
      if (expected.indexOf(file) === -1) {
        errors.push("unknown:" + file);
      }
    });

    return Object.freeze({ ok: errors.length === 0, errors: Object.freeze(errors.slice()) });
  }

  function createNoUiNoWriteSummary() {
    return Object.freeze({
      sourceOnly: true,
      loadedByIndexNow: false,
      deployedNow: false,
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

  var api = Object.freeze({
    MARKER: MARKER,
    getLoadOrder: getLoadOrder,
    getExpectedFiles: getExpectedFiles,
    getExpectedGlobalNames: getExpectedGlobalNames,
    validateLoadOrder: validateLoadOrder,
    getSafetyFlags: createNoUiNoWriteSummary
  });

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }

  root.APC_STUDY_CARD_IMAGES_DISABLED_PANEL_LOAD_ORDER_CONTRACT = api;
})(typeof globalThis !== "undefined" ? globalThis : this);
