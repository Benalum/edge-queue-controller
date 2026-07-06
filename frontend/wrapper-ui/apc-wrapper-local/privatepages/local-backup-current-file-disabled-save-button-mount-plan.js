(function disabledSaveButtonMountPlanR14ZR2(root) {
  "use strict";

  const MARKER = "APC_LOCAL_BACKUP_CURRENT_FILE_DISABLED_SAVE_BUTTON_MOUNT_PLAN_R14Z_R2_SOURCE_ONLY";
  const MODE = "source-only-visible-disabled-save-button-mount-plan";
  const HTML_RENDERER_GLOBAL = "APC_LOCAL_BACKUP_CURRENT_FILE_DISABLED_SAVE_BUTTON_HTML_PREVIEW_RENDERER";

  function getHtmlRendererApi() {
    return root && root[HTML_RENDERER_GLOBAL] ? root[HTML_RENDERER_GLOBAL] : null;
  }

  function createVisibleDisabledSaveButtonMountPlan(input, options) {
    const htmlApi = getHtmlRendererApi();
    const preview = htmlApi && typeof htmlApi.createDisabledSaveButtonHtmlPreview === "function"
      ? htmlApi.createDisabledSaveButtonHtmlPreview(input || {}, options || {})
      : null;

    return {
      marker: MARKER,
      mode: MODE,
      sourceOnly: true,
      deployed: false,
      uiLoaded: false,
      mountPlanOnly: true,
      htmlPreviewAvailable: !!preview,
      targetSectionName: "Current backup save plan",
      targetPlacement: "after-current-backup-save-action-status-preview",
      futureElementSelector: "[data-apc-local-backup-disabled-save-button-mounted-r14z-r2='true']",
      futureButtonText: "Save current backup",
      futureButtonDisabled: true,
      futureButtonVisibleOnlyAfterLaterMountStage: true,
      domElementCreated: false,
      elementInserted: false,
      buttonElementCreated: false,
      buttonVisibleNow: false,
      buttonDisabledNow: true,
      htmlStringCreated: !!preview,
      renderAllowedNow: false,
      actionBoundToUi: false,
      clickHandlerAdded: false,
      clickHandlerCallsWriteExecutor: false,
      writeExecutorCalled: false,
      canWriteNow: false,
      writesEnabledNow: false,
      currentFileSaveEnabledNow: false,
      sameFileWriteEnabledNow: false,
      requiresLaterDeployStage: true,
      requiresLaterUiMountStage: true,
      requiresLaterBrowserProof: true,
      htmlPreview: preview,
      safety: [
        "Source-only mount plan.",
        "No DOM element is created by R14Z-R2.",
        "No button is inserted by R14Z-R2.",
        "No click handler is attached by R14Z-R2.",
        "No write executor is called by R14Z-R2.",
        "No file is saved, replaced, merged, restored, or overwritten."
      ]
    };
  }

  function createVisibleDisabledSaveButtonMountPlanText(plan) {
    const view = plan || createVisibleDisabledSaveButtonMountPlan({}, {});
    return [
      "Visible disabled Save current backup mount plan",
      "Mode: source-only",
      "Target section: " + String(view.targetSectionName),
      "Target placement: " + String(view.targetPlacement),
      "Future button text: " + String(view.futureButtonText),
      "Future button disabled: " + String(view.futureButtonDisabled),
      "DOM element created: " + String(view.domElementCreated),
      "Element inserted: " + String(view.elementInserted),
      "Button visible now: " + String(view.buttonVisibleNow),
      "Button disabled now: " + String(view.buttonDisabledNow),
      "Click handler added: " + String(view.clickHandlerAdded),
      "Action bound to UI: " + String(view.actionBoundToUi),
      "Can write now: " + String(view.canWriteNow),
      "Writes enabled now: " + String(view.writesEnabledNow),
      "Write executor called: " + String(view.writeExecutorCalled),
      "",
      "Safety",
      "No DOM element is created by R14Z-R2.",
      "No button is inserted by R14Z-R2.",
      "No click handler is attached by R14Z-R2.",
      "No file is saved, replaced, merged, restored, or overwritten."
    ].join("\n");
  }

  const api = Object.freeze({
    MARKER: MARKER,
    MODE: MODE,
    createVisibleDisabledSaveButtonMountPlan: createVisibleDisabledSaveButtonMountPlan,
    createVisibleDisabledSaveButtonMountPlanText: createVisibleDisabledSaveButtonMountPlanText
  });

  root.APC_LOCAL_BACKUP_CURRENT_FILE_DISABLED_SAVE_BUTTON_MOUNT_PLAN = api;

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }
})(typeof window !== "undefined" ? window : globalThis);
