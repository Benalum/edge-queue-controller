(function () {
  "use strict";

  var MARKER = "APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_MOUNT_READINESS_GATE_R16BE_SOURCE_ONLY";

  var STATUS = Object.freeze({
    sourceOnly: true,
    disabled: true,
    loadedByIndex: false,
    deployed: false,
    executed: false,
    resolvedSlot: false,
    createdElement: false,
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

  var REQUIRED_APIS = Object.freeze([
    "APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_R16AJ",
    "APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_MOUNT_ADAPTER_R16AK",
    "APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_DOM_TEMPLATE_R16AO",
    "APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_SLOT_RESOLVER_R16AS",
    "APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_MOUNT_CONTROLLER_R16AW",
    "APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_SAFE_MOUNT_EXECUTOR_R16BA"
  ]);

  function createMountReadinessReport() {
    return Object.freeze({
      marker: MARKER,
      sourceOnly: true,
      enabled: false,
      mayExecute: false,
      mayResolveSlot: false,
      mayCreateElement: false,
      mayMount: false,
      mayBindEvents: false,
      mayOpenFilePicker: false,
      mayRenderPreview: false,
      mayWriteClientState: false,
      mayUploadToBackend: false,
      maySyncToDrive: false,
      mayMutateAnki: false,
      requiredApis: REQUIRED_APIS.slice(),
      requiredLoadOrder: REQUIRED_APIS.slice(),
      nextAllowedStage: "mount disabled panel only after a browser proof records this readiness gate loaded safely"
    });
  }

  function assertMountReadinessDisabled(report) {
    if (!report || report.marker !== MARKER) return false;
    return report.sourceOnly === true &&
      report.enabled === false &&
      report.mayExecute === false &&
      report.mayResolveSlot === false &&
      report.mayCreateElement === false &&
      report.mayMount === false &&
      report.mayBindEvents === false &&
      report.mayOpenFilePicker === false &&
      report.mayRenderPreview === false &&
      report.mayWriteClientState === false &&
      report.mayUploadToBackend === false &&
      report.maySyncToDrive === false &&
      report.mayMutateAnki === false;
  }

  window.APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_MOUNT_READINESS_GATE_R16BE = Object.freeze({
    marker: MARKER,
    sourceOnly: true,
    disabled: true,
    status: STATUS,
    requiredApis: REQUIRED_APIS,
    createMountReadinessReport: createMountReadinessReport,
    assertMountReadinessDisabled: assertMountReadinessDisabled
  });
})();
