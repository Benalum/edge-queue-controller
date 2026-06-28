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
  let browserVoices = [];

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
      voiceEnabled: false,
      voiceProvider: "browser",
      browserVoiceURI: "",
      browserVoiceName: "",
      kokoroEnabled: false,
      voiceName: "",
      volume: 1.0,
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


  /* Companion Browser Voice R3C */
  function browserSpeechSupported() {
    return Boolean(
      window &&
      "speechSynthesis" in window &&
      "SpeechSynthesisUtterance" in window
    );
  }

  function normalizeVoiceSettings(settings) {
    const next = { ...defaultSettings(), ...(settings || {}) };

    next.voiceProvider = browserSpeechSupported() ? "browser" : "kokoro";

    if (next.voiceProvider === "browser") {
      next.kokoroEnabled = false;
    }

    next.autoListen = false;
    next.volume = 1.0;
    next.speed = 1.0;

    return next;
  }

  function voiceProviderLabel(settings) {
    if (!settings || !settings.voiceEnabled) return "Voice is off.";
    if (browserSpeechSupported()) return "Voice is on using your browser.";
    return "Browser voice is not supported in this browser.";
  }

  function speakWithBrowser(text, settings) {
    return new Promise(function (resolve, reject) {
      if (!browserSpeechSupported()) {
        reject(new Error("Browser speechSynthesis is not supported."));
        return;
      }

      const clean = String(text || "").trim();
      if (!clean) {
        resolve();
        return;
      }

      try {
        window.speechSynthesis.cancel();

        const utterance = new SpeechSynthesisUtterance(clean);
        const selectedVoice = selectedBrowserVoice(settings);
        if (selectedVoice) utterance.voice = selectedVoice;

        utterance.volume = 1.0;
        utterance.rate = 1.0;
        utterance.pitch = 1.0;

        utterance.onend = function () {
          resolve();
        };

        utterance.onerror = function (event) {
          reject(new Error(event && event.error ? event.error : "Browser speech failed."));
        };

        window.speechSynthesis.speak(utterance);
      } catch (error) {
        reject(error);
      }
    });
  }

  function companionVoiceNotice(message) {
    loadMessages();
    addMessage("assistant", message);
    setSolState("talking");
    render();
  }

  function enableVoice() {
    const settings = normalizeVoiceSettings(loadSettings());
    settings.voiceEnabled = true;

    if (browserSpeechSupported()) {
      settings.voiceProvider = "browser";
      settings.kokoroEnabled = false;
      saveSettings(settings);
      companionVoiceNotice("Voice enabled using your browser.");
      speakWithBrowser("Voice enabled.", settings).catch(function (error) {
        console.warn("[companion] browser voice unlock failed", error);
      });
      return;
    }

    settings.voiceProvider = "kokoro";
    settings.kokoroEnabled = true;
    saveSettings(settings);
    companionVoiceNotice("Browser voice is not supported in this browser.");
  }

  function disableVoice() {
    const settings = normalizeVoiceSettings(loadSettings());
    settings.voiceEnabled = false;
    settings.kokoroEnabled = false;
    saveSettings(settings);

    try {
      if (browserSpeechSupported()) window.speechSynthesis.cancel();
    } catch (_) {}

    companionVoiceNotice("Voice disabled.");
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

  /* Companion Browser Voice R3D */
  function getBrowserVoices() {
    try {
      if (!browserSpeechSupported()) return [];

      const voices = window.speechSynthesis.getVoices() || [];
      if (voices.length) browserVoices = voices;

      return browserVoices || [];
    } catch (_) {
      return browserVoices || [];
    }
  }

  function browserVoiceKey(voice) {
    if (!voice) return "";
    return voice.voiceURI || `${voice.name || "voice"}|${voice.lang || ""}`;
  }

  function browserVoiceLabel(voice) {
    const parts = [
      voice.name || "Unnamed voice",
      voice.lang || "unknown language",
      voice.localService ? "local" : "browser"
    ];

    if (voice.default) parts.push("default");

    return parts.join(" — ");
  }

  function selectedBrowserVoice(settings) {
    const voices = getBrowserVoices();
    if (!voices.length) return null;

    const key = settings && settings.browserVoiceURI ? String(settings.browserVoiceURI) : "";
    if (key) {
      const selected = voices.find((voice) => browserVoiceKey(voice) === key);
      if (selected) return selected;
    }

    return voices.find((voice) => voice.default) || null;
  }

  function renderBrowserVoiceOptions(settings) {
    const voices = getBrowserVoices();

    const systemSelected = !settings.browserVoiceURI ? "selected" : "";
    const options = [`<option value="" ${systemSelected}>System default</option>`];

    voices.forEach((voice) => {
      const key = browserVoiceKey(voice);
      const selected = settings.browserVoiceURI === key ? "selected" : "";
      options.push(`<option value="${escapeHtml(key)}" ${selected}>${escapeHtml(browserVoiceLabel(voice))}</option>`);
    });

    if (!voices.length) {
      options.push(`<option value="" disabled>No browser voices listed yet</option>`);
    }

    return options.join("");
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
    settings = normalizeVoiceSettings(settings);

    const browserOk = browserSpeechSupported();
    const providerText = voiceProviderLabel(settings);
    const enableDisabled = settings.voiceEnabled ? "disabled" : "";
    const disableDisabled = settings.voiceEnabled ? "" : "disabled";

    return `
      <section class="sol-voice-box">
        <h2>Voice</h2>
        <p class="study-muted">${escapeHtml(providerText)}</p>

        <div class="sol-voice-actions">
          <button class="sol-button" type="button" data-companion-action="enable-voice" ${enableDisabled}>Enable Voice</button>
          <button class="sol-button secondary" type="button" data-companion-action="disable-voice" ${disableDisabled}>Disable Voice</button>
        </div>

        ${
          browserOk
            ? `<label class="sol-control full-width">
                Browser voice
                <select id="companionBrowserVoiceSelect">
                  ${renderBrowserVoiceOptions(settings)}
                </select>
              </label>`
            : ""
        }
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


  /* Companion Study Command Router R2 */
  let studyCommandFlow = null;

  function commandNormalize(value) {
    return String(value || "")
      .trim()
      .toLowerCase()
      .replace(/[^\w\s+-]/g, " ")
      .replace(/\s+/g, " ");
  }

  function commandTitle(value) {
    return String(value || "").trim();
  }

  function commandState() {
    const apcStore = store();
    if (!apcStore) return null;
    return apcStore.load();
  }

  function commandActiveDeck(state) {
    const decks = (state && state.decks) || [];
    return decks.find((deck) => String(deck.id) === String(state.activeDeckId)) || decks[0] || null;
  }

  function commandCardsForDeck(state, deckId) {
    return ((state && state.cards) || []).filter((card) => String(card.deckId) === String(deckId));
  }

  function commandFindDeck(state, text) {
    const query = commandNormalize(text);
    if (!query) return null;

    const decks = (state && state.decks) || [];
    return decks.find((deck) => commandNormalize(deck.title) === query)
      || decks.find((deck) => commandNormalize(deck.title).includes(query))
      || decks.find((deck) => query.includes(commandNormalize(deck.title)));
  }

  function commandFindCard(state, text) {
    const query = commandNormalize(text);
    if (!query) return null;

    const cards = (state && state.cards) || [];
    const activeDeck = commandActiveDeck(state);
    const scoped = activeDeck
      ? cards.filter((card) => String(card.deckId) === String(activeDeck.id))
      : cards;

    return scoped.find((card) => String(card.id) === String(text))
      || scoped.find((card) => commandNormalize(card.front) === query)
      || scoped.find((card) => commandNormalize(card.back) === query)
      || scoped.find((card) => commandNormalize(card.front).includes(query))
      || cards.find((card) => commandNormalize(card.front).includes(query))
      || cards.find((card) => query.includes(commandNormalize(card.front)));
  }

  function commandCurrentCard(state) {
    const apcStore = store();
    const current = apcStore && apcStore.currentCard ? apcStore.currentCard(state) : null;
    if (current) return current;

    const activeDeck = commandActiveDeck(state);
    const cards = activeDeck ? commandCardsForDeck(state, activeDeck.id) : ((state && state.cards) || []);
    return cards[0] || null;
  }

  function commandListDecks(state) {
    const decks = (state && state.decks) || [];
    if (!decks.length) return "You do not have any active decks yet. Say “create deck” to make one.";
    return "Your active decks are:\n\n" + decks.map((deck) => `- ${deck.title}`).join("\n");
  }

  function commandListCards(state) {
    const activeDeck = commandActiveDeck(state);
    if (!activeDeck) return "Select or create a deck first.";

    const cards = commandCardsForDeck(state, activeDeck.id);
    if (!cards.length) return `The deck “${activeDeck.title}” does not have cards yet. Say “create card” to add one.`;

    return `Cards in “${activeDeck.title}”:\n\n` + cards.map((card) => `- ${card.front} → ${card.back}`).join("\n");
  }

  function commandSelectDeck(deckText) {
    const state = commandState();
    if (!state) return "Study is not ready yet.";

    const deck = commandFindDeck(state, deckText);
    if (!deck) return `I could not find a deck named “${commandTitle(deckText)}”. Say “list decks” to see your decks.`;

    store().setActiveDeck(String(deck.id));
    return `Selected deck “${deck.title}”.`;
  }

  function commandStartStudy(prompt) {
    const state = commandState();
    if (!state) return "Study is not ready yet.";

    const rt = state.runtime;
    if (rt && rt.status === "active") return "A study session is already active. Answer the current card, or say “pause study” or “stop study”.";
    if (rt && rt.status === "paused") return "A study session is paused. Say “resume study” to continue it, or “stop study” to end it.";

    const lower = commandNormalize(prompt);
    let style = "balanced";
    if (lower.includes("hard")) style = "hard";
    if (lower.includes("new")) style = "new";
    if (lower.includes("all")) style = "all";

    let deck = commandActiveDeck(state);
    const deckMatch = lower.match(/(?:deck|with|using|from)\s+(.+)$/);
    if (deckMatch && deckMatch[1]) {
      const found = commandFindDeck(state, deckMatch[1]);
      if (found) deck = found;
    }

    if (!deck) return "Create or select a deck first. You can say “list decks” or “select deck mathmatic”.";

    store().setActiveDeck(String(deck.id));
    const result = store().startSession(style, [String(deck.id)]);
    if (!result.ok) return result.message || "I could not start a study session yet.";

    const nextState = store().load();
    const card = commandCurrentCard(nextState);
    return `Started a ${style} study session with “${deck.title}”.\n\n${card ? `Question:\n\n${card.front}` : "No card is ready yet."}`;
  }

  function commandPauseStudy() {
    const state = commandState();
    const rt = state && state.runtime;
    if (!rt || rt.status !== "active") return "There is no active study session to pause.";
    return store().pauseSession().message;
  }

  function commandResumeStudy() {
    const state = commandState();
    const rt = state && state.runtime;
    if (!rt || rt.status !== "paused") return "There is no paused study session to resume.";
    const result = store().resumeSession();
    const nextState = store().load();
    const card = commandCurrentCard(nextState);
    return `${result.message}\n\n${card ? `Question:\n\n${card.front}` : ""}`.trim();
  }

  function commandStopStudy() {
    const state = commandState();
    const rt = state && state.runtime;
    if (!rt) return "There is no active study session to stop.";
    return store().stopSession().message;
  }

  function commandCreateDeckStart(text) {
    const title = commandTitle(text.replace(/^create\s+deck/i, ""));
    if (title) {
      studyCommandFlow = { type: "create_deck_description", title };
      return `What description should I use for the deck “${title}”? Say “skip” for no description.`;
    }

    studyCommandFlow = { type: "create_deck_title" };
    return "What should I name the new deck?";
  }

  function commandCreateCardStart(prompt) {
    const state = commandState();
    if (!state) return "Study is not ready yet.";

    const lower = commandNormalize(prompt);
    let deck = null;

    const inMatch = lower.match(/(?:in|deck|to)\s+(.+)$/);
    if (inMatch && inMatch[1] && lower !== "create card" && lower !== "add card") {
      deck = commandFindDeck(state, inMatch[1]);
    }

    if (!deck) {
      studyCommandFlow = { type: "create_card_deck" };
      return "Which deck should I put the new card in?";
    }

    studyCommandFlow = { type: "create_card_question", deckId: String(deck.id), deckTitle: deck.title };
    return `I will add the card to “${deck.title}”. What is the question/front of the card?`;
  }

  function commandDeleteCardStart(prompt) {
    const state = commandState();
    if (!state) return "Study is not ready yet.";

    const raw = commandTitle(prompt)
      .replace(/^delete\s+card/i, "")
      .replace(/^remove\s+card/i, "")
      .trim();

    const card = raw ? commandFindCard(state, raw) : commandCurrentCard(state);
    if (!card) return "Which card should I delete? Say “delete card” followed by the card question.";

    studyCommandFlow = {
      type: "delete_card_confirm",
      cardId: String(card.id),
      front: card.front,
      back: card.back
    };

    return `I found this card:\n\n${card.front} → ${card.back}\n\nTo archive it, say “delete”. To keep it, say “cancel”.`;
  }

  function commandFlagCard(prompt, flagged) {
    const state = commandState();
    if (!state) return "Study is not ready yet.";

    const raw = commandTitle(prompt)
      .replace(/^(flag|unflag)\s+card/i, "")
      .replace(/^(flag|unflag)\s+current\s+card/i, "")
      .trim();

    const card = raw ? commandFindCard(state, raw) : commandCurrentCard(state);
    if (!card) return "Which card should I flag or unflag?";

    if (Boolean(card.flagged) !== Boolean(flagged)) {
      store().toggleFlagCard(String(card.id));
    }

    return `${flagged ? "Flagged" : "Unflagged"} card: ${card.front}`;
  }

  function commandEditCardStart(prompt) {
    const state = commandState();
    if (!state) return "Study is not ready yet.";

    const raw = commandTitle(prompt)
      .replace(/^edit\s+card/i, "")
      .trim();

    const card = raw ? commandFindCard(state, raw) : commandCurrentCard(state);
    if (!card) return "Which card should I edit? Say “edit card” followed by the card question.";

    studyCommandFlow = {
      type: "edit_card_field",
      cardId: String(card.id),
      front: card.front,
      back: card.back,
      difficulty: card.difficulty || "new"
    };

    return `Editing card:\n\n${card.front} → ${card.back}\n\nWhat do you want to edit: question, answer, or difficulty?`;
  }

  function continueStudyCommandFlow(prompt) {
    if (!studyCommandFlow) return null;

    const clean = commandTitle(prompt);
    const lower = commandNormalize(clean);

    if (["cancel", "never mind", "nevermind", "stop"].includes(lower)) {
      studyCommandFlow = null;
      return "Canceled.";
    }

    if (studyCommandFlow.type === "create_deck_title") {
      studyCommandFlow = { type: "create_deck_description", title: clean || "Untitled deck" };
      return `What description should I use for “${studyCommandFlow.title}”? Say “skip” for no description.`;
    }

    if (studyCommandFlow.type === "create_deck_description") {
      const description = ["skip", "none", "no description"].includes(lower) ? "" : clean;
      store().createDeck(studyCommandFlow.title, description);
      const title = studyCommandFlow.title;
      studyCommandFlow = null;
      return `Created deck “${title}”.`;
    }

    if (studyCommandFlow.type === "create_card_deck") {
      const state = commandState();
      const deck = commandFindDeck(state, clean);
      if (!deck) return `I could not find “${clean}”. Say another deck name, or say “cancel”.`;

      studyCommandFlow = { type: "create_card_question", deckId: String(deck.id), deckTitle: deck.title };
      return `I will add the card to “${deck.title}”. What is the question/front of the card?`;
    }

    if (studyCommandFlow.type === "create_card_question") {
      studyCommandFlow.front = clean;
      studyCommandFlow.type = "create_card_answer";
      return "What is the answer/back of the card?";
    }

    if (studyCommandFlow.type === "create_card_answer") {
      const deckId = studyCommandFlow.deckId;
      const deckTitle = studyCommandFlow.deckTitle;
      const front = studyCommandFlow.front;
      const back = clean;

      store().createCard(deckId, front, back, "new");
      studyCommandFlow = null;

      return `Created a new card in “${deckTitle}”:\n\n${front} → ${back}`;
    }

    if (studyCommandFlow.type === "delete_card_confirm") {
      if (lower !== "delete") return "I did not delete it. Say “delete” to confirm, or “cancel” to keep it.";

      const front = studyCommandFlow.front;
      store().deleteCard(studyCommandFlow.cardId);
      studyCommandFlow = null;

      return `Archived card: ${front}`;
    }

    if (studyCommandFlow.type === "edit_card_field") {
      if (!["question", "front", "answer", "back", "difficulty"].includes(lower)) {
        return "Please say question, answer, difficulty, or cancel.";
      }

      studyCommandFlow.field = lower;
      studyCommandFlow.type = "edit_card_value";
      return `What should the new ${lower === "front" ? "question" : lower === "back" ? "answer" : lower} be?`;
    }

    if (studyCommandFlow.type === "edit_card_value") {
      const cardId = studyCommandFlow.cardId;
      const state = commandState();
      const card = ((state && state.cards) || []).find((item) => String(item.id) === String(cardId));

      if (!card) {
        studyCommandFlow = null;
        return "I could not find that card anymore.";
      }

      const patch = {
        front: card.front,
        back: card.back,
        difficulty: card.difficulty || "new"
      };

      if (studyCommandFlow.field === "question" || studyCommandFlow.field === "front") patch.front = clean;
      if (studyCommandFlow.field === "answer" || studyCommandFlow.field === "back") patch.back = clean;
      if (studyCommandFlow.field === "difficulty") patch.difficulty = lower || "new";

      store().editCard(cardId, patch);
      studyCommandFlow = null;

      return `Updated card:\n\n${patch.front} → ${patch.back}`;
    }

    studyCommandFlow = null;
    return null;
  }

  function routeStudyCommand(prompt) {
    const flowReply = continueStudyCommandFlow(prompt);
    if (flowReply) return flowReply;

    const clean = commandTitle(prompt);
    const lower = commandNormalize(clean);

    if (!lower) return null;

    if (lower === "list decks" || lower === "show decks") return commandListDecks(commandState());
    if (lower === "list cards" || lower === "show cards") return commandListCards(commandState());

    if (lower === "show current card" || lower === "current card") {
      const card = commandCurrentCard(commandState());
      return card ? `Current card:\n\n${card.front} → ${card.back}` : "No current card is selected.";
    }

    if (lower.startsWith("select deck ") || lower.startsWith("use deck ")) {
      return commandSelectDeck(clean.replace(/^(select|use)\s+deck\s+/i, ""));
    }

    if (lower === "start study" || lower.includes("start study session") || lower.includes("begin study")) return commandStartStudy(clean);
    if (lower.includes("start hard study")) return commandStartStudy(clean);
    if (lower.includes("start new study")) return commandStartStudy(clean);
    if (lower.includes("start all study")) return commandStartStudy(clean);

    if (lower === "pause study" || lower.includes("pause study session")) return commandPauseStudy();
    if (lower === "resume study" || lower.includes("resume study session") || lower.includes("continue study")) return commandResumeStudy();
    if (lower === "stop study" || lower.includes("stop study session") || lower.includes("end study") || lower.includes("finish study") || lower.includes("quit study")) return commandStopStudy();

    if (lower === "create deck" || lower.startsWith("create deck ")) return commandCreateDeckStart(clean);
    if (lower === "create card" || lower === "add card" || lower.startsWith("create card ") || lower.startsWith("add card ")) return commandCreateCardStart(clean);

    if (lower === "delete card" || lower.startsWith("delete card ") || lower === "remove card" || lower.startsWith("remove card ")) return commandDeleteCardStart(clean);

    if (lower === "flag card" || lower.startsWith("flag card ") || lower === "flag current card") return commandFlagCard(clean, true);
    if (lower === "unflag card" || lower.startsWith("unflag card ") || lower === "unflag current card") return commandFlagCard(clean, false);

    if (lower === "edit card" || lower.startsWith("edit card ")) return commandEditCardStart(clean);

    return null;
  }

  function normalReply(prompt) {
    const routed = routeStudyCommand(prompt);
    if (routed) return routed;

    if (commandNormalize(prompt).includes("hello") || commandNormalize(prompt).includes("hi")) {
      return "Hi, I’m Sol. What would you like to work on?";
    }

    return "I’m here with you. To study, say things like: list decks, select deck mathmatic, start study, create card, edit card, delete card, flag card, pause study, resume study, or stop study.";
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

      const routed = routeStudyCommand(clean);

      if (routed) {
        reply = routed;
      } else if (rt && rt.status === "active" && store().currentCard(state)) {
        reply = store().answerCurrent(clean).reply;
      } else if (rt && rt.status === "paused") {
        reply = "The study session is paused. Say “resume study” to continue it, or “stop study” to end it.";
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
    const clean = String(text || "").trim();
    if (!clean) return;

    const settings = normalizeVoiceSettings(loadSettings());
    if (!settings.voiceEnabled) return;

    setSolState("talking");

    try {
      if (browserSpeechSupported()) {
        settings.voiceProvider = "browser";
        settings.kokoroEnabled = false;
        saveSettings(settings);
        await speakWithBrowser(clean, settings);
      } else {
        settings.voiceProvider = "kokoro";
        settings.kokoroEnabled = true;
        saveSettings(settings);
        await speakWithKokoro(clean, settings);
      }
    } catch (error) {
      console.warn("[companion] voice failed", error);
      loadMessages();
      addMessage("assistant", browserSpeechSupported()
        ? "Browser voice failed. Click Enable Voice and try again."
        : "Browser voice is not supported and Kokoro fallback is not available yet.");
    } finally {
      const latestSettings = normalizeVoiceSettings(loadSettings());
      if (latestSettings.autoListen) {
        startListening();
      } else {
        setSolState("listening");
      }
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

    if (action === "enable-voice") return enableVoice();
    if (action === "disable-voice") return disableVoice();
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

  /* Companion Browser Voice R3D change handler */
  document.addEventListener("change", function (event) {
    if (!event.target || !event.target.matches("#companionBrowserVoiceSelect")) return;

    const settings = normalizeVoiceSettings(loadSettings());
    settings.browserVoiceURI = event.target.value || "";

    const selected = selectedBrowserVoice(settings);
    settings.browserVoiceName = selected ? selected.name || "" : "";

    saveSettings(settings);
  });

  if (browserSpeechSupported()) {
    try {
      browserVoices = window.speechSynthesis.getVoices() || [];

      const refreshVoices = function () {
        browserVoices = window.speechSynthesis.getVoices() || [];
        if (byId("companionBrowserVoiceSelect")) render();
      };

      if (typeof window.speechSynthesis.addEventListener === "function") {
        window.speechSynthesis.addEventListener("voiceschanged", refreshVoices);
      } else {
        window.speechSynthesis.onvoiceschanged = refreshVoices;
      }
    } catch (_) {}
  }

})();
