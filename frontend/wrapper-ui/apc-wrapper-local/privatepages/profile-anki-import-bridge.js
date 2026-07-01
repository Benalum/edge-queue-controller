(function attachApcProfileAnkiImportBridge(root) {
  "use strict";

  const PATCH_MARKER = "APC_PROFILE_ANKI_IMPORT_BRIDGE_R11E";

  function safeString(value) {
    return value == null ? "" : String(value);
  }

  function getImporter(explicitApi) {
    const api = explicitApi || root.APC_ANKI_IMPORT_LOCAL;
    if (!api || typeof api.inspectApkgFile !== "function") {
      throw new Error("Profile Anki import bridge requires APC_ANKI_IMPORT_LOCAL.inspectApkgFile.");
    }
    return api;
  }

  function summarizeEntries(entries) {
    return (Array.isArray(entries) ? entries : []).map((entry) => ({
      name: safeString(entry.name),
      compressionMethod: Number(entry.compressionMethod),
      compressedSize: Number(entry.compressedSize),
      uncompressedSize: Number(entry.uncompressedSize),
      isStored: Boolean(entry.isStored),
      isDeflated: Boolean(entry.isDeflated)
    }));
  }

  function buildPreviewFromInspection(inspection) {
    const source = inspection && inspection.source ? inspection.source : {};
    const container = inspection && inspection.container ? inspection.container : {};
    const entries = summarizeEntries(container.entries);
    const collectionEntry = entries.find((entry) => entry.name === "collection.anki2" || entry.name === "collection.anki21") || null;
    const mediaManifestEntry = entries.find((entry) => entry.name === "media") || null;
    const numericMediaEntries = entries.filter((entry) => /^[0-9]+$/.test(entry.name));

    return Object.freeze({
      marker: PATCH_MARKER,
      sourceSurface: "profile",
      mode: "apkg-preview-only",
      disabledPreviewOnly: true,
      writesOriginalAnki: false,
      writesServer: false,
      writesLocalDocs: false,
      file: Object.freeze({
        name: safeString(source.displayName),
        sizeBytes: Number(source.sizeBytes || 0),
        lastModified: Number(source.lastModified || 0),
        kind: safeString(source.kind)
      }),
      package: Object.freeze({
        isZip: Boolean(container.isZip),
        isApkgContainer: Boolean(container.isApkgContainer),
        hasCollectionAnki2: Boolean(container.hasCollectionAnki2),
        hasCollectionAnki21: Boolean(container.hasCollectionAnki21),
        hasMediaJson: Boolean(container.hasMediaJson),
        hasTopLevelMediaFiles: Boolean(container.hasTopLevelMediaFiles),
        entryCount: Number(container.entryCount || 0),
        collectionEntry,
        mediaManifestEntry,
        numericMediaEntryCount: numericMediaEntries.length
      }),
      warnings: Object.freeze((Array.isArray(container.warnings) ? container.warnings : []).map(safeString)),
      entries: Object.freeze(entries)
    });
  }

  async function createProfileAnkiPreview(input) {
    const args = input || {};
    const file = args.file || args.fileLike;
    if (!file || typeof file.arrayBuffer !== "function") {
      throw new Error("Profile Anki preview requires a browser File-like object with arrayBuffer().");
    }

    const importer = getImporter(args.importer || args.api);
    const inspection = await importer.inspectApkgFile(file);
    return buildPreviewFromInspection(inspection);
  }

  const api = Object.freeze({
    marker: PATCH_MARKER,
    createProfileAnkiPreview,
    buildPreviewFromInspection
  });

  root.APC_PROFILE_ANKI_IMPORT_BRIDGE = api;

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }
})(typeof globalThis !== "undefined" ? globalThis : window);
