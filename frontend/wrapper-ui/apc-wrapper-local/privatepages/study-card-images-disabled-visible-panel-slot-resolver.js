(function () {
  "use strict";

  var MARKER = "APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_SLOT_RESOLVER_R16AS_SOURCE_ONLY";
  var API_NAME = "APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_SLOT_RESOLVER_R16AS";

  var SIDE_EFFECTS = Object.freeze({
    inspectPageOnLoad: false,
    createSlot: false,
    mountPanel: false,
    bindEvents: false,
    openFilePicker: false,
    renderPreview: false,
    writeClientStorage: false,
    writeBackupPayload: false,
    uploadBackend: false,
    syncGoogleDrive: false,
    mutateAnki: false
  });

  var CANDIDATE_SLOTS = Object.freeze([
    Object.freeze({
      name: "card-editor-images-after-answer",
      anchor: "card-editor-answer-field",
      placement: "after",
      required: false
    }),
    Object.freeze({
      name: "card-editor-images-after-question",
      anchor: "card-editor-question-field",
      placement: "after",
      required: false
    }),
    Object.freeze({
      name: "card-editor-images-footer",
      anchor: "card-editor-form-footer",
      placement: "before",
      required: false
    })
  ]);

  function createSlotResolutionPlan(options) {
    var input = options || {};
    var preferredSlot = String(input.preferredSlot || "card-editor-images-after-answer");
    var matching = CANDIDATE_SLOTS.filter(function (slot) {
      return slot.name === preferredSlot;
    })[0] || CANDIDATE_SLOTS[0];

    return Object.freeze({
      marker: MARKER,
      sourceOnly: true,
      enabled: false,
      mounted: false,
      preferredSlot: preferredSlot,
      selectedSlot: matching,
      candidateSlots: CANDIDATE_SLOTS,
      fallback: Object.freeze({
        behavior: "defer",
        createMissingSlot: false,
        mountWithoutAnchor: false,
        userVisibleError: false
      }),
      sideEffects: SIDE_EFFECTS
    });
  }

  function assertSlotResolutionPlan(plan) {
    if (!plan || plan.marker !== MARKER) return false;
    if (plan.sourceOnly !== true || plan.enabled !== false || plan.mounted !== false) return false;
    if (!plan.selectedSlot || typeof plan.selectedSlot.name !== "string") return false;
    if (!Array.isArray(plan.candidateSlots) || plan.candidateSlots.length < 2) return false;
    if (!plan.fallback || plan.fallback.createMissingSlot !== false) return false;
    if (plan.fallback.mountWithoutAnchor !== false) return false;
    if (!plan.sideEffects) return false;
    if (plan.sideEffects.inspectPageOnLoad !== false) return false;
    if (plan.sideEffects.createSlot !== false) return false;
    if (plan.sideEffects.mountPanel !== false) return false;
    if (plan.sideEffects.bindEvents !== false) return false;
    if (plan.sideEffects.openFilePicker !== false) return false;
    if (plan.sideEffects.renderPreview !== false) return false;
    if (plan.sideEffects.writeClientStorage !== false) return false;
    if (plan.sideEffects.uploadBackend !== false) return false;
    if (plan.sideEffects.syncGoogleDrive !== false) return false;
    if (plan.sideEffects.mutateAnki !== false) return false;
    return true;
  }

  var api = Object.freeze({
    marker: MARKER,
    sourceOnly: true,
    enabled: false,
    mounted: false,
    sideEffects: SIDE_EFFECTS,
    candidateSlots: CANDIDATE_SLOTS,
    createSlotResolutionPlan: createSlotResolutionPlan,
    assertSlotResolutionPlan: assertSlotResolutionPlan
  });

  if (typeof window !== "undefined") {
    Object.defineProperty(window, API_NAME, {
      value: api,
      enumerable: false,
      configurable: false,
      writable: false
    });
  }

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }
})();
