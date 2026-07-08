(function initStudyCardImagesDisabledPanelRenderSpec(global) {
  "use strict";

  var MARKER = "APC_STUDY_CARD_IMAGES_DISABLED_PANEL_RENDER_SPEC_R16AB_SOURCE_ONLY";

  function asText(value) {
    if (value === null || value === undefined) return "";
    return String(value);
  }

  function escapeHtml(value) {
    return asText(value)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/\"/g, "&quot;")
      .replace(/'/g, "&#39;");
  }

  function createDisabledImageSlot(side, input) {
    var safeSide = side === "answer" ? "answer" : "question";
    var data = input || {};
    var label = safeSide === "answer" ? "Answer image" : "Question image";
    return {
      side: safeSide,
      label: label,
      status: "disabled",
      buttonLabel: "Add " + safeSide + " image",
      disabledReason: asText(data.disabledReason || "Image picker is staged but not enabled yet."),
      hasImageNow: false,
      previewRenderedNow: false,
      filePickerBoundNow: false,
      writePathEnabledNow: false,
      allowedMimeTypes: ["image/jpeg", "image/png", "image/webp", "image/gif"]
    };
  }

  function createDisabledPanelRenderSpec(options) {
    var opts = options || {};
    return {
      marker: MARKER,
      title: asText(opts.title || "Card images"),
      description: asText(opts.description || "Optional question-side and answer-side images will stay browser-local. This panel is staged disabled until the local-only picker and storage path are proven."),
      status: "disabled-preview-only",
      rootDataAttribute: "data-apc-study-card-images-disabled-panel",
      questionSlot: createDisabledImageSlot("question", opts.question || {}),
      answerSlot: createDisabledImageSlot("answer", opts.answer || {}),
      controlsEnabledNow: false,
      mountedNow: false,
      buttonRenderedNow: false,
      filePickerOpenedNow: false,
      imagePreviewRenderedNow: false,
      blobStoredNow: false,
      indexedDbWriteNow: false,
      backupPayloadWriteNow: false,
      backendUploadAllowed: false,
      serverSyncAllowed: false,
      googleDriveSyncAllowedNow: false,
      ankiMutationAllowed: false
    };
  }

  function renderSlotHtml(slot) {
    var item = slot || createDisabledImageSlot("question", {});
    return [
      "<section class=\"apc-study-card-image-slot apc-study-card-image-slot--" + escapeHtml(item.side) + "\" data-apc-study-card-image-slot=\"" + escapeHtml(item.side) + "\">",
      "<h4>" + escapeHtml(item.label) + "</h4>",
      "<p class=\"apc-muted\">" + escapeHtml(item.disabledReason) + "</p>",
      "<button type=\"button\" disabled aria-disabled=\"true\" data-apc-study-card-image-disabled-control=\"" + escapeHtml(item.side) + "\">" + escapeHtml(item.buttonLabel) + " disabled</button>",
      "</section>"
    ].join("");
  }

  function renderDisabledPanelHtml(specInput) {
    var spec = specInput && specInput.marker === MARKER ? specInput : createDisabledPanelRenderSpec(specInput || {});
    return [
      "<aside class=\"apc-study-card-images-disabled-panel\" data-apc-study-card-images-disabled-panel=\"true\" aria-disabled=\"true\">",
      "<h3>" + escapeHtml(spec.title) + "</h3>",
      "<p>" + escapeHtml(spec.description) + "</p>",
      "<div class=\"apc-study-card-images-disabled-slots\">",
      renderSlotHtml(spec.questionSlot),
      renderSlotHtml(spec.answerSlot),
      "</div>",
      "</aside>"
    ].join("");
  }

  function validateRenderSpec(spec) {
    var errors = [];
    if (!spec || typeof spec !== "object") errors.push("spec must be an object");
    if (spec && spec.marker !== MARKER) errors.push("marker mismatch");
    if (spec && spec.controlsEnabledNow !== false) errors.push("controls must remain disabled");
    if (spec && spec.mountedNow !== false) errors.push("mount must remain false");
    if (spec && spec.questionSlot && spec.questionSlot.side !== "question") errors.push("question slot side mismatch");
    if (spec && spec.answerSlot && spec.answerSlot.side !== "answer") errors.push("answer slot side mismatch");
    return { ok: errors.length === 0, errors: errors };
  }

  function getSafetyFlags() {
    return {
      marker: MARKER,
      sourceOnly: true,
      loadedByIndexNow: false,
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
    };
  }

  var api = Object.freeze({
    MARKER: MARKER,
    createDisabledImageSlot: createDisabledImageSlot,
    createDisabledPanelRenderSpec: createDisabledPanelRenderSpec,
    renderDisabledPanelHtml: renderDisabledPanelHtml,
    validateRenderSpec: validateRenderSpec,
    getSafetyFlags: getSafetyFlags
  });

  global.APC_STUDY_CARD_IMAGES_DISABLED_PANEL_RENDER_SPEC = api;
  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }
})(typeof window !== "undefined" ? window : globalThis);
