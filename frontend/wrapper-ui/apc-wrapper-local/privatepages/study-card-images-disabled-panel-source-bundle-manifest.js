(function attachDisabledPanelSourceBundleManifest(root) {
  "use strict";

  var MARKER = "APC_STUDY_CARD_IMAGES_DISABLED_PANEL_SOURCE_BUNDLE_MANIFEST_R16AH_SOURCE_ONLY";

  var PANEL_BUNDLE_ASSETS = Object.freeze([
    Object.freeze({ stage: "R16X", file: "study-card-images-disabled-panel-bridge.js", globalName: "APC_STUDY_CARD_IMAGES_DISABLED_PANEL_BRIDGE", role: "disabled bridge shell" }),
    Object.freeze({ stage: "R16Y", file: "study-card-images-panel-integration-gate.js", globalName: "APC_STUDY_CARD_IMAGES_PANEL_INTEGRATION_GATE", role: "integration gate" }),
    Object.freeze({ stage: "R16Z", file: "study-card-images-disabled-panel-bind-plan.js", globalName: "APC_STUDY_CARD_IMAGES_DISABLED_PANEL_BIND_PLAN", role: "disabled bind plan" }),
    Object.freeze({ stage: "R16AA", file: "study-card-images-disabled-panel-composition-plan.js", globalName: "APC_STUDY_CARD_IMAGES_DISABLED_PANEL_COMPOSITION_PLAN", role: "composition plan" }),
    Object.freeze({ stage: "R16AB", file: "study-card-images-disabled-panel-render-spec.js", globalName: "APC_STUDY_CARD_IMAGES_DISABLED_PANEL_RENDER_SPEC", role: "panel render spec" }),
    Object.freeze({ stage: "R16AC", file: "study-card-images-disabled-panel-html-preview-renderer.js", globalName: "APC_STUDY_CARD_IMAGES_DISABLED_PANEL_HTML_PREVIEW_RENDERER", role: "disabled panel preview renderer" }),
    Object.freeze({ stage: "R16AD", file: "study-card-images-disabled-panel-mount-target.js", globalName: "APC_STUDY_CARD_IMAGES_DISABLED_PANEL_MOUNT_TARGET", role: "mount target locator" }),
    Object.freeze({ stage: "R16AE", file: "study-card-images-disabled-panel-controller-plan.js", globalName: "APC_STUDY_CARD_IMAGES_DISABLED_PANEL_CONTROLLER_PLAN", role: "controller plan" }),
    Object.freeze({ stage: "R16AF", file: "study-card-images-disabled-panel-activation-guard.js", globalName: "APC_STUDY_CARD_IMAGES_DISABLED_PANEL_ACTIVATION_GUARD", role: "activation guard" }),
    Object.freeze({ stage: "R16AG", file: "study-card-images-disabled-panel-load-order-contract.js", globalName: "APC_STUDY_CARD_IMAGES_DISABLED_PANEL_LOAD_ORDER_CONTRACT", role: "load order contract" })
  ]);

  function cloneAsset(asset) {
    return {
      stage: asset.stage,
      file: asset.file,
      globalName: asset.globalName,
      role: asset.role
    };
  }

  function getBundleAssets() {
    return PANEL_BUNDLE_ASSETS.map(cloneAsset);
  }

  function getBundleFiles() {
    return PANEL_BUNDLE_ASSETS.map(function toFile(asset) {
      return asset.file;
    });
  }

  function getBundleGlobals() {
    return PANEL_BUNDLE_ASSETS.map(function toGlobal(asset) {
      return asset.globalName;
    });
  }

  function validateSourceBundle(files) {
    var incoming = Array.isArray(files) ? files.slice() : [];
    var expected = getBundleFiles();
    var errors = [];

    expected.forEach(function requireFile(file) {
      if (incoming.indexOf(file) === -1) {
        errors.push("missing:" + file);
      }
    });

    incoming.forEach(function rejectUnknown(file) {
      if (expected.indexOf(file) === -1) {
        errors.push("unknown:" + file);
      }
    });

    return Object.freeze({ ok: errors.length === 0, errors: Object.freeze(errors.slice()) });
  }

  function getDeploymentPlan() {
    return Object.freeze({
      sourceOnlyNow: true,
      deployNow: false,
      loadByIndexNow: false,
      mountNow: false,
      enableControlsNow: false,
      requiresSeparateDeployStage: true,
      requiresSeparateLoadStage: true,
      requiresBrowserProofBeforeEnable: true,
      bundleAssetCount: PANEL_BUNDLE_ASSETS.length
    });
  }

  function getSafetyFlags() {
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
    getBundleAssets: getBundleAssets,
    getBundleFiles: getBundleFiles,
    getBundleGlobals: getBundleGlobals,
    validateSourceBundle: validateSourceBundle,
    getDeploymentPlan: getDeploymentPlan,
    getSafetyFlags: getSafetyFlags
  });

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }

  root.APC_STUDY_CARD_IMAGES_DISABLED_PANEL_SOURCE_BUNDLE_MANIFEST = api;
})(typeof globalThis !== "undefined" ? globalThis : this);
