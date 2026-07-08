(function studyCardImagesBackupManifestContractR16C(root) {
  "use strict";

  const MARKER = "APC_STUDY_CARD_IMAGES_BACKUP_MANIFEST_CONTRACT_R16C_SOURCE_ONLY";
  const MODE = "source-only-study-card-images-backup-manifest-contract";
  const VERSION = 1;
  const IMAGE_CONTRACT_GLOBAL = "APC_STUDY_CARD_IMAGES_LOCAL_ONLY_CONTRACT";
  const STORAGE_CONTRACT_GLOBAL = "APC_STUDY_CARD_IMAGES_LOCAL_STORAGE_ADAPTER_CONTRACT";

  function cleanString(value) {
    return String(value == null ? "" : value).trim();
  }

  function safeArray(value) {
    return Array.isArray(value) ? value : [];
  }

  function positiveInteger(value) {
    const n = Number(value);
    if (!Number.isFinite(n) || n < 0) return 0;
    return Math.floor(n);
  }

  function getImageContract() {
    return root && root[IMAGE_CONTRACT_GLOBAL] ? root[IMAGE_CONTRACT_GLOBAL] : null;
  }

  function getStorageContract() {
    return root && root[STORAGE_CONTRACT_GLOBAL] ? root[STORAGE_CONTRACT_GLOBAL] : null;
  }

  function normalizeCardImages(card) {
    const imageContract = getImageContract();
    if (imageContract && typeof imageContract.normalizeCardImages === "function") {
      return imageContract.normalizeCardImages(card || {});
    }
    const images = card && card.images ? card.images : {};
    return {
      question: safeArray(images.question),
      answer: safeArray(images.answer)
    };
  }

  function createImageBackupEntry(attachment, options) {
    const source = attachment || {};
    const settings = options || {};
    return Object.freeze({
      marker: MARKER,
      version: VERSION,
      type: "study-card-image-backup-entry",
      mode: MODE,
      sourceOnly: true,
      localOnly: true,
      cardId: cleanString(settings.cardId),
      side: cleanString(source.side),
      id: cleanString(source.id),
      fileName: cleanString(source.fileName),
      mimeType: cleanString(source.mimeType).toLowerCase(),
      sizeBytes: positiveInteger(source.sizeBytes),
      width: source.width == null ? null : positiveInteger(source.width),
      height: source.height == null ? null : positiveInteger(source.height),
      altText: cleanString(source.altText).slice(0, 500),
      caption: cleanString(source.caption).slice(0, 500),
      localBlobId: cleanString(source.localBlobId),
      sha256: cleanString(source.sha256),
      isValidAttachment: source.isValid === true,
      includesBlobBytesNow: false,
      blobReadNow: false,
      blobWrittenNow: false,
      backupPayloadWriteNow: false,
      indexedDbReadNow: false,
      indexedDbWriteNow: false,
      objectUrlCreatedNow: false,
      downloadUrlCreatedNow: false,
      uploadNow: false,
      serverSyncNow: false,
      googleDriveSyncNow: false,
      ankiMutationNow: false
    });
  }

  function createCardImagesBackupSection(card, options) {
    const sourceCard = card || {};
    const settings = options || {};
    const images = normalizeCardImages(sourceCard);
    const questionEntries = safeArray(images.question).map((item) => createImageBackupEntry(item, { cardId: sourceCard.id }));
    const answerEntries = safeArray(images.answer).map((item) => createImageBackupEntry(item, { cardId: sourceCard.id }));
    const all = questionEntries.concat(answerEntries);
    const storageContract = getStorageContract();

    return Object.freeze({
      marker: MARKER,
      version: VERSION,
      type: "study-card-images-backup-section",
      mode: MODE,
      sourceOnly: true,
      localOnly: true,
      cardId: cleanString(sourceCard.id),
      exportedAt: cleanString(settings.exportedAt),
      storageContractAvailable: !!storageContract,
      questionImageCount: questionEntries.length,
      answerImageCount: answerEntries.length,
      totalImageCount: all.length,
      containsBlobBytesNow: false,
      readsBlobBytesNow: false,
      writesBackupNow: false,
      writesIndexedDbNow: false,
      uploadsNow: false,
      serverSyncNow: false,
      googleDriveSyncNow: false,
      mutatesAnkiNow: false,
      entries: Object.freeze({
        question: Object.freeze(questionEntries.slice()),
        answer: Object.freeze(answerEntries.slice())
      }),
      validation: Object.freeze(validateCardImagesBackupEntries(all))
    });
  }

  function validateCardImagesBackupEntries(entries) {
    const list = safeArray(entries);
    const errors = [];
    const warnings = [];
    list.forEach((entry, index) => {
      if (!entry || !entry.id) errors.push("entry[" + index + "].id missing");
      if (!entry || !entry.side) errors.push("entry[" + index + "].side missing");
      if (entry && entry.includesBlobBytesNow !== false) errors.push("entry[" + index + "].includesBlobBytesNow must be false");
      if (entry && entry.uploadNow !== false) errors.push("entry[" + index + "].uploadNow must be false");
      if (entry && entry.ankiMutationNow !== false) errors.push("entry[" + index + "].ankiMutationNow must be false");
      if (entry && !entry.localBlobId) warnings.push("entry[" + index + "].localBlobId missing");
      if (entry && !entry.sha256) warnings.push("entry[" + index + "].sha256 missing");
    });
    return Object.freeze({
      isValid: errors.length === 0,
      errorCount: errors.length,
      warningCount: warnings.length,
      errors: Object.freeze(errors),
      warnings: Object.freeze(warnings)
    });
  }

  function validateCardImagesBackupSection(section) {
    const source = section || {};
    const entries = safeArray(source.entries && source.entries.question).concat(safeArray(source.entries && source.entries.answer));
    const entryValidation = validateCardImagesBackupEntries(entries);
    const errors = entryValidation.errors.slice();
    if (source.marker !== MARKER) errors.push("marker mismatch");
    if (source.containsBlobBytesNow !== false) errors.push("containsBlobBytesNow must be false");
    if (source.writesBackupNow !== false) errors.push("writesBackupNow must be false");
    if (source.uploadsNow !== false) errors.push("uploadsNow must be false");
    if (source.mutatesAnkiNow !== false) errors.push("mutatesAnkiNow must be false");
    return Object.freeze({
      isValid: errors.length === 0,
      errorCount: errors.length,
      warningCount: entryValidation.warningCount,
      errors: Object.freeze(errors),
      warnings: entryValidation.warnings
    });
  }

  function createImportPlanFromBackupSection(section) {
    const source = section || {};
    const validation = validateCardImagesBackupSection(source);
    const entries = safeArray(source.entries && source.entries.question).concat(safeArray(source.entries && source.entries.answer));
    return Object.freeze({
      marker: MARKER,
      version: VERSION,
      type: "study-card-images-import-plan",
      mode: MODE,
      sourceOnly: true,
      localOnly: true,
      cardId: cleanString(source.cardId),
      totalImageCount: entries.length,
      validation: validation,
      createsCardsNow: false,
      writesCardMetadataNow: false,
      writesImageBlobsNow: false,
      writesIndexedDbNow: false,
      readsBlobBytesNow: false,
      opensFilePickerNow: false,
      mutatesAnkiNow: false,
      uploadsNow: false,
      serverSyncNow: false,
      googleDriveSyncNow: false,
      steps: Object.freeze(entries.map((entry) => Object.freeze({
        id: entry.id,
        side: entry.side,
        fileName: entry.fileName,
        localBlobId: entry.localBlobId,
        plannedOnly: true,
        writeNow: false
      })))
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
      containsBlobBytesNow: false,
      readsBlobBytesNow: false,
      writesBackupNow: false,
      writesIndexedDbNow: false,
      uploadsNow: false,
      serverSyncNow: false,
      googleDriveSyncNow: false,
      mutatesAnkiNow: false
    });
  }

  const api = Object.freeze({
    MARKER: MARKER,
    MODE: MODE,
    VERSION: VERSION,
    createImageBackupEntry: createImageBackupEntry,
    createCardImagesBackupSection: createCardImagesBackupSection,
    validateCardImagesBackupSection: validateCardImagesBackupSection,
    createImportPlanFromBackupSection: createImportPlanFromBackupSection,
    getSafetyFlags: getSafetyFlags
  });

  root.APC_STUDY_CARD_IMAGES_BACKUP_MANIFEST_CONTRACT = api;

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }
})(globalThis);
