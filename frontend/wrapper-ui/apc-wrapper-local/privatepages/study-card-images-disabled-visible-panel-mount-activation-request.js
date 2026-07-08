(function attachStudyCardImagesDisabledVisiblePanelMountActivationRequestR16BM(root) {
  "use strict";

  var marker = "APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_MOUNT_ACTIVATION_REQUEST_R16BM_SOURCE_ONLY";
  var apiName = "APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_MOUNT_ACTIVATION_REQUEST_R16BM";

  var requiredGlobalApis = Object.freeze([
    "APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_R16AJ",
    "APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_MOUNT_ADAPTER_R16AK",
    "APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_DOM_TEMPLATE_R16AO",
    "APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_SLOT_RESOLVER_R16AS",
    "APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_MOUNT_CONTROLLER_R16AW",
    "APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_SAFE_MOUNT_EXECUTOR_R16BA",
    "APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_MOUNT_READINESS_GATE_R16BE",
    "APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_DOM_MOUNT_CANDIDATE_R16BI"
  ]);

  var safety = Object.freeze({
    sourceOnly: true,
    loadedByIndex: false,
    autoRun: false,
    executeNow: false,
    visibleShellAllowedInLaterStage: true,
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

  var request = Object.freeze({
    marker: marker,
    stage: "stage-17k-r16bm-study-card-images-disabled-visible-panel-mount-activation-request-source-only",
    route: "/profile",
    mountMode: "disabled-visible-shell",
    targetSlot: "profile-study-card-images-disabled-panel-slot",
    requires: requiredGlobalApis,
    safety: safety
  });

  function getStatus() {
    return Object.freeze({
      marker: marker,
      requestStage: request.stage,
      sourceOnly: true,
      loadedByIndex: false,
      executed: false,
      mounted: false,
      visibleShellAllowedInLaterStage: true,
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
  }

  function describeActivationRequest() {
    return Object.freeze({
      marker: marker,
      request: request,
      status: getStatus()
    });
  }

  var api = Object.freeze({
    marker: marker,
    apiName: apiName,
    request: request,
    status: getStatus(),
    describeActivationRequest: describeActivationRequest
  });

  root[apiName] = api;
})(typeof window !== "undefined" ? window : globalThis);
