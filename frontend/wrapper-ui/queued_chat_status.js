/*
 * Dormant queued-chat frontend status helper.
 *
 * Stage 5F-27.
 *
 * This file is intentionally not imported by index.html or app.js yet.
 * It defines frontend polling/status behavior for future queued chat UI wiring.
 *
 * Safety:
 * - no runtime behavior changes while unimported
 * - does not submit jobs
 * - does not send user_id
 * - does not send X-Synthetic-User-Id
 * - does not call CT101 or Ollama directly
 */

(function attachQueuedChatStatusHelper(root) {
  "use strict";

  const TERMINAL_STATUSES = new Set(["complete", "failed", "cancelled"]);
  const ACTIVE_STATUSES = new Set(["queued", "running", "claimed"]);

  function normalizeQueuedChatStatus(status) {
    return String(status || "").trim().toLowerCase() || "unknown";
  }

  function queuedChatShouldPoll(status) {
    const normalized = normalizeQueuedChatStatus(status);
    return ACTIVE_STATUSES.has(normalized);
  }

  function queuedChatIsTerminal(status) {
    const normalized = normalizeQueuedChatStatus(status);
    return TERMINAL_STATUSES.has(normalized);
  }

  function queuedChatPollDelayMs(elapsedMs) {
    const elapsed = Number(elapsedMs || 0);

    if (elapsed < 30_000) {
      return 2_000;
    }

    if (elapsed < 120_000) {
      return 5_000;
    }

    return null;
  }

  function queuedChatStatusLabel(status) {
    const normalized = normalizeQueuedChatStatus(status);

    if (normalized === "queued") {
      return "Queued";
    }

    if (normalized === "claimed" || normalized === "running") {
      return "Running";
    }

    if (normalized === "complete") {
      return "Complete";
    }

    if (normalized === "failed") {
      return "Failed";
    }

    if (normalized === "cancelled") {
      return "Cancelled";
    }

    return "Waiting";
  }

  function queuedChatAssistantPlaceholder(status) {
    const normalized = normalizeQueuedChatStatus(status);

    if (normalized === "failed") {
      return "The assistant response failed. You can try again.";
    }

    if (normalized === "complete") {
      return "";
    }

    if (normalized === "queued") {
      return "Queued. Waiting for the AI worker.";
    }

    if (normalized === "claimed" || normalized === "running") {
      return "The AI worker is generating a response.";
    }

    return "Waiting for queued response status.";
  }

  function queuedChatExtractAssistantReply(job) {
    if (!job || typeof job !== "object") {
      return "";
    }

    const result = job.result_json || job.result || {};

    return String(result.reply || result.response || result.content || "").trim();
  }

  function queuedChatCanRenderAssistant(job) {
    const status = normalizeQueuedChatStatus(job && job.status);
    return status === "complete" && queuedChatExtractAssistantReply(job).length > 0;
  }

  function queuedChatBuildStatusView(job, elapsedMs) {
    const status = normalizeQueuedChatStatus(job && job.status);
    const delayMs = queuedChatPollDelayMs(elapsedMs);

    return {
      status,
      label: queuedChatStatusLabel(status),
      shouldPoll: queuedChatShouldPoll(status) && delayMs !== null,
      delayMs,
      terminal: queuedChatIsTerminal(status),
      canRenderAssistant: queuedChatCanRenderAssistant(job),
      assistantReply: queuedChatExtractAssistantReply(job),
      placeholder: queuedChatAssistantPlaceholder(status),
    };
  }

  const api = {
    normalizeQueuedChatStatus,
    queuedChatShouldPoll,
    queuedChatIsTerminal,
    queuedChatPollDelayMs,
    queuedChatStatusLabel,
    queuedChatAssistantPlaceholder,
    queuedChatExtractAssistantReply,
    queuedChatCanRenderAssistant,
    queuedChatBuildStatusView,
  };

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }

  root.QueuedChatStatusHelper = api;
})(typeof window !== "undefined" ? window : globalThis);
