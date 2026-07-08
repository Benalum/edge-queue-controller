(function (root, factory) {
  var api = factory();
  if (typeof module === "object" && module.exports) {
    module.exports = api;
  }
  if (root) {
    root.APC_STUDY_CARD_IMAGES_DISABLED_RENDER_SPEC = api;
  }
})(typeof window !== "undefined" ? window : null, function () {
  "use strict";

  var MARKER = "APC_STUDY_CARD_IMAGES_DISABLED_RENDER_SPEC_R16I_SOURCE_ONLY";
  var VERSION = "stage17k-r16i-study-card-images-disabled-render-spec-source-only-20260708";
  var SIDES = ["question", "answer"];
  var ALLOWED_MIME_TYPES = ["image/jpeg", "image/png", "image/webp", "image/gif"];

  function clone(value) {
    return JSON.parse(JSON.stringify(value));
  }

  function normalizeSide(side) {
    var normalized = String(side || "").trim().toLowerCase();
    if (normalized !== "question" && normalized !== "answer") {
      throw new Error("Invalid study card image side");
    }
    return normalized;
  }

  function normalizeAttachmentSummary(attachment) {
    if (!attachment || typeof attachment !== "object") {
      return null;
    }
    return {
      id: String(attachment.id || attachment.imageId || ""),
      side: attachment.side ? normalizeSide(attachment.side) : null,
      mimeType: String(attachment.mimeType || ""),
      byteSize: Number.isFinite(Number(attachment.byteSize)) ? Number(attachment.byteSize) : null,
      width: Number.isFinite(Number(attachment.width)) ? Number(attachment.width) : null,
      height: Number.isFinite(Number(attachment.height)) ? Number(attachment.height) : null,
      altText: String(attachment.altText || ""),
      source: "metadata-only"
    };
  }

  function createEmptySlot(side) {
    var normalized = normalizeSide(side);
    var labelPrefix = normalized === "question" ? "Question" : "Answer";
    return {
      type: "study-card-image-slot",
      side: normalized,
      label: labelPrefix + " image",
      emptyText: "No " + normalized + " image attached",
      plannedButtonText: "Add " + normalized + " image",
      disabled: true,
      reason: "Image UI is planned but not mounted or bound in R16I.",
      attachment: null,
      accepts: ALLOWED_MIME_TYPES.slice(),
      mountNow: false,
      bindNow: false,
      openPickerNow: false,
      previewNow: false,
      persistNow: false,
      uploadNow: false,
      mutateAnkiNow: false
    };
  }

  function createFilledSlot(side, attachment) {
    var slot = createEmptySlot(side);
    slot.emptyText = "Image metadata present but preview is disabled in R16I";
    slot.attachment = normalizeAttachmentSummary(attachment);
    return slot;
  }

  function extractAttachments(cardMetadata) {
    var value = cardMetadata && typeof cardMetadata === "object" ? cardMetadata : {};
    var images = value.images && typeof value.images === "object" ? value.images : {};
    return {
      question: normalizeAttachmentSummary(images.question || value.questionImage || null),
      answer: normalizeAttachmentSummary(images.answer || value.answerImage || null)
    };
  }

  function createDisabledRenderSpec(cardMetadata, options) {
    var opts = options && typeof options === "object" ? options : {};
    var attachments = extractAttachments(cardMetadata);
    var slots = SIDES.map(function (side) {
      return attachments[side] ? createFilledSlot(side, attachments[side]) : createEmptySlot(side);
    });

    return {
      marker: MARKER,
      version: VERSION,
      type: "study-card-images-disabled-render-spec",
      surface: String(opts.surface || "study-card-editor"),
      title: "Optional card images",
      description: "Render specification only. Question and answer image controls remain disabled until a later mounted stage.",
      slots: slots,
      policy: {
        localOnly: true,
        optionalQuestionImage: true,
        optionalAnswerImage: true,
        allowedMimeTypes: ALLOWED_MIME_TYPES.slice(),
        svgAllowed: false,
        serverUploadAllowed: false,
        googleDriveSyncAllowedNow: false,
        ankiMutationAllowed: false,
        originalFileMutationAllowed: false,
        mediaExtractionNow: false
      },
      actions: {
        mountNow: false,
        bindNow: false,
        openPickerNow: false,
        previewNow: false,
        persistNow: false,
        writeIndexedDbNow: false,
        writeBackupNow: false,
        uploadNow: false,
        mutateAnkiNow: false
      }
    };
  }

  function validateDisabledRenderSpec(spec) {
    var errors = [];
    if (!spec || typeof spec !== "object") {
      errors.push("spec must be an object");
    }
    if (spec && spec.marker !== MARKER) {
      errors.push("marker mismatch");
    }
    if (!Array.isArray(spec && spec.slots) || spec.slots.length !== 2) {
      errors.push("expected question and answer slots");
    }
    (spec && Array.isArray(spec.slots) ? spec.slots : []).forEach(function (slot) {
      try {
        normalizeSide(slot.side);
      } catch (err) {
        errors.push("invalid slot side");
      }
      ["mountNow", "bindNow", "openPickerNow", "previewNow", "persistNow", "uploadNow", "mutateAnkiNow"].forEach(function (key) {
        if (slot[key] !== false) {
          errors.push("slot " + slot.side + " has unsafe flag " + key);
        }
      });
      if (slot.disabled !== true) {
        errors.push("slot " + slot.side + " must remain disabled");
      }
    });
    if (spec && spec.policy) {
      ["serverUploadAllowed", "googleDriveSyncAllowedNow", "ankiMutationAllowed", "originalFileMutationAllowed", "mediaExtractionNow"].forEach(function (key) {
        if (spec.policy[key] !== false) {
          errors.push("policy has unsafe flag " + key);
        }
      });
    }
    if (spec && spec.actions) {
      Object.keys(spec.actions).forEach(function (key) {
        if (spec.actions[key] !== false) {
          errors.push("action has unsafe flag " + key);
        }
      });
    }
    return {
      ok: errors.length === 0,
      errors: errors
    };
  }

  function getSafetyFlags() {
    return {
      marker: MARKER,
      sourceOnly: true,
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
      mediaExtractionNow: false
    };
  }

  return {
    MARKER: MARKER,
    VERSION: VERSION,
    ALLOWED_MIME_TYPES: ALLOWED_MIME_TYPES.slice(),
    createDisabledRenderSpec: createDisabledRenderSpec,
    validateDisabledRenderSpec: validateDisabledRenderSpec,
    getSafetyFlags: getSafetyFlags,
    _cloneForTest: clone
  };
});
