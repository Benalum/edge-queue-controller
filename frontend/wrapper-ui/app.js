const API_BASE = "https://edge-public-proxy.alexhartel179.workers.dev/api";

const $ = (id) => document.getElementById(id);

function titleCase(value) {
  if (!value) return "Unknown";
  return String(value).slice(0, 1).toUpperCase() + String(value).slice(1);
}

function setSystemPill(state) {
  const clean = state || "unknown";
  $("systemDot").className = `dot ${clean}`;
  $("systemLabel").textContent = `System: ${titleCase(clean)}`;
}

function setText(id, value) {
  const el = $(id);
  if (el) el.textContent = value || "unknown";
}

function renderItems(id, items) {
  const target = $(id);
  if (!target) return;

  target.innerHTML = "";

  for (const item of items || []) {
    const state = item.state || "unknown";
    const row = document.createElement("div");
    row.className = "status-item";
    row.innerHTML = `
      <div class="status-row">
        <div class="status-name"></div>
        <div class="badge ${state}"></div>
      </div>
      <div class="status-detail"></div>
    `;

    row.querySelector(".status-name").textContent = item.name || item.id || "Unknown";
    row.querySelector(".badge").textContent = state;
    row.querySelector(".status-detail").textContent = item.detail || item.role || "";

    target.appendChild(row);
  }
}

async function loadSystemStatus() {
  try {
    const res = await fetch(`${API_BASE}/system/status`, {
      cache: "no-store",
    });

    if (!res.ok) {
      throw new Error(`HTTP ${res.status}`);
    }

    const data = await res.json();
    const nodes = data.nodes || [];
    const services = data.services || [];

    setSystemPill(data.overall_state);

    $("systemSummary").textContent =
      `Overall state: ${titleCase(data.overall_state)}. Last checked: ${data.checked_at || "unknown"}.`;

    renderItems("nodesList", nodes);
    renderItems("servicesList", services);

    const controller = nodes.find((n) => n.id === "master-laptop");
    const pveso = nodes.find((n) => n.id === "pveso");
    const llm = nodes.find((n) => n.id === "ct-101");
    const comfy = nodes.find((n) => n.id === "ct-108");

    setText("controllerState", controller?.state);
    setText("serverState", pveso?.state);
    setText("llmState", llm?.state);
    setText("comfyState", comfy?.state);

    if (pveso?.state === "offline") {
      $("notice").textContent =
        "Main server is offline. The Cloudflare wrapper is still online. Login-based wake will be added next.";
    } else if (pveso?.state === "booting") {
      $("notice").textContent =
        "Main server is booting. Services may become available shortly.";
    } else {
      $("notice").textContent = `System state: ${data.overall_state || "unknown"}.`;
    }
  } catch (err) {
    setSystemPill("unknown");
    $("systemSummary").textContent = `Could not reach system API: ${err.message}`;
    $("notice").textContent = `Could not reach system API: ${err.message}`;
  }
}

function toggleSystemPanel() {
  $("systemPanel").classList.toggle("hidden");
  loadSystemStatus();
}

$("systemButton").addEventListener("click", toggleSystemPanel);
$("openSystemCard").addEventListener("click", toggleSystemPanel);

loadSystemStatus();
setInterval(loadSystemStatus, 30000);
