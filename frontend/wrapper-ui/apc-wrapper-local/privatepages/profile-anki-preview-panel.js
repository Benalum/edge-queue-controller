(function attachApcProfileAnkiPreviewPanel(root) {
  "use strict";

  const PATCH_MARKER = "APC_PROFILE_ANKI_PREVIEW_PANEL_R11F";

  function safeString(value) {
    return value == null ? "" : String(value);
  }

  function escapeHtml(value) {
    return safeString(value)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;");
  }

  function getBridge(explicitBridge) {
    const bridge = explicitBridge || root.APC_PROFILE_ANKI_IMPORT_BRIDGE;
    if (!bridge || typeof bridge.createProfileAnkiPreview !== "function") {
      throw new Error("Profile Anki preview panel requires APC_PROFILE_ANKI_IMPORT_BRIDGE.createProfileAnkiPreview.");
    }
    return bridge;
  }

  function normalizePreview(preview) {
    const value = preview || {};
    const file = value.file || {};
    const pkg = value.package || {};
    return Object.freeze({
      marker: PATCH_MARKER,
      sourceSurface: safeString(value.sourceSurface || "profile"),
      mode: safeString(value.mode || "apkg-preview-only"),
      disabledPreviewOnly: value.disabledPreviewOnly !== false,
      writesOriginalAnki: false,
      writesServer: false,
      writesLocalDocs: false,
      file: Object.freeze({
        name: safeString(file.name),
        sizeBytes: Number(file.sizeBytes || 0),
        lastModified: Number(file.lastModified || 0),
        kind: safeString(file.kind)
      }),
      package: Object.freeze({
        isZip: Boolean(pkg.isZip),
        isApkgContainer: Boolean(pkg.isApkgContainer),
        hasCollectionAnki2: Boolean(pkg.hasCollectionAnki2),
        hasCollectionAnki21: Boolean(pkg.hasCollectionAnki21),
        hasMediaJson: Boolean(pkg.hasMediaJson),
        hasTopLevelMediaFiles: Boolean(pkg.hasTopLevelMediaFiles),
        entryCount: Number(pkg.entryCount || 0),
        numericMediaEntryCount: Number(pkg.numericMediaEntryCount || 0)
      }),
      warnings: Object.freeze((Array.isArray(value.warnings) ? value.warnings : []).map(safeString)),
      entries: Object.freeze((Array.isArray(value.entries) ? value.entries : []).map((entry) => Object.freeze({
        name: safeString(entry.name),
        compressionMethod: Number(entry.compressionMethod || 0),
        compressedSize: Number(entry.compressedSize || 0),
        uncompressedSize: Number(entry.uncompressedSize || 0),
        isStored: Boolean(entry.isStored),
        isDeflated: Boolean(entry.isDeflated)
      })))
    });
  }

  async function createPreviewModel(input) {
    const args = input || {};
    const file = args.file || args.fileLike;
    if (!file || typeof file.arrayBuffer !== "function") {
      throw new Error("Profile Anki preview panel requires a browser File-like object with arrayBuffer().");
    }
    const bridge = getBridge(args.bridge);
    const preview = await bridge.createProfileAnkiPreview({
      file,
      api: args.importer || args.api || root.APC_ANKI_IMPORT_LOCAL
    });
    return normalizePreview(preview);
  }

  function yesNo(value) {
    return value ? "yes" : "no";
  }

  function renderPreviewHtml(previewLike) {
    const preview = normalizePreview(previewLike);
    const warnings = preview.warnings.length
      ? preview.warnings.map((warning) => `<li>${escapeHtml(warning)}</li>`).join("")
      : "<li>none</li>";
    const entries = preview.entries.length
      ? preview.entries.slice(0, 20).map((entry) => `<li>${escapeHtml(entry.name)} — ${entry.uncompressedSize} bytes</li>`).join("")
      : "<li>none detected</li>";

    return [
      '<section class="apc-profile-anki-preview-result" data-apc-profile-anki-preview-result="true">',
      '<h4>Anki package preview</h4>',
      `<p><strong>File:</strong> ${escapeHtml(preview.file.name)} (${preview.file.sizeBytes} bytes)</p>`,
      '<dl>',
      `<dt>APKG container</dt><dd>${escapeHtml(yesNo(preview.package.isApkgContainer))}</dd>`,
      `<dt>collection.anki2</dt><dd>${escapeHtml(yesNo(preview.package.hasCollectionAnki2))}</dd>`,
      `<dt>collection.anki21</dt><dd>${escapeHtml(yesNo(preview.package.hasCollectionAnki21))}</dd>`,
      `<dt>media manifest</dt><dd>${escapeHtml(yesNo(preview.package.hasMediaJson))}</dd>`,
      `<dt>numeric media entries</dt><dd>${preview.package.numericMediaEntryCount}</dd>`,
      `<dt>total ZIP entries</dt><dd>${preview.package.entryCount}</dd>`,
      '</dl>',
      '<p><strong>Privacy:</strong> Preview only. Nothing is uploaded, saved, or written back to Anki.</p>',
      '<h5>Warnings</h5>',
      `<ul>${warnings}</ul>`,
      '<h5>Entries</h5>',
      `<ul>${entries}</ul>`,
      '</section>'
    ].join("");
  }

  function renderPanel(targetNode, options) {
    if (!targetNode || typeof targetNode.appendChild !== "function") {
      throw new Error("renderPanel requires a DOM node target.");
    }
    if (!root.document || typeof root.document.createElement !== "function") {
      throw new Error("renderPanel requires a browser document.");
    }

    const opts = options || {};
    const documentRef = root.document;
    const wrapper = documentRef.createElement("section");
    wrapper.className = "apc-profile-anki-preview-panel";
    wrapper.setAttribute("data-apc-profile-anki-preview-panel", "true");
    wrapper.innerHTML = [
      '<h3>Anki package preview</h3>',
      '<p>Select an .apkg file to inspect it locally before importing. This preview does not upload or save anything.</p>',
      '<input type="file" accept=".apkg" data-apc-profile-anki-file="true" />',
      '<button type="button" data-apc-profile-anki-preview-button="true">Preview locally</button>',
      '<div data-apc-profile-anki-preview-status="true">No file selected.</div>',
      '<div data-apc-profile-anki-preview-output="true"></div>'
    ].join("");

    const input = wrapper.querySelector("[data-apc-profile-anki-file]");
    const button = wrapper.querySelector("[data-apc-profile-anki-preview-button]");
    const status = wrapper.querySelector("[data-apc-profile-anki-preview-status]");
    const output = wrapper.querySelector("[data-apc-profile-anki-preview-output]");

    async function runPreview() {
      const file = input && input.files && input.files[0];
      if (!file) {
        status.textContent = "Choose an .apkg file first.";
        output.innerHTML = "";
        return;
      }
      status.textContent = "Inspecting locally...";
      output.innerHTML = "";
      try {
        const preview = await createPreviewModel({
          file,
          bridge: opts.bridge,
          importer: opts.importer
        });
        output.innerHTML = renderPreviewHtml(preview);
        status.textContent = preview.package.isApkgContainer
          ? "Preview ready. This looks like an Anki package."
          : "Preview ready. This does not look like a supported Anki package.";
      } catch (error) {
        status.textContent = "Preview failed.";
        output.innerHTML = `<p role="alert">${escapeHtml(error && error.message ? error.message : error)}</p>`;
      }
    }

    button.addEventListener("click", runPreview);
    targetNode.appendChild(wrapper);
    return Object.freeze({
      marker: PATCH_MARKER,
      node: wrapper,
      runPreview
    });
  }

  const api = Object.freeze({
    marker: PATCH_MARKER,
    createPreviewModel,
    renderPreviewHtml,
    renderPanel
  });

  root.APC_PROFILE_ANKI_PREVIEW_PANEL = api;

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }
})(typeof globalThis !== "undefined" ? globalThis : window);
