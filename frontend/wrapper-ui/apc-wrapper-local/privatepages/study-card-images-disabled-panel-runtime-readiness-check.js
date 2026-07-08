(function attachR16AIRuntimeReadiness(root) {
  "use strict";

  const MARKER = "APC_STUDY_CARD_IMAGES_DISABLED_PANEL_RUNTIME_READINESS_R16AI_SOURCE_ONLY";
  const STAGE = "stage-17k-r16ai-study-card-images-disabled-panel-runtime-readiness-source-only";

  const requiredPanelAssets = Object.freeze([
    "study-card-images-disabled-panel-bridge.js",
    "study-card-images-panel-integration-gate.js",
    "study-card-images-disabled-panel-bind-plan.js",
    "study-card-images-disabled-panel-composition-plan.js",
    "study-card-images-disabled-panel-render-spec.js",
    "study-card-images-disabled-panel-html-preview-renderer.js",
    "study-card-images-disabled-panel-mount-target.js",
    "study-card-images-disabled-panel-controller-plan.js",
    "study-card-images-disabled-panel-activation-guard.js",
    "study-card-images-disabled-panel-load-order-contract.js",
    "study-card-images-disabled-panel-source-bundle-manifest.js"
  ]);

  const disabledRuntimeFlags = Object.freeze({
    mounted: false,
    controlsEnabled: false,
    pickerEnabled: false,
    previewEnabled: false,
    binaryWriteEnabled: false,
    syncEnabled: false,
    serverTransferEnabled: false,
    deckMutationEnabled: false
  });

  function listMissingAssets(registry) {
    const source = registry && typeof registry === "object" ? registry : {};
    return requiredPanelAssets.filter((name) => source[name] !== true);
  }

  function evaluateReadiness(registry) {
    const missingAssets = listMissingAssets(registry);
    return Object.freeze({
      stage: STAGE,
      marker: MARKER,
      sourceOnly: true,
      runtimeEnabled: false,
      readyToLoadAsDisabledPanel: missingAssets.length === 0,
      missingAssets,
      disabledRuntimeFlags
    });
  }

  const api = Object.freeze({
    stage: STAGE,
    marker: MARKER,
    sourceOnly: true,
    runtimeEnabled: false,
    loadedByIndex: false,
    deploy: false,
    mount: false,
    requiredPanelAssets,
    disabledRuntimeFlags,
    listMissingAssets,
    evaluateReadiness
  });

  root[MARKER] = api;
  root.APC_STUDY_CARD_IMAGES_DISABLED_PANEL_RUNTIME_READINESS_R16AI = api;
})(typeof window !== "undefined" ? window : globalThis);
