(function currentBackupDisabledSaveButtonViewModelR14K(root) {
  "use strict";

  const MARKER = "APC_LOCAL_BACKUP_CURRENT_FILE_DISABLED_SAVE_BUTTON_VIEW_MODEL_R14K_SOURCE_ONLY";
  const MODE = "source-only-disabled-save-button-view-model";
  const CURRENT_FILE_NAME = "buddies-who-study-current.json";
  const PREVIOUS_FILE_NAME = "buddies-who-study-current.previous.json";
  const LABEL = "Save current backup";

  function getControllerApi() {
    return root && root.APC_LOCAL_BACKUP_CURRENT_FILE_SAVE_ACTION_CONTROLLER
      ? root.APC_LOCAL_BACKUP_CURRENT_FILE_SAVE_ACTION_CONTROLLER
      : null;
  }

  function asArray(value) {
    return Array.isArray(value) ? value.slice() : [];
  }

  function safeState(input, options) {
    const controller = getControllerApi();
    const errors = [];

    if (!controller || typeof controller.createSaveCurrentBackupActionState !== "function") {
      errors.push("Save action controller is not loaded.");
      return {
        state: null,
        errors: errors
      };
    }

    try {
      return {
        state: controller.createSaveCurrentBackupActionState(input || {}, options || {}),
        errors: []
      };
    } catch (error) {
      errors.push(String(error && error.message ? error.message : error));
      return {
        state: null,
        errors: errors
      };
    }
  }

  function createDisabledSaveButtonViewModel(input, options) {
    const result = safeState(input, options);
    const state = result.state;
    const stateErrors = result.errors;
    const blockers = state ? asArray(state.blockers) : stateErrors;
    const warnings = state ? asArray(state.warnings) : [];
    const futureEligible = Boolean(state && state.eligibleForFutureEnablement === true);
    const futureMayShow = Boolean(state && state.canShowFutureSaveButton === true);

    return {
      marker: MARKER,
      mode: MODE,
      sourceOnly: true,
      deployed: false,
      uiLoaded: false,
      domElementCreated: false,
      buttonElementCreated: false,
      buttonVisibleNow: false,
      buttonDisabledNow: true,
      buttonMayBeShownInFutureStage: futureMayShow,
      futureEligible: futureEligible,
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
      requiresUserGestureInLaterStage: true,
      requiresExplicitEnableTokenInLaterStage: true,
      label: LABEL,
      ariaLabel: LABEL + " disabled",
      disabledReason: futureEligible
        ? "Future eligible, but disabled because R14K is source-only and does not render or bind a save action."
        : blockers.join(" "),
      helperText: [
        "Preview only.",
        "No file is saved, replaced, merged, restored, or overwritten.",
        "No Save button is rendered in R14K.",
        "No click handler is attached in R14K.",
        "A later explicit stage is required before any current-file save UI can exist."
      ],
      currentFileName: CURRENT_FILE_NAME,
      previousFileName: PREVIOUS_FILE_NAME,
      selectedFileName: state ? state.selectedFileName : "",
      selectedFileAllowed: Boolean(state && state.selectedFileAllowed === true),
      currentFileHandleAllowed: Boolean(state && state.currentFileHandleAllowed === true),
      directoryHandlePresent: Boolean(state && state.directoryHandlePresent === true),
      sanitizedPlanReady: Boolean(state && state.sanitizedPlanReady === true),
      removedFieldCount: state ? Number(state.removedFieldCount || 0) : 0,
      afterLegacyFieldPaths: state && Array.isArray(state.afterLegacyFieldPaths) ? state.afterLegacyFieldPaths.slice() : [],
      controllerLoaded: Boolean(state),
      controllerMarker: state && state.marker ? state.marker : "",
      executorLoaded: Boolean(state && state.executorLoaded === true),
      executorHasPlanningFunction: Boolean(state && state.executorHasPlanningFunction === true),
      executorHasWriteFunction: Boolean(state && state.executorHasWriteFunction === true),
      blockers: blockers,
      warnings: warnings,
      actionState: state
    };
  }

  function createDisabledSaveButtonStatusText(viewModel) {
    const vm = viewModel || createDisabledSaveButtonViewModel({}, {});
    const lines = [
      "Save current backup button view model",
      "Mode: source-only",
      "Label: " + vm.label,
      "Visible now: " + String(vm.buttonVisibleNow),
      "Disabled now: " + String(vm.buttonDisabledNow),
      "Future eligible: " + String(vm.futureEligible),
      "May be shown in later stage: " + String(vm.buttonMayBeShownInFutureStage),
      "Click handler added: " + String(vm.clickHandlerAdded),
      "Action bound to UI: " + String(vm.actionBoundToUi),
      "Can write now: " + String(vm.canWriteNow),
      "Writes enabled now: " + String(vm.writesEnabledNow),
      "Current-file save enabled now: " + String(vm.currentFileSaveEnabledNow),
      "Same-file write enabled now: " + String(vm.sameFileWriteEnabledNow),
      "Write executor called: " + String(vm.writeExecutorCalled),
      "Current file: " + vm.currentFileName,
      "Last-good file: " + vm.previousFileName,
      "Legacy backend cache fields removed: " + String(vm.removedFieldCount),
      "After legacy backend cache fields: " + (vm.afterLegacyFieldPaths.length ? vm.afterLegacyFieldPaths.join(", ") : "none"),
      "",
      "Safety"
    ];

    vm.helperText.forEach(function addHelperText(line) {
      lines.push(line);
    });

    if (vm.blockers.length) {
      lines.push("");
      lines.push("Blockers: " + vm.blockers.length);
      vm.blockers.forEach(function addBlocker(blocker) {
        lines.push("- " + blocker);
      });
    }

    if (vm.warnings.length) {
      lines.push("");
      lines.push("Warnings: " + vm.warnings.length);
      vm.warnings.forEach(function addWarning(warning) {
        lines.push("- " + warning);
      });
    }

    return lines.join("\n");
  }

  const api = Object.freeze({
    MARKER: MARKER,
    MODE: MODE,
    CURRENT_FILE_NAME: CURRENT_FILE_NAME,
    PREVIOUS_FILE_NAME: PREVIOUS_FILE_NAME,
    LABEL: LABEL,
    createDisabledSaveButtonViewModel: createDisabledSaveButtonViewModel,
    createDisabledSaveButtonStatusText: createDisabledSaveButtonStatusText
  });

  root.APC_LOCAL_BACKUP_CURRENT_FILE_DISABLED_SAVE_BUTTON_VIEW_MODEL = api;

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }
})(typeof window !== "undefined" ? window : globalThis);
