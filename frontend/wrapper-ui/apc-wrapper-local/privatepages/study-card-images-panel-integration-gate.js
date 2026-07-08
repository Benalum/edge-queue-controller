(function initStudyCardImagesPanelIntegrationGate(globalScope) {
  'use strict';

  var MARKER = 'APC_STUDY_CARD_IMAGES_PANEL_INTEGRATION_GATE_R16Y_SOURCE_ONLY';
  var SIDES = Object.freeze(['question', 'answer']);
  var FEATURE_STATE = 'disabled-placeholder-only';

  function clone(value) {
    return JSON.parse(JSON.stringify(value));
  }

  function normalizeSide(side) {
    var value = String(side || '').toLowerCase();
    return SIDES.indexOf(value) >= 0 ? value : 'question';
  }

  function createSideGate(side, options) {
    var normalized = normalizeSide(side);
    var opts = options || {};
    return Object.freeze({
      side: normalized,
      label: normalized === 'question' ? 'Question image' : 'Answer image',
      state: FEATURE_STATE,
      allowedToShowDisabledPlaceholder: true,
      allowedToRenderButton: false,
      allowedToEnableControls: false,
      allowedToOpenFilePicker: false,
      allowedToReadFileBytes: false,
      allowedToCreateObjectUrl: false,
      allowedToRenderImagePreview: false,
      reason: opts.reason || 'Image support is staged but disabled until the explicit writable local-only stage.',
      copy: {
        title: normalized === 'question' ? 'Question-side image' : 'Answer-side image',
        disabledText: 'Image support is being prepared. No image picker or storage is enabled yet.',
        safetyText: 'No image leaves this browser and no card image bytes are written in this stage.'
      }
    });
  }

  function createPanelIntegrationGate(options) {
    var opts = options || {};
    var requestedSide = normalizeSide(opts.requestedSide || opts.side || 'question');
    return Object.freeze({
      marker: MARKER,
      stage: 'R16Y',
      sourceOnly: true,
      ppbRunnable: true,
      interactiveRequired: false,
      deployNow: false,
      mountedNow: false,
      requestedSurface: opts.surface || 'study-card-editor',
      requestedSide: requestedSide,
      featureState: FEATURE_STATE,
      question: createSideGate('question', opts),
      answer: createSideGate('answer', opts),
      storage: Object.freeze({
        allowedToWriteBlob: false,
        allowedToWriteIndexedDb: false,
        allowedToWriteBackupPayload: false,
        allowedToMutateAnki: false
      }),
      network: Object.freeze({
        allowedToUpload: false,
        allowedToSyncServer: false,
        allowedToSyncGoogleDrive: false
      })
    });
  }

  function getSafetyFlags() {
    return Object.freeze({
      marker: MARKER,
      sourceOnly: true,
      ppbRunnable: true,
      interactiveRequired: false,
      deployNow: false,
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

  var api = Object.freeze({
    MARKER: MARKER,
    SIDES: SIDES,
    FEATURE_STATE: FEATURE_STATE,
    clone: clone,
    normalizeSide: normalizeSide,
    createSideGate: createSideGate,
    createPanelIntegrationGate: createPanelIntegrationGate,
    getSafetyFlags: getSafetyFlags
  });

  if (typeof module !== 'undefined' && module.exports) {
    module.exports = api;
  }
  if (globalScope) {
    globalScope.APC_STUDY_CARD_IMAGES_PANEL_INTEGRATION_GATE = api;
  }
})(typeof globalThis !== 'undefined' ? globalThis : this);
