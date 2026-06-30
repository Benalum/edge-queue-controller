/*
 * Dormant queued-chat frontend config.
 *
 * Stage 5F-30.
 *
 * This file exposes a disabled-by-default browser flag for future queued chat UI wiring.
 *
 * Safety:
 * - queued chat defaults off
 * - does not submit jobs
 * - does not call /api/chat/queued
 * - does not send user_id
 * - does not send X-Synthetic-User-Id
 * - does not call CT101 or Ollama directly
 */

(function attachQueuedChatConfig(root) {
  "use strict";

  const config = Object.freeze({
    stage: "5f30",
    source: "queued_chat_config_default_off",
    enabled: false,
    initialPollDelayMs: 2000,
    slowPollDelayMs: 5000,
    fastPollUntilMs: 30000,
    timeoutMs: 120000,
  });

  root.AI_PLATFORM_QUEUED_CHAT_CONFIG = config;
  root.AI_PLATFORM_QUEUED_CHAT_ENABLED = false;

  if (typeof module !== "undefined" && module.exports) {
    module.exports = config;
  }
})(typeof window !== "undefined" ? window : globalThis);
