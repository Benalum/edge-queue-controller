# Stage 5P-8H Companion Canonical Renderer

Replaces the old Companion queued-chat renderer with the polished Companion layout directly.

This is a cleanup/consolidation stage:

- The old Companion page is no longer the primary render output.
- The polished layout is rendered directly by `renderQueuedChatPage`.
- Existing queue behavior is preserved.
- Existing DOM ids used by the queue submit/poll logic are preserved:
  - queuedChatForm
  - queuedChatInput
  - queuedChatSendBtn
  - queuedChatClearBtn
  - queuedChatStatus
  - queuedChatMessages
- Stage 5O-35 enhancer now stands down when the canonical renderer is present.

No backend routes are changed.
