(function disabledSaveButtonHtmlPreviewRendererR14U(root) {
  "use strict";

  const MARKER = "APC_LOCAL_BACKUP_CURRENT_FILE_DISABLED_SAVE_BUTTON_HTML_PREVIEW_RENDERER_R14U_SOURCE_ONLY";
  const MODE = "source-only-disabled-save-button-html-preview-renderer";
  const RENDER_SPEC_GLOBAL = "APC_LOCAL_BACKUP_CURRENT_FILE_DISABLED_SAVE_BUTTON_RENDER_SPEC";
  const LABEL = "Save current backup";

  function escapeHtml(value) {
    return String(value == null ? "" : value)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;");
  }

  function getRenderSpecApi() {
    return root && root[RENDER_SPEC_GLOBAL] ? root[RENDER_SPEC_GLOBAL] : null;
  }

  function createFallbackSpec(reason) {
    return {
      marker: "",
      sourceOnly: true,
      deployed: false,
      uiLoaded: false,
      renderSpecOnly: true,
      domElementCreated: false,
      elementInserted: false,
      buttonElementCreated: false,
      buttonVisibleNow: false,
      buttonDisabledNow: true,
      renderAllowedNow: false,
      actionBoundToUi: false,
      clickHandlerAdded: false,
      clickHandlerCallsWriteExecutor: false,
      writeExecutorCalled: false,
      canWriteNow: false,
      writesEnabledNow: false,
      currentFileSaveEnabledNow: false,
      sameFileWriteEnabledNow: false,
      requiresLaterDeployStage: true,
      requiresLaterUiMountStage: true,
      tagName: "button",
      type: "button",
      textContent: LABEL,
      disabled: true,
      ariaLabel: LABEL + " disabled",
      ariaDisabled: "true",
      title: reason,
      attributes: {
        type: "button",
        disabled: "disabled",
        "aria-disabled": "true",
        "aria-label": LABEL + " disabled",
        "data-apc-local-backup-disabled-save-button-html-preview-r14u": "true",
        "data-apc-local-backup-disabled-save-button-source-only": "true"
      },
      classNames: [
        "apc-local-backup-disabled-save-button",
        "apc-local-backup-disabled-save-button-source-only"
      ],
      eventHandlers: {},
      helperText: [
        "Preview only.",
        "No file is saved, replaced, merged, restored, or overwritten.",
        "No DOM element is created by R14U.",
        "No click handler is attached by R14U."
      ],
      blockers: [reason],
      warnings: []
    };
  }

  function createRenderSpec(input, options) {
    const api = getRenderSpecApi();
    if (!api || typeof api.createDisabledSaveButtonRenderSpec !== "function") {
      return createFallbackSpec("Disabled save button render spec is not loaded.");
    }
    return api.createDisabledSaveButtonRenderSpec(input || {}, options || {});
  }

  function createDisabledSaveButtonHtmlPreview(input, options) {
    const spec = createRenderSpec(input, options);
    const attrs = Object.assign({}, spec.attributes || {}, {
      type: "button",
      disabled: "disabled",
      "aria-disabled": "true",
      "aria-label": spec.ariaLabel || LABEL + " disabled",
      "data-apc-local-backup-disabled-save-button-html-preview-r14u": "true",
      "data-apc-local-backup-disabled-save-button-source-only": "true"
    });

    const classNames = Array.isArray(spec.classNames) ? spec.classNames.slice() : [];
    if (!classNames.includes("apc-local-backup-disabled-save-button")) {
      classNames.push("apc-local-backup-disabled-save-button");
    }
    if (!classNames.includes("apc-local-backup-disabled-save-button-source-only")) {
      classNames.push("apc-local-backup-disabled-save-button-source-only");
    }
    attrs.class = classNames.join(" ");

    const attrText = Object.keys(attrs)
      .sort()
      .map(function renderAttribute(key) {
        return escapeHtml(key) + '="' + escapeHtml(attrs[key]) + '"';
      })
      .join(" ");

    const html = "<button " + attrText + ">" + escapeHtml(spec.textContent || LABEL) + "</button>";

    return {
      marker: MARKER,
      mode: MODE,
      sourceOnly: true,
      deployed: false,
      uiLoaded: false,
      htmlPreviewOnly: true,
      domElementCreated: false,
      elementInserted: false,
      buttonElementCreated: false,
      buttonVisibleNow: false,
      buttonDisabledNow: true,
      htmlStringCreated: true,
      renderAllowedNow: false,
      actionBoundToUi: false,
      clickHandlerAdded: false,
      clickHandlerCallsWriteExecutor: false,
      writeExecutorCalled: false,
      canWriteNow: false,
      writesEnabledNow: false,
      currentFileSaveEnabledNow: false,
      sameFileWriteEnabledNow: false,
      requiresLaterDeployStage: true,
      requiresLaterUiMountStage: true,
      html: html,
      textContent: spec.textContent || LABEL,
      attributes: attrs,
      renderSpec: spec
    };
  }

  function createDisabledSaveButtonHtmlPreviewText(preview) {
    const view = preview || createDisabledSaveButtonHtmlPreview({}, {});
    return [
      "Save current backup HTML preview",
      "Mode: source-only",
      "HTML string created: " + String(view.htmlStringCreated),
      "DOM element created: " + String(view.domElementCreated),
      "Element inserted: " + String(view.elementInserted),
      "Button visible now: " + String(view.buttonVisibleNow),
      "Button disabled now: " + String(view.buttonDisabledNow),
      "Click handler added: " + String(view.clickHandlerAdded),
      "Action bound to UI: " + String(view.actionBoundToUi),
      "Can write now: " + String(view.canWriteNow),
      "Writes enabled now: " + String(view.writesEnabledNow),
      "Write executor called: " + String(view.writeExecutorCalled),
      "",
      "Safety",
      "No DOM element is created by R14U.",
      "No button is inserted by R14U.",
      "No click handler is attached by R14U.",
      "No file is saved, replaced, merged, restored, or overwritten."
    ].join("\n");
  }

  const api = Object.freeze({
    MARKER: MARKER,
    MODE: MODE,
    createDisabledSaveButtonHtmlPreview: createDisabledSaveButtonHtmlPreview,
    createDisabledSaveButtonHtmlPreviewText: createDisabledSaveButtonHtmlPreviewText
  });

  root.APC_LOCAL_BACKUP_CURRENT_FILE_DISABLED_SAVE_BUTTON_HTML_PREVIEW_RENDERER = api;

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }
})(typeof window !== "undefined" ? window : globalThis);
