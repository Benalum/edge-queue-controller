(function attachStudyCardImagesDisabledVisiblePanelMountController(global) {
  "use strict";

  var MARKER = "APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_MOUNT_CONTROLLER_R16AW_SOURCE_ONLY";

  var STATUS = Object.freeze({
    sourceOnly: true,
    disabled: true,
    loadedByIndex: false,
    deployed: false,
    mounted: false,
    controlsEnabled: false,
    pickerOpened: false,
    previewRendered: false,
    clientWrite: false,
    backupPayloadWrite: false,
    backendUpload: false,
    driveSync: false,
    ankiMutation: false
  });

  var REQUIRED_MARKERS = Object.freeze([
    "APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_R16AJ_SOURCE_ONLY",
    "APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_MOUNT_ADAPTER_R16AK_SOURCE_ONLY",
    "APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_DOM_TEMPLATE_R16AO_SOURCE_ONLY",
    "APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_SLOT_RESOLVER_R16AS_SOURCE_ONLY"
  ]);

  function freezeClone(value) {
    return Object.freeze(JSON.parse(JSON.stringify(value)));
  }

  function createDisabledMountController(options) {
    var config = options || {};
    var slotName = String(config.slotName || "study-card-editor-image-panel-slot");
    return freezeClone({
      stage: "R16AW",
      marker: MARKER,
      slotName: slotName,
      disabled: true,
      sourceOnly: true,
      requiredMarkers: REQUIRED_MARKERS.slice(),
      plannedSequence: [
        "resolve-card-editor-slot",
        "prepare-disabled-template",
        "prepare-disabled-mount-adapter",
        "keep-controls-disabled",
        "keep-picker-closed",
        "keep-preview-hidden",
        "keep-writes-blocked"
      ],
      effects: {
        domMount: false,
        elementCreate: false,
        eventBind: false,
        pickerOpen: false,
        previewPaint: false,
        clientWrite: false,
        backupPayloadWrite: false,
        backendUpload: false,
        driveSync: false,
        ankiMutation: false
      }
    });
  }

  function assertDisabledMountController(controller) {
    return Boolean(
      controller &&
        controller.marker === MARKER &&
        controller.disabled === true &&
        controller.sourceOnly === true &&
        controller.effects &&
        controller.effects.domMount === false &&
        controller.effects.elementCreate === false &&
        controller.effects.eventBind === false &&
        controller.effects.pickerOpen === false &&
        controller.effects.previewPaint === false &&
        controller.effects.clientWrite === false &&
        controller.effects.backupPayloadWrite === false &&
        controller.effects.backendUpload === false &&
        controller.effects.driveSync === false &&
        controller.effects.ankiMutation === false
    );
  }

  function describeDisabledMountController(controller) {
    if (!assertDisabledMountController(controller)) {
      throw new Error("R16AW disabled mount controller assertion failed");
    }
    return freezeClone({
      marker: controller.marker,
      slotName: controller.slotName,
      mounted: false,
      controlsEnabled: false,
      pickerOpened: false,
      previewRendered: false,
      writesAllowed: false,
      safeToLoadBeforeEnableStage: true
    });
  }

  var api = Object.freeze({
    marker: MARKER,
    sourceOnly: true,
    disabled: true,
    status: STATUS,
    requiredMarkers: REQUIRED_MARKERS,
    createDisabledMountController: createDisabledMountController,
    assertDisabledMountController: assertDisabledMountController,
    describeDisabledMountController: describeDisabledMountController
  });

  global.APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_MOUNT_CONTROLLER_R16AW = api;
})(typeof window !== "undefined" ? window : globalThis);
