#!/usr/bin/env bash
set -euo pipefail

PLAN="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-stable-file-plan.js"
DOC="docs/stage-17k-r13c-stable-current-backup-file-plan-source-only.md"
OUT_DIR="docs/smoke/generated/stage-17k-r13c-stable-current-backup-file-plan-source-only"

test -f "$PLAN"
test -f "$DOC"
test -d "$OUT_DIR"

grep -Fq "APC_LOCAL_BACKUP_STABLE_FILE_PLAN_R13C_SOURCE_ONLY" "$PLAN"
grep -Fq "buddies-who-study-current.json" "$PLAN"
grep -Fq "buddies-who-study-current.previous.json" "$PLAN"
grep -Fq "snapshots" "$PLAN"
grep -Fq "canWrite: false" "$PLAN"
grep -Fq "writesEnabled: false" "$PLAN"
grep -Fq "overwriteExistingLocalData: false" "$PLAN"
grep -Fq "normalDownloadsMayCreateDuplicates: true" "$PLAN"
grep -Fq "stableFileUpdatesRequireUserSelectedFileOrFolder: true" "$PLAN"
grep -Fq 'replace(/>/g, "&gt;")' "$PLAN"

grep -Fq "Stable Current Backup File Plan Source-Only" "$DOC"
grep -Fq "buddies-who-study-current.json" "$DOC"
grep -Fq "No local Study restore write" "$DOC"
grep -Fq "No frontend deploy" "$DOC"
grep -Fq "R13D" "$DOC"

if grep -Eq "fetch\\(|XMLHttpRequest|sendBeacon|indexedDB|localStorage\\.setItem|sessionStorage\\.setItem|showSaveFilePicker|showDirectoryPicker|createWritable\\(" "$PLAN"; then
  echo "FAIL: stable file plan contains forbidden write/network API"
  exit 1
fi

if command -v node >/dev/null 2>&1; then
  node --check "$PLAN"
  node - <<'NODE'
globalThis.APC_LOCAL_BACKUP_MERGE_PLANNER = {
  createMergePlan: function createMergePlan() {
    return {
      ok: true,
      writeMode: "preview-only",
      canWrite: false,
      writesEnabled: false,
      warnings: [],
      errors: [],
      totals: {
        adds: 2,
        updates: 1,
        skips: 3,
        conflicts: 0
      }
    };
  }
};

const planApi = require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-stable-file-plan.js");

if (planApi.CURRENT_FILE_NAME !== "buddies-who-study-current.json") {
  throw new Error("stable current filename mismatch");
}
if (!planApi.isStableCurrentFileName("buddies-who-study-current.json")) {
  throw new Error("stable current filename not recognized");
}
if (!planApi.isSnapshotFileName("buddies-who-study-local-backup-v2-2026-07-02T01-08-17-924Z.json")) {
  throw new Error("snapshot filename not recognized");
}

const stable = planApi.classifyBackupFileName("buddies-who-study-current.json");
if (stable.role !== "stable-current") throw new Error("expected stable-current role");
if (stable.canBeMainMergeFile !== true) throw new Error("stable current should be main merge file");

const snap = planApi.classifyBackupFileName("buddies-who-study-local-backup-v2-2026-07-02T01-08-17-924Z.json");
if (snap.role !== "manual-snapshot") throw new Error("expected manual-snapshot role");
if (snap.canBeMainMergeFile !== false) throw new Error("snapshot should not be main merge file");

const plan = planApi.createStableCurrentFilePlan({
  selectedFileName: "buddies-who-study-local-backup-v2-2026-07-02T01-08-17-924Z.json",
  createdAt: "2026-07-02T01:08:17.924Z",
  currentPayload: {
    kind: "buddies-who-study-local-backup",
    version: 2,
    docs: {}
  },
  incomingPayload: {
    kind: "buddies-who-study-local-backup",
    version: 2,
    docs: {}
  }
});

if (plan.writeMode !== "plan-only") throw new Error("plan must be plan-only");
if (plan.canWrite !== false) throw new Error("plan canWrite must be false");
if (plan.writesEnabled !== false) throw new Error("plan writesEnabled must be false");
if (plan.normalCurrentFileName !== "buddies-who-study-current.json") throw new Error("normal current name mismatch");
if (plan.selectedFile.role !== "manual-snapshot") throw new Error("selected snapshot role mismatch");
if (plan.browserDownloadRule.normalDownloadsMayCreateDuplicates !== true) {
  throw new Error("browser duplicate rule missing");
}
if (plan.browserDownloadRule.stableFileUpdatesRequireUserSelectedFileOrFolder !== true) {
  throw new Error("stable file update rule missing");
}

const text = planApi.formatStableCurrentFilePlanText(plan);
if (!text.includes("Stable backup file plan")) throw new Error("missing text heading");
if (!text.includes("Normal file: buddies-who-study-current.json")) throw new Error("missing normal file text");

const html = planApi.formatStableCurrentFilePlanHtml({
  normalCurrentFileName: "buddies-who-study-current.json",
  selectedFile: { role: "stable-current", recommendation: "<ok>" },
  mergePlan: { totals: {} },
  futureFlow: ["> safety"]
});

if (!html.includes("&lt;ok&gt;")) throw new Error("HTML < escape failed");
if (!html.includes("&gt; safety")) throw new Error("HTML > escape failed");
if (!html.includes("data-apc-local-backup-stable-file-plan-preview")) {
  throw new Error("missing html marker");
}

console.log("PASS node R13C stable current backup file plan behavior smoke");
NODE
fi

echo "PASS stage-17k-r13c stable current backup file plan source-only smoke"
