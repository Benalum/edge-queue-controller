#!/usr/bin/env bash
set -euo pipefail

EXECUTOR="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-current-file-write-executor.js"
WRITER="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-current-file-save-writer.js"
BUILDER="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-sanitized-payload-builder.js"
SNAPSHOT="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-sanitized-snapshot-output-helper.js"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
MOUNT="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-mount.js"
PANEL="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-panel.js"
DOC="docs/stage-17k-r13x-current-backup-write-executor-source-only.md"
OUT_DIR="docs/smoke/generated/stage-17k-r13x-current-backup-write-executor-source-only"

test -f "$EXECUTOR"
test -f "$WRITER"
test -f "$BUILDER"
test -f "$SNAPSHOT"
test -f "$DOC"
test -d "$OUT_DIR"

grep -Fq "APC_LOCAL_BACKUP_CURRENT_FILE_WRITE_EXECUTOR_R13X_SOURCE_ONLY" "$EXECUTOR"
grep -Fq "R13X_EXPLICIT_CURRENT_BACKUP_WRITE_ENABLE" "$EXECUTOR"
grep -Fq "buddies-who-study-current.json" "$EXECUTOR"
grep -Fq "buddies-who-study-current.previous.json" "$EXECUTOR"
grep -Fq "executeCurrentBackupWrite" "$EXECUTOR"
grep -Fq "createCurrentBackupWriteExecutionPlan" "$EXECUTOR"
grep -Fq "enableWrite !== true" "$EXECUTOR"
grep -Fq "enableToken !== ENABLE_TOKEN" "$EXECUTOR"
grep -Fq "confirmSelectedFileName !== CURRENT_FILE_NAME" "$EXECUTOR"
grep -Fq "createWritable" "$EXECUTOR"
grep -Fq ".write(" "$EXECUTOR"
grep -Fq ".close(" "$EXECUTOR"
grep -Fq "validateSanitizedReadbackText" "$EXECUTOR"

grep -Fq "Current Backup Write Executor Source-Only" "$DOC"
grep -Fq "No deploy" "$DOC"
grep -Fq "No live UI change" "$DOC"
grep -Fq "No real file write" "$DOC"
grep -Fq "fake in-memory file handles" "$DOC"
grep -Fq "No current-file save in live UI" "$DOC"
grep -Fq "No same-file write path in live UI" "$DOC"

if grep -Fq "/privatepages/local-backup-current-file-write-executor.js" "$INDEX"; then
  echo "FAIL: executor must not be loaded by index.html"
  exit 1
fi

if grep -Fq "APC_LOCAL_BACKUP_CURRENT_FILE_WRITE_EXECUTOR" "$MOUNT" "$PANEL"; then
  echo "FAIL: executor must not be reachable from live mount or panel"
  exit 1
fi

if grep -Eq "fetch\\(|XMLHttpRequest|sendBeacon|localStorage\\.setItem|sessionStorage\\.setItem|indexedDB" "$EXECUTOR"; then
  echo "FAIL: executor contains forbidden network/storage API"
  exit 1
fi

if grep -Eq "showSaveFilePicker|showDirectoryPicker" "$EXECUTOR"; then
  echo "FAIL: executor must not prompt for file/directory selection"
  exit 1
fi

if command -v node >/dev/null 2>&1; then
  node --check "$EXECUTOR"
  node --check "$WRITER"
  node --check "$BUILDER"
  node --check "$SNAPSHOT"
  node - <<'NODE'
const builder = require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-sanitized-payload-builder.js");
globalThis.APC_LOCAL_BACKUP_SANITIZED_PAYLOAD_BUILDER = builder;

const snapshot = require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-sanitized-snapshot-output-helper.js");
globalThis.APC_LOCAL_BACKUP_SANITIZED_SNAPSHOT_OUTPUT = snapshot;

const writer = require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-current-file-save-writer.js");
globalThis.APC_LOCAL_BACKUP_CURRENT_FILE_SAVE_WRITER = writer;

const executor = require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-current-file-write-executor.js");

class FakeFileHandle {
  constructor(name, text) {
    this.name = name;
    this.textValue = text || "";
  }

  async getFile() {
    return {
      text: async () => this.textValue
    };
  }

  async createWritable() {
    const self = this;
    let buffer = "";
    return {
      write: async (text) => {
        buffer += String(text || "");
      },
      close: async () => {
        self.textValue = buffer;
      }
    };
  }
}

class FakeDirectoryHandle {
  constructor() {
    this.files = {};
  }

  async getFileHandle(name, options) {
    if (!this.files[name]) {
      if (!options || options.create !== true) throw new Error("missing file: " + name);
      this.files[name] = new FakeFileHandle(name, "");
    }
    return this.files[name];
  }
}

