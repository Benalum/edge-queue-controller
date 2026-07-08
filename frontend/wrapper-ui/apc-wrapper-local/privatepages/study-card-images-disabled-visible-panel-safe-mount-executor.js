(function attachStudyCardImagesDisabledVisiblePanelSafeMountExecutor(global) {
  "use strict";

  var MARKER = "APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_SAFE_MOUNT_EXECUTOR_R16BA_SOURCE_ONLY";

  var REQUIRED_MARKERS = Object.freeze([
    "APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_R16AJ_SOURCE_ONLY",
    "APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_MOUNT_ADAPTER_R16AK_SOURCE_ONLY",
    "APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_DOM_TEMPLATE_R16AO_SOURCE_ONLY",
    "APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_SLOT_RESOLVER_R16AS_SOURCE_ONLY",
    "APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_MOUNT_CONTROLLER_R16AW_SOURCE_ONLY"
  ]);

  var STATUS = Object.freeze({
    sourceOnly: true,
    disabled: true,
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

  function freezeClone(value) {
    return Object.freeze(JSON.parse(JSON.stringify(value)));
  }

  function createSafeMountExecutionPlan(options) {
    var config = options || {};
    var slotName = String(config.slotName || "study-card-editor-image-panel-slot");
    var routeName = String(config.routeName || "profile-or-study-card-editor");
    return freezeClone({
      stage: "R16BA",
      marker: MARKER,
      slotName: slotName,
      routeName: routeName,
      sourceOnly: true,
      disabled: true,
      execute: false,
      requiredMarkers: REQUIRED_MARKERS.slice(),
      plan: [
        "confirm-safe-route",
        "confirm-disabled-panel-template",
        "confirm-disabled-slot-resolver",
        "confirm-disabled-mount-controller",
        "leave-panel-unmounted",
        "leave-controls-unbound",
        "leave-writes-blocked"
      ],
      allowedEffects: {
        readConfiguration: true,
        validateContracts: true,
        returnPlan: true
      },
      blockedEffects: {
        domMount: true,
        elementCreate: true,
        eventBind: true,
        filePicker: true,
        previewPaint: true,
        clientWrite: true,
        indexedDbWrite: true,
        backupPayloadWrite: true,
        backendUpload: true,
        googleDriveSync: true,
        ankiMutation: true
      }
    });
  }

  function assertSafeMountExecutionPlan(plan) {
    return Boolean(
      plan &&
        plan.marker === MARKER &&
        plan.sourceOnly === true &&
        plan.disabled === true &&
        plan.execute === false &&
        plan.blockedEffects &&
        plan.blockedEffects.domMount === true &&
        plan.blockedEffects.elementCreate === true &&
        plan.blockedEffects.eventBind === true &&
        plan.blockedEffects.filePicker === true &&
        plan.blockedEffects.previewPaint === true &&
        plan.blockedEffects.clientWrite === true &&
        plan.blockedEffects.indexedDbWrite === true &&
        plan.blockedEffects.backupPayloadWrite === true &&
        plan.blockedEffects.backendUpload === true &&
        plan.blockedEffects.googleDriveSync === true &&
        plan.blockedEffects.ankiMutation === true
    );
  }

  function describeSafeMountExecutionPlan(plan) {
    if (!assertSafeMountExecutionPlan(plan)) {
      throw new Error("R16BA safe mount execution plan assertion failed");
    }
    return freezeClone({
      marker: plan.marker,
      slotName: plan.slotName,
      routeName: plan.routeName,
      sourceOnly: true,
      execute: false,
      mounted: false,
      controlsEnabled: false,
      filePickerOpened: false,
      imagePreviewRendered: false,
      writesAllowed: false,
      safeForPreEnableLoad: true
    });
  }

  var api = Object.freeze({
    marker: MARKER,
    sourceOnly: true,
    disabled: true,
    status: STATUS,
    requiredMarkers: REQUIRED_MARKERS,
    createSafeMountExecutionPlan: createSafeMountExecutionPlan,
    assertSafeMountExecutionPlan: assertSafeMountExecutionPlan,
    describeSafeMountExecutionPlan: describeSafeMountExecutionPlan
  });

  global.APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_SAFE_MOUNT_EXECUTOR_R16BA = api;
})(typeof window !== "undefined" ? window : globalThis);
