(function currentBackupSaveActionControllerR14D(root) {
  "use strict";

  const MARKER = "APC_LOCAL_BACKUP_CURRENT_FILE_SAVE_ACTION_CONTROLLER_R14D_SOURCE_ONLY";
  const MODE = "source-only-save-action-controller";
  const CURRENT_FILE_NAME = "buddies-who-study-current.json";
  const PREVIOUS_FILE_NAME = "buddies-who-study-current.previous.json";
  const REQUIRED_EXECUTOR_MARKER = "APC_LOCAL_BACKUP_CURRENT_FILE_WRITE_EXECUTOR_R13X_SOURCE_ONLY";
  const REQUIRED_ENABLE_TOKEN = "R13X_EXPLICIT_CURRENT_BACKUP_WRITE_ENABLE";

  function isObject(value) {
    return value !== null && typeof value === "object" && !Array.isArray(value);
  }

  function cloneJson(value) {
    if (value === undefined) return undefined;
    return JSON.parse(JSON.stringify(value));
  }

  function fileNameFromCandidate(candidate) {
    if (typeof candidate === "string") return candidate;
    if (candidate && typeof candidate.name === "string") return candidate.name;
    if (candidate && typeof candidate.fileName === "string") return candidate.fileName;
    return "";
  }

  function getWriterApi() {
    return root && root.APC_LOCAL_BACKUP_CURRENT_FILE_SAVE_WRITER
      ? root.APC_LOCAL_BACKUP_CURRENT_FILE_SAVE_WRITER
      : null;
  }

  function getExecutorApi() {
    return root && root.APC_LOCAL_BACKUP_CURRENT_FILE_WRITE_EXECUTOR
      ? root.APC_LOCAL_BACKUP_CURRENT_FILE_WRITE_EXECUTOR
      : null;
  }

  function hasFunction(value, key) {
    return Boolean(value && typeof value[key] === "function");
  }

  function hasLegacyBackendCacheFieldsInPlan(plan) {
    return Boolean(plan && Array.isArray(plan.afterLegacyFieldPaths) && plan.afterLegacyFieldPaths.length > 0);
  }

  function buildWriterPlan(payload, selectedFileName, options) {
    const writer = getWriterApi();
    if (!writer || typeof writer.createCurrentBackupSaveWriterPlan !== "function") {
      return null;
    }

    return writer.createCurrentBackupSaveWriterPlan({
      selectedFileName: selectedFileName,
      payload: cloneJson(payload || {})
    }, {
      createdAt: options && options.createdAt ? options.createdAt : new Date().toISOString(),
      updatedAt: options && options.updatedAt ? options.updatedAt : undefined
    });
  }

  function createSaveCurrentBackupActionState(input, options) {
    const source = input || {};
    const opts = options || {};
    const selectedFileName = fileNameFromCandidate(
      source.selectedFileName ||
      source.currentFileHandle ||
      source.selectedFileHandle ||
      source.fileHandle ||
      source.file ||
      ""
    );
    const currentFileHandleName = fileNameFromCandidate(source.currentFileHandle || "");
    const directoryHandlePresent = Boolean(source.directoryHandle && typeof source.directoryHandle.getFileHandle === "function");
    const payload = source.payload || source.currentPayload || source.backupPayload || {};
    const writer = getWriterApi();
    const executor = getExecutorApi();
    const writerPlan = buildWriterPlan(payload, selectedFileName, opts);

    const blockers = [];
    const warnings = [];

    if (selectedFileName !== CURRENT_FILE_NAME) {
      blockers.push("Selected file must be " + CURRENT_FILE_NAME + ".");
    }

    if (currentFileHandleName && currentFileHandleName !== CURRENT_FILE_NAME) {
      blockers.push("Current file handle name must be " + CURRENT_FILE_NAME + ".");
    }

    if (!directoryHandlePresent) {
      blockers.push("Directory handle is required for future previous-file preparation.");
    }

    if (!writer || typeof writer.createCurrentBackupSaveWriterPlan !== "function") {
      blockers.push("Save writer plan helper is not loaded.");
    }

    if (!writerPlan) {
      blockers.push("Save writer plan could not be built.");
    }

    if (writerPlan && writerPlan.readyForFutureWriteEnablement !== true) {
      blockers.push("Save writer plan is not ready for future write enablement.");
    }

    if (writerPlan && Array.isArray(writerPlan.errors) && writerPlan.errors.length) {
      writerPlan.errors.forEach(function addWriterError(error) {
        blockers.push(error);
      });
    }

    if (writerPlan && hasLegacyBackendCacheFieldsInPlan(writerPlan)) {
      blockers.push("Sanitized writer plan still contains legacy backend cache fields.");
    }

    if (writerPlan && Array.isArray(writerPlan.warnings) && writerPlan.warnings.length) {
      writerPlan.warnings.forEach(function addWriterWarning(warning) {
        warnings.push(warning);
      });
    }

    if (!executor) {
      warnings.push("Write executor is not loaded in this source-only controller context.");
    } else {
      if (executor.MARKER !== REQUIRED_EXECUTOR_MARKER) {
        blockers.push("Write executor marker mismatch.");
      }

      if (executor.ENABLE_TOKEN !== REQUIRED_ENABLE_TOKEN) {
        blockers.push("Write executor enable token mismatch.");
      }

      if (!hasFunction(executor, "createCurrentBackupWriteExecutionPlan")) {
        blockers.push("Write executor planning function is unavailable.");
      }

      if (!hasFunction(executor, "executeCurrentBackupWrite")) {
        blockers.push("Write executor function is unavailable.");
      }
    }

    const eligibleForFutureEnablement = blockers.length === 0;

    return {
      marker: MARKER,
      mode: MODE,
      sourceOnly: true,
      deployed: false,
      uiLoaded: false,
      uiButtonAdded: false,
      actionBoundToUi: false,
      executorCallAllowedNow: false,
      executorCalled: false,
      writesEnabledNow: false,
      canWriteNow: false,
      canShowFutureSaveButton: eligibleForFutureEnablement,
      eligibleForFutureEnablement: eligibleForFutureEnablement,
      requiresLaterDeployStage: true,
      requiresUserGesture: true,
      requiresExplicitEnableToken: true,
      requiredEnableToken: REQUIRED_ENABLE_TOKEN,
      selectedFileName: selectedFileName,
      currentFileHandleName: currentFileHandleName,
      selectedFileAllowed: selectedFileName === CURRENT_FILE_NAME,
      currentFileHandleAllowed: currentFileHandleName ? currentFileHandleName === CURRENT_FILE_NAME : false,
      directoryHandlePresent: directoryHandlePresent,
      currentFileName: CURRENT_FILE_NAME,
      previousFileName: PREVIOUS_FILE_NAME,
      previousFileMustBePreparedFirst: true,
      sanitizedPlanReady: Boolean(writerPlan && writerPlan.readyForFutureWriteEnablement === true),
      removedFieldCount: writerPlan ? Number(writerPlan.removedFieldCount || 0) : 0,
      afterLegacyFieldPaths: writerPlan && Array.isArray(writerPlan.afterLegacyFieldPaths) ? writerPlan.afterLegacyFieldPaths.slice() : [],
      beforeSummary: writerPlan ? writerPlan.beforeSummary : null,
      afterSummary: writerPlan ? writerPlan.afterSummary : null,
      writerPlan: writerPlan,
      executorLoaded: Boolean(executor),
      executorMarker: executor && executor.MARKER ? executor.MARKER : "",
      executorHasPlanningFunction: hasFunction(executor, "createCurrentBackupWriteExecutionPlan"),
      executorHasWriteFunction: hasFunction(executor, "executeCurrentBackupWrite"),
      blockers: blockers,
      warnings: warnings
    };
  }

  function createDisabledActionViewModel(input, options) {
    const state = createSaveCurrentBackupActionState(input, options);

    return {
      marker: MARKER,
      mode: MODE,
      label: "Save current backup",
      visible: false,
      disabled: true,
      reason: state.eligibleForFutureEnablement
        ? "Future eligible, but R14D is source-only and does not expose a UI action."
        : state.blockers.join(" "),
      actionState: state
    };
  }

  const api = Object.freeze({
    MARKER: MARKER,
    MODE: MODE,
    CURRENT_FILE_NAME: CURRENT_FILE_NAME,
    PREVIOUS_FILE_NAME: PREVIOUS_FILE_NAME,
    REQUIRED_EXECUTOR_MARKER: REQUIRED_EXECUTOR_MARKER,
    REQUIRED_ENABLE_TOKEN: REQUIRED_ENABLE_TOKEN,
    createSaveCurrentBackupActionState: createSaveCurrentBackupActionState,
    createDisabledActionViewModel: createDisabledActionViewModel
  });

  root.APC_LOCAL_BACKUP_CURRENT_FILE_SAVE_ACTION_CONTROLLER = api;

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }
})(typeof window !== "undefined" ? window : globalThis);
