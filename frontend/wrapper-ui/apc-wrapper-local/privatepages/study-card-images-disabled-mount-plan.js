(function attachDisabledStudyCardImageMountPlan(globalScope) {
  "use strict";

  var MARKER = "APC_STUDY_CARD_IMAGES_DISABLED_MOUNT_PLAN_R16S_SOURCE_ONLY";
  var SUPPORTED_SIDES = Object.freeze(["question", "answer"]);

  function clonePlain(value) {
    return JSON.parse(JSON.stringify(value));
  }

  function normalizeSide(side) {
    var raw = String(side || "").trim().toLowerCase();
    if (raw === "front") return "question";
    if (raw === "back") return "answer";
    if (SUPPORTED_SIDES.indexOf(raw) !== -1) return raw;
    return "question";
  }

  function makeControlPlan(side, options) {
    var normalized = normalizeSide(side);
    var labelPrefix = normalized === "question" ? "Question" : "Answer";
    var opts = options && typeof options === "object" ? options : {};
    return Object.freeze({
      side: normalized,
      slotId: "study-card-image-" + normalized,
      label: labelPrefix + " image",
      helpText: "Optional " + normalized + "-side flashcard images will stay browser-local only.",
      buttonText: "Add " + normalized + " image",
      disabledReason: opts.disabledReason || "Image picker is staged but not enabled yet.",
      enabled: false,
      visible: false,
      bindsClickHandlerNow: false,
      opensFilePickerNow: false,
      rendersPreviewNow: false,
      writesBlobNow: false,
      writesIndexedDbNow: false,
      writesBackupPayloadNow: false,
      uploadsNow: false,
      mutatesAnkiNow: false,
      attributes: Object.freeze({
        "data-apc-study-card-image-side": normalized,
        "data-apc-study-card-image-disabled": "true",
        "aria-disabled": "true"
      })
    });
  }

  function createDisabledImageMountPlan(options) {
    var opts = options && typeof options === "object" ? options : {};
    var targetSurface = opts.targetSurface || "study-card-editor";
    var targetMode = opts.targetMode || "future-disabled-ui-only";
    var controls = SUPPORTED_SIDES.map(function mapSide(side) {
      return makeControlPlan(side, opts);
    });

    return Object.freeze({
      marker: MARKER,
      sourceOnly: true,
      stage: "R16S",
      targetSurface: targetSurface,
      targetMode: targetMode,
      hostCandidates: Object.freeze([
        "study card editor question field region",
        "study card editor answer field region",
        "local-only My Decks card editor surface"
      ]),
      controls: Object.freeze(controls),
      dependencies: Object.freeze([
        "APC_STUDY_CARD_IMAGES_LOCAL_ONLY_CONTRACT",
        "APC_STUDY_CARD_IMAGES_LOCAL_STORAGE_ADAPTER_CONTRACT",
        "APC_STUDY_CARD_IMAGES_BACKUP_MANIFEST_CONTRACT",
        "APC_STUDY_CARD_IMAGES_CARD_EDITOR_UI_PLAN",
        "APC_STUDY_CARD_IMAGES_DISABLED_RENDER_SPEC",
        "APC_STUDY_CARD_IMAGES_DISABLED_HTML_PREVIEW_RENDERER"
      ]),
      enabledNow: false,
      mountedNow: false,
      bindsEventsNow: false,
      rendersDomNow: false,
      opensFilePickerNow: false,
      rendersImagePreviewNow: false,
      writesBlobNow: false,
      writesIndexedDbNow: false,
      writesBackupPayloadNow: false,
      uploadsNow: false,
      syncsNow: false,
      mutatesAnkiNow: false
    });
  }

  function validateMountPlan(plan) {
    var errors = [];
    if (!plan || typeof plan !== "object") errors.push("plan must be an object");
    if (plan && plan.marker !== MARKER) errors.push("marker mismatch");
    if (plan && plan.sourceOnly !== true) errors.push("sourceOnly must be true");
    if (plan && plan.enabledNow !== false) errors.push("enabledNow must be false");
    if (plan && plan.mountedNow !== false) errors.push("mountedNow must be false");
    if (plan && plan.rendersDomNow !== false) errors.push("rendersDomNow must be false");
    if (plan && plan.bindsEventsNow !== false) errors.push("bindsEventsNow must be false");
    if (plan && plan.opensFilePickerNow !== false) errors.push("opensFilePickerNow must be false");
    if (plan && plan.rendersImagePreviewNow !== false) errors.push("rendersImagePreviewNow must be false");
    if (plan && plan.writesBlobNow !== false) errors.push("writesBlobNow must be false");
    if (plan && plan.writesIndexedDbNow !== false) errors.push("writesIndexedDbNow must be false");
    if (plan && plan.writesBackupPayloadNow !== false) errors.push("writesBackupPayloadNow must be false");
    if (plan && plan.uploadsNow !== false) errors.push("uploadsNow must be false");
    if (plan && plan.syncsNow !== false) errors.push("syncsNow must be false");
    if (plan && plan.mutatesAnkiNow !== false) errors.push("mutatesAnkiNow must be false");
    if (plan && (!Array.isArray(plan.controls) || plan.controls.length !== 2)) errors.push("expected question and answer controls");
    return Object.freeze({ ok: errors.length === 0, errors: Object.freeze(errors) });
  }

  function summarizeMountPlan(plan) {
    var p = plan || createDisabledImageMountPlan();
    var validation = validateMountPlan(p);
    return Object.freeze({
      marker: MARKER,
      ok: validation.ok,
      errors: validation.errors,
      targetSurface: p.targetSurface,
      controlCount: Array.isArray(p.controls) ? p.controls.length : 0,
      sides: Array.isArray(p.controls) ? Object.freeze(p.controls.map(function mapControl(control) { return control.side; })) : Object.freeze([]),
      enabledNow: p.enabledNow === true,
      mountedNow: p.mountedNow === true,
      writesNow: !!(p.writesBlobNow || p.writesIndexedDbNow || p.writesBackupPayloadNow || p.uploadsNow || p.syncsNow || p.mutatesAnkiNow)
    });
  }

  function getSafetyFlags() {
    return Object.freeze({
      sourceOnly: true,
      uiMountedNow: false,
      buttonRenderedNow: false,
      controlsEnabledNow: false,
      bindsEventsNow: false,
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

  var api = Object.freeze({
    MARKER: MARKER,
    SUPPORTED_SIDES: SUPPORTED_SIDES,
    createDisabledImageMountPlan: createDisabledImageMountPlan,
    makeControlPlan: makeControlPlan,
    validateMountPlan: validateMountPlan,
    summarizeMountPlan: summarizeMountPlan,
    getSafetyFlags: getSafetyFlags,
    clonePlain: clonePlain
  });

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }
  if (globalScope) {
    globalScope.APC_STUDY_CARD_IMAGES_DISABLED_MOUNT_PLAN = api;
  }
})(typeof window !== "undefined" ? window : (typeof globalThis !== "undefined" ? globalThis : this));
