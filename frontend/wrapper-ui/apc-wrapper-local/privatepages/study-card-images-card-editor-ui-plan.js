(function studyCardImagesCardEditorUiPlanR16D(root) {
  "use strict";

  const MARKER = "APC_STUDY_CARD_IMAGES_CARD_EDITOR_UI_PLAN_R16D_SOURCE_ONLY";
  const MODE = "source-only-study-card-images-card-editor-ui-plan";
  const VERSION = 1;
  const SIDES = Object.freeze(["question", "answer"]);
  const ALLOWED_MIME_TYPES = Object.freeze(["image/jpeg", "image/png", "image/webp", "image/gif"]);
  const ACCEPT_ATTRIBUTE = ALLOWED_MIME_TYPES.join(",");
  const MAX_IMAGE_BYTES = 8 * 1024 * 1024;

  function clean(value) {
    return String(value == null ? "" : value).trim();
  }

  function normalizeSide(side) {
    const value = clean(side).toLowerCase();
    return SIDES.includes(value) ? value : null;
  }

  function toArray(value) {
    return Array.isArray(value) ? value : [];
  }

  function existingImagesForSide(card, side) {
    const images = card && card.images ? card.images : {};
    return toArray(images[side]).map((item) => Object.freeze({
      id: clean(item && item.id),
      side: side,
      fileName: clean(item && item.fileName),
      mimeType: clean(item && item.mimeType),
      sizeBytes: Number(item && item.sizeBytes) || 0,
      altText: clean(item && item.altText),
      caption: clean(item && item.caption),
      localBlobId: clean(item && item.localBlobId),
      previewUrlCreatedNow: false,
      blobReadNow: false,
      storedNow: false
    }));
  }

  function createSideImageUiPlan(side, card, options) {
    const normalizedSide = normalizeSide(side);
    const label = normalizedSide === "answer" ? "answer" : "question";
    const title = label === "answer" ? "Answer images" : "Question images";
    const addButtonText = label === "answer" ? "Add answer image" : "Add question image";

    return Object.freeze({
      marker: MARKER,
      version: VERSION,
      mode: MODE,
      sourceOnly: true,
      localOnly: true,
      side: label,
      title: title,
      addButtonText: addButtonText,
      removeButtonText: "Remove image",
      replaceButtonText: "Replace image",
      altTextLabel: "Image alt text",
      captionLabel: "Image caption",
      acceptAttribute: ACCEPT_ATTRIBUTE,
      allowedMimeTypes: ALLOWED_MIME_TYPES.slice(),
      maxImageBytes: MAX_IMAGE_BYTES,
      existingImages: existingImagesForSide(card || {}, label),
      proposedElements: Object.freeze({
        wrapperRole: "group",
        fileInputType: "file",
        fileInputMultiple: false,
        fileInputAccept: ACCEPT_ATTRIBUTE,
        previewRegionAriaLive: "polite",
        validationRegionAriaLive: "polite"
      }),
      uiPolicy: Object.freeze({
        loadedByIndexNow: false,
        uiMountedNow: false,
        domElementCreatedNow: false,
        buttonInsertedNow: false,
        fileInputInsertedNow: false,
        filePickerOpenedNow: false,
        dragDropEnabledNow: false,
        imagePreviewRenderedNow: false,
        objectUrlCreatedNow: false,
        fileBytesReadNow: false,
        blobStoredNow: false,
        indexedDbWriteNow: false,
        backupPayloadWriteNow: false,
        backendUploadAllowed: false,
        serverSyncAllowed: false,
        googleDriveSyncAllowedNow: false,
        ankiMutationAllowed: false,
        originalFileMutationAllowed: false,
        mediaExtractionNow: false,
        companionModelCallNow: false
      })
    });
  }

  function createCardEditorImageUiPlan(card, options) {
    const sourceCard = card || {};
    return Object.freeze({
      marker: MARKER,
      version: VERSION,
      mode: MODE,
      sourceOnly: true,
      localOnly: true,
      cardId: clean(sourceCard.id),
      question: createSideImageUiPlan("question", sourceCard, options || {}),
      answer: createSideImageUiPlan("answer", sourceCard, options || {}),
      editorPlacement: Object.freeze({
        questionSidePlacement: "below-question-text-editor",
        answerSidePlacement: "below-answer-text-editor",
        studyModePlacement: "read-only-image-preview-below-card-text-later"
      }),
      uiPolicy: getSafetyFlags(),
      requiresLaterDeployStage: true,
      requiresLaterLoadStage: true,
      requiresLaterMountStage: true,
      requiresLaterStorageWriteStage: true,
      requiresLaterBackupProof: true
    });
  }

  function createCardEditorImageUiPlanText(plan) {
    const view = plan || createCardEditorImageUiPlan({}, {});
    return [
      "Study card image editor UI plan",
      "Mode: source-only",
      "Question side add button: " + view.question.addButtonText,
      "Answer side add button: " + view.answer.addButtonText,
      "Accepts: " + view.question.acceptAttribute,
      "Question placement: " + view.editorPlacement.questionSidePlacement,
      "Answer placement: " + view.editorPlacement.answerSidePlacement,
      "UI mounted now: " + String(view.uiPolicy.uiMountedNow),
      "DOM element created now: " + String(view.uiPolicy.domElementCreatedNow),
      "File picker opened now: " + String(view.uiPolicy.filePickerOpenedNow),
      "Image preview rendered now: " + String(view.uiPolicy.imagePreviewRenderedNow),
      "Blob stored now: " + String(view.uiPolicy.blobStoredNow),
      "IndexedDB write now: " + String(view.uiPolicy.indexedDbWriteNow),
      "Backup payload write now: " + String(view.uiPolicy.backupPayloadWriteNow),
      "Backend upload allowed: " + String(view.uiPolicy.backendUploadAllowed),
      "Anki mutation allowed: " + String(view.uiPolicy.ankiMutationAllowed)
    ].join("\n");
  }

  function validateCardEditorImageUiPlan(plan) {
    const view = plan || createCardEditorImageUiPlan({}, {});
    return Object.freeze({
      marker: MARKER,
      valid: view.sourceOnly === true &&
        view.localOnly === true &&
        view.question.side === "question" &&
        view.answer.side === "answer" &&
        view.uiPolicy.uiMountedNow === false &&
        view.uiPolicy.domElementCreatedNow === false &&
        view.uiPolicy.filePickerOpenedNow === false &&
        view.uiPolicy.imagePreviewRenderedNow === false &&
        view.uiPolicy.blobStoredNow === false &&
        view.uiPolicy.indexedDbWriteNow === false &&
        view.uiPolicy.backupPayloadWriteNow === false &&
        view.uiPolicy.backendUploadAllowed === false &&
        view.uiPolicy.ankiMutationAllowed === false,
      questionSidePresent: view.question.side === "question",
      answerSidePresent: view.answer.side === "answer",
      noUiNow: view.uiPolicy.uiMountedNow === false && view.uiPolicy.domElementCreatedNow === false,
      noWritesNow: view.uiPolicy.blobStoredNow === false && view.uiPolicy.indexedDbWriteNow === false && view.uiPolicy.backupPayloadWriteNow === false,
      noExternalMutationNow: view.uiPolicy.backendUploadAllowed === false && view.uiPolicy.ankiMutationAllowed === false
    });
  }

  function getSafetyFlags() {
    return Object.freeze({
      marker: MARKER,
      mode: MODE,
      sourceOnly: true,
      loadedByIndexNow: false,
      uiMountedNow: false,
      domElementCreatedNow: false,
      buttonInsertedNow: false,
      fileInputInsertedNow: false,
      filePickerOpenedNow: false,
      dragDropEnabledNow: false,
      imagePreviewRenderedNow: false,
      objectUrlCreatedNow: false,
      fileBytesReadNow: false,
      blobStoredNow: false,
      indexedDbWriteNow: false,
      backupPayloadWriteNow: false,
      backendUploadAllowed: false,
      serverSyncAllowed: false,
      googleDriveSyncAllowedNow: false,
      ankiMutationAllowed: false,
      originalFileMutationAllowed: false,
      mediaExtractionNow: false,
      companionModelCallNow: false
    });
  }

  const api = Object.freeze({
    MARKER: MARKER,
    MODE: MODE,
    VERSION: VERSION,
    SIDES: SIDES,
    ALLOWED_MIME_TYPES: ALLOWED_MIME_TYPES,
    ACCEPT_ATTRIBUTE: ACCEPT_ATTRIBUTE,
    MAX_IMAGE_BYTES: MAX_IMAGE_BYTES,
    createSideImageUiPlan: createSideImageUiPlan,
    createCardEditorImageUiPlan: createCardEditorImageUiPlan,
    createCardEditorImageUiPlanText: createCardEditorImageUiPlanText,
    validateCardEditorImageUiPlan: validateCardEditorImageUiPlan,
    getSafetyFlags: getSafetyFlags
  });

  root.APC_STUDY_CARD_IMAGES_CARD_EDITOR_UI_PLAN = api;

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }
})(globalThis);
