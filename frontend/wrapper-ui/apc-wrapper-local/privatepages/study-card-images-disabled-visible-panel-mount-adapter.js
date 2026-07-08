(function attachR16AK(root) {
  "use strict";

  var MARKER = "APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_MOUNT_ADAPTER_R16AK_SOURCE_ONLY";

  function freeze(value) {
    if (value && typeof Object.freeze === "function") {
      return Object.freeze(value);
    }
    return value;
  }

  function normalizeSlotName(slotName) {
    if (typeof slotName !== "string") {
      return "study-card-editor-image-panel-slot";
    }
    var trimmed = slotName.trim();
    return trimmed || "study-card-editor-image-panel-slot";
  }

  function createMountAdapter(options) {
    var opts = options && typeof options === "object" ? options : {};
    var slotName = normalizeSlotName(opts.slotName);
    return freeze({
      marker: MARKER,
      stage: "R16AK",
      sourceOnly: true,
      disabled: true,
      loadedByIndex: false,
      deployReady: false,
      mountAdapterReady: true,
      slotName: slotName,
      mountMode: "describe-only",
      activationMode: "locked",
      sideEffects: freeze({
        domMount: false,
        elementCreate: false,
        eventBind: false,
        filePicker: false,
        previewPaint: false,
        clientWrite: false,
        backupWrite: false,
        networkWrite: false,
        syncWrite: false,
        importedDeckWrite: false
      })
    });
  }

  function describeMount(adapter) {
    var safeAdapter = adapter && typeof adapter === "object" ? adapter : createMountAdapter({});
    return freeze({
      marker: MARKER,
      stage: "R16AK",
      sourceOnly: true,
      status: "disabled-descriptor-only",
      slotName: normalizeSlotName(safeAdapter.slotName),
      mounted: false,
      controlsEnabled: false,
      previewVisible: false,
      writesAllowed: false,
      reason: "Visible panel mount adapter is defined for review only and is not loaded by index.html."
    });
  }

  var api = freeze({
    marker: MARKER,
    stage: "R16AK",
    sourceOnly: true,
    disabled: true,
    createMountAdapter: createMountAdapter,
    describeMount: describeMount
  });

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }
  root.APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_MOUNT_ADAPTER_R16AK = api;
})(typeof globalThis !== "undefined" ? globalThis : this);
