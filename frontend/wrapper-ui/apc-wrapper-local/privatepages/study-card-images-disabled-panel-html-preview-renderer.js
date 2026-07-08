(function apcStudyCardImagesDisabledPanelHtmlPreviewRendererFactory(root, factory) {
  const api = factory();
  if (typeof module === "object" && module.exports) {
    module.exports = api;
  }
  if (root) {
    root.APC_STUDY_CARD_IMAGES_DISABLED_PANEL_HTML_PREVIEW_RENDERER = api;
  }
})(typeof globalThis !== "undefined" ? globalThis : this, function apcStudyCardImagesDisabledPanelHtmlPreviewRendererApi() {
  const MARKER = "APC_STUDY_CARD_IMAGES_DISABLED_PANEL_HTML_PREVIEW_RENDERER_R16AC_SOURCE_ONLY";

  function escapeHtml(value) {
    return String(value == null ? "" : value)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/\"/g, "&quot;")
      .replace(/'/g, "&#39;");
  }

  function normalizeSide(side) {
    return side === "answer" ? "answer" : "question";
  }

  function createDisabledSidePreview(side, options) {
    const normalizedSide = normalizeSide(side);
    const label = normalizedSide === "answer" ? "Answer image" : "Question image";
    const note = options && options.note ? String(options.note) : "Image support is staged but not enabled yet.";
    return Object.freeze({
      side: normalizedSide,
      label,
      buttonText: "Add " + normalizedSide + " image",
      disabled: true,
      ariaDisabled: "true",
      inputType: "file",
      inputDisabled: true,
      accept: "image/jpeg,image/png,image/webp,image/gif",
      previewState: "not-rendered",
      note,
      safety: Object.freeze({
        opensFilePicker: false,
        rendersImagePreview: false,
        writesBlob: false,
        writesIndexedDb: false,
        writesBackupPayload: false,
        uploadsToBackend: false,
        syncsToGoogleDrive: false,
        mutatesAnki: false
      })
    });
  }

  function createDisabledPanelPreviewModel(options) {
    const safeOptions = options || {};
    const title = safeOptions.title || "Card images";
    const description = safeOptions.description || "Question and answer image slots are being staged for local-only flashcards.";
    return Object.freeze({
      marker: MARKER,
      title,
      description,
      disabled: true,
      mounted: false,
      sides: Object.freeze([
        createDisabledSidePreview("question", safeOptions),
        createDisabledSidePreview("answer", safeOptions)
      ]),
      footer: "Local-only image controls remain disabled until the explicit enable stage."
    });
  }

  function renderDisabledSideHtml(sidePreview) {
    const sideClass = "apc-study-card-images-disabled-side apc-study-card-images-disabled-side--" + escapeHtml(sidePreview.side);
    return [
      "<section class=\"" + sideClass + "\" data-apc-study-card-image-preview-side=\"" + escapeHtml(sidePreview.side) + "\">",
      "  <h4>" + escapeHtml(sidePreview.label) + "</h4>",
      "  <button type=\"button\" disabled aria-disabled=\"true\" data-apc-study-card-image-disabled-button=\"" + escapeHtml(sidePreview.side) + "\">" + escapeHtml(sidePreview.buttonText) + "</button>",
      "  <p class=\"apc-muted\">" + escapeHtml(sidePreview.note) + "</p>",
      "</section>"
    ].join("\n");
  }

  function buildDisabledPanelHtmlPreview(options) {
    const model = createDisabledPanelPreviewModel(options);
    return [
      "<section class=\"apc-study-card-images-disabled-panel-preview\" data-apc-study-card-images-disabled-preview=\"true\">",
      "  <h3>" + escapeHtml(model.title) + "</h3>",
      "  <p>" + escapeHtml(model.description) + "</p>",
      renderDisabledSideHtml(model.sides[0]),
      renderDisabledSideHtml(model.sides[1]),
      "  <p class=\"apc-muted\">" + escapeHtml(model.footer) + "</p>",
      "</section>"
    ].join("\n");
  }

  function getSafetyFlags() {
    return Object.freeze({
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
      mediaExtractionNow: false,
      uploadsNow: false,
      writesBackupNow: false,
      writesIndexedDbNow: false,
      mutatesAnkiNow: false
    });
  }

  return Object.freeze({
    MARKER,
    escapeHtml,
    createDisabledSidePreview,
    createDisabledPanelPreviewModel,
    buildDisabledPanelHtmlPreview,
    getSafetyFlags
  });
});
