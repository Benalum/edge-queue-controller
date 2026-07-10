(function attachDisabledVisiblePanelControlledMountExecutor(globalObject) {
  "use strict";

  var MARKER = "APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_CONTROLLED_MOUNT_EXECUTOR_R16BQ_SOURCE_ONLY";
  var API_NAME = "APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_CONTROLLED_MOUNT_EXECUTOR_R16BQ";

  var STATUS = Object.freeze({
    marker: MARKER,
    stage: "stage-17k-r16bq-study-card-images-disabled-visible-panel-controlled-mount-executor-source-only",
    sourceOnly: true,
    loadedByIndex: false,
    deployed: false,
    executed: false,
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

  function safeBoolean(value) {
    return value === true;
  }

  function makeControlledMountPlan(input) {
    var request = input && input.activationRequest;
    var readiness = input && input.readinessGate;
    var candidate = input && input.domMountCandidate;

    return Object.freeze({
      marker: MARKER,
      sourceOnly: true,
      canExecute: false,
      shouldMount: false,
      reason: "source_only_not_loaded_by_index_not_deployed_not_runtime_armed",
      activationRequestReady: !!request,
      readinessGateReady: !!readiness,
      domMountCandidateReady: !!candidate,
      activationRequested: safeBoolean(request && request.activationRequested),
      readinessAllowed: safeBoolean(readiness && readiness.ready),
      candidateAvailable: !!candidate,
      executed: false,
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
  }

  var API = Object.freeze({
    marker: MARKER,
    status: STATUS,
    makeControlledMountPlan: makeControlledMountPlan
  });

  if (globalObject) {
    globalObject[API_NAME] = API;
  }
})(typeof window !== "undefined" ? window : globalThis);
