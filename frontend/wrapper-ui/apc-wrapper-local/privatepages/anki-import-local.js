(function attachApcAnkiImportLocal(root) {
  "use strict";

  const PATCH_MARKER = "APC_ANKI_IMPORT_LOCAL_DISABLED_SKELETON_R11B";
  const APKG_INSPECTOR_MARKER = "APC_ANKI_IMPORT_LOCAL_APKG_CONTAINER_INSPECTOR_R11C";

  const DOC_KEYS = Object.freeze({
    importSources: "study/import-sources/v1",
    ankiPackages: "study/anki-packages/v1",
    ankiNotes: "study/anki-notes/v1",
    ankiCards: "study/anki-cards/v1",
    ankiMedia: "study/anki-media/v1",
    importRuns: "study/import-runs/v1"
  });

  const SUPPORTED_EXTENSIONS = Object.freeze([".apkg"]);

  function safeString(value) {
    return value == null ? "" : String(value);
  }

  function normalizeFilename(name) {
    return safeString(name).split(/[\\/]/).pop().trim();
  }

  function isSupportedFileName(name) {
    const normalized = normalizeFilename(name).toLowerCase();
    return SUPPORTED_EXTENSIONS.some((extension) => normalized.endsWith(extension));
  }

  function stableHashText(input) {
    const text = safeString(input);
    let hash = 2166136261;
    for (let i = 0; i < text.length; i += 1) {
      hash ^= text.charCodeAt(i);
      hash = Math.imul(hash, 16777619);
    }
    return (hash >>> 0).toString(16).padStart(8, "0");
  }

  function makeLocalId(prefix, parts) {
    return `${prefix}_${stableHashText(parts.map(safeString).join("|"))}`;
  }

  function describeFileSource(fileLike, options) {
    const opts = options || {};
    const displayName = normalizeFilename(fileLike && fileLike.name);
    if (!displayName) {
      throw new Error("Anki import source requires a display filename.");
    }
    if (!isSupportedFileName(displayName)) {
      throw new Error("Only .apkg files are supported by the disabled R11B skeleton.");
    }

    const sizeBytes = Number(fileLike && fileLike.size);
    const lastModified = Number(fileLike && fileLike.lastModified);
    const createdAt = safeString(opts.createdAt || new Date(0).toISOString());
    const contentSha256 = safeString(opts.contentSha256 || "");

    return Object.freeze({
      id: makeLocalId("src_local", [displayName, Number.isFinite(sizeBytes) ? sizeBytes : 0, Number.isFinite(lastModified) ? lastModified : 0, contentSha256]),
      kind: "anki-apkg",
      displayName,
      sizeBytes: Number.isFinite(sizeBytes) ? sizeBytes : 0,
      lastModified: Number.isFinite(lastModified) ? lastModified : 0,
      createdAt,
      contentSha256,
      status: "selected"
    });
  }

  function arrayOrEmpty(value) {
    return Array.isArray(value) ? value : [];
  }

  function validatePackageSummary(summary) {
    const value = summary || {};
    const errors = [];

    if (!Array.isArray(value.decks)) errors.push("summary.decks must be an array");
    if (!Array.isArray(value.notes)) errors.push("summary.notes must be an array");
    if (!Array.isArray(value.cards)) errors.push("summary.cards must be an array");
    if (!Array.isArray(value.media)) errors.push("summary.media must be an array");

    arrayOrEmpty(value.notes).forEach((note, index) => {
      if (!safeString(note.guid)) errors.push(`notes[${index}].guid is required`);
    });

    arrayOrEmpty(value.cards).forEach((card, index) => {
      if (!Number.isFinite(Number(card.ordinal))) errors.push(`cards[${index}].ordinal is required`);
      if (!safeString(card.deckPath)) errors.push(`cards[${index}].deckPath is required`);
    });

    return Object.freeze({
      ok: errors.length === 0,
      errors
    });
  }

  function createImportPlan(input) {
    const args = input || {};
    const source = args.source || {};
    const summary = args.summary || {};
    const timestamp = safeString(args.timestamp || new Date(0).toISOString());
    const validation = validatePackageSummary(summary);

    if (!validation.ok) {
      throw new Error(`Invalid Anki package summary: ${validation.errors.join("; ")}`);
    }

    const packageId = makeLocalId("anki_pkg", [
      source.id,
      source.displayName,
      arrayOrEmpty(summary.notes).length,
      arrayOrEmpty(summary.cards).length,
      arrayOrEmpty(summary.media).length
    ]);

    const noteLocalIdBySourceId = new Map();

    const notes = arrayOrEmpty(summary.notes).map((note) => {
      const noteLocalId = makeLocalId("anki_note", [packageId, note.ankiNoteId, note.guid]);
      noteLocalIdBySourceId.set(String(note.ankiNoteId), noteLocalId);
      return {
        id: noteLocalId,
        packageId,
        ankiNoteId: note.ankiNoteId == null ? null : Number(note.ankiNoteId),
        guid: safeString(note.guid),
        modelId: note.modelId == null ? null : Number(note.modelId),
        noteTypeName: safeString(note.noteTypeName),
        fields: arrayOrEmpty(note.fields).map(safeString),
        tags: arrayOrEmpty(note.tags).map(safeString),
        sortField: safeString(note.sortField),
        contentSha256: safeString(note.contentSha256)
      };
    });

    const cards = arrayOrEmpty(summary.cards).map((card) => {
      const noteLocalId = noteLocalIdBySourceId.get(String(card.ankiNoteId)) || "";
      return {
        id: makeLocalId("anki_card", [packageId, card.ankiCardId, card.ankiNoteId, card.ordinal]),
        packageId,
        noteLocalId,
        ankiCardId: card.ankiCardId == null ? null : Number(card.ankiCardId),
        ankiNoteId: card.ankiNoteId == null ? null : Number(card.ankiNoteId),
        deckId: card.deckId == null ? null : Number(card.deckId),
        deckPath: safeString(card.deckPath),
        ordinal: Number(card.ordinal),
        templateName: safeString(card.templateName),
        queue: card.queue == null ? null : Number(card.queue),
        due: card.due == null ? null : Number(card.due)
      };
    });

    const media = arrayOrEmpty(summary.media).map((item) => ({
      id: makeLocalId("anki_media", [packageId, item.packageMediaKey, item.originalFilename, item.contentSha256]),
      packageId,
      originalFilename: normalizeFilename(item.originalFilename),
      packageMediaKey: safeString(item.packageMediaKey),
      mimeType: safeString(item.mimeType),
      sizeBytes: item.sizeBytes == null ? 0 : Number(item.sizeBytes),
      contentSha256: safeString(item.contentSha256)
    }));

    const decks = arrayOrEmpty(summary.decks).map((deck) => ({
      id: makeLocalId("anki_deck", [packageId, deck.deckId, deck.deckPath || deck.name]),
      packageId,
      deckId: deck.deckId == null ? null : Number(deck.deckId),
      name: safeString(deck.name),
      deckPath: safeString(deck.deckPath || deck.name)
    }));

    const packageRecord = {
      id: packageId,
      sourceId: safeString(source.id),
      originalFilename: safeString(source.displayName),
      collectionSchema: safeString(summary.collectionSchema || "anki2"),
      collectionModified: summary.collectionModified == null ? null : Number(summary.collectionModified),
      deckCount: decks.length,
      noteCount: notes.length,
      cardCount: cards.length,
      mediaCount: media.length,
      importedAt: timestamp,
      status: "planned"
    };

    const runRecord = {
      id: makeLocalId("import_run", [packageId, timestamp]),
      sourceId: safeString(source.id),
      packageId,
      startedAt: timestamp,
      finishedAt: timestamp,
      status: "planned",
      warnings: [],
      errors: [],
      counts: {
        decks: decks.length,
        notes: notes.length,
        cards: cards.length,
        media: media.length
      }
    };

    return Object.freeze({
      marker: PATCH_MARKER,
      disabledSkeleton: true,
      writesOriginalAnki: false,
      writesServer: false,
      writesLocalDocs: false,
      docs: {
        [DOC_KEYS.importSources]: { sources: [Object.assign({}, source, { status: "planned" })] },
        [DOC_KEYS.ankiPackages]: { packages: [packageRecord] },
        [DOC_KEYS.ankiNotes]: { notes },
        [DOC_KEYS.ankiCards]: { cards },
        [DOC_KEYS.ankiMedia]: { media },
        [DOC_KEYS.importRuns]: { runs: [runRecord] }
      }
    });
  }

  function asUint8Array(bufferLike) {
    if (bufferLike instanceof Uint8Array) return bufferLike;
    if (bufferLike instanceof ArrayBuffer) return new Uint8Array(bufferLike);
    if (bufferLike && bufferLike.buffer instanceof ArrayBuffer) {
      return new Uint8Array(bufferLike.buffer, bufferLike.byteOffset || 0, bufferLike.byteLength);
    }
    throw new Error("APKG inspector requires an ArrayBuffer or Uint8Array.");
  }

  function readUInt16LE(bytes, offset) {
    return bytes[offset] | (bytes[offset + 1] << 8);
  }

  function readUInt32LE(bytes, offset) {
    return (bytes[offset] |
      (bytes[offset + 1] << 8) |
      (bytes[offset + 2] << 16) |
      (bytes[offset + 3] << 24)) >>> 0;
  }

  function decodeZipName(bytes, offset, length) {
    const slice = bytes.slice(offset, offset + length);
    if (typeof TextDecoder !== "undefined") {
      return new TextDecoder("utf-8").decode(slice);
    }
    let text = "";
    for (let i = 0; i < slice.length; i += 1) {
      text += String.fromCharCode(slice[i]);
    }
    return text;
  }

  function findEndOfCentralDirectory(bytes) {
    const minOffset = Math.max(0, bytes.length - 22 - 65535);
    for (let offset = bytes.length - 22; offset >= minOffset; offset -= 1) {
      if (readUInt32LE(bytes, offset) === 0x06054b50) {
        const commentLength = readUInt16LE(bytes, offset + 20);
        if (offset + 22 + commentLength === bytes.length) {
          return {
            offset,
            diskEntries: readUInt16LE(bytes, offset + 8),
            totalEntries: readUInt16LE(bytes, offset + 10),
            centralDirectorySize: readUInt32LE(bytes, offset + 12),
            centralDirectoryOffset: readUInt32LE(bytes, offset + 16),
            commentLength
          };
        }
      }
    }
    return null;
  }

  function inspectZipContainer(bufferLike) {
    const bytes = asUint8Array(bufferLike);
    const eocd = findEndOfCentralDirectory(bytes);
    if (!eocd) {
      return Object.freeze({
        marker: APKG_INSPECTOR_MARKER,
        isZip: false,
        entryCount: 0,
        entries: [],
        warnings: ["ZIP end of central directory record not found"]
      });
    }

    const entries = [];
    let offset = eocd.centralDirectoryOffset;
    const end = eocd.centralDirectoryOffset + eocd.centralDirectorySize;

    while (offset + 46 <= bytes.length && offset < end) {
      const signature = readUInt32LE(bytes, offset);
      if (signature !== 0x02014b50) {
        break;
      }

      const flags = readUInt16LE(bytes, offset + 8);
      const compressionMethod = readUInt16LE(bytes, offset + 10);
      const crc32 = readUInt32LE(bytes, offset + 16).toString(16).padStart(8, "0");
      const compressedSize = readUInt32LE(bytes, offset + 20);
      const uncompressedSize = readUInt32LE(bytes, offset + 24);
      const nameLength = readUInt16LE(bytes, offset + 28);
      const extraLength = readUInt16LE(bytes, offset + 30);
      const commentLength = readUInt16LE(bytes, offset + 32);
      const localHeaderOffset = readUInt32LE(bytes, offset + 42);
      const name = decodeZipName(bytes, offset + 46, nameLength);

      entries.push(Object.freeze({
        name,
        compressionMethod,
        isDeflated: compressionMethod === 8,
        isStored: compressionMethod === 0,
        utf8Name: Boolean(flags & 0x0800),
        compressedSize,
        uncompressedSize,
        crc32,
        localHeaderOffset
      }));

      offset += 46 + nameLength + extraLength + commentLength;
    }

    return Object.freeze({
      marker: APKG_INSPECTOR_MARKER,
      isZip: true,
      entryCount: entries.length,
      eocd,
      entries,
      hasCollectionAnki2: entries.some((entry) => entry.name === "collection.anki2"),
      hasCollectionAnki21: entries.some((entry) => entry.name === "collection.anki21"),
      hasMediaJson: entries.some((entry) => entry.name === "media"),
      hasTopLevelMediaFiles: entries.some((entry) => /^[0-9]+$/.test(entry.name)),
      warnings: entries.length === eocd.totalEntries ? [] : ["central directory entry count mismatch"]
    });
  }

  function inspectApkgContainer(bufferLike, fileName) {
    const displayName = normalizeFilename(fileName || "package.apkg");
    if (!isSupportedFileName(displayName)) {
      throw new Error("APKG container inspector only accepts .apkg filenames.");
    }

    const inspected = inspectZipContainer(bufferLike);
    return Object.freeze(Object.assign({}, inspected, {
      fileName: displayName,
      isApkgContainer: inspected.isZip && (inspected.hasCollectionAnki2 || inspected.hasCollectionAnki21)
    }));
  }

  async function inspectApkgFile(fileLike) {
    if (!fileLike || typeof fileLike.arrayBuffer !== "function") {
      throw new Error("inspectApkgFile requires a browser File-like object with arrayBuffer().");
    }
    const source = describeFileSource(fileLike);
    const buffer = await fileLike.arrayBuffer();
    const container = inspectApkgContainer(buffer, source.displayName);
    return Object.freeze({
      marker: APKG_INSPECTOR_MARKER,
      source,
      container,
      disabledInspectorOnly: true,
      writesOriginalAnki: false,
      writesServer: false,
      writesLocalDocs: false
    });
  }

  function readApkgMetadataDisabled() {
    return Promise.reject(new Error("R11B is a disabled skeleton. Real apkg parsing is intentionally not active."));
  }

  const api = Object.freeze({
    marker: PATCH_MARKER,
    docKeys: DOC_KEYS,
    supportedExtensions: SUPPORTED_EXTENSIONS,
    isSupportedFileName,
    describeFileSource,
    validatePackageSummary,
    createImportPlan,
    apkgInspectorMarker: APKG_INSPECTOR_MARKER,
    inspectZipContainer,
    inspectApkgContainer,
    inspectApkgFile,
    readApkgMetadataDisabled
  });

  root.APC_ANKI_IMPORT_LOCAL = api;

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }
})(typeof globalThis !== "undefined" ? globalThis : window);