const payload = {
  kind: "buddies-who-study-local-backup",
  version: 2,
  privacy: {
    serverUpload: true,
    uploadsToServer: true,
    localOnly: false,
    ankiSourceMutation: true,
    sourceMutation: true
  },
  docs: {
    "study/decks/v1": { decks: [{ id: "deck-1" }, { id: "deck-2" }] },
    "study/cards/v1": { cards: [{ id: "card-1" }, { id: "card-2" }] },
    "study/sessions/v1": { recentSessions: Array.from({ length: 16 }, (_, i) => ({ id: String(i + 1) })) },
    "study/media-manifest/v1": { mediaCount: 0, totalBytes: 0 },
    "study/store-state/v1": {
      state: {
        version: "study-store-v2",
        activeDeckId: "deck-1",
        decks: [],
        cards: [],
        sessions: [],
        runtime: null,
        backendProgress: { legacy: true },
        backendReviewSummary: { legacy: true },
        backendSessions: { legacy: true },
        backendSyncedAt: "2026-07-01T03:04:16.458Z"
      }
    }
  }
};

const current = new FakeFileHandle("buddies-who-study-current.json", "OLD_CURRENT_BACKUP_TEXT");
const directory = new FakeDirectoryHandle();

const plan = executor.createCurrentBackupWriteExecutionPlan({
  selectedFileName: "buddies-who-study-current.json",
  currentFileHandle: current,
  directoryHandle: directory,
  payload
}, {
  createdAt: "2026-07-05T23:55:00.000Z"
});

if (plan.selectedFileAllowed !== true) throw new Error("selected file should be allowed");
if (plan.currentFileHandleAllowed !== true) throw new Error("current handle should be allowed");
if (plan.writerPlanReady !== true) throw new Error("writer plan should be ready");
if (plan.defaultWritesEnabled !== false) throw new Error("default writes should be disabled");
if (plan.canExecuteWithoutExplicitToken !== false) throw new Error("explicit token should be required");
if (plan.requiredEnableToken !== "R13X_EXPLICIT_CURRENT_BACKUP_WRITE_ENABLE") throw new Error("wrong enable token");
if (plan.removedFieldCount !== 4) throw new Error("expected 4 removed legacy fields");
if (plan.afterLegacyFieldPaths.length !== 0) throw new Error("after legacy fields should be empty");
if (!plan.sanitizedJsonText || plan.sanitizedJsonText.includes("backendProgress")) throw new Error("sanitized text still has backendProgress");

executor.executeCurrentBackupWrite({
  selectedFileName: "buddies-who-study-current.json",
  currentFileHandle: current,
  directoryHandle: directory,
  payload
}, {
  createdAt: "2026-07-05T23:55:00.000Z"
}).then(async (refused) => {
  if (refused.executed !== false) throw new Error("write without token must not execute");
  if (refused.refused !== true) throw new Error("write without token should be refused");
  if (!refused.errors.some((msg) => msg.includes("enableWrite is not true"))) throw new Error("missing enableWrite refusal");

  const executed = await executor.executeCurrentBackupWrite({
    selectedFileName: "buddies-who-study-current.json",
    currentFileHandle: current,
    directoryHandle: directory,
    payload
  }, {
    createdAt: "2026-07-05T23:55:00.000Z",
    enableWrite: true,
    enableToken: "R13X_EXPLICIT_CURRENT_BACKUP_WRITE_ENABLE",
    confirmSelectedFileName: "buddies-who-study-current.json"
  });

  if (executed.executed !== true) throw new Error("guarded fake write should execute");
  if (executed.wrotePrevious !== true) throw new Error("previous file should be written");
  if (executed.wroteCurrent !== true) throw new Error("current file should be written");
  if (executed.readbackVerified !== true) throw new Error("readback should be verified");
  if (executed.readbackLegacyFieldPaths.length !== 0) throw new Error("readback should not have legacy fields");
  if (!directory.files["buddies-who-study-current.previous.json"]) throw new Error("previous handle missing");
  if (directory.files["buddies-who-study-current.previous.json"].textValue !== "OLD_CURRENT_BACKUP_TEXT") {
    throw new Error("previous file did not receive old current contents");
  }
  if (!current.textValue.includes('"serverUpload": false')) throw new Error("current did not receive sanitized privacy");
  if (current.textValue.includes("backendProgress")) throw new Error("current still has backendProgress");
  if (JSON.parse(current.textValue).kind !== "buddies-who-study-local-backup") throw new Error("current kind mismatch");

  const wrongName = executor.createCurrentBackupWriteExecutionPlan({
    selectedFileName: "buddies-who-study-local-backup-v2-test.json",
    currentFileHandle: current,
    directoryHandle: directory,
    payload
  }, {
    createdAt: "2026-07-05T23:55:00.000Z"
  });

  if (wrongName.selectedFileAllowed !== false) throw new Error("wrong selected file should be refused");
  if (!wrongName.errors.some((msg) => msg.includes("Selected file must be buddies-who-study-current.json"))) {
    throw new Error("wrong selected file refusal missing");
  }

  console.log("PASS node R13X current backup write executor source-only fake-handle behavior smoke");
}).catch((error) => {
  console.error(error);
  process.exit(1);
});
NODE
fi

echo "PASS stage-17k-r13x current backup write executor source-only smoke"
