(function () {
  "use strict";

  var MARKER = "APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_R16AJ_SOURCE_ONLY";
  var API_NAME = "APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_R16AJ";

  var PANEL_STATUS = Object.freeze({
    stage: "stage-17k-r16aj-study-card-images-disabled-visible-panel-source-only",
    marker: MARKER,
    sourceOnly: true,
    enabled: false,
    mounted: false,
    controlsEnabled: false,
    filePickerOpened: false,
    imagePreviewRendered: false,
    blobStored: false,
    indexedDbWrite: false,
    backupPayloadWrite: false,
    backendUpload: false,
    googleDriveSync: false,
    ankiMutation: false
  });

  function clone(value) {
    return JSON.parse(JSON.stringify(value));
  }

  function panelModel() {
    return Object.freeze({
      marker: MARKER,
      heading: "Images",
      disabledLabel: "Image support is being prepared",
      helpText: "Question and answer images will stay browser-local only when enabled.",
      questionSlot: Object.freeze({
        side: "question",
        label: "Question image",
        disabled: true,
        buttonText: "Add question image",
        preview: null
      }),
      answerSlot: Object.freeze({
        side: "answer",
        label: "Answer image",
        disabled: true,
        buttonText: "Add answer image",
        preview: null
      }),
      status: clone(PANEL_STATUS)
    });
  }

  function renderDisabledPanelDocument() {
    var model = panelModel();
    return Object.freeze({
      marker: MARKER,
      role: "region",
      ariaLabel: "Card images disabled panel",
      className: "apc-study-card-images-disabled-panel",
      heading: model.heading,
      disabledLabel: model.disabledLabel,
      helpText: model.helpText,
      controls: Object.freeze([
        Object.freeze({
          side: model.questionSlot.side,
          label: model.questionSlot.label,
          buttonText: model.questionSlot.buttonText,
          disabled: true,
          inputType: "file",
          accept: "image/jpeg,image/png,image/webp,image/gif",
          bind: false
        }),
        Object.freeze({
          side: model.answerSlot.side,
          label: model.answerSlot.label,
          buttonText: model.answerSlot.buttonText,
          disabled: true,
          inputType: "file",
          accept: "image/jpeg,image/png,image/webp,image/gif",
          bind: false
        })
      ]),
      previewPolicy: Object.freeze({
        renderPreview: false,
        previewSource: null,
        objectUrlCreate: false,
        revokeRequired: false
      }),
      persistencePolicy: Object.freeze({
        writeBlob: false,
        writeMetadata: false,
        uploadToBackend: false,
        syncToDrive: false,
        mutateAnki: false
      })
    });
  }

  function assertDisabledPanelDocument(doc) {
    if (!doc || doc.marker !== MARKER) return false;
    if (!Array.isArray(doc.controls) || doc.controls.length !== 2) return false;
    if (doc.previewPolicy.renderPreview !== false) return false;
    if (doc.persistencePolicy.writeBlob !== false) return false;
    if (doc.persistencePolicy.uploadToBackend !== false) return false;
    return doc.controls.every(function (control) {
      return control.disabled === true && control.bind === false;
    });
  }

  var api = Object.freeze({
    marker: MARKER,
    status: clone(PANEL_STATUS),
    panelModel: panelModel,
    renderDisabledPanelDocument: renderDisabledPanelDocument,
    assertDisabledPanelDocument: assertDisabledPanelDocument
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
