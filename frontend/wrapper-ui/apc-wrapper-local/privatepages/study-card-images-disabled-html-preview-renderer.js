(function attachStudyCardImagesDisabledHtmlPreviewRenderer(global) {
  "use strict";

  var MARKER = "APC_STUDY_CARD_IMAGES_DISABLED_HTML_PREVIEW_RENDERER_R16N_SOURCE_ONLY";
  var DEFAULT_HINT = "Image attachments are being prepared. This control is intentionally disabled until the local-only picker and storage path are proven.";

  function escapeHtml(value) {
    return String(value == null ? "" : value)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;");
  }

  function normalizeSide(side) {
    return side === "answer" ? "answer" : "question";
  }

  function sideLabel(side) {
    return normalizeSide(side) === "answer" ? "Answer image" : "Question image";
  }

  function getDisabledRenderSpecContract() {
    return global && global.APC_STUDY_CARD_IMAGES_DISABLED_RENDER_SPEC
      ? global.APC_STUDY_CARD_IMAGES_DISABLED_RENDER_SPEC
      : null;
  }

  function createDisabledImageSlotModel(side, options) {
    var safeSide = normalizeSide(side);
    var opts = options || {};
    var disabledContract = getDisabledRenderSpecContract();
    var contractFlags = disabledContract && typeof disabledContract.getSafetyFlags === "function"
      ? disabledContract.getSafetyFlags()
      : null;

    return Object.freeze({
      marker: MARKER,
      side: safeSide,
      label: sideLabel(safeSide),
      disabled: true,
      buttonText: opts.buttonText || ("Add " + safeSide + " image"),
      statusText: opts.statusText || "Disabled until local-only image storage is mounted.",
      hintText: opts.hintText || DEFAULT_HINT,
      hasAttachment: false,
      imagePreviewRendered: false,
      filePickerBound: false,
      clickBound: false,
      contractAvailable: !!disabledContract,
      contractSafetyFlags: contractFlags
    });
  }

  function renderDisabledImageSlotHtml(side, options) {
    var model = createDisabledImageSlotModel(side, options);
    var safeSide = escapeHtml(model.side);
    var safeLabel = escapeHtml(model.label);
    var safeButton = escapeHtml(model.buttonText);
    var safeStatus = escapeHtml(model.statusText);
    var safeHint = escapeHtml(model.hintText);

    return [
      '<section class="apc-study-card-image-slot apc-study-card-image-slot--disabled" data-apc-study-card-image-preview="', safeSide, '" aria-label="', safeLabel, '">',
      '<div class="apc-study-card-image-slot__header">', safeLabel, '</div>',
      '<button type="button" class="apc-study-card-image-slot__button" disabled aria-disabled="true">', safeButton, '</button>',
      '<p class="apc-study-card-image-slot__status">', safeStatus, '</p>',
      '<p class="apc-study-card-image-slot__hint">', safeHint, '</p>',
      '</section>'
    ].join("");
  }

  function renderDisabledCardImagesPreviewHtml(options) {
    var opts = options || {};
    var heading = escapeHtml(opts.heading || "Optional card images");
    var intro = escapeHtml(opts.intro || "Question-side and answer-side images are planned, but the controls remain disabled until local-only storage is mounted.");

    return [
      '<section class="apc-study-card-images-disabled-preview" data-apc-study-card-images-disabled-preview="', MARKER, '">',
      '<h3>', heading, '</h3>',
      '<p>', intro, '</p>',
      renderDisabledImageSlotHtml("question", opts.question || {}),
      renderDisabledImageSlotHtml("answer", opts.answer || {}),
      '</section>'
    ].join("");
  }

  function createPreviewSummary(options) {
    return Object.freeze({
      marker: MARKER,
      sourceOnly: true,
      htmlOnly: true,
      loadedByIndexNow: false,
      mountedNow: false,
      questionSlot: createDisabledImageSlotModel("question", options && options.question),
      answerSlot: createDisabledImageSlotModel("answer", options && options.answer)
    });
  }

  function getSafetyFlags() {
    return Object.freeze({
      marker: MARKER,
      sourceOnly: true,
      htmlOnly: true,
      loadedByIndexNow: false,
      uiMountedNow: false,
      buttonRenderedNow: false,
      controlsEnabledNow: false,
      filePickerOpenedNow: false,
      imagePreviewRenderedNow: false,
      clickBoundNow: false,
      blobStoredNow: false,
      indexedDbWriteNow: false,
      backupPayloadWriteNow: false,
      backendUploadAllowed: false,
      serverSyncAllowed: false,
      googleDriveSyncAllowedNow: false,
      ankiMutationAllowed: false,
      originalFileMutationAllowed: false,
      mediaExtractionNow: false
    });
  }

  var api = Object.freeze({
    MARKER: MARKER,
    createDisabledImageSlotModel: createDisabledImageSlotModel,
    renderDisabledImageSlotHtml: renderDisabledImageSlotHtml,
    renderDisabledCardImagesPreviewHtml: renderDisabledCardImagesPreviewHtml,
    createPreviewSummary: createPreviewSummary,
    getSafetyFlags: getSafetyFlags
  });

  if (global) {
    global.APC_STUDY_CARD_IMAGES_DISABLED_HTML_PREVIEW_RENDERER = api;
  }

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }
})(typeof window !== "undefined" ? window : globalThis);
