(function studyCardImagesLocalStorageAdapterContractR16B(root) {
  "use strict";

  const MARKER = "APC_STUDY_CARD_IMAGES_LOCAL_STORAGE_ADAPTER_CONTRACT_R16B_SOURCE_ONLY";
  const MODE = "source-only-study-card-images-local-storage-adapter-contract";
  const VERSION = 1;
  const DB_NAME = "buddies_who_study_local_v1";
  const STORE_NAME = "study_card_image_blobs_v1";
  const METADATA_NAMESPACE = "study/card-images/v1";
  const CONTRACT_GLOBAL = "APC_STUDY_CARD_IMAGES_LOCAL_ONLY_CONTRACT";
  const MAX_IMAGE_BYTES = 8 * 1024 * 1024;
  const ALLOWED_MIME_TYPES = Object.freeze(["image/jpeg", "image/png", "image/webp", "image/gif"]);

  function cleanString(value) {
    return String(value == null ? "" : value).trim();
  }

  function cleanSide(side) {
    const value = cleanString(side).toLowerCase();
    return value === "question" || value === "answer" ? value : null;
  }

  function cleanMimeType(value) {
    return cleanString(value).toLowerCase();
  }

  function cleanInteger(value, fallback) {
    const n = Number(value);
    if (!Number.isFinite(n) || n < 0) return fallback;
    return Math.floor(n);
  }

  function cleanFileName(value) {
    const name = cleanString(value).replace(/[\\/\u0000-\u001f]+/g, "_").slice(0, 180);
    return name || "card-image";
  }

  function allowedMimeType(value) {
    return ALLOWED_MIME_TYPES.includes(cleanMimeType(value));
  }

  function getImageContractApi() {
    return root && root[CONTRACT_GLOBAL] ? root[CONTRACT_GLOBAL] : null;
  }

  function stableId(seed) {
    const text = cleanString(seed).toLowerCase();
    let hash = 2166136261;
    for (let i = 0; i < text.length; i += 1) {
      hash ^= text.charCodeAt(i);
      hash = Math.imul(hash, 16777619);
    }
    return (hash >>> 0).toString(16);
  }

  function createBlobId(input) {
    const source = input || {};
    const side = cleanSide(source.side) || "question";
    const cardId = cleanString(source.cardId) || "card";
    const fileName = cleanFileName(source.fileName);
    const sizeBytes = cleanInteger(source.sizeBytes, 0);
    const mimeType = cleanMimeType(source.mimeType);
    const sha256 = cleanString(source.sha256);
    return ["study-card-image", side, stableId([cardId, fileName, sizeBytes, mimeType, sha256].join(":"))].join("-");
  }

  function normalizeAttachment(input) {
    const contract = getImageContractApi();
    if (contract && typeof contract.createCardImageAttachment === "function") {
      return contract.createCardImageAttachment(input || {});
    }
    const source = input || {};
    const side = cleanSide(source.side);
    const mimeType = cleanMimeType(source.mimeType);
    const sizeBytes = cleanInteger(source.sizeBytes, 0);
    return Object.freeze({
      version: VERSION,
      type: "study-card-image-attachment",
      sourceOnly: true,
      localOnly: true,
      side: side,
      id: cleanString(source.id) || createBlobId(source),
      fileName: cleanFileName(source.fileName),
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      localBlobId: cleanString(source.localBlobId),
      sha256: cleanString(source.sha256),
      isValid: !!side && allowedMimeType(mimeType) && sizeBytes > 0 && sizeBytes <= MAX_IMAGE_BYTES
    });
  }

  function createImageBlobStorageDescriptor(input) {
    const source = input || {};
    const attachment = normalizeAttachment(source);
    const cardId = cleanString(source.cardId);
    const deckId = cleanString(source.deckId);
    const blobId = cleanString(source.localBlobId) || createBlobId(Object.assign({}, source, attachment));
    const objectKey = [METADATA_NAMESPACE, deckId || "deck", cardId || "card", attachment.side || "unknown", blobId].join("/");

    return Object.freeze({
      marker: MARKER,
      version: VERSION,
      mode: MODE,
      type: "study-card-image-blob-storage-descriptor",
      sourceOnly: true,
      localOnly: true,
      dbName: DB_NAME,
      storeName: STORE_NAME,
      metadataNamespace: METADATA_NAMESPACE,
      cardId: cardId,
      deckId: deckId,
      side: attachment.side,
      attachmentId: attachment.id,
      blobId: blobId,
      objectKey: objectKey,
      fileName: attachment.fileName,
      mimeType: attachment.mimeType,
      sizeBytes: attachment.sizeBytes,
      sha256: attachment.sha256 || "",
      isValidAttachment: attachment.isValid === true,
      plannedOnly: true,
      storageAdapterLoadedNow: false,
      filePickerOpenedNow: false,
      blobReadNow: false,
      blobStoredNow: false,
      databaseOpenNow: false,
      databaseWriteNow: false,
      databaseDeleteNow: false,
      backupPayloadWriteNow: false,
      previewUrlCreatedNow: false,
      previewRenderedNow: false,
      backendUploadAllowed: false,
      serverSyncAllowed: false,
      googleDriveSyncAllowedNow: false,
      ankiMutationAllowed: false,
      originalFileMutationAllowed: false,
      mediaExtractionNow: false,
      safety: Object.freeze([
        "Source-only storage descriptor.",
        "No browser database is opened by R16B.",
        "No blob is read or stored by R16B.",
        "No preview URL is created by R16B.",
        "No backup payload is written by R16B.",
        "No upload or Anki mutation is allowed by R16B."
      ])
    });
  }

  function collectCardAttachments(card) {
    const source = card && card.images ? card.images : {};
    const question = Array.isArray(source.question) ? source.question : [];
    const answer = Array.isArray(source.answer) ? source.answer : [];
    return question.map((item) => Object.assign({}, item || {}, { side: "question" }))
      .concat(answer.map((item) => Object.assign({}, item || {}, { side: "answer" })));
  }

  function createCardImageStoragePlan(card) {
    const source = card || {};
    const cardId = cleanString(source.id);
    const deckId = cleanString(source.deckId);
    const attachments = collectCardAttachments(source).map((item) => createImageBlobStorageDescriptor(Object.assign({}, item, {
      cardId: cardId,
      deckId: deckId
    })));
    const questionImageCount = attachments.filter((item) => item.side === "question").length;
    const answerImageCount = attachments.filter((item) => item.side === "answer").length;

    return Object.freeze({
      marker: MARKER,
      version: VERSION,
      mode: MODE,
      type: "study-card-image-storage-plan",
      sourceOnly: true,
      localOnly: true,
      dbName: DB_NAME,
      storeName: STORE_NAME,
      metadataNamespace: METADATA_NAMESPACE,
      cardId: cardId,
      deckId: deckId,
      questionImageCount: questionImageCount,
      answerImageCount: answerImageCount,
      totalImageCount: attachments.length,
      totalPlannedBytes: attachments.reduce((sum, item) => sum + cleanInteger(item.sizeBytes, 0), 0),
      descriptors: attachments,
      plannedOnly: true,
      databaseOpenNow: false,
      databaseWriteNow: false,
      blobStoredNow: false,
      backupPayloadWriteNow: false,
      uploadsNow: false,
      mutatesAnkiNow: false
    });
  }

  function createBackupReferencePlan(card) {
    const plan = createCardImageStoragePlan(card || {});
    return Object.freeze({
      marker: MARKER,
      version: VERSION,
      mode: MODE,
      type: "study-card-image-backup-reference-plan",
      sourceOnly: true,
      localOnly: true,
      cardId: plan.cardId,
      deckId: plan.deckId,
      questionImageCount: plan.questionImageCount,
      answerImageCount: plan.answerImageCount,
      totalImageCount: plan.totalImageCount,
      metadataNamespace: METADATA_NAMESPACE,
      containsBlobBytesNow: false,
      backupPayloadWriteNow: false,
      databaseOpenNow: false,
      databaseReadNow: false,
      databaseWriteNow: false,
      uploadNow: false,
      ankiMutationNow: false,
      references: plan.descriptors.map((item) => ({
        attachmentId: item.attachmentId,
        blobId: item.blobId,
        objectKey: item.objectKey,
        side: item.side,
        fileName: item.fileName,
        mimeType: item.mimeType,
        sizeBytes: item.sizeBytes,
        sha256: item.sha256,
        isValidAttachment: item.isValidAttachment
      }))
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
      blobReadNow: false,
      blobStoredNow: false,
      databaseOpenNow: false,
      databaseWriteNow: false,
      databaseDeleteNow: false,
      backupPayloadWriteNow: false,
      previewUrlCreatedNow: false,
      previewRenderedNow: false,
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
    DB_NAME: DB_NAME,
    STORE_NAME: STORE_NAME,
    METADATA_NAMESPACE: METADATA_NAMESPACE,
    ALLOWED_MIME_TYPES: ALLOWED_MIME_TYPES,
    MAX_IMAGE_BYTES: MAX_IMAGE_BYTES,
    createBlobId: createBlobId,
    createImageBlobStorageDescriptor: createImageBlobStorageDescriptor,
    createCardImageStoragePlan: createCardImageStoragePlan,
    createBackupReferencePlan: createBackupReferencePlan,
    getSafetyFlags: getSafetyFlags
  });

  root.APC_STUDY_CARD_IMAGES_LOCAL_STORAGE_ADAPTER_CONTRACT = api;

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }
})(globalThis);
