(function studyCardImagesLocalOnlyContractR16AR3(root) {
  "use strict";

  const MARKER = "APC_STUDY_CARD_IMAGES_LOCAL_ONLY_CONTRACT_R16A_R3_SOURCE_ONLY";
  const MODE = "source-only-study-card-images-local-only-contract";
  const VERSION = 1;
  const MAX_IMAGE_BYTES = 8 * 1024 * 1024;
  const SIDES = Object.freeze(["question", "answer"]);
  const ALLOWED_MIME_TYPES = Object.freeze(["image/jpeg", "image/png", "image/webp", "image/gif"]);

  function cleanText(value) {
    return String(value == null ? "" : value).trim();
  }

  function cleanSide(value) {
    const side = cleanText(value).toLowerCase();
    return SIDES.indexOf(side) >= 0 ? side : null;
  }

  function cleanMime(value) {
    return cleanText(value).toLowerCase();
  }

  function cleanName(value) {
    return cleanText(value).replace(/[\\/\u0000-\u001f]+/g, "_").slice(0, 180) || "card-image";
  }

  function cleanInt(value, fallback) {
    const n = Number(value);
    return Number.isFinite(n) && n >= 0 ? Math.floor(n) : fallback;
  }

  function isAllowedMimeType(value) {
    return ALLOWED_MIME_TYPES.indexOf(cleanMime(value)) >= 0;
  }

  function stableId(input) {
    const src = input || {};
    const side = cleanSide(src.side) || "question";
    const seed = [side, cleanName(src.fileName), cleanInt(src.sizeBytes, 0), cleanText(src.localBlobId)].join(":").toLowerCase();
    let hash = 2166136261;
    for (let i = 0; i < seed.length; i += 1) {
      hash ^= seed.charCodeAt(i);
      hash = Math.imul(hash, 16777619);
    }
    return "card-image-" + side + "-" + (hash >>> 0).toString(16);
  }

  function createCardImageAttachment(input) {
    const src = input || {};
    const side = cleanSide(src.side);
    const mimeType = cleanMime(src.mimeType);
    const sizeBytes = cleanInt(src.sizeBytes, 0);
    const attachment = {
      version: VERSION,
      marker: MARKER,
      type: "study-card-image-attachment",
      mode: MODE,
      sourceOnly: true,
      localOnly: true,
      side: side,
      id: cleanText(src.id) || stableId(src),
      fileName: cleanName(src.fileName),
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      width: cleanInt(src.width, null),
      height: cleanInt(src.height, null),
      altText: cleanText(src.altText).slice(0, 500),
      caption: cleanText(src.caption).slice(0, 500),
      localBlobId: cleanText(src.localBlobId),
      sha256: cleanText(src.sha256),
      validation: {
        sideAllowed: !!side,
        mimeTypeAllowed: isAllowedMimeType(mimeType),
        sizeAllowed: sizeBytes > 0 && sizeBytes <= MAX_IMAGE_BYTES,
        blobReferencePresent: !!cleanText(src.localBlobId)
      },
      storagePolicy: {
        backendUploadAllowed: false,
        serverSyncAllowed: false,
        googleDriveSyncAllowedNow: false,
        ankiMutationAllowed: false,
        originalFileMutationAllowed: false,
        blobStoredNow: false,
        indexedDbWriteNow: false,
        backupPayloadWriteNow: false,
        mediaExtractionNow: false
      }
    };
    attachment.isValid = attachment.validation.sideAllowed && attachment.validation.mimeTypeAllowed && attachment.validation.sizeAllowed;
    return Object.freeze(attachment);
  }

  function normalizeAttachmentList(side, list) {
    if (!Array.isArray(list)) return [];
    return list.map(function itemToAttachment(item) {
      return createCardImageAttachment(Object.assign({}, item || {}, { side: side }));
    }).filter(function sameSide(item) {
      return item.side === side;
    });
  }

  function normalizeCardImages(card) {
    const images = card && card.images ? card.images : {};
    return {
      question: normalizeAttachmentList("question", images.question),
      answer: normalizeAttachmentList("answer", images.answer)
    };
  }

  function attachImagesToCardMetadata(card, images) {
    const normalized = images ? {
      question: normalizeAttachmentList("question", images.question),
      answer: normalizeAttachmentList("answer", images.answer)
    } : normalizeCardImages(card);
    return Object.freeze(Object.assign({}, card || {}, {
      images: normalized,
      imagePolicy: {
        marker: MARKER,
        version: VERSION,
        localOnly: true,
        sourceOnly: true,
        backendUploadAllowed: false,
        serverSyncAllowed: false,
        googleDriveSyncAllowedNow: false,
        ankiMutationAllowed: false,
        originalFileMutationAllowed: false,
        blobStoredNow: false,
        indexedDbWriteNow: false,
        backupPayloadWriteNow: false
      }
    }));
  }

  function createBackupManifestForCardImages(card) {
    const images = normalizeCardImages(card || {});
    const all = images.question.concat(images.answer);
    return Object.freeze({
      marker: MARKER,
      version: VERSION,
      mode: MODE,
      localOnly: true,
      sourceOnly: true,
      cardId: cleanText(card && card.id),
      questionImageCount: images.question.length,
      answerImageCount: images.answer.length,
      totalImageCount: all.length,
      allowedMimeTypes: ALLOWED_MIME_TYPES.slice(),
      maxImageBytes: MAX_IMAGE_BYTES,
      containsBlobBytesNow: false,
      writesBackupNow: false,
      writesIndexedDbNow: false,
      uploadsNow: false,
      mutatesAnkiNow: false,
      attachments: all.map(function manifestAttachment(item) {
        return {
          id: item.id,
          side: item.side,
          fileName: item.fileName,
          mimeType: item.mimeType,
          sizeBytes: item.sizeBytes,
          localBlobId: item.localBlobId,
          sha256: item.sha256,
          isValid: item.isValid
        };
      })
    });
  }

  function getSafetyFlags() {
    return Object.freeze({
      marker: MARKER,
      mode: MODE,
      sourceOnly: true,
      loadedByIndexNow: false,
      uiMountedNow: false,
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
    });
  }

  const api = Object.freeze({
    MARKER: MARKER,
    MODE: MODE,
    VERSION: VERSION,
    SIDES: SIDES,
    ALLOWED_MIME_TYPES: ALLOWED_MIME_TYPES,
    MAX_IMAGE_BYTES: MAX_IMAGE_BYTES,
    createCardImageAttachment: createCardImageAttachment,
    normalizeCardImages: normalizeCardImages,
    attachImagesToCardMetadata: attachImagesToCardMetadata,
    createBackupManifestForCardImages: createBackupManifestForCardImages,
    getSafetyFlags: getSafetyFlags,
    isAllowedMimeType: isAllowedMimeType
  });

  root.APC_STUDY_CARD_IMAGES_LOCAL_ONLY_CONTRACT = api;
  if (typeof module !== "undefined" && module.exports) module.exports = api;
})(globalThis);
