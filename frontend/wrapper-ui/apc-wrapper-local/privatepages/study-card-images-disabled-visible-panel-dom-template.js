(function () {
  "use strict";

  var MARKER = "APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_DOM_TEMPLATE_R16AO_SOURCE_ONLY";
  var API_NAME = "APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_DOM_TEMPLATE_R16AO";

  var SIDE_EFFECTS = Object.freeze({
    autoMount: false,
    createElementOnLoad: false,
    bindEvents: false,
    openFilePicker: false,
    paintPreview: false,
    writeIndexedDb: false,
    writeBackupPayload: false,
    uploadBackend: false,
    syncGoogleDrive: false,
    mutateAnki: false
  });

  function escapeHtml(value) {
    return String(value)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/\"/g, "&quot;")
      .replace(/'/g, "&#39;");
  }

  function disabledPanelTemplateModel() {
    return Object.freeze({
      marker: MARKER,
      sourceOnly: true,
      enabled: false,
      mounted: false,
      className: "apc-study-card-images-disabled-visible-panel",
      dataAttribute: "data-apc-study-card-images-disabled-visible-panel",
      heading: "Card images",
      statusText: "Image support is being prepared and is not enabled yet.",
      helpText: "When enabled, question and answer images will stay browser-local only.",
      controls: Object.freeze([
        Object.freeze({
          side: "question",
          label: "Question image",
          buttonText: "Add question image",
          disabled: true,
          bind: false,
          previewVisible: false
        }),
        Object.freeze({
          side: "answer",
          label: "Answer image",
          buttonText: "Add answer image",
          disabled: true,
          bind: false,
          previewVisible: false
        })
      ]),
      sideEffects: SIDE_EFFECTS
    });
  }

  function renderDisabledVisiblePanelHtml(modelInput) {
    var model = modelInput || disabledPanelTemplateModel();
    var controls = model.controls.map(function (control) {
      return [
        '<div class="apc-study-card-images-disabled-visible-panel__control" data-apc-image-side="' + escapeHtml(control.side) + '">',
        '<div class="apc-study-card-images-disabled-visible-panel__label">' + escapeHtml(control.label) + '</div>',
        '<button type="button" class="apc-study-card-images-disabled-visible-panel__button" disabled aria-disabled="true" data-apc-image-control="' + escapeHtml(control.side) + '">',
        escapeHtml(control.buttonText),
        '</button>',
        '<div class="apc-study-card-images-disabled-visible-panel__preview" hidden data-apc-image-preview="' + escapeHtml(control.side) + '"></div>',
        '</div>'
      ].join('');
    }).join('');

    return [
      '<section class="' + escapeHtml(model.className) + '" ' + escapeHtml(model.dataAttribute) + '="true" aria-label="Card images" data-apc-source-only="true" data-apc-mounted="false">',
      '<h3 class="apc-study-card-images-disabled-visible-panel__heading">' + escapeHtml(model.heading) + '</h3>',
      '<p class="apc-study-card-images-disabled-visible-panel__status">' + escapeHtml(model.statusText) + '</p>',
      '<p class="apc-study-card-images-disabled-visible-panel__help">' + escapeHtml(model.helpText) + '</p>',
      '<div class="apc-study-card-images-disabled-visible-panel__controls">',
      controls,
      '</div>',
      '</section>'
    ].join('');
  }

  function assertDisabledVisiblePanelHtml(html) {
    if (typeof html !== "string" || html.length < 50) return false;
    if (html.indexOf(MARKER) !== -1) return false;
    if (html.indexOf('type="file"') !== -1) return false;
    if (html.indexOf('onchange=') !== -1 || html.indexOf('onclick=') !== -1) return false;
    if (html.indexOf('disabled aria-disabled="true"') === -1) return false;
    if (html.indexOf('data-apc-source-only="true"') === -1) return false;
    if (html.indexOf('data-apc-mounted="false"') === -1) return false;
    if (html.indexOf('data-apc-image-control="question"') === -1) return false;
    if (html.indexOf('data-apc-image-control="answer"') === -1) return false;
    return true;
  }

  var api = Object.freeze({
    marker: MARKER,
    sourceOnly: true,
    enabled: false,
    mounted: false,
    sideEffects: SIDE_EFFECTS,
    disabledPanelTemplateModel: disabledPanelTemplateModel,
    renderDisabledVisiblePanelHtml: renderDisabledVisiblePanelHtml,
    assertDisabledVisiblePanelHtml: assertDisabledVisiblePanelHtml
  });

  if (typeof window !== "undefined") {
    Object.defineProperty(window, API_NAME, {
      value: api,
      enumerable: false,
      configurable: false,
      writable: false
    });
  }

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }
})();
