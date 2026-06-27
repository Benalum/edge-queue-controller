(function () {
  "use strict";

  if (window.__APC_SOL_STUDY_SESSION_V2__) return;
  window.__APC_SOL_STUDY_SESSION_V2__ = true;

  const VERSION = "sol-study-session-v2";

  const CLIPS = {
    listening: "/privatepages/assets/sol-clips/dog_listening_236b385d.mp4",
    thinking: "/privatepages/assets/sol-clips/dog_thinking_8dcd159e.mp4",
    talking: "/privatepages/assets/sol-clips/dog_talking_f28d314b.mp4"
  };

  let messages = [];
  let recognition = null;
  let listening = false;
  let solState = "listening";

  function store() {
    return window.APC_STUDY_STORE;
  }

  function byId(id) {
    return document.getElementById(id);
  }

  function getUserEmail() {
    try {
      const user = window.APC_PRIVATEPAGES && window.APC_PRIVATEPAGES.me ? window.APC_PRIVATEPAGES.me() : null;
      return user && user.email ? user.email : "local-user";
    } catch (_) {
      return "local-user";
    }
  }

  function escapeHtml(value) {
    return String(value ?? "")
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;")
      .replaceAll("'", "&#039;");
  }

  function messageKey() {
    return "apcPrivateCompanionMessages:" + getUserEmail();
  }

  function settingsKey() {
    return "apcPrivateCompanionVoiceSettings:" + getUserEmail();
  }

  function loadMessages() {
    try {
      messages = JSON.parse(localStorage.getItem(messageKey()) || "[]");
      if (!Array.isArray(messages)) messages = [];
    } catch (_) {
      messages = [];
    }
  }

  function saveMessages() {
    localStorage.setItem(messageKey(), JSON.stringify(messages.slice(-24)));
  }

  function addMessage(role, content) {
    messages.push({ role, content, createdAt: new Date().toISOString() });
    saveMessages();
  }

  function lastAssistantMessage() {
    for (let i = messages.length - 1; i >= 0; i--) {
      if (messages[i] && messages[i].role === "assistant") return messages[i].content || "";
    }
    return "";
  }

  function defaultSettings() {
    return {
      kokoroEnabled: false,
      voiceName: "kokoro:af_sarah",
      volume: 0.85,
      speed: 1.0,
      autoListen: false
    };
  }

  function loadSettings() {
    try {
      return { ...defaultSettings(), ...(JSON.parse(localStorage.getItem(settingsKey()) || "{}")) };
    } catch (_) {
      return defaultSettings();
    }
  }

  function saveSettings(settings) {
    localStorage.setItem(settingsKey(), JSON.stringify(settings));
  }

  function setSolState(nextState) {
    if (!CLIPS[nextState]) nextState = "listening";
    solState = nextState;

    const video = byId("solStateVideo");
    if (video && !video.currentSrc.endsWith(CLIPS[nextState])) {
      video.src = CLIPS[nextState];
      video.load();
      video.play().catch(function () {});
    }
  }

  function renderVoiceOptions(settings) {
    return [
      ["kokoro:af_heart", "af_heart"],
      ["kokoro:af_bella", "af_bella"],
      ["kokoro:af_sarah", "af_sarah"],
      ["kokoro:am_adam", "am_adam"],
      ["kokoro:am_michael", "am_michael"]
    ].map(([value, label]) => (
      `<option value="${value}" ${settings.voiceName === value ? "selected" : ""}>${label}</option>`
    )).join("");
  }

  function renderLastMessage() {
    const latest = lastAssistantMessage();
    if (!latest) return `<div class="sol-reply empty">Ask Sol a question or start a study session below.</div>`;
    return `<div class="sol-reply">${escapeHtml(latest)}</div>`;
  }

  function renderDeckChoices(state) {
    if (!state.decks.length) return `<p class="study-muted">No decks yet. Create a deck below or on the Study page.</p>`;

    const activeIds = state.runtime && state.runtime.deckIds && state.runtime.deckIds.length
      ? state.runtime.deckIds
      : [state.activeDeckId || state.decks[0].id];

    return state.decks.map((deck) => `
      <label class="sol-check-pill">
        <input type="checkbox" name="solDeckChoice" value="${escapeHtml(deck.id)}" ${activeIds.includes(deck.id) ? "checked" : ""}>
        ${escapeHtml(deck.title)}
      </label>
    `).join("");
  }

  function renderRuntime(state) {
    const rt = state.runtime;
    if (!rt) return `<p class="study-muted">No active study session.</p>`;

    const card = store().currentCard(state);
    return `
      <div class="sol-session-status">
        <strong>${escapeHtml(rt.status)}</strong>
        <span>${escapeHtml(rt.style)} · ${rt.cardsSeen} reviewed · ${store().formatDuration(store().activeElapsedMs(rt))}</span>
      </div>
      ${
        card
          ? `<div class="sol-current-card">
              <strong>Current question</strong>
              <p>${escapeHtml(card.front)}</p>
            </div>`
          : ""
      }
    `;
  }

  function renderStudyControls(state) {
    const activeDeck = state.decks.find((deck) => deck.id === state.activeDeckId) || state.decks[0] || null;
    const deckCards = activeDeck ? state.cards.filter((card) => card.deckId === activeDeck.id) : [];

    return `
      <section class="sol-study-box">
        <h2>Study session</h2>

        ${renderRuntime(state)}

        <div class="sol-session-grid">
          <label class="sol-control">
            Study style
            <select id="solStudyStyle">
              <option value="new">go over new cards</option>
              <option value="all">all cards</option>
              <option value="balanced" selected>balanced cards</option>
              <option value="hard">hard cards</option>
              <option value="medium">medium cards</option>
              <option value="easy">easy cards</option>
            </select>
          </label>

          <div class="sol-control">
            Decks to use
            <div class="sol-deck-choice-list">
              ${renderDeckChoices(state)}
            </div>
          </div>
        </div>

        <div class="sol-voice-actions">
          <button class="sol-button" type="button" data-companion-action="start-session">Start</button>
          <button class="sol-button secondary" type="button" data-companion-action="pause-session">Pause</button>
          <button class="sol-button secondary" type="button" data-companion-action="resume-session">Resume</button>
          <button class="sol-button secondary" type="button" data-companion-action="stop-session">Stop</button>
        </div>

        <details class="sol-manager-details">
          <summary>Manage decks and cards</summary>

          <div class="sol-manager-grid">
            <form class="sol-mini-form" data-companion-form="create-deck">
              <h3>Create deck</h3>
              <input id="solNewDeckTitle" placeholder="Deck name" />
              <input id="solNewDeckDescription" placeholder="Description optional" />
              <button class="sol-button" type="submit">Create deck</button>
            </form>

            <form class="sol-mini-form" data-companion-form="create-card">
              <h3>Create card</h3>
              <select id="solCardDeckId">
                ${state.decks.map((deck) => `<option value="${escapeHtml(deck.id)}" ${deck.id === state.activeDeckId ? "selected" : ""}>${escapeHtml(deck.title)}</option>`).join("")}
              </select>
              <textarea id="solCardFront" placeholder="Question / front"></textarea>
              <textarea id="solCardBack" placeholder="Answer / back"></textarea>
              <select id="solCardDifficulty">
                <option value="new">new</option>
                <option value="easy">easy</option>
                <option value="medium">medium</option>
                <option value="hard">hard</option>
              </select>
              <button class="sol-button" type="submit" ${state.decks.length ? "" : "disabled"}>Create card</button>
            </form>
          </div>

          <div class="study-list compact">
            ${
              state.decks.length
                ? state.decks.map((deck) => `
                  <article class="study-row">
                    <div>
                      <h3>${escapeHtml(deck.title)}</h3>
                      <small>${state.cards.filter((card) => card.deckId === deck.id).length} card(s)</small>
                    </div>
                    <div class="study-row-actions">
                      <button class="study-button secondary" data-companion-action="select-deck" data-deck-id="${escapeHtml(deck.id)}">Select</button>
                      <button class="study-button secondary" data-companion-action="edit-deck" data-deck-id="${escapeHtml(deck.id)}">Edit</button>
                      <button class="study-button danger" data-companion-action="delete-deck" data-deck-id="${escapeHtml(deck.id)}">Remove</button>
                    </div>
                  </article>
                `).join("")
                : `<p class="study-muted">No decks yet.</p>`
            }
          </div>

          <h3>${activeDeck ? `Cards in ${escapeHtml(activeDeck.title)}` : "Cards"}</h3>
          <div class="study-list compact">
            ${
              deckCards.length
                ? deckCards.slice(0, 30).map((card) => `
                  <article class="study-row card">
                    <div>
                      <h3>${escapeHtml(card.front)}</h3>
                      <p>${escapeHtml(card.back)}</p>
                      <small>${escapeHtml(card.difficulty)} ${card.flagged ? "· flagged" : ""} · seen ${card.seenCount}</small>
                    </div>
                    <div class="study-row-actions">
                      <button class="study-button secondary" data-companion-action="flag-card" data-card-id="${escapeHtml(card.id)}">${card.flagged ? "Unflag" : "Flag"}</button>
                      <button class="study-button secondary" data-companion-action="edit-card" data-card-id="${escapeHtml(card.id)}">Edit</button>
                      <button class="study-button danger" data-companion-action="delete-card" data-card-id="${escapeHtml(card.id)}">Remove</button>
                    </div>
                  </article>
                `).join("")
                : `<p class="study-muted">No cards in the selected deck.</p>`
            }
          </div>
        </details>
      </section>
    `;
  }

  function renderVoiceBox(settings) {
    return `
      <section class="sol-voice-box">
        <h2>Voice</h2>

        <div class="sol-voice-grid">
          <label class="sol-toggle">
            <input id="companionKokoroEnabled" type="checkbox" ${settings.kokoroEnabled ? "checked" : ""}>
            Enable Kokoro
          </label>

          <label class="sol-toggle">
            <input id="companionAutoListen" type="checkbox" ${settings.autoListen ? "checked" : ""}>
            Auto-listen after Sol speaks
          </label>

          <label class="sol-control full-width">
            Kokoro voice
            <select id="companionVoiceSelect">${renderVoiceOptions(settings)}</select>
          </label>

          <label class="sol-control">
            Volume: <span id="companionVolumeValue">${Math.round(Number(settings.volume) * 100)}%</span>
            <input id="companionVolume" type="range" min="0" max="1" step="0.05" value="${escapeHtml(settings.volume)}">
          </label>

          <label class="sol-control">
            Speed: <span id="companionSpeedValue">${Number(settings.speed).toFixed(2)}x</span>
            <input id="companionSpeed" type="range" min="0.6" max="1.6" step="0.05" value="${escapeHtml(settings.speed)}">
          </label>
        </div>

        <div class="sol-voice-actions">
          <button class="sol-button secondary" type="button" data-companion-action="listen">Start listening</button>
          <button class="sol-button secondary" type="button" data-companion-action="stop-speaking">Stop speaking</button>
          <button class="sol-button secondary" type="button" data-companion-action="clear-chat">Clear</button>
        </div>
      </section>
    `;
  }

  function render() {
    const el = document.getElementById("companionPrivateApp");
    if (!el || !store()) return;

    const state = store().load();
    const settings = loadSettings();
    loadMessages();

    el.innerHTML = `
      <section class="sol-card">
        <div class="sol-header with-video">
          <div class="sol-video-frame" style="width:180px;height:135px;max-width:180px;max-height:135px;overflow:hidden;">
            <video id="solStateVideo" width="180" height="135" style="width:180px;height:135px;max-width:180px;max-height:135px;object-fit:cover;display:block;" src="${CLIPS[solState]}" autoplay muted loop playsinline preload="auto" aria-label="Sol animation"></video>
          </div>
          <div class="sol-title-wrap">
            <h1 class="sol-title">Sol</h1>
          </div>
        </div>

        <div class="sol-message-window">${renderLastMessage()}</div>

        <form class="sol-input-form" data-companion-form="chat">
          <textarea id="companionPrompt" placeholder="Message Sol..."></textarea>
          <button class="sol-button sol-send" type="submit">Send</button>
        </form>
      </section>

      ${renderVoiceBox(settings)}
    `;

    bindRenderedControls();
    bindEnterToSend();
    setSolState(solState);
  }

  function bindRenderedControls() {
    ["companionKokoroEnabled", "companionAutoListen", "companionVoiceSelect", "companionVolume", "companionSpeed"].forEach((id) => {
      const el = byId(id);
      if (!el) return;
      el.addEventListener("input", updateSettingsFromControls);
      el.addEventListener("change", updateSettingsFromControls);
    });
  }

  function bindEnterToSend() {
    const input = byId("companionPrompt");
    if (!input) return;
    input.addEventListener("keydown", function (event) {
      if (event.key === "Enter" && !event.shiftKey) {
        event.preventDefault();
        submitPrompt(input.value);
        input.value = "";
      }
    });
  }

  function updateSettingsFromControls() {
    const settings = {
      kokoroEnabled: Boolean(byId("companionKokoroEnabled")?.checked),
      autoListen: Boolean(byId("companionAutoListen")?.checked),
      voiceName: byId("companionVoiceSelect")?.value || "kokoro:af_sarah",
      volume: Number(byId("companionVolume")?.value || 0.85),
      speed: Number(byId("companionSpeed")?.value || 1.0)
    };
    saveSettings(settings);

    const volumeLabel = byId("companionVolumeValue");
    if (volumeLabel) volumeLabel.textContent = Math.round(settings.volume * 100) + "%";
    const speedLabel = byId("companionSpeedValue");
    if (speedLabel) speedLabel.textContent = settings.speed.toFixed(2) + "x";
    return settings;
  }

  function selectedStyleFromText(text) {
    const lower = String(text || "").toLowerCase();
    if (lower.includes("new")) return "new";
    if (lower.includes("all")) return "all";
    if (lower.includes("hard")) return "hard";
    if (lower.includes("medium")) return "medium";
    if (lower.includes("easy")) return "easy";
    if (lower.includes("balanced")) return "balanced";
    return "balanced";
  }

  function normalReply(prompt) {
    const lower = String(prompt || "").toLowerCase();

    if (!store()) return "Study tools are still loading. Try again in a moment.";

    const state = store().load();

    // Important: stop/pause/resume must be checked before generic "study session".
    if (
      lower.includes("stop study") ||
      lower.includes("stop session") ||
      lower.includes("stop study session") ||
      lower.includes("end study") ||
      lower.includes("end session") ||
      lower.includes("finish study") ||
      lower.includes("quit study")
    ) {
      return store().stopSession().message;
    }

    if (
      lower.includes("pause study") ||
      lower.includes("pause session") ||
      lower.includes("pause study session")
    ) {
      return store().pauseSession().message;
    }

    if (
      lower.includes("resume study") ||
      lower.includes("resume session") ||
      lower.includes("resume study session") ||
      lower.includes("continue study") ||
      lower.includes("continue session")
    ) {
      const result = store().resumeSession();
      const next = store().load();
      let reply = result.message;
      if (next.runtime && next.runtime.status === "active") reply += "\n\n" + store().questionText(next);
      return reply;
    }

    if (
      lower.includes("start study") ||
      lower.includes("start session") ||
      lower.includes("start study session") ||
      lower.includes("begin study") ||
      lower.includes("begin session")
    ) {
      const style = selectedStyleFromText(lower);
      const deckIds = state.activeDeckId ? [state.activeDeckId] : (state.decks[0] ? [state.decks[0].id] : []);
      const result = store().startSession(style, deckIds);
      const next = store().load();

      if (!result.ok) return result.message || "I could not start a study session yet.";

      return "Study session started. Style: " + style + "\n\n" + store().questionText(next);
    }

    if (lower.includes("hello") || lower.includes("hi")) return "Hi, I’m Sol. What would you like to work on?";

    return "I’m here with you. To study, say something like: start study, start hard study, pause study, resume study, or stop study.";
  }

  function submitPrompt(prompt) {
    const clean = String(prompt || "").trim();
    if (!clean || !store()) return;

    loadMessages();
    addMessage("user", clean);
    setSolState("thinking");

    window.setTimeout(function () {
      const state = store().load();
      const rt = state.runtime;
      let reply = "";

      if (rt && rt.status === "active" && store().currentCard(state)) {
        reply = store().answerCurrent(clean).reply;
      } else if (rt && rt.status === "paused") {
        reply = "The study session is paused. Resume it when you are ready.";
      } else {
        reply = normalReply(clean);
      }

      addMessage("assistant", reply);
      setSolState("talking");
      render();
      speakText(reply);
    }, 250);
  }

  function startStudySession() {
    const style = byId("solStudyStyle")?.value || "balanced";
    const deckIds = Array.from(document.querySelectorAll('input[name="solDeckChoice"]:checked')).map((input) => input.value);

    const result = store().startSession(style, deckIds);
    const state = store().load();

    let reply = result.message || "Study session started.";
    if (result.ok) reply += "\n\n" + store().questionText(state);

    loadMessages();
    addMessage("assistant", reply);
    setSolState("talking");
    render();
    speakText(reply);
  }

  function pauseStudySession() {
    const result = store().pauseSession();
    loadMessages();
    addMessage("assistant", result.message);
    render();
    speakText(result.message);
  }

  function resumeStudySession() {
    const result = store().resumeSession();
    const state = store().load();
    let reply = result.message;
    if (state.runtime && state.runtime.status === "active") reply += "\n\n" + store().questionText(state);
    loadMessages();
    addMessage("assistant", reply);
    render();
    speakText(reply);
  }

  function stopStudySession() {
    const result = store().stopSession();
    loadMessages();
    addMessage("assistant", result.message);
    render();
    speakText(result.message);
  }

  function kokoroVoiceId(settings) {
    const selected = settings.voiceName || "kokoro:af_sarah";
    if (selected.startsWith("kokoro:")) return selected.replace(/^kokoro:/, "");
    return "af_sarah";
  }

  async function speakWithKokoro(text, settings) {
    const response = await fetch("/api/tts/kokoro", {
      method: "POST",
      credentials: "same-origin",
      headers: {
        Accept: "audio/wav,audio/mpeg,audio/*,application/json",
        "Content-Type": "application/json",
        ...(localStorage.getItem("edgeStudyToken") ? { Authorization: "Bearer " + localStorage.getItem("edgeStudyToken") } : {})
      },
      body: JSON.stringify({
        text,
        voice: kokoroVoiceId(settings),
        speed: Number(settings.speed) || 1.0,
        volume: Number(settings.volume) || 0.85,
        format: "wav"
      })
    });

    if (!response.ok) throw new Error("Kokoro failed HTTP " + response.status);
    const blob = await response.blob();
    const audioUrl = URL.createObjectURL(blob);
    await playAudioUrl(audioUrl, settings, true);
  }

  function playAudioUrl(url, settings, revokeWhenDone) {
    return new Promise((resolve, reject) => {
      const audio = new Audio(url);
      audio.volume = Math.max(0, Math.min(1, Number(settings.volume) || 0.85));
      setSolState("talking");

      audio.onended = function () {
        if (revokeWhenDone) URL.revokeObjectURL(url);
        if (loadSettings().autoListen) startListening();
        resolve(true);
      };

      audio.onerror = function () {
        if (revokeWhenDone) URL.revokeObjectURL(url);
        reject(new Error("Audio playback failed"));
      };

      audio.play().catch(reject);
    });
  }

  async function speakText(text) {
    const settings = loadSettings();
    if (!settings.kokoroEnabled) {
      setSolState("talking");
      return;
    }
    try {
      await speakWithKokoro(text, settings);
    } catch (error) {
      console.warn("[sol] Kokoro TTS failed", error);
    }
  }

  function setupRecognition() {
    const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
    if (!SpeechRecognition) return null;

    const rec = new SpeechRecognition();
    rec.lang = "en-US";
    rec.interimResults = false;
    rec.continuous = false;

    rec.onstart = function () {
      listening = true;
      setSolState("listening");
    };
    rec.onend = function () {
      listening = false;
    };
    rec.onerror = function () {
      listening = false;
    };
    rec.onresult = function (event) {
      const transcript = Array.from(event.results || []).map((result) => result[0]?.transcript || "").join(" ").trim();
      if (transcript) submitPrompt(transcript);
    };

    return rec;
  }

  function startListening() {
    if (listening) return;
    if (!recognition) recognition = setupRecognition();
    setSolState("listening");
    if (!recognition) return;
    try { recognition.start(); } catch (error) { console.warn("[sol] recognition start failed", error); }
  }

  function stopSpeaking() {
    try { window.speechSynthesis && window.speechSynthesis.cancel(); } catch (_) {}
    setSolState("talking");
  }

  function clearChat() {
    messages = [];
    saveMessages();
    render();
  }

  function handleManagerAction(action, button) {
    if (action === "start-session") return startStudySession();
    if (action === "pause-session") return pauseStudySession();
    if (action === "resume-session") return resumeStudySession();
    if (action === "stop-session") return stopStudySession();

    if (action === "listen") return startListening();
    if (action === "stop-speaking") return stopSpeaking();
    if (action === "clear-chat") return clearChat();

    if (action === "select-deck") store().setActiveDeck(button.dataset.deckId);

    if (action === "delete-deck" && confirm("Remove this deck and its cards?")) {
      store().deleteDeck(button.dataset.deckId);
    }

    if (action === "edit-deck") {
      const state = store().load();
      const deck = state.decks.find((item) => item.id === button.dataset.deckId);
      if (deck) {
        store().editDeck(deck.id, {
          title: prompt("Deck name", deck.title),
          description: prompt("Deck description", deck.description || "")
        });
      }
    }

    if (action === "flag-card") store().toggleFlagCard(button.dataset.cardId);

    if (action === "delete-card" && confirm("Remove this card?")) {
      store().deleteCard(button.dataset.cardId);
    }

    if (action === "edit-card") {
      const state = store().load();
      const card = state.cards.find((item) => item.id === button.dataset.cardId);
      if (card) {
        store().editCard(card.id, {
          front: prompt("Question / front", card.front),
          back: prompt("Answer / back", card.back),
          difficulty: prompt("Difficulty: new, easy, medium, hard", card.difficulty)
        });
      }
    }

    render();
  }

  function bindGlobal() {
    document.addEventListener("submit", function (event) {
      const form = event.target.closest("[data-companion-form]");
      if (!form) return;
      event.preventDefault();

      if (form.dataset.companionForm === "chat") {
        const input = byId("companionPrompt");
        const prompt = input ? input.value : "";
        if (input) input.value = "";
        submitPrompt(prompt);
      }

      if (form.dataset.companionForm === "create-deck") {
        store().createDeck(byId("solNewDeckTitle").value, byId("solNewDeckDescription").value);
        render();
      }

      if (form.dataset.companionForm === "create-card") {
        store().createCard(
          byId("solCardDeckId").value,
          byId("solCardFront").value,
          byId("solCardBack").value,
          byId("solCardDifficulty").value
        );
        render();
      }
    });

    document.addEventListener("click", function (event) {
      const button = event.target.closest("[data-companion-action]");
      if (!button) return;
      event.preventDefault();
      handleManagerAction(button.dataset.companionAction, button);
    });
  }

  async function syncThenRender() {
    try {
      if (store() && store().syncFromBackend) {
        await store().syncFromBackend();
      }
    } catch (error) {
      console.warn("[sol] backend sync failed", error);
    }
    render();
  }

  function init() {
    syncThenRender();
  }

  window.APC_PRIVATE_COMPANION = {
    render,
    submitPrompt,
    startListening,
    stopSpeaking,
    clearChat,
    setSolState,
    version: VERSION
  };

  bindGlobal();

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init, { once: true });
  } else {
    init();
  }

  document.addEventListener("apc-private-page-rendered", function (event) {
    if (event.detail && event.detail.page === "companion") syncThenRender();
  });
})();
