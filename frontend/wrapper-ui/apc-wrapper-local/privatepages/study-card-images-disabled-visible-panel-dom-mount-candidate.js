(function installDisabledVisiblePanelDomMountCandidate(global) {
  "use strict";

  var MARKER = "APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_DOM_MOUNT_CANDIDATE_R16BI_SOURCE_ONLY";
  var SLOT_SELECTOR = "[data-apc-study-card-editor-image-panel-slot]";

  var status = Object.freeze({
    sourceOnly: true,
    disabled: true,
    loadedByIndex: false,
    executed: false,
    resolvedSlot: false,
    mounted: false,
    controlsEnabled: false,
    filePickerOpened: false,
    imagePreviewRendered: false,
    clientWrite: false,
    indexedDbWrite: false,
    backupPayloadWrite: false,
    backendUpload: false,
    googleDriveSync: false,
    ankiMutation: false
  });

  function createDomMountCandidate(options) {
    var opts = options || {};
    var slotName = String(opts.slotName || "study-card-editor-image-panel-slot");
    return Object.freeze({
      marker: MARKER,
      sourceOnly: true,
      disabled: true,
      autoExecute: false,
      wouldRenderDisabledPanel: true,
      slotName: slotName,
      slotSelector: SLOT_SELECTOR,
      requiredApis: Object.freeze([
        "APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_R16AJ",
        "APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_MOUNT_ADAPTER_R16AK",
        "APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_DOM_TEMPLATE_R16AO",
        "APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_SLOT_RESOLVER_R16AS",
        "APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_MOUNT_CONTROLLER_R16AW",
        "APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_SAFE_MOUNT_EXECUTOR_R16BA",
        "APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_MOUNT_READINESS_GATE_R16BE"
      ]),
      sideEffects: Object.freeze({
        execute: false,
        domLookup: false,
        domNodeCreation: false,
        domInsertion: false,
        domReplacement: false,
        eventBinding: false,
        filePicker: false,
        previewPaint: false,
        clientWrite: false,
        networkWrite: false,
        ankiMutation: false
      }),
      safety: Object.freeze({
        noAutoMount: true,
        noEventBinding: true,
        noFilePicker: true,
        noPreviewRendering: true,
        noIndexedDbWrite: true,
        noBackupPayloadWrite: true,
        noBackendUpload: true,
        noGoogleDriveSync: true,
        noAnkiMutation: true
      })
    });
  }

  function assertDomMountCandidate(candidate) {
    if (!candidate || candidate.marker !== MARKER) return false;
    if (candidate.sourceOnly !== true || candidate.disabled !== true) return false;
    if (candidate.autoExecute !== false) return false;
    if (!candidate.sideEffects || candidate.sideEffects.execute !== false) return false;
    if (candidate.sideEffects.domNodeCreation !== false) return false;
    if (candidate.sideEffects.domInsertion !== false) return false;
    if (candidate.sideEffects.domReplacement !== false) return false;
    if (candidate.sideEffects.eventBinding !== false) return false;
    if (candidate.sideEffects.filePicker !== false) return false;
    if (candidate.sideEffects.previewPaint !== false) return false;
    if (candidate.sideEffects.clientWrite !== false) return false;
    if (candidate.sideEffects.networkWrite !== false) return false;
    if (candidate.sideEffects.ankiMutation !== false) return false;
    if (!candidate.safety || candidate.safety.noAutoMount !== true) return false;
    if (candidate.safety.noIndexedDbWrite !== true) return false;
    if (candidate.safety.noBackendUpload !== true) return false;
    if (candidate.safety.noGoogleDriveSync !== true) return false;
    if (candidate.safety.noAnkiMutation !== true) return false;
    return true;
  }

  global.APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_DOM_MOUNT_CANDIDATE_R16BI = Object.freeze({
    marker: MARKER,
    sourceOnly: true,
    disabled: true,
    status: status,
    createDomMountCandidate: createDomMountCandidate,
    assertDomMountCandidate: assertDomMountCandidate
  });
})(typeof window !== "undefined" ? window : globalThis);
