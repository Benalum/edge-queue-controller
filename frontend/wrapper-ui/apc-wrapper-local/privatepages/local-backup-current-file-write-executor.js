(function currentBackupWriteExecutorR13X(root) {
  "use strict";

  const MARKER = "APC_LOCAL_BACKUP_CURRENT_FILE_WRITE_EXECUTOR_R13X_SOURCE_ONLY";
  const MODE = "source-only-guarded-write-executor";
  const CURRENT_FILE_NAME = "buddies-who-study-current.json";
  const PREVIOUS_FILE_NAME = "buddies-who-study-current.previous.json";
  const ENABLE_TOKEN = "R13X_EXPLICIT_CURRENT_BACKUP_WRITE_ENABLE";
  const BACKUP_KIND = "buddies-who-study-local-backup";
  const BACKUP_VERSION = 2;

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

  function isExpectedCurrentFileName(fileName) {
    return String(fileName || "") === CURRENT_FILE_NAME;
  }

  function getSaveWriterPlanApi() {
    return root && root.APC_LOCAL_BACKUP_CURRENT_FILE_SAVE_WRITER
      ? root.APC_LOCAL_BACKUP_CURRENT_FILE_SAVE_WRITER
      : null;
  }

  function findLegacyBackendCacheKeys(payload) {
    const docs = payload && isObject(payload.docs) ? payload.docs : {};
    const storeDoc = docs["study/store-state/v1"];
    const state = storeDoc && isObject(storeDoc.state) ? storeDoc.state : null;
    const legacyKeys = ["backendProgress", "backendReviewSummary", "backendSessions", "backendSyncedAt"];

    if (!state) return [];

    return legacyKeys
      .filter(function hasKey(key) {
        return Object.prototype.hasOwnProperty.call(state, key);
      })
      .map(function toPath(key) {
        return "study/store-state/v1.state." + key;
      });
  }

  function validateSanitizedReadbackText(text) {
    const errors = [];
    let parsed = null;

    try {
      parsed = JSON.parse(String(text || ""));
    } catch (error) {
      errors.push("Readback JSON parse failed: " + String(error && error.message ? error.message : error));
    }

    if (parsed) {
      if (parsed.kind !== BACKUP_KIND) {
        errors.push("Readback kind mismatch.");
      }
      if (parsed.version !== BACKUP_VERSION) {
        errors.push("Readback version mismatch.");
      }

      const legacy = findLegacyBackendCacheKeys(parsed);
      if (legacy.length) {
        errors.push("Readback still contains legacy backend cache fields.");
      }
    }

    return {
      ok: errors.length === 0,
      errors: errors,
      parsed: parsed
    };
  }

  function createCurrentBackupWriteExecutionPlan(input, options) {
    const opts = options || {};
    const source = input || {};
    const selectedFileName = fileNameFromCandidate(
      source.selectedFileName ||
      source.currentFileHandle ||
      source.selectedFileHandle ||
      source.fileHandle ||
      source.file ||
      ""
    );
    const currentFileHandleName = fileNameFromCandidate(source.currentFileHandle || "");
    const payload = source.payload || source.currentPayload || source.backupPayload || {};
    const writerApi = getSaveWriterPlanApi();
    const errors = [];
    const warnings = [];
    const now = opts.createdAt || opts.updatedAt || new Date().toISOString();

    if (!writerApi || typeof writerApi.createCurrentBackupSaveWriterPlan !== "function") {
      errors.push("Current backup save writer plan helper is not loaded.");
    }

    if (!isExpectedCurrentFileName(selectedFileName)) {
      errors.push("Selected file must be " + CURRENT_FILE_NAME + ".");
    }

    if (currentFileHandleName && !isExpectedCurrentFileName(currentFileHandleName)) {
      errors.push("Current file handle name must be " + CURRENT_FILE_NAME + ".");
    }

    let writerPlan = null;
    if (writerApi && typeof writerApi.createCurrentBackupSaveWriterPlan === "function") {
      writerPlan = writerApi.createCurrentBackupSaveWriterPlan({
        selectedFileName: selectedFileName,
        payload: cloneJson(payload)
      }, {
        createdAt: now,
        updatedAt: now
      });

      if (!writerPlan.readyForFutureWriteEnablement) {
        errors.push("Save writer plan is not ready for future write enablement.");
      }

      if (writerPlan.errors && writerPlan.errors.length) {
        writerPlan.errors.forEach(function addWriterError(error) {
          errors.push(error);
        });
      }

      if (writerPlan.warnings && writerPlan.warnings.length) {
        writerPlan.warnings.forEach(function addWriterWarning(warning) {
          warnings.push(warning);
        });
      }
    }

    return {
      marker: MARKER,
      mode: MODE,
      sourceOnly: true,
      deployed: false,
      uiReachable: false,
      defaultWritesEnabled: false,
      canExecuteWithoutExplicitToken: false,
      requiredEnableWrite: true,
      requiredEnableToken: ENABLE_TOKEN,
      requiredConfirmSelectedFileName: CURRENT_FILE_NAME,
      currentFileName: CURRENT_FILE_NAME,
      previousFileName: PREVIOUS_FILE_NAME,
      selectedFileName: selectedFileName,
      currentFileHandleName: currentFileHandleName,
      selectedFileAllowed: isExpectedCurrentFileName(selectedFileName),
      currentFileHandleAllowed: currentFileHandleName ? isExpectedCurrentFileName(currentFileHandleName) : false,
      previousFileMustBeWrittenFirst: true,
      currentFileMustBeWrittenSecond: true,
      replaceCurrentFileOnlyAfterPreviousFile: true,
      readbackVerificationRequired: true,
      generatedAt: now,
      writerPlanReady: Boolean(writerPlan && writerPlan.readyForFutureWriteEnablement),
      writerPlan: writerPlan,
      sanitizedJsonText: writerPlan && writerPlan.sanitizedJsonText ? writerPlan.sanitizedJsonText : "",
      sanitizedByteLength: writerPlan && writerPlan.sanitizedJsonText ? writerPlan.sanitizedJsonText.length : 0,
      beforeLegacyFieldPaths: writerPlan && writerPlan.beforeLegacyFieldPaths ? writerPlan.beforeLegacyFieldPaths.slice() : [],
      afterLegacyFieldPaths: writerPlan && writerPlan.afterLegacyFieldPaths ? writerPlan.afterLegacyFieldPaths.slice() : [],
      removedFieldCount: writerPlan ? Number(writerPlan.removedFieldCount || 0) : 0,
      beforeSummary: writerPlan ? writerPlan.beforeSummary : null,
      afterSummary: writerPlan ? writerPlan.afterSummary : null,
      errors: errors,
      warnings: warnings
    };
  }

  async function readHandleText(fileHandle) {
    if (!fileHandle || typeof fileHandle.getFile !== "function") {
      throw new Error("File handle cannot be read.");
    }

    const file = await fileHandle.getFile();
    if (!file || typeof file.text !== "function") {
      throw new Error("File handle did not return a readable file.");
    }

    return String(await file.text());
  }

  async function writeHandleText(fileHandle, text) {
    if (!fileHandle || typeof fileHandle.createWritable !== "function") {
      throw new Error("File handle cannot create a writable stream.");
    }

    const writable = await fileHandle.createWritable();
    if (!writable || typeof writable.write !== "function" || typeof writable.close !== "function") {
      throw new Error("Writable stream is incomplete.");
    }

    await writable.write(String(text || ""));
    await writable.close();
  }

  async function executeCurrentBackupWrite(input, options) {
    const opts = options || {};
    const source = input || {};
    const plan = createCurrentBackupWriteExecutionPlan(source, opts);
    const errors = plan.errors.slice();

    if (opts.enableWrite !== true) {
      errors.push("Write execution refused because enableWrite is not true.");
    }

    if (opts.enableToken !== ENABLE_TOKEN) {
      errors.push("Write execution refused because enableToken does not match.");
    }

    if (opts.confirmSelectedFileName !== CURRENT_FILE_NAME) {
      errors.push("Write execution refused because confirmSelectedFileName does not match " + CURRENT_FILE_NAME + ".");
    }

    if (!source.currentFileHandle || fileNameFromCandidate(source.currentFileHandle) !== CURRENT_FILE_NAME) {
      errors.push("Write execution refused because currentFileHandle is not " + CURRENT_FILE_NAME + ".");
    }

    if (!source.directoryHandle || typeof source.directoryHandle.getFileHandle !== "function") {
      errors.push("Write execution refused because directoryHandle.getFileHandle is unavailable.");
    }

    if (!plan.sanitizedJsonText) {
      errors.push("Write execution refused because sanitizedJsonText is empty.");
    }

    if (errors.length) {
      return {
        marker: MARKER,
        mode: MODE,
        executed: false,
        refused: true,
        phase: "guard",
        wrotePrevious: false,
        wroteCurrent: false,
        readbackVerified: false,
        plan: plan,
        errors: errors
      };
    }

    let wrotePrevious = false;
    let wroteCurrent = false;
    let readbackVerified = false;
    let previousFileHandle = null;
    let readback = null;

    try {
      const oldCurrentText = await readHandleText(source.currentFileHandle);

      previousFileHandle = await source.directoryHandle.getFileHandle(PREVIOUS_FILE_NAME, {
        create: true
      });

      if (!previousFileHandle || fileNameFromCandidate(previousFileHandle) !== PREVIOUS_FILE_NAME) {
        throw new Error("Previous file handle name mismatch.");
      }

      await writeHandleText(previousFileHandle, oldCurrentText);
      wrotePrevious = true;

      await writeHandleText(source.currentFileHandle, plan.sanitizedJsonText);
      wroteCurrent = true;

      const readbackText = await readHandleText(source.currentFileHandle);
      readback = validateSanitizedReadbackText(readbackText);
      if (!readback.ok) {
        throw new Error(readback.errors.join("; "));
      }

      readbackVerified = true;

      return {
        marker: MARKER,
        mode: MODE,
        executed: true,
        refused: false,
        phase: "complete",
        wrotePrevious: wrotePrevious,
        wroteCurrent: wroteCurrent,
        readbackVerified: readbackVerified,
        previousFileName: PREVIOUS_FILE_NAME,
        currentFileName: CURRENT_FILE_NAME,
        readbackKind: readback.parsed ? readback.parsed.kind : "",
        readbackVersion: readback.parsed ? readback.parsed.version : null,
        readbackLegacyFieldPaths: readback.parsed ? findLegacyBackendCacheKeys(readback.parsed) : [],
        plan: plan,
        errors: []
      };
    } catch (error) {
      return {
        marker: MARKER,
        mode: MODE,
        executed: false,
        refused: false,
        phase: wrotePrevious && !wroteCurrent ? "after-previous-before-current" : "write-or-verify-error",
        wrotePrevious: wrotePrevious,
        wroteCurrent: wroteCurrent,
        readbackVerified: readbackVerified,
        previousFileName: PREVIOUS_FILE_NAME,
        currentFileName: CURRENT_FILE_NAME,
        plan: plan,
        errors: [String(error && error.message ? error.message : error)]
      };
    }
  }

  const api = Object.freeze({
    MARKER: MARKER,
    MODE: MODE,
    CURRENT_FILE_NAME: CURRENT_FILE_NAME,
    PREVIOUS_FILE_NAME: PREVIOUS_FILE_NAME,
    ENABLE_TOKEN: ENABLE_TOKEN,
    isExpectedCurrentFileName: isExpectedCurrentFileName,
    findLegacyBackendCacheKeys: findLegacyBackendCacheKeys,
    validateSanitizedReadbackText: validateSanitizedReadbackText,
    createCurrentBackupWriteExecutionPlan: createCurrentBackupWriteExecutionPlan,
    executeCurrentBackupWrite: executeCurrentBackupWrite
  });

  root.APC_LOCAL_BACKUP_CURRENT_FILE_WRITE_EXECUTOR = api;

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }
})(typeof window !== "undefined" ? window : globalThis);
