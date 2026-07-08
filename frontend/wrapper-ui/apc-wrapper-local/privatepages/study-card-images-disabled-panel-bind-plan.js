(function initStudyCardImagesDisabledPanelBindPlan(globalScope) {
  'use strict';

  var MARKER = 'APC_STUDY_CARD_IMAGES_DISABLED_PANEL_BIND_PLAN_R16Z_SOURCE_ONLY';
  var SIDES = Object.freeze(['question', 'answer']);
  var REQUIRED_GLOBALS = Object.freeze([
    'APC_STUDY_CARD_IMAGES_DISABLED_MOUNT_PLAN',
    'APC_STUDY_CARD_IMAGES_DISABLED_HTML_PREVIEW_RENDERER',
    'APC_STUDY_CARD_IMAGES_PANEL_INTEGRATION_GATE'
  ]);

  function clone(value) {
    return JSON.parse(JSON.stringify(value));
  }

  function normalizeRootKey(rootKey) {
    var value = String(rootKey || '').trim();
    return value || 'studyCardImagePanel';
  }

  function createControlPlan(side) {
    var normalized = SIDES.indexOf(side) >= 0 ? side : 'question';
    return Object.freeze({
      side: normalized,
      enabledNow: false,
      renderedNow: false,
      pickerOpenNow: false,
      previewRenderNow: false,
      placeholderOnly: true,
      localOnlyCopy: 'Image controls are staged but disabled. No image bytes are read or written yet.'
    });
  }

  function createPanelBindPlan(options) {
    var opts = options || {};
    var rootKey = normalizeRootKey(opts.rootKey);
    return Object.freeze({
      marker: MARKER,
      stage: 'R16Z',
      sourceOnly: true,
      deployNow: false,
      mountNow: false,
      bindNow: false,
      eventWiringNow: false,
      domWriteNow: false,
      surface: opts.surface || 'study-card-editor',
      rootKey: rootKey,
      requiredGlobals: REQUIRED_GLOBALS.slice(),
      controls: Object.freeze({
        question: createControlPlan('question'),
        answer: createControlPlan('answer')
      }),
      storage: Object.freeze({
        writeBlobNow: false,
        writeIndexedDbNow: false,
        writeBackupPayloadNow: false,
        mutateAnkiNow: false
      }),
      network: Object.freeze({
        uploadNow: false,
        serverSyncNow: false,
        googleDriveSyncNow: false
      })
    });
  }

  function getSafetyFlags() {
    return Object.freeze({
      marker: MARKER,
      sourceOnly: true,
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
      mutatesAnkiNow: false,
      eventWiringNow: false,
      domWriteNow: false
    });
  }

  var api = Object.freeze({
    MARKER: MARKER,
    SIDES: SIDES,
    REQUIRED_GLOBALS: REQUIRED_GLOBALS,
    clone: clone,
    createControlPlan: createControlPlan,
    createPanelBindPlan: createPanelBindPlan,
    getSafetyFlags: getSafetyFlags
  });

  if (typeof module !== 'undefined' && module.exports) {
    module.exports = api;
    return;
  }

  globalScope.APC_STUDY_CARD_IMAGES_DISABLED_PANEL_BIND_PLAN = api;
})(typeof window !== 'undefined' ? window : globalThis);
