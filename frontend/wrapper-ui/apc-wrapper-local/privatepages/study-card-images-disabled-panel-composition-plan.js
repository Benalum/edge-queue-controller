(function (root, factory) {
  if (typeof module === "object" && module.exports) {
    module.exports = factory();
  } else {
    root.APC_STUDY_CARD_IMAGES_DISABLED_PANEL_COMPOSITION_PLAN = factory();
  }
})(typeof globalThis !== "undefined" ? globalThis : this, function () {
  "use strict";

  const MARKER = "APC_STUDY_CARD_IMAGES_DISABLED_PANEL_COMPOSITION_PLAN_R16AA_SOURCE_ONLY";
  const ALLOWED_SIDES = Object.freeze(["question", "answer"]);

  function clone(value) {
    return JSON.parse(JSON.stringify(value));
  }

  function safeText(value, fallback) {
    const text = typeof value === "string" ? value.trim() : "";
    return text || fallback;
  }

  function getSafetyFlags() {
    return Object.freeze({
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
    });
  }

  function createDisabledSideComposition(side, options) {
    const normalizedSide = ALLOWED_SIDES.indexOf(side) >= 0 ? side : "question";
    const sideLabel = normalizedSide === "question" ? "Question" : "Answer";
    const suffix = normalizedSide === "question" ? "question" : "answer";

    return Object.freeze({
      id: `study-card-image-${suffix}-disabled-panel`,
      side: normalizedSide,
      title: safeText(options && options.title, `${sideLabel} image`),
      disabled: true,
      statusText: "Image support is being staged. This control is intentionally disabled.",
      helpText: "Images will remain browser-local when enabled. No server upload, Google Drive sync, or Anki mutation is active in this stage.",
      renderSpecId: `study-card-image-${suffix}-disabled-render-spec`,
      htmlPreviewId: `study-card-image-${suffix}-disabled-html-preview`,
      bindPlanId: `study-card-image-${suffix}-disabled-bind-plan`,
      controls: Object.freeze([
        Object.freeze({ role: "button", label: `Add ${normalizedSide} image`, disabled: true, action: "none" }),
        Object.freeze({ role: "button", label: `Remove ${normalizedSide} image`, disabled: true, action: "none" })
      ])
    });
  }

  function createPanelCompositionPlan(options) {
    const opts = options && typeof options === "object" ? options : {};
    const includeQuestion = opts.includeQuestion !== false;
    const includeAnswer = opts.includeAnswer !== false;
    const sides = [];

    if (includeQuestion) sides.push(createDisabledSideComposition("question", opts.question || {}));
    if (includeAnswer) sides.push(createDisabledSideComposition("answer", opts.answer || {}));

    return Object.freeze({
      marker: MARKER,
      stage: "R16AA",
      sourceOnly: true,
      enabled: false,
      mounted: false,
      bindingEnabled: false,
      targetSurface: safeText(opts.targetSurface, "study-card-editor"),
      requiredGlobals: Object.freeze([
        "APC_STUDY_CARD_IMAGES_LOCAL_ONLY_CONTRACT",
        "APC_STUDY_CARD_IMAGES_LOCAL_STORAGE_ADAPTER_CONTRACT",
        "APC_STUDY_CARD_IMAGES_BACKUP_MANIFEST_CONTRACT",
        "APC_STUDY_CARD_IMAGES_CARD_EDITOR_UI_PLAN",
        "APC_STUDY_CARD_IMAGES_DISABLED_RENDER_SPEC",
        "APC_STUDY_CARD_IMAGES_DISABLED_HTML_PREVIEW_RENDERER",
        "APC_STUDY_CARD_IMAGES_DISABLED_MOUNT_PLAN",
        "APC_STUDY_CARD_IMAGES_DISABLED_PANEL_BRIDGE",
        "APC_STUDY_CARD_IMAGES_PANEL_INTEGRATION_GATE",
        "APC_STUDY_CARD_IMAGES_DISABLED_PANEL_BIND_PLAN"
      ]),
      sides: Object.freeze(sides),
      safety: getSafetyFlags()
    });
  }

  function validatePanelCompositionPlan(plan) {
    const errors = [];
    if (!plan || typeof plan !== "object") {
      return Object.freeze({ ok: false, errors: Object.freeze(["plan must be an object"]) });
    }
    if (plan.marker !== MARKER) errors.push("marker mismatch");
    if (plan.sourceOnly !== true) errors.push("sourceOnly must be true");
    if (plan.enabled !== false) errors.push("enabled must be false");
    if (plan.mounted !== false) errors.push("mounted must be false");
    if (plan.bindingEnabled !== false) errors.push("bindingEnabled must be false");
    if (!Array.isArray(plan.sides) || plan.sides.length < 1) errors.push("at least one side composition is required");
    if (Array.isArray(plan.sides)) {
      plan.sides.forEach(function (sidePlan, index) {
        if (ALLOWED_SIDES.indexOf(sidePlan.side) < 0) errors.push(`side ${index} has invalid side`);
        if (sidePlan.disabled !== true) errors.push(`side ${index} must be disabled`);
        if (!Array.isArray(sidePlan.controls)) errors.push(`side ${index} controls must be an array`);
        if (Array.isArray(sidePlan.controls)) {
          sidePlan.controls.forEach(function (control, controlIndex) {
            if (control.disabled !== true) errors.push(`side ${index} control ${controlIndex} must be disabled`);
            if (control.action !== "none") errors.push(`side ${index} control ${controlIndex} action must be none`);
          });
        }
      });
    }
    const safety = plan.safety || {};
    Object.keys(getSafetyFlags()).forEach(function (key) {
      const expected = key === "sourceOnly";
      if (safety[key] !== expected) errors.push(`safety.${key} must be ${String(expected)}`);
    });
    return Object.freeze({ ok: errors.length === 0, errors: Object.freeze(errors) });
  }

  function summarizePanelCompositionPlan(plan) {
    const validation = validatePanelCompositionPlan(plan);
    return Object.freeze({
      marker: MARKER,
      ok: validation.ok,
      sideCount: plan && Array.isArray(plan.sides) ? plan.sides.length : 0,
      enabled: !!(plan && plan.enabled),
      mounted: !!(plan && plan.mounted),
      bindingEnabled: !!(plan && plan.bindingEnabled),
      safety: plan && plan.safety ? clone(plan.safety) : clone(getSafetyFlags()),
      errors: clone(validation.errors)
    });
  }

  return Object.freeze({
    MARKER: MARKER,
    createPanelCompositionPlan: createPanelCompositionPlan,
    validatePanelCompositionPlan: validatePanelCompositionPlan,
    summarizePanelCompositionPlan: summarizePanelCompositionPlan,
    getSafetyFlags: getSafetyFlags
  });
});
