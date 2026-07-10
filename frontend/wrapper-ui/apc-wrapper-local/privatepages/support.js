(function () {
  "use strict";

  if (window.__APC_SUPPORT_UI__) return;
  window.__APC_SUPPORT_UI__ = true;

  const TOKEN_KEY = "edgeStudyToken";
  let selectedTicketId = null;

  function byId(id) { return document.getElementById(id); }

  function escapeHtml(value) {
    return String(value ?? "")
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;")
      .replaceAll("'", "&#039;");
  }

  function token() {
    try { return localStorage.getItem(TOKEN_KEY) || ""; } catch (_) { return ""; }
  }

  async function api(path, options) {
    const auth = token();
    if (!auth) throw new Error("Please sign in to use Support.");

    const response = await fetch(path, {
      credentials: "same-origin",
      method: options && options.method ? options.method : "GET",
      headers: {
        Accept: "application/json",
        "Content-Type": "application/json",
        Authorization: "Bearer " + auth
      },
      body: options && options.body ? JSON.stringify(options.body) : undefined
    });

    const text = await response.text();
    let data = null;
    try { data = text ? JSON.parse(text) : null; } catch (_) { data = text; }

    if (!response.ok) {
      const detail = data && (data.detail || data.error || data.message);
      throw new Error(detail || "Support request failed HTTP " + response.status);
    }

    return data;
  }

  function setStatus(message) {
    const el = byId("supportStatus");
    if (el) el.textContent = message || "";
  }

  function ticketArray(payload) {
    if (Array.isArray(payload)) return payload;
    if (payload && Array.isArray(payload.tickets)) return payload.tickets;
    if (payload && Array.isArray(payload.items)) return payload.items;
    return [];
  }

  function messageArray(payload) {
    if (Array.isArray(payload)) return payload;
    if (payload && Array.isArray(payload.messages)) return payload.messages;
    if (payload && Array.isArray(payload.items)) return payload.items;
    return [];
  }

  async function loadTickets() {
    const list = byId("supportTicketList");
    if (!list) return;

    try {
      list.innerHTML = `<p class="study-muted">Loading support tickets...</p>`;
      const payload = await api("/system/support/tickets");
      const tickets = ticketArray(payload);

      list.innerHTML = tickets.length
        ? tickets.map((ticket) => {
            const id = ticket.id || ticket.ticket_id || "";
            return `<article class="study-row">
              <div>
                <h3>${escapeHtml(ticket.subject || ticket.title || "Support ticket")}</h3>
                <small>${escapeHtml(ticket.status || "open")} · ${escapeHtml(ticket.category || "general")}</small>
              </div>
              <div class="study-row-actions">
                <button class="study-button secondary" type="button" data-support-open-ticket="${escapeHtml(id)}">Open</button>
              </div>
            </article>`;
          }).join("")
        : `<p class="study-muted">No support tickets yet.</p>`;
    } catch (error) {
      list.innerHTML = `<p class="study-muted">${escapeHtml(error.message || "Could not load support tickets.")}</p>`;
    }
  }

  async function createTicket() {
    const subject = byId("supportSubject")?.value.trim() || "";
    const category = byId("supportCategory")?.value || "general";
    const body = byId("supportBody")?.value.trim() || "";

    if (!subject || !body) {
      setStatus("Subject and message are required.");
      return;
    }

    setStatus("Sending support message...");
    await api("/system/support/tickets", {
      method: "POST",
      body: { subject, category, message: body, body }
    });

    if (byId("supportSubject")) byId("supportSubject").value = "";
    if (byId("supportBody")) byId("supportBody").value = "";
    setStatus("Support message sent.");
    await loadTickets();
  }

  async function openTicket(ticketId) {
    selectedTicketId = ticketId;
    const card = byId("supportConversationCard");
    const list = byId("supportMessageList");
    const title = byId("supportConversationTitle");
    if (!card || !list) return;

    card.hidden = false;
    list.innerHTML = `<p class="study-muted">Loading conversation...</p>`;

    try {
      const payload = await api(`/system/support/tickets/${encodeURIComponent(ticketId)}/messages`);
      const ticket = payload && payload.ticket ? payload.ticket : {};
      const messages = messageArray(payload);
      if (title) title.textContent = ticket.subject || ticket.title || "Support conversation";
      list.innerHTML = messages.length
        ? messages.map((message) => `<article class="study-row">
            <div>
              <h3>${escapeHtml(message.author_email || message.author || message.sender || "Support")}</h3>
              <p>${escapeHtml(message.body || message.message || message.content || "")}</p>
              <small>${escapeHtml(message.created_at || message.createdAt || "")}</small>
            </div>
          </article>`).join("")
        : `<p class="study-muted">No messages yet.</p>`;
    } catch (error) {
      list.innerHTML = `<p class="study-muted">${escapeHtml(error.message || "Could not load messages.")}</p>`;
    }
  }

  async function sendReply() {
    if (!selectedTicketId) return;
    const body = byId("supportReplyBody")?.value.trim() || "";
    if (!body) return;

    setStatus("Sending reply...");
    await api(`/system/support/tickets/${encodeURIComponent(selectedTicketId)}/messages`, {
      method: "POST",
      body: { message: body, body }
    });
    if (byId("supportReplyBody")) byId("supportReplyBody").value = "";
    setStatus("Reply sent.");
    await openTicket(selectedTicketId);
    await loadTickets();
  }

  document.addEventListener("submit", function (event) {
    const form = event.target && event.target.closest ? event.target.closest("[data-support-form]") : null;
    if (!form) return;
    event.preventDefault();

    if (form.dataset.supportForm === "create-ticket") {
      createTicket().catch((error) => setStatus(error.message || "Could not send support message."));
    }

    if (form.dataset.supportForm === "reply-ticket") {
      sendReply().catch((error) => setStatus(error.message || "Could not send reply."));
    }
  });

  document.addEventListener("click", function (event) {
    const button = event.target && event.target.closest ? event.target.closest("[data-support-open-ticket]") : null;
    if (!button) return;
    event.preventDefault();
    openTicket(button.getAttribute("data-support-open-ticket"));
  });

  document.addEventListener("apc-private-page-rendered", function (event) {
    if (event.detail && event.detail.page === "support") loadTickets();
  });
})();
