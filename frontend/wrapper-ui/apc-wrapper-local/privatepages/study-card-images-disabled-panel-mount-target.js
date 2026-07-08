(function initStudyCardImagesDisabledPanelMountTarget(root, factory) {
  var api = factory();
  if (typeof module === "object" && module.exports) {
    module.exports = api;
  }
  if (root) {
    root.APC_STUDY_CARD_IMAGES_DISABLED_PANEL_MOUNT_TARGET = api;
  }
})(typeof window !== "undefined" ? window : (typeof globalThis !== "undefined" ? globalThis : null), function buildApi() {
  "use strict";

  var MARKER = "APC_STUDY_CARD_IMAGES_DISABLED_PANEL_MOUNT_TARGET_R16AD_SOURCE_ONLY";
  var DEFAULT_TARGETS = [
    "study-card-editor-main",
    "study-card-editor-panel",
    "study-card-form",
    "study-panel-root"
  ];

  function cleanText(value) {
    return String(value || "").replace(/[^a-zA-Z0-9_-]/g, "").slice(0, 96);
  }

  function normalizeSide(side) {
    var value = String(side || "question").toLowerCase();
    if (value === "answer") return "answer";
    return "question";
  }

  function buildCandidate(side, name, priority) {
    var safeSide = normalizeSide(side);
    var safeName = cleanText(name || "study-card-editor-main");
    return {
      side: safeSide,
      targetId: safeName,
      selector: "#" + safeName,
      priority: Number(priority || 0),
      disabled: true,
      intendedOnly: true,
      resolvesNow: false,
      mountsNow: false,
      bindsNow: false
    };
  }

  function createMountTargetPlan(options) {
    var opts = options || {};
    var side = normalizeSide(opts.side);
    var sourceTargets = Array.isArray(opts.targetIds) && opts.targetIds.length ? opts.targetIds : DEFAULT_TARGETS;
    var candidates = sourceTargets.map(function eachTarget(targetId, index) {
      return buildCandidate(side, targetId, index + 1);
    });
    return {
      marker: MARKER,
      stage: "R16AD",
      sourceOnly: true,
      disabled: true,
      side: side,
      title: side === "answer" ? "Answer image area" : "Question image area",
      candidates: candidates,
      selectedTarget: null,
      targetResolvedNow: false,
      mountedNow: false,
      boundNow: false,
      writeEnabledNow: false
    };
  }

  function validateMountTargetPlan(plan) {
    var errors = [];
    if (!plan || typeof plan !== "object") errors.push("plan_missing");
    if (plan && plan.marker !== MARKER) errors.push("marker_mismatch");
    if (plan && plan.sourceOnly !== true) errors.push("source_only_required");
    if (plan && plan.disabled !== true) errors.push("disabled_required");
    if (plan && plan.mountedNow !== false) errors.push("mounted_now_must_be_false");
    if (plan && plan.boundNow !== false) errors.push("bound_now_must_be_false");
    if (plan && plan.writeEnabledNow !== false) errors.push("write_enabled_now_must_be_false");
    if (plan && !Array.isArray(plan.candidates)) errors.push("candidates_required");
    return { ok: errors.length === 0, errors: errors };
  }

  function getSafetyFlags() {
    return {
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
    };
  }

  return Object.freeze({
    MARKER: MARKER,
    DEFAULT_TARGETS: DEFAULT_TARGETS.slice(),
    createMountTargetPlan: createMountTargetPlan,
    validateMountTargetPlan: validateMountTargetPlan,
    getSafetyFlags: getSafetyFlags
  });
});
