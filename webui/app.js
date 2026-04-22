(function () {
  "use strict";

  var state = {
    ws: null,
    nextCorrId: 1,
    pending: new Map(),
    user: null,
    contacts: [],
    selectedContactId: null,
    messagesByContactId: new Map(),
    currentAddress: "",
    pendingContactRequest: null,
  };

  var els = {
    setupScreen: byId("setup-screen"),
    app: byId("app"),
    setupError: byId("setup-error"),
    displayName: byId("display-name"),
    fullName: byId("full-name"),
    createProfileBtn: byId("create-profile-btn"),
    userName: byId("user-name"),
    userAvatar: byId("user-avatar"),
    contactSearch: byId("contact-search"),
    contactList: byId("contact-list"),
    emptyState: byId("empty-state"),
    chatView: byId("chat-view"),
    chatAvatar: byId("chat-avatar"),
    chatName: byId("chat-name"),
    chatStatus: byId("chat-status"),
    messagesList: byId("messages-list"),
    messagesContainer: byId("messages-container"),
    messageInput: byId("message-input"),
    sendBtn: byId("send-btn"),
    statusText: byId("status-text"),
    showAddressBtn: byId("show-address-btn"),
    connectBtn: byId("connect-btn"),
    addressModal: byId("address-modal"),
    connectModal: byId("connect-modal"),
    closeAddressModal: byId("close-address-modal"),
    closeConnectModal: byId("close-connect-modal"),
    addressText: byId("address-text"),
    copyAddressBtn: byId("copy-address-btn"),
    createAddressBtn: byId("create-address-btn"),
    noAddressMsg: byId("no-address-msg"),
    qrcodeCanvas: byId("qrcode-canvas"),
    connectLink: byId("connect-link"),
    connectSubmitBtn: byId("connect-submit-btn"),
    connectError: byId("connect-error"),
    connectSuccess: byId("connect-success"),
    contactRequestBar: byId("contact-request-bar"),
    contactRequestText: byId("contact-request-text"),
    acceptRequestBtn: byId("accept-request-btn"),
    rejectRequestBtn: byId("reject-request-btn"),
  };

  setupEvents();
  connectWebSocket();

  function setupEvents() {
    els.createProfileBtn.addEventListener("click", createProfile);
    els.contactSearch.addEventListener("input", renderContacts);
    els.sendBtn.addEventListener("click", sendMessage);
    els.messageInput.addEventListener("keydown", function (e) {
      if (e.key === "Enter" && !e.shiftKey) {
        e.preventDefault();
        sendMessage();
      }
    });

    els.showAddressBtn.addEventListener("click", openAddressModal);
    els.connectBtn.addEventListener("click", openConnectModal);
    els.closeAddressModal.addEventListener("click", function () {
      hide(els.addressModal);
    });
    els.closeConnectModal.addEventListener("click", function () {
      hide(els.connectModal);
    });
    els.copyAddressBtn.addEventListener("click", copyAddress);
    els.createAddressBtn.addEventListener("click", createAddress);
    els.connectSubmitBtn.addEventListener("click", connectViaLink);
    els.acceptRequestBtn.addEventListener("click", acceptContactRequest);
    els.rejectRequestBtn.addEventListener("click", rejectContactRequest);
  }

  function connectWebSocket() {
    setStatus("Connecting...");
    var scheme = window.location.protocol === "https:" ? "wss" : "ws";
    var endpoint = scheme + "://" + window.location.host + "/ws";

    var ws = new WebSocket(endpoint);
    state.ws = ws;

    ws.onopen = function () {
      setStatus("Connected");
      bootstrap();
    };

    ws.onmessage = function (event) {
      handleSocketMessage(event.data);
    };

    ws.onclose = function () {
      setStatus("Disconnected. Reconnecting...");
      failAllPending("WebSocket disconnected");
      window.setTimeout(connectWebSocket, 1500);
    };

    ws.onerror = function () {
      setStatus("Connection error");
    };
  }

  async function bootstrap() {
    try {
      var resp = await sendCommand("/user");
      if (isType(resp, "activeUser")) {
        applyActiveUser(resp.user);
      } else {
        showSetup("No active user profile. Create one to continue.");
      }
    } catch (e) {
      showSetup("No active user profile. Create one to continue.");
    }
  }

  async function createProfile() {
    clearSetupError();

    var displayName = els.displayName.value.trim();
    var fullName = els.fullName.value.trim();
    if (!displayName) {
      showSetupError("Display name is required.");
      return;
    }

    var payload = {
      profile: {
        displayName: displayName,
        fullName: fullName,
      },
      pastTimestamp: false,
    };

    try {
      var resp = await sendCommand("/_create user " + JSON.stringify(payload));
      if (isType(resp, "activeUser")) {
        applyActiveUser(resp.user);
      } else {
        showSetupError(extractError(resp) || "Failed to create profile.");
      }
    } catch (e) {
      showSetupError(e.message || "Failed to create profile.");
    }
  }

  function applyActiveUser(user) {
    state.user = user;
    var name = user && user.profile ? user.profile.displayName : "Unknown";
    els.userName.textContent = name;
    els.userAvatar.textContent = firstLetter(name);

    hide(els.setupScreen);
    show(els.app);

    loadContacts();
    refreshAddress();
  }

  async function loadContacts() {
    if (!state.user || !state.user.userId) {
      return;
    }

    try {
      var resp = await sendCommand("/_contacts " + state.user.userId);
      if (isType(resp, "contactsList")) {
        state.contacts = Array.isArray(resp.contacts) ? resp.contacts : [];
        renderContacts();
      }
    } catch (_e) {
      // Contact list can be refreshed by later responses/events.
    }
  }

  function renderContacts() {
    var filter = els.contactSearch.value.trim().toLowerCase();
    var contacts = state.contacts.filter(function (c) {
      if (!filter) {
        return true;
      }
      var name = (c.localDisplayName || "").toLowerCase();
      var fullName = c.profile && c.profile.fullName ? c.profile.fullName.toLowerCase() : "";
      return name.indexOf(filter) >= 0 || fullName.indexOf(filter) >= 0;
    });

    els.contactList.innerHTML = "";

    if (!contacts.length) {
      els.contactList.innerHTML = '<div class="loading-state">No contacts yet</div>';
      return;
    }

    contacts.forEach(function (contact) {
      var item = document.createElement("div");
      item.className = "contact-item" + (state.selectedContactId === contact.contactId ? " active" : "");
      item.addEventListener("click", function () {
        selectContact(contact.contactId);
      });

      var avatar = document.createElement("div");
      avatar.className = "avatar";
      avatar.textContent = firstLetter(contact.localDisplayName);

      var right = document.createElement("div");
      right.style.minWidth = "0";
      right.style.width = "100%";

      var main = document.createElement("div");
      main.className = "contact-main";
      var name = document.createElement("span");
      name.className = "user-name";
      name.textContent = contact.localDisplayName;
      var status = document.createElement("span");
      status.className = "contact-meta";
      status.textContent = contact.contactStatus || "active";
      main.appendChild(name);
      main.appendChild(status);

      right.appendChild(main);
      item.appendChild(avatar);
      item.appendChild(right);
      els.contactList.appendChild(item);
    });
  }

  function selectContact(contactId) {
    state.selectedContactId = contactId;
    renderContacts();

    var contact = findContact(contactId);
    if (!contact) {
      return;
    }

    hide(els.emptyState);
    show(els.chatView);

    els.chatName.textContent = contact.localDisplayName;
    els.chatAvatar.textContent = firstLetter(contact.localDisplayName);
    els.chatStatus.textContent = contact.contactStatus || "active";

    renderMessages(contactId);
  }

  function renderMessages(contactId) {
    var list = state.messagesByContactId.get(contactId) || [];
    els.messagesList.innerHTML = "";

    list.forEach(function (m) {
      var item = document.createElement("div");
      item.className = "message" + (m.isOwn ? " own" : "");

      var text = document.createElement("div");
      text.textContent = m.text;

      var meta = document.createElement("span");
      meta.className = "meta";
      meta.textContent = m.time;

      item.appendChild(text);
      item.appendChild(meta);
      els.messagesList.appendChild(item);
    });

    els.messagesContainer.scrollTop = els.messagesContainer.scrollHeight;
  }

  async function sendMessage() {
    var text = els.messageInput.value.trim();
    if (!text || !state.selectedContactId) {
      return;
    }

    var composedMessages = [
      {
        msgContent: {
          type: "text",
          text: text,
        },
        mentions: {},
      },
    ];

    var cmd = "/_send @" + state.selectedContactId + " json " + JSON.stringify(composedMessages);

    try {
      var resp = await sendCommand(cmd);
      if (isType(resp, "newChatItems")) {
        consumeChatItems(resp.chatItems);
      } else if (isType(resp, "chatCmdError")) {
        showTransientMessage(extractError(resp) || "Send failed.");
      }
    } catch (e) {
      showTransientMessage(e.message || "Send failed.");
    }

    els.messageInput.value = "";
  }

  function handleSocketMessage(raw) {
    var message;
    try {
      message = JSON.parse(raw);
    } catch (_e) {
      return;
    }

    var payload = message.resp || {};

    if (message.corrId) {
      var pending = state.pending.get(message.corrId);
      if (pending) {
        state.pending.delete(message.corrId);
        pending.resolve(payload);
      }
    } else {
      handleEvent(payload);
    }
  }

  function handleEvent(payload) {
    if (!payload || typeof payload !== "object") {
      return;
    }

    if (isType(payload, "newChatItems")) {
      consumeChatItems(payload.chatItems);
      return;
    }

    if (isType(payload, "receivedContactRequest")) {
      state.pendingContactRequest = payload.contactRequest || null;
      renderContactRequest();
      return;
    }

    if (isType(payload, "contactConnected") || isType(payload, "contactUpdated")) {
      loadContacts();
    }
  }

  function consumeChatItems(chatItems) {
    if (!Array.isArray(chatItems)) {
      return;
    }

    chatItems.forEach(function (entry) {
      var info = entry && entry.chatInfo ? entry.chatInfo : {};
      if (info.type !== "direct" || !info.contact || !info.contact.contactId) {
        return;
      }

      var contact = info.contact;
      upsertContact(contact);

      var msg = normalizeMessage(entry);
      if (!msg) {
        return;
      }

      var bucket = state.messagesByContactId.get(contact.contactId) || [];
      bucket.push(msg);
      state.messagesByContactId.set(contact.contactId, bucket);

      if (state.selectedContactId === contact.contactId) {
        renderMessages(contact.contactId);
      }
    });
  }

  function normalizeMessage(chatItemEnvelope) {
    var chatItem = chatItemEnvelope && chatItemEnvelope.chatItem ? chatItemEnvelope.chatItem : null;
    if (!chatItem || !chatItem.content) {
      return null;
    }

    var msgContent = chatItem.content.msgContent || null;
    var text;
    if (msgContent && typeof msgContent.text === "string") {
      text = msgContent.text;
    } else {
      text = "[" + (chatItem.content.type || "event") + "]";
    }

    var dir = chatItem.chatDir && chatItem.chatDir.type ? chatItem.chatDir.type : "";
    var isOwn = dir === "directSnd" || dir === "groupSnd" || dir === "localSnd";

    return {
      text: text,
      isOwn: isOwn,
      time: formatTime(chatItem.meta && chatItem.meta.itemTs),
    };
  }

  async function refreshAddress() {
    if (!state.user || !state.user.userId) {
      return;
    }

    try {
      var resp = await sendCommand("/_show_address " + state.user.userId);
      if (isType(resp, "userContactLink") && resp.contactLink && resp.contactLink.connLinkContact) {
        state.currentAddress = resp.contactLink.connLinkContact.connFullLink || "";
      } else {
        state.currentAddress = "";
      }
    } catch (_e) {
      state.currentAddress = "";
    }

    renderAddress();
  }

  function renderAddress() {
    els.addressText.value = state.currentAddress || "";
    if (!state.currentAddress) {
      show(els.noAddressMsg);
      els.qrcodeCanvas.width = 0;
      els.qrcodeCanvas.height = 0;
      return;
    }

    hide(els.noAddressMsg);
    if (window.QRCode) {
      if (typeof window.QRCode.toCanvas === "function") {
        window.QRCode.toCanvas(
          els.qrcodeCanvas,
          state.currentAddress,
          {
            margin: 2,
            width: 216,
            errorCorrectionLevel: "M",
          },
          function (_err) {
            // Keep UI usable even if QR rendering fails.
          }
        );
      } else {
        new window.QRCode(els.qrcodeCanvas, state.currentAddress);
      }
    }
  }

  async function createAddress() {
    if (!state.user || !state.user.userId) {
      return;
    }

    try {
      var resp = await sendCommand("/_address " + state.user.userId);
      if (isType(resp, "userContactLinkCreated")) {
        state.currentAddress = resp.connLinkContact ? resp.connLinkContact.connFullLink : "";
      }
      await refreshAddress();
    } catch (e) {
      showTransientMessage(e.message || "Failed to create address.");
    }
  }

  async function connectViaLink() {
    hide(els.connectError);
    hide(els.connectSuccess);

    var link = els.connectLink.value.trim();
    if (!link) {
      els.connectError.textContent = "Please paste a link.";
      show(els.connectError);
      return;
    }

    try {
      var resp = await sendCommand("/connect " + link);
      if (isType(resp, "chatCmdError")) {
        els.connectError.textContent = extractError(resp) || "Failed to connect.";
        show(els.connectError);
        return;
      }

      els.connectSuccess.textContent = "Connection command sent.";
      show(els.connectSuccess);
      loadContacts();
    } catch (e) {
      els.connectError.textContent = e.message || "Failed to connect.";
      show(els.connectError);
    }
  }

  async function acceptContactRequest() {
    if (!state.pendingContactRequest || !state.pendingContactRequest.contactRequestId) {
      return;
    }

    var id = state.pendingContactRequest.contactRequestId;
    try {
      await sendCommand("/_accept " + id);
      state.pendingContactRequest = null;
      renderContactRequest();
      loadContacts();
    } catch (e) {
      showTransientMessage(e.message || "Failed to accept request.");
    }
  }

  async function rejectContactRequest() {
    if (!state.pendingContactRequest || !state.pendingContactRequest.contactRequestId) {
      return;
    }

    var id = state.pendingContactRequest.contactRequestId;
    try {
      await sendCommand("/_reject " + id);
      state.pendingContactRequest = null;
      renderContactRequest();
    } catch (e) {
      showTransientMessage(e.message || "Failed to reject request.");
    }
  }

  function renderContactRequest() {
    var req = state.pendingContactRequest;
    if (!req) {
      hide(els.contactRequestBar);
      return;
    }

    var name = req.localDisplayName || (req.profile && req.profile.displayName) || "Unknown";
    els.contactRequestText.textContent = "Incoming contact request from " + name;
    show(els.contactRequestBar);
  }

  function openAddressModal() {
    refreshAddress();
    show(els.addressModal);
  }

  function openConnectModal() {
    hide(els.connectError);
    hide(els.connectSuccess);
    show(els.connectModal);
  }

  function copyAddress() {
    if (!state.currentAddress) {
      return;
    }

    navigator.clipboard
      .writeText(state.currentAddress)
      .then(function () {
        showTransientMessage("Address copied.");
      })
      .catch(function () {
        showTransientMessage("Copy failed.");
      });
  }

  function showSetup(message) {
    show(els.setupScreen);
    hide(els.app);
    if (message) {
      showSetupError(message);
    } else {
      clearSetupError();
    }
  }

  function showSetupError(message) {
    els.setupError.textContent = message;
    show(els.setupError);
  }

  function clearSetupError() {
    els.setupError.textContent = "";
    hide(els.setupError);
  }

  function sendCommand(cmd) {
    if (!state.ws || state.ws.readyState !== WebSocket.OPEN) {
      return Promise.reject(new Error("WebSocket is not connected."));
    }

    var corrId = String(state.nextCorrId++);
    var payload = {
      corrId: corrId,
      cmd: cmd,
    };

    return new Promise(function (resolve, reject) {
      var timeout = window.setTimeout(function () {
        state.pending.delete(corrId);
        reject(new Error("Command timeout."));
      }, 20000);

      state.pending.set(corrId, {
        resolve: function (resp) {
          window.clearTimeout(timeout);
          resolve(resp);
        },
        reject: function (err) {
          window.clearTimeout(timeout);
          reject(err);
        },
      });

      state.ws.send(JSON.stringify(payload));
    });
  }

  function failAllPending(reason) {
    state.pending.forEach(function (pending) {
      pending.reject(new Error(reason));
    });
    state.pending.clear();
  }

  function showTransientMessage(message) {
    setStatus(message);
    window.setTimeout(function () {
      if (state.ws && state.ws.readyState === WebSocket.OPEN) {
        setStatus("Connected");
      }
    }, 1800);
  }

  function setStatus(text) {
    els.statusText.textContent = text;
  }

  function firstLetter(text) {
    if (!text) {
      return "?";
    }
    return text.charAt(0).toUpperCase();
  }

  function isType(obj, type) {
    return !!obj && obj.type === type;
  }

  function extractError(resp) {
    if (!resp) {
      return "";
    }
    var err = resp.chatError || {};
    if (typeof err === "string") {
      return err;
    }
    if (err.errorType && err.errorType.type) {
      return err.errorType.type;
    }
    if (err.agentError && err.agentError.type) {
      return err.agentError.type;
    }
    return err.type || "Unknown error";
  }

  function formatTime(value) {
    if (!value) {
      return "";
    }
    var dt = new Date(value);
    if (isNaN(dt.getTime())) {
      return "";
    }
    return dt.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
  }

  function findContact(contactId) {
    for (var i = 0; i < state.contacts.length; i += 1) {
      if (state.contacts[i].contactId === contactId) {
        return state.contacts[i];
      }
    }
    return null;
  }

  function upsertContact(contact) {
    var updated = false;
    for (var i = 0; i < state.contacts.length; i += 1) {
      if (state.contacts[i].contactId === contact.contactId) {
        state.contacts[i] = contact;
        updated = true;
        break;
      }
    }
    if (!updated) {
      state.contacts.unshift(contact);
    }
    renderContacts();
  }

  function byId(id) {
    return document.getElementById(id);
  }

  function show(el) {
    el.classList.remove("hidden");
  }

  function hide(el) {
    el.classList.add("hidden");
  }
})();

