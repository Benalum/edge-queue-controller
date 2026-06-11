#!/usr/bin/env bash

stage5o35_main() {
  cd "$HOME/Desktop/edge-queue-controller" || return 1

  echo "=== Stage 5O-35 checkpoint before changes ==="
  git status --short
  git rev-parse --short HEAD
  git tag --points-at HEAD || true

  echo
  echo "=== Inspect Companion / queued chat function markers ==="
  python3 - <<'PY'
from pathlib import Path
import re

p = Path("frontend/wrapper-ui/app.js")
s = p.read_text()

patterns = [
    r"function\s+([A-Za-z0-9_$]*(?:Companion|companion|Queued|queued|Chat|chat)[A-Za-z0-9_$]*)\s*\(",
    r"(?:const|let|var)\s+([A-Za-z0-9_$]*(?:Companion|companion|Queued|queued|Chat|chat)[A-Za-z0-9_$]*)\s*=\s*(?:async\s*)?(?:\([^)]*\)|[A-Za-z0-9_$]+)\s*=>",
    r"(?:async\s+)?([A-Za-z0-9_$]*(?:Companion|companion|Queued|queued|Chat|chat)[A-Za-z0-9_$]*)\s*\([^)]*\)\s*\{",
]

found = []
for rx in patterns:
    for m in re.finditer(rx, s):
        line = s.count("\n", 0, m.start()) + 1
        name = m.group(1)
        if (line, name) not in found:
            found.append((line, name))

for line, name in sorted(found):
    print(f"{line}: {name}")

print()
print("=== /api/chat/queued references ===")
for i, line in enumerate(s.splitlines(), 1):
    if "/api/chat/queued" in line or "queued/" in line.lower() or "poll" in line.lower():
        print(f"{i}: {line[:180]}")
PY

  echo
  echo "=== Create backups ==="
  stamp="$(date +%F-%H%M%S)"
  cp -a frontend/wrapper-ui/app.js "frontend/wrapper-ui/app.js.bak-stage-5o35-$stamp"
  cp -a frontend/wrapper-ui/styles.css "frontend/wrapper-ui/styles.css.bak-stage-5o35-$stamp"
  cp -a frontend/wrapper-ui/index.html "frontend/wrapper-ui/index.html.bak-stage-5o35-$stamp"

  echo
  echo "=== Apply frontend-only Companion enhancer and styles ==="
  python3 - <<'PY'
from pathlib import Path
import datetime
import re

app_path = Path("frontend/wrapper-ui/app.js")
css_path = Path("frontend/wrapper-ui/styles.css")
html_path = Path("frontend/wrapper-ui/index.html")

APP_START = "// STAGE_5O35_COMPANION_UX_BEGIN"
APP_END = "// STAGE_5O35_COMPANION_UX_END"
CSS_START = "/* STAGE_5O35_COMPANION_UX_BEGIN */"
CSS_END = "/* STAGE_5O35_COMPANION_UX_END */"

app_block = r'''// STAGE_5O35_COMPANION_UX_BEGIN
(function () {
  const stageClass = "stage5o35";
  const snapshotKey = "stage5o35CompanionQueueSnapshot";
  let stageScheduled = false;

  function stageRouteLooksCompanion() {
    const path = String(window.location.pathname || "").replace(/\/+$/, "");
    const hash = String(window.location.hash || "").toLowerCase();
    return path === "/companion" || path.endsWith("/companion") || hash.includes("companion");
  }

  function stageFindRoot() {
    return document.querySelector("#app")
      || document.querySelector("#root")
      || document.querySelector("main")
      || document.querySelector(".app-main")
      || document.querySelector(".page-root");
  }

  function stageNodeMentionsCompanion(root) {
    if (!root) return false;
    const text = String(root.innerText || "");
    if (/companion|queued chat|message|assistant|worker|model/i.test(text)) return true;
    return Array.from(root.querySelectorAll("[id], [class], [data-page], [data-route]")).some(function (el) {
      const blob = [
        el.id || "",
        el.className || "",
        el.getAttribute("data-page") || "",
        el.getAttribute("data-route") || ""
      ].join(" ");
      return /companion|queued|chat/i.test(blob);
    });
  }

  function stageHasInteractiveCompanion(root) {
    if (!root) return false;
    const hasMessageControl = !!root.querySelector("textarea, input[type='text'], input:not([type]), form");
    const hasButton = Array.from(root.querySelectorAll("button, input[type='submit']")).some(function (btn) {
      return /send|submit|message|chat|start|retry/i.test(String(btn.textContent || btn.value || ""));
    });
    return stageNodeMentionsCompanion(root) && (hasMessageControl || hasButton);
  }

  function stageReadSnapshot() {
    try {
      return JSON.parse(window.localStorage.getItem(snapshotKey) || "{}") || {};
    } catch (err) {
      return {};
    }
  }

  function stageWriteSnapshot(next) {
    const previous = stageReadSnapshot();
    const merged = Object.assign({}, previous, next, {
      updatedAt: new Date().toLocaleString()
    });
    try {
      window.localStorage.setItem(snapshotKey, JSON.stringify(merged));
    } catch (err) {
      /* storage may be unavailable */
    }
    stageUpdateCards();
  }

  function stagePickValue(data, keys) {
    if (!data || typeof data !== "object") return "";
    for (const key of keys) {
      if (data[key] !== undefined && data[key] !== null && String(data[key]).trim() !== "") {
        return String(data[key]);
      }
    }
    for (const value of Object.values(data)) {
      if (value && typeof value === "object") {
        const nested = stagePickValue(value, keys);
        if (nested) return nested;
      }
    }
    return "";
  }

  function stageCaptureQueueResponse(url, response) {
    if (!url || !String(url).includes("/api/chat/queued") || !response || !response.clone) return;
    response.clone().json().then(function (data) {
      const jobId = stagePickValue(data, ["job_id", "jobId", "id"]);
      const status = stagePickValue(data, ["status", "state", "job_status", "jobStatus"]);
      const model = stagePickValue(data, ["model", "current_model", "worker_model", "model_name"]);
      const worker = stagePickValue(data, ["worker", "worker_id", "worker_name"]);
      stageWriteSnapshot({
        lastJobId: jobId || stageReadSnapshot().lastJobId || "",
        status: status || stageReadSnapshot().status || "updated",
        model: model || stageReadSnapshot().model || "",
        worker: worker || stageReadSnapshot().worker || ""
      });
    }).catch(function () {
      stageWriteSnapshot({
        status: stageReadSnapshot().status || "waiting for response"
      });
    });
  }

  function stageInstallFetchObserver() {
    if (window.__stage5o35CompanionFetchObserver || typeof window.fetch !== "function") return;
    const nativeFetch = window.fetch.bind(window);
    window.fetch = function (input, init) {
      const url = typeof input === "string" ? input : (input && input.url ? input.url : "");
      return nativeFetch(input, init).then(function (response) {
        stageCaptureQueueResponse(url, response);
        return response;
      });
    };
    window.__stage5o35CompanionFetchObserver = true;
  }

  function stageField(name) {
    const shell = document.querySelector(".stage5o35-companion-shell");
    return shell ? shell.querySelector("[data-stage5o35-field='" + name + "']") : null;
  }

  function stageFindStatusFromText() {
    const shell = document.querySelector(".stage5o35-companion-shell");
    const text = shell ? String(shell.innerText || "") : "";
    const statusMatch = text.match(/\b(queued|pending|running|processing|complete|completed|done|failed|error|cancelled)\b/i);
    return statusMatch ? statusMatch[1].toLowerCase() : "";
  }

  function stageFindModelFromText() {
    const shell = document.querySelector(".stage5o35-companion-shell");
    const text = shell ? String(shell.innerText || "") : "";
    const modelMatch = text.match(/\bmodel\s*[:\-]\s*([^\n\r]+)/i);
    return modelMatch ? modelMatch[1].trim().slice(0, 80) : "";
  }

  function stageFindJobFromText() {
    const shell = document.querySelector(".stage5o35-companion-shell");
    const text = shell ? String(shell.innerText || "") : "";
    const jobMatch = text.match(/\b(?:job[_\s-]*id|job)\s*[:#\-]?\s*([A-Za-z0-9_-]{8,})/i);
    return jobMatch ? jobMatch[1] : "";
  }

  function stageSetField(name, value) {
    const el = stageField(name);
    if (el) el.textContent = value || "—";
  }

  function stageUpdateCards() {
    const shell = document.querySelector(".stage5o35-companion-shell");
    if (!shell) return;

    const snapshot = stageReadSnapshot();
    const status = snapshot.status || stageFindStatusFromText() || "ready";
    const model = snapshot.model || stageFindModelFromText() || "backend default";
    const jobId = snapshot.lastJobId || stageFindJobFromText() || "";
    const worker = snapshot.worker || "local worker pool";
    const updatedAt = snapshot.updatedAt || "not started this session";

    stageSetField("queueStatus", status);
    stageSetField("model", model);
    stageSetField("jobId", jobId ? jobId : "no recent job");
    stageSetField("worker", worker);
    stageSetField("updatedAt", updatedAt);

    shell.dataset.queueStatus = String(status).toLowerCase();

    const empty = shell.querySelector(".stage5o35-empty-state");
    if (empty) {
      const hasMessages = !!shell.querySelector(".message, .chat-message, .assistant-message, .user-message, [data-role='assistant'], [data-role='user']")
        || /\bassistant\s*·|\buser\s*·/i.test(String(shell.innerText || ""));
      empty.hidden = hasMessages;
    }
  }

  function stageUpgradeControls(shell) {
    shell.querySelectorAll("textarea, input[type='text'], input:not([type])").forEach(function (input) {
      input.classList.add("stage5o35-message-input");
      if (!input.getAttribute("placeholder")) {
        input.setAttribute("placeholder", "Message Companion...");
      }
    });

    shell.querySelectorAll("button, input[type='submit']").forEach(function (button) {
      const label = String(button.textContent || button.value || "");
      if (/send|submit|message|chat/i.test(label)) {
        button.classList.add("stage5o35-send-button");
      }
    });

    shell.querySelectorAll(".message, .chat-message, [data-role='assistant'], [data-role='user']").forEach(function (msg) {
      const role = String(msg.getAttribute("data-role") || msg.className || msg.textContent || "").toLowerCase();
      msg.classList.add("stage5o35-message-bubble");
      if (role.includes("user")) msg.classList.add("stage5o35-user-bubble");
      if (role.includes("assistant")) msg.classList.add("stage5o35-assistant-bubble");
    });
  }

  function stageEnhanceCompanion() {
    if (!stageRouteLooksCompanion()) return;

    const root = stageFindRoot();
    if (!stageHasInteractiveCompanion(root)) return;

    const existingShell = root.querySelector(".stage5o35-companion-shell");
    if (existingShell) {
      stageUpgradeControls(existingShell);
      stageUpdateCards();
      return;
    }

    const originalChildren = Array.from(root.children).filter(function (child) {
      return !child.classList.contains("stage5o35-companion-shell");
    });
    if (!originalChildren.length) return;

    const shell = document.createElement("section");
    shell.className = "stage5o35-companion-shell";
    shell.setAttribute("aria-label", "Companion workspace");

    const hero = document.createElement("div");
    hero.className = "stage5o35-companion-hero";
    hero.innerHTML = [
      '<div class="stage5o35-companion-hero-copy">',
      '<p class="stage5o35-eyebrow">Companion</p>',
      '<h1>Supportive chat workspace</h1>',
      '<p>Talk with your local Companion while the queue handles work safely behind the scenes.</p>',
      '</div>',
      '<div class="stage5o35-companion-hero-badge">Queue-aware UI</div>'
    ].join("");

    const grid = document.createElement("div");
    grid.className = "stage5o35-companion-grid";

    const main = document.createElement("div");
    main.className = "stage5o35-companion-main";

    const conversation = document.createElement("div");
    conversation.className = "stage5o35-conversation-card";

    const empty = document.createElement("div");
    empty.className = "stage5o35-empty-state";
    empty.innerHTML = [
      '<div class="stage5o35-empty-icon">💬</div>',
      '<div>',
      '<h2>Start a Companion conversation</h2>',
      '<p>Send a message below. New work still uses the existing queued chat endpoint and polling flow.</p>',
      '</div>'
    ].join("");

    const legacy = document.createElement("div");
    legacy.className = "stage5o35-existing-companion-ui";
    originalChildren.forEach(function (child) {
      legacy.appendChild(child);
    });

    conversation.appendChild(empty);
    conversation.appendChild(legacy);
    main.appendChild(conversation);

    const aside = document.createElement("aside");
    aside.className = "stage5o35-companion-aside";
    aside.innerHTML = [
      '<section class="stage5o35-status-card">',
      '<div class="stage5o35-card-title-row"><h2>Companion status</h2><span class="stage5o35-live-dot"></span></div>',
      '<dl>',
      '<div><dt>Queue</dt><dd data-stage5o35-field="queueStatus">ready</dd></div>',
      '<div><dt>Worker</dt><dd data-stage5o35-field="worker">local worker pool</dd></div>',
      '<div><dt>Model</dt><dd data-stage5o35-field="model">backend default</dd></div>',
      '</dl>',
      '</section>',
      '<section class="stage5o35-status-card">',
      '<h2>Last job</h2>',
      '<dl>',
      '<div><dt>Job id</dt><dd data-stage5o35-field="jobId">no recent job</dd></div>',
      '<div><dt>Updated</dt><dd data-stage5o35-field="updatedAt">not started this session</dd></div>',
      '</dl>',
      '</section>',
      '<section class="stage5o35-status-card stage5o35-how-card">',
      '<h2>How this works</h2>',
      '<p>Messages continue through <code>/api/chat/queued</code>. The page watches the same polling flow and displays queue state without changing backend behavior.</p>',
      '</section>',
      '<section class="stage5o35-status-card stage5o35-toggle-card">',
      '<div>',
      '<h2>Study context</h2>',
      '<p>Future toggle placeholder. No Study data is connected here yet.</p>',
      '</div>',
      '<button type="button" class="stage5o35-toggle" disabled aria-disabled="true">Coming next</button>',
      '</section>'
    ].join("");

    grid.appendChild(main);
    grid.appendChild(aside);
    shell.appendChild(hero);
    shell.appendChild(grid);
    root.appendChild(shell);

    stageUpgradeControls(shell);
    stageUpdateCards();
  }

  function stageSchedule() {
    if (stageScheduled) return;
    stageScheduled = true;
    window.setTimeout(function () {
      stageScheduled = false;
      stageInstallFetchObserver();
      stageEnhanceCompanion();
    }, 60);
  }

  document.addEventListener("DOMContentLoaded", stageSchedule);
  window.addEventListener("hashchange", stageSchedule);
  window.addEventListener("popstate", stageSchedule);
  document.addEventListener("click", function (event) {
    const link = event.target && event.target.closest ? event.target.closest("a[href]") : null;
    if (link && String(link.getAttribute("href") || "").includes("companion")) {
      window.setTimeout(stageSchedule, 100);
    }
  });

  const observer = new MutationObserver(stageSchedule);
  observer.observe(document.documentElement, { childList: true, subtree: true });

  stageSchedule();
})();
// STAGE_5O35_COMPANION_UX_END
'''

css_block = r'''/* STAGE_5O35_COMPANION_UX_BEGIN */
.stage5o35-companion-shell {
  width: min(1180px, calc(100% - 32px));
  margin: 0 auto;
  padding: 28px 0 42px;
}

.stage5o35-companion-hero {
  display: flex;
  justify-content: space-between;
  gap: 18px;
  align-items: flex-start;
  margin-bottom: 20px;
  padding: 28px;
  border: 1px solid rgba(148, 163, 184, 0.24);
  border-radius: 28px;
  background:
    radial-gradient(circle at top left, rgba(99, 102, 241, 0.18), transparent 34%),
    linear-gradient(135deg, rgba(15, 23, 42, 0.96), rgba(30, 41, 59, 0.92));
  box-shadow: 0 22px 60px rgba(15, 23, 42, 0.22);
  color: #f8fafc;
}

.stage5o35-companion-hero h1 {
  margin: 4px 0 8px;
  font-size: clamp(2rem, 4vw, 3.4rem);
  line-height: 1.02;
  letter-spacing: -0.045em;
}

.stage5o35-companion-hero p {
  margin: 0;
  max-width: 720px;
  color: rgba(226, 232, 240, 0.86);
  font-size: 1rem;
}

.stage5o35-eyebrow {
  margin: 0;
  color: #c4b5fd !important;
  font-weight: 800;
  letter-spacing: 0.14em;
  text-transform: uppercase;
  font-size: 0.78rem !important;
}

.stage5o35-companion-hero-badge {
  flex: 0 0 auto;
  display: inline-flex;
  align-items: center;
  border-radius: 999px;
  padding: 9px 14px;
  border: 1px solid rgba(196, 181, 253, 0.34);
  background: rgba(255, 255, 255, 0.1);
  color: #ede9fe;
  font-weight: 800;
  white-space: nowrap;
}

.stage5o35-companion-grid {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 340px;
  gap: 20px;
  align-items: start;
}

.stage5o35-conversation-card,
.stage5o35-status-card {
  border: 1px solid rgba(148, 163, 184, 0.22);
  border-radius: 24px;
  background: rgba(255, 255, 255, 0.9);
  box-shadow: 0 16px 42px rgba(15, 23, 42, 0.1);
}

.stage5o35-conversation-card {
  min-height: 560px;
  padding: 18px;
  overflow: hidden;
}

.stage5o35-empty-state {
  display: flex;
  gap: 16px;
  align-items: center;
  margin-bottom: 16px;
  padding: 18px;
  border: 1px dashed rgba(99, 102, 241, 0.28);
  border-radius: 20px;
  background: linear-gradient(135deg, rgba(99, 102, 241, 0.08), rgba(14, 165, 233, 0.06));
}

.stage5o35-empty-state[hidden] {
  display: none !important;
}

.stage5o35-empty-icon {
  display: grid;
  place-items: center;
  width: 52px;
  height: 52px;
  border-radius: 18px;
  background: rgba(99, 102, 241, 0.12);
  font-size: 1.6rem;
}

.stage5o35-empty-state h2 {
  margin: 0 0 4px;
  font-size: 1.08rem;
}

.stage5o35-empty-state p {
  margin: 0;
  color: #64748b;
}

.stage5o35-existing-companion-ui {
  display: grid;
  gap: 14px;
}

.stage5o35-existing-companion-ui form,
.stage5o35-existing-companion-ui .form,
.stage5o35-existing-companion-ui [class*="input"],
.stage5o35-existing-companion-ui [class*="composer"] {
  border-radius: 18px;
}

.stage5o35-message-input {
  width: 100%;
  min-height: 48px;
  border: 1px solid rgba(148, 163, 184, 0.34) !important;
  border-radius: 18px !important;
  padding: 13px 14px !important;
  background: rgba(248, 250, 252, 0.96) !important;
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.74);
}

.stage5o35-message-input:focus {
  border-color: rgba(99, 102, 241, 0.7) !important;
  box-shadow: 0 0 0 4px rgba(99, 102, 241, 0.14) !important;
  outline: none !important;
}

.stage5o35-send-button {
  border: 0 !important;
  border-radius: 999px !important;
  padding: 12px 18px !important;
  background: linear-gradient(135deg, #4f46e5, #0ea5e9) !important;
  color: #ffffff !important;
  font-weight: 800 !important;
  box-shadow: 0 12px 26px rgba(79, 70, 229, 0.24) !important;
}

.stage5o35-send-button:disabled {
  cursor: wait !important;
  opacity: 0.68 !important;
  box-shadow: none !important;
}

.stage5o35-message-bubble,
.stage5o35-existing-companion-ui .message,
.stage5o35-existing-companion-ui .chat-message,
.stage5o35-existing-companion-ui [data-role="assistant"],
.stage5o35-existing-companion-ui [data-role="user"] {
  max-width: min(760px, 92%);
  margin: 10px 0;
  padding: 13px 15px;
  border-radius: 18px;
  line-height: 1.5;
}

.stage5o35-user-bubble,
.stage5o35-existing-companion-ui [data-role="user"],
.stage5o35-existing-companion-ui .user-message {
  margin-left: auto;
  background: linear-gradient(135deg, #4f46e5, #2563eb);
  color: #ffffff;
  border-bottom-right-radius: 7px;
}

.stage5o35-assistant-bubble,
.stage5o35-existing-companion-ui [data-role="assistant"],
.stage5o35-existing-companion-ui .assistant-message {
  margin-right: auto;
  background: #f1f5f9;
  color: #0f172a;
  border-bottom-left-radius: 7px;
}

.stage5o35-companion-aside {
  display: grid;
  gap: 16px;
  position: sticky;
  top: 18px;
}

.stage5o35-status-card {
  padding: 18px;
}

.stage5o35-card-title-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
}

.stage5o35-status-card h2 {
  margin: 0 0 12px;
  color: #0f172a;
  font-size: 1rem;
  letter-spacing: -0.01em;
}

.stage5o35-status-card dl {
  display: grid;
  gap: 12px;
  margin: 0;
}

.stage5o35-status-card dl > div {
  display: grid;
  gap: 3px;
  padding: 12px;
  border-radius: 16px;
  background: #f8fafc;
  border: 1px solid rgba(226, 232, 240, 0.92);
}

.stage5o35-status-card dt {
  color: #64748b;
  font-size: 0.78rem;
  font-weight: 800;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.stage5o35-status-card dd {
  margin: 0;
  color: #0f172a;
  font-weight: 800;
  overflow-wrap: anywhere;
}

.stage5o35-live-dot {
  width: 11px;
  height: 11px;
  border-radius: 999px;
  background: #22c55e;
  box-shadow: 0 0 0 6px rgba(34, 197, 94, 0.14);
}

.stage5o35-companion-shell[data-queue-status*="fail"] .stage5o35-live-dot,
.stage5o35-companion-shell[data-queue-status*="error"] .stage5o35-live-dot {
  background: #ef4444;
  box-shadow: 0 0 0 6px rgba(239, 68, 68, 0.14);
}

.stage5o35-companion-shell[data-queue-status*="queued"] .stage5o35-live-dot,
.stage5o35-companion-shell[data-queue-status*="running"] .stage5o35-live-dot,
.stage5o35-companion-shell[data-queue-status*="processing"] .stage5o35-live-dot {
  background: #f59e0b;
  box-shadow: 0 0 0 6px rgba(245, 158, 11, 0.16);
}

.stage5o35-how-card p,
.stage5o35-toggle-card p {
  margin: 0;
  color: #64748b;
  line-height: 1.55;
}

.stage5o35-how-card code {
  padding: 2px 6px;
  border-radius: 8px;
  background: #eef2ff;
  color: #3730a3;
  font-weight: 800;
}

.stage5o35-toggle-card {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 14px;
}

.stage5o35-toggle {
  flex: 0 0 auto;
  border: 1px solid rgba(148, 163, 184, 0.28);
  border-radius: 999px;
  padding: 9px 12px;
  background: #f8fafc;
  color: #64748b;
  font-weight: 800;
}

@media (max-width: 920px) {
  .stage5o35-companion-shell {
    width: min(100% - 20px, 1180px);
    padding-top: 18px;
  }

  .stage5o35-companion-hero {
    flex-direction: column;
    padding: 22px;
  }

  .stage5o35-companion-grid {
    grid-template-columns: 1fr;
  }

  .stage5o35-companion-aside {
    position: static;
  }
}
/* STAGE_5O35_COMPANION_UX_END */
'''

def upsert(text, start, end, block):
    if start in text and end in text:
        return re.sub(re.escape(start) + r".*?" + re.escape(end), block, text, flags=re.S)
    return text.rstrip() + "\n\n" + block + "\n"

app = app_path.read_text()
css = css_path.read_text()
html = html_path.read_text()

app_path.write_text(upsert(app, APP_START, APP_END, app_block))
css_path.write_text(upsert(css, CSS_START, CSS_END, css_block))

stamp = datetime.datetime.now().strftime("%Y%m%d%H%M%S")
html = re.sub(r'(app\.js)(?:\?v=[^"\']*)?', rf'\1?v={stamp}', html)
html = re.sub(r'(styles\.css)(?:\?v=[^"\']*)?', rf'\1?v={stamp}', html)
html_path.write_text(html)

Path("docs/stage-5o35-companion-visual-ux-redesign.md").write_text("""# Stage 5O-35 Companion Visual UX Redesign

## Purpose

Stage 5O-35 polishes the logged-in Companion page into a two-column app-style workspace while preserving the existing queued chat backend flow.

## Scope

- Frontend-only Companion UI enhancer.
- Keeps `/api/chat/queued` and `/api/chat/queued/{job_id}` behavior unchanged.
- Adds a conversation workspace shell, status cards, last-job display, model/worker placeholders, explanation card, and UI-only Study context placeholder.
- Does not add backend routes.
- Does not add a local calendar database.
- Does not change header/auth behavior.

## Verification

- `node --check frontend/wrapper-ui/app.js`
- Local wrapper route smoke for Companion, Chat, Profile, Study, Support, Credits, Admin, and System.
- Recent journal review for traceback/error signals.
""")
PY

  echo
  echo "=== Write Stage 5O-35 smoke helper ==="
  cat > ops/smoke/check-stage-5o35-companion-visual-ux-redesign.sh <<'SMOKE'
#!/usr/bin/env bash

stage5o35_smoke_main() {
  cd "$HOME/Desktop/edge-queue-controller" || return 1

  ok=1
  base="http://127.0.0.1:8787"
  tmpdir="/tmp/stage5o35-smoke"
  mkdir -p "$tmpdir"

  echo "=== node syntax check ==="
  if node --check frontend/wrapper-ui/app.js; then
    echo "OK node syntax"
  else
    echo "FAIL node syntax"
    ok=0
  fi

  echo
  echo "=== wait for public status ==="
  ready=0
  i=1
  while [ "$i" -le 30 ]; do
    if curl -fsS "$base/api/system/public-status" > "$tmpdir/public-status.json" 2> "$tmpdir/public-status.err"; then
      ready=1
      break
    fi
    sleep 1
    i=$((i + 1))
  done

  if [ "$ready" = "1" ]; then
    echo "OK public-status"
    cat "$tmpdir/public-status.json"
    echo
  else
    echo "FAIL public-status"
    cat "$tmpdir/public-status.err" 2>/dev/null || true
    ok=0
  fi

  echo
  echo "=== route smoke ==="
  for route in /companion /chat /profile /study /support /credits /admin /system; do
    outfile="$tmpdir/${route////_}.html"
    code="$(curl -sS -L -o "$outfile" -w "%{http_code}" "$base$route" 2>> "$tmpdir/curl.err")"
    bytes="$(wc -c < "$outfile" 2>/dev/null || printf 0)"
    if [ "$code" = "200" ] && [ "$bytes" -gt 100 ]; then
      echo "OK $route code=$code bytes=$bytes"
    else
      echo "FAIL $route code=$code bytes=$bytes"
      ok=0
    fi
  done

  echo
  echo "=== marker checks ==="
  if grep -q "STAGE_5O35_COMPANION_UX_BEGIN" frontend/wrapper-ui/app.js && grep -q "STAGE_5O35_COMPANION_UX_BEGIN" frontend/wrapper-ui/styles.css; then
    echo "OK Stage 5O-35 markers present"
  else
    echo "FAIL Stage 5O-35 markers missing"
    ok=0
  fi

  echo
  echo "=== recent journal signals ==="
  journalctl --user -n 120 --no-pager 2>/dev/null | grep -Ei "traceback|exception|failed|error" | tail -40 || true

  echo
  if [ "$ok" = "1" ]; then
    echo "STAGE_5O35_SMOKE_OK"
    return 0
  fi

  echo "STAGE_5O35_SMOKE_FAIL"
  return 1
}

stage5o35_smoke_main "$@"
return 0 2>/dev/null || true
SMOKE
  chmod +x ops/smoke/check-stage-5o35-companion-visual-ux-redesign.sh

  echo
  echo "=== Syntax check ==="
  stage_ok=1
  if node --check frontend/wrapper-ui/app.js; then
    echo "OK app.js syntax"
  else
    echo "FAIL app.js syntax"
    stage_ok=0
  fi

  echo
  echo "=== Restart wrapper/controller service if a matching user unit exists ==="
  restarted=0
  for unit in edge-queue-controller.service edge-controller.service edge-wrapper.service edge-queue-wrapper.service; do
    if systemctl --user list-unit-files "$unit" >/tmp/stage5o35-unit.txt 2>/dev/null && grep -q "$unit" /tmp/stage5o35-unit.txt; then
      echo "Restarting user unit: $unit"
      systemctl --user restart "$unit" || stage_ok=0
      restarted=1
      break
    fi
  done
  if [ "$restarted" = "0" ]; then
    echo "No matching user unit found; continuing because static assets are read from disk by the wrapper."
  fi

  echo
  echo "=== Run Stage 5O-35 smoke ==="
  if bash ops/smoke/check-stage-5o35-companion-visual-ux-redesign.sh; then
    echo "OK smoke"
  else
    echo "FAIL smoke"
    stage_ok=0
  fi

  echo
  echo "=== Git diff summary ==="
  git diff -- frontend/wrapper-ui/app.js frontend/wrapper-ui/styles.css frontend/wrapper-ui/index.html docs/stage-5o35-companion-visual-ux-redesign.md ops/smoke/check-stage-5o35-companion-visual-ux-redesign.sh | sed -n '1,260p'

  echo
  echo "=== Commit and tag when checks passed ==="
  if [ "$stage_ok" = "1" ]; then
    git add frontend/wrapper-ui/app.js \
            frontend/wrapper-ui/styles.css \
            frontend/wrapper-ui/index.html \
            docs/stage-5o35-companion-visual-ux-redesign.md \
            ops/smoke/check-stage-5o35-companion-visual-ux-redesign.sh

    if git diff --cached --quiet; then
      echo "No staged changes found."
    else
      git commit -m "style: redesign companion page stage 5o35"
    fi

    tag="controller-stage-5o35-companion-visual-ux-redesign-2026-06-11"
    if git rev-parse -q --verify "refs/tags/$tag" >/dev/null; then
      echo "Tag already exists: $tag"
    else
      git tag "$tag"
      echo "Created tag: $tag"
    fi
  else
    echo "Checks did not all pass. Review output above; no commit/tag attempted."
  fi

  echo
  echo "=== Final checkpoint ==="
  git status --short
  git rev-parse --short HEAD
  git tag --points-at HEAD || true

  return 0
}

stage5o35_main "$@"
return 0 2>/dev/null || true
