# Stage 16 FC-O45-E-AU — Companion Immersion Deploy Readiness

Date: 2026-06-24

Repo checkpoint before this phase:

- Expected HEAD/origin/main: `5a1adb2`
- Prior tag: `controller-stage-16-fc-o45-e-at-companion-immersion-visible-panel-source-only-2026-06-24`

## Scope

This phase is read-only readiness plus repo docs/smoke/commit/tag/push.

Explicitly not allowed and not performed:

- NO DB write.
- NO job mutation.
- NO result insert.
- NO model/helper/Ollama call.
- NO model generation.
- NO scheduler activation.
- NO timer activation.
- NO persistent worker activation.
- NO backend/frontend deploy.
- NO public `/var/www` mutation.
- NO service restart/reload/start/stop/enable/disable.
- NO CT/VM restart.
- NO nginx/cloudflared/storage mutation.
- NO file deletion.

## Readiness result

The source now contains the Companion Immersion scaffold and visible-panel wiring.

Required source markers:

- `Stage 16 FC-O45-E-AS Companion Immersion Mode scaffold`
- `Stage 16 FC-O45-E-AT Companion Immersion visible panel source wiring`
- `COMPANION_IMMERSION_STATES`
- `window.apcCompanionImmersion`
- `window.apcCompanionImmersionRuntime`
- `apcCompanionImmersionObservedFetch`
- `#companionImmersionVisiblePanel`

The public site is still expected to show the previous non-Immersion app until a separate deploy phase.

## Next deploy gate

Do not deploy without explicit approval.

Suggested approval phrase:

```
APPROVE_FC_O45_E_AV_DEPLOY_COMPANION_IMMERSION_UI
```

AV should:

1. verify repo HEAD/origin remains pinned,
2. verify source syntax,
3. back up the current live public wrapper files,
4. copy only wrapper UI static files needed for the Immersion UI,
5. use a new cache-busted app.js URL,
6. verify public root HTTP 200,
7. verify public app.js HTTP 200,
8. verify public app.js contains both result-reader and Immersion markers,
9. verify public unauth result endpoints remain protected,
10. perform no DB/model/worker/scheduler mutation.

## Live readiness output

```
=== Stage 16 FC-O45-E-AU Companion Immersion deploy readiness ===
MUTATION_SCOPE=read_only_source_public_readiness_plus_repo_doc_smoke_commit_tag_push
NO DB write
NO job mutation
NO result insert
NO model/helper/Ollama call
NO model generation
NO scheduler activation
NO timer activation
NO persistent worker activation
NO backend/frontend deploy
NO public /var/www mutation
NO service restart/reload/start/stop/enable/disable
NO CT/VM restart
NO nginx/cloudflared/storage mutation
NO file deletion

=== git preflight ===
From https://github.com/Benalum/edge-queue-controller
 * branch            main       -> FETCH_HEAD
expected_head=5a1adb2
head_now=5a1adb2
origin_main_now=5a1adb2
git_preflight=PASS

=== source readiness markers ===
14065: * Stage 16 FC-O45-E-AS Companion Immersion Mode scaffold.
14204: * Stage 16 FC-O45-E-AT Companion Immersion visible panel source wiring.
14078:const COMPANION_IMMERSION_STATES = Object.freeze({
14087:  if (normalized === COMPANION_IMMERSION_STATES.THINKING) return "Thinking";
14088:  if (normalized === COMPANION_IMMERSION_STATES.SPEAKING) return "Speaking";
14089:  if (normalized === COMPANION_IMMERSION_STATES.NEEDS_ATTENTION) return "Needs attention";
14105:    return COMPANION_IMMERSION_STATES.NEEDS_ATTENTION;
14109:    return COMPANION_IMMERSION_STATES.SPEAKING;
14119:    return COMPANION_IMMERSION_STATES.THINKING;
14122:  return COMPANION_IMMERSION_STATES.LISTENING;
14192:  window.apcCompanionImmersion = Object.freeze({
14301:    const api = window.apcCompanionImmersion;
14393:    const api = window.apcCompanionImmersion;
14470:  window.apcCompanionImmersionRuntime = Object.freeze({
14470:  window.apcCompanionImmersionRuntime = Object.freeze({
14422:    window.fetch = async function apcCompanionImmersionObservedFetch(input, init = {}) {
2948:/* Stage 16 FC-O45-E-AS Companion Immersion Mode CSS scaffold. */
3001:/* Stage 16 FC-O45-E-AT Companion Immersion visible panel CSS wiring. */

=== source syntax check ===

=== current public static readiness, read-only ===
public_root_http=200
public_app_js_http=200
public_script_tags
<script src="router_shadow_read_stub.js?v=2026061208k"
<script src="/app.js?v=20260624fc045eader2"
<script src="/queued_chat_config.js"

=== current public markers, read-only ===
// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
              Messages continue through /api/chat/queued. The page polls the existing job status endpoint and displays the final assistant reply without changing backend behavior.
    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
    const res = await fetch("/api/chat/queued", {
    const response = await fetch("/api/chat/queued", {
    const response = await fetch(`/api/chat/queued/${encodeURIComponent(cleanJobId)}`, {
    if (!url || !String(url).includes("/api/chat/queued") || !response || !response.clone) return;
      '<p>Messages continue through <code>/api/chat/queued</code>. The page watches the same polling flow and displays queue state without changing backend behavior.</p>',
 * FC-O45-E-Q no-enqueue validation header and displays queue_write=false.
      const ok = response.ok && data.auth_validated === true && data.queue_write === false;
          ? "PASS: signed-in Companion auth validated; queue_write=false."
    lines.push("queue_write: " + String(data.queue_write));
    title.textContent = "Companion result reader";

=== readiness conclusion ===
deploy_readiness=PASS
next_approval_phrase=APPROVE_FC_O45_E_AV_DEPLOY_COMPANION_IMMERSION_UI
```
