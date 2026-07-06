(function currentBackupDisabledSaveButtonRenderSpecR14PR2(root) {
  "use strict";

  const MARKER = "APC_LOCAL_BACKUP_CURRENT_FILE_DISABLED_SAVE_BUTTON_RENDER_SPEC_R14P_R2_SOURCE_ONLY";
  const MODE = "source-only-disabled-save-button-render-spec";
  const VIEW_MODEL_GLOBAL = "APC_LOCAL_BACKUP_CURRENT_FILE_DISABLED_SAVE_BUTTON_VIEW_MODEL";
  const LABEL = "Save current backup";

  function getViewModelApi() {
    return root && root[VIEW_MODEL_GLOBAL] ? root[VIEW_MODEL_GLOBAL] : null;
  }

  function makeFallbackViewModel(reason) {
    return {
      sourceOnly: true,
      futureEligible: false,
      buttonVisibleNow: false,
      buttonDisabledNow: true,
      actionBoundToUi: false,
      clickHandlerAdded: false,
      clickHandlerCallsWriteExecutor: false,
      writeExecutorCalled: false,
      canWriteNow: false,
      writesEnabledNow: false,
      currentFileSaveEnabledNow: false,
      sameFileWriteEnabledNow: false,
      requiresLaterDeployStage: true,
      label: LABEL,
      ariaLabel: LABEL + " disabled",
      disabledReason: reason,
      helperText: [
        "Preview only.",
        "No file is saved, replaced, merged, restored, or overwritten.",
        "No button is rendered by R14P-R2.",
        "No click handler is attached by R14P-R2."
      ],
      blockers: [reason],
      warnings: [],
      removedFieldCount: 0,
      afterLegacyFieldPaths: []
    };
  }

  function createViewModel(input, options) {
    const api = getViewModelApi();
    if (!api || typeof api.createDisabledSaveButtonViewModel !== "function") {
      return makeFallbackViewModel("Disabled save button view model is not loaded.");
    }
    return api.createDisabledSaveButtonViewModel(input || {}, options || {});
  }

  function createDisabledSaveButtonRenderSpec(input, options) {
    const viewModel = createViewModel(input, options);
    return {
      marker: MARKER,
      mode: MODE,
      sourceOnly: true,
      deployed: false,
      uiLoaded: false,
      renderSpecOnly: true,
      domElementCreated: false,
      elementInserted: false,
      buttonElementCreated: false,
      buttonVisibleNow: false,
      buttonDisabledNow: true,
      renderAllowedNow: false,
      actionBoundToUi: false,
      clickHandlerAdded: false,
      clickHandlerName: "",
      clickHandlerCallsWriteExecutor: false,
      writeExecutorCalled: false,
      canWriteNow: false,
      writesEnabledNow: false,
      currentFileSaveEnabledNow: false,
      sameFileWriteEnabledNow: false,
      requiresLaterDeployStage: true,
      requiresLaterUiMountStage: true,
      tagName: "button",
      type: "button",
      textContent: viewModel.label || LABEL,
      disabled: true,
      ariaLabel: viewModel.ariaLabel || LABEL + " disabled",
      ariaDisabled: "true",
      title: viewModel.disabledReason || "Disabled until a later explicit stage.",
      attributes: {
        type: "button",
        disabled: "disabled",
        "aria-disabled": "true",
        "aria-label": viewModel.ariaLabel || LABEL + " disabled",
        "data-apc-local-backup-disabled-save-button-render-spec-r14p-r2": "true",
        "data-apc-local-backup-disabled-save-button-source-only": "true"
      },
      classNames: [
        "apc-local-backup-disabled-save-button",
        "apc-local-backup-disabled-save-button-source-only"
      ],
      eventHandlers: {},
      helperText: Array.isArray(viewModel.helperText) ? viewModel.helperText.slice() : [],
      blockers: Array.isArray(viewModel.blockers) ? viewModel.blockers.slice() : [],
      warnings: Array.isArray(viewModel.warnings) ? viewModel.warnings.slice() : [],
      viewModel: viewModel
    };
  }

  function createDisabledSaveButtonRenderSpecText(renderSpec) {
    const spec = renderSpec || createDisabledSaveButtonRenderSpec({}, {});
    return [
      "Save current backup render spec",
      "Mode: source-only",
      "Text: " + spec.textContent,
      "Disabled: " + String(spec.disabled),
      "Visible now: " + String(spec.buttonVisibleNow),
      "DOM element created: " + String(spec.domElementCreated),
      "Element inserted: " + String(spec.elementInserted),
      "Click handler added: " + String(spec.clickHandlerAdded),
      "Action bound to UI: " + String(spec.actionBoundToUi),
      "Can write now: " + String(spec.canWriteNow),
      "Writes enabled now: " + String(spec.writesEnabledNow),
      "Write executor called: " + String(spec.writeExecutorCalled),
      "Requires later deploy stage: " + String(spec.requiresLaterDeployStage),
      "Requires later UI mount stage: " + String(spec.requiresLaterUiMountStage),
      "",
      "Safety",
      "No DOM element is created by R14P-R2.",
      "No button is inserted by R14P-R2.",
      "No click handler is attached by R14P-R2.",
      "No file is saved, replaced, merged, restored, or overwritten."
    ].join("\n");
  }

  const api = Object.freeze({
    MARKER: MARKER,
    MODE: MODE,
    createDisabledSaveButtonRenderSpec: createDisabledSaveButtonRenderSpec,
    createDisabledSaveButtonRenderSpecText: createDisabledSaveButtonRenderSpecText
  });

  root.APC_LOCAL_BACKUP_CURRENT_FILE_DISABLED_SAVE_BUTTON_RENDER_SPEC = api;

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }
})(typeof window !== "undefined" ? window : globalThis);
