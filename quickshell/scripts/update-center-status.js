#!/run/current-system/sw/bin/node

const fs = require("fs");
const path = require("path");
const os = require("os");
const { spawnSync } = require("child_process");

const HOME = process.env.HOME || os.homedir();
const dotfiles = path.join(HOME, "dotfiles");
const cacheDir = path.join(HOME, ".cache", "strata", "update-center");
const statusPath = path.join(cacheDir, "status.json");
const logPath = path.join(cacheDir, "update.log");
const flakeLockPath = path.join(dotfiles, "flake.lock");
const appcenterCatalogPath = path.join(HOME, ".cache", "strata", "appcenter", "catalog.json");
const appcenterStatusPath = path.join(HOME, ".cache", "strata", "appcenter", "rebuild-status.txt");
const releaseConfPath = "/etc/strata-release.conf";

const host = detectHost();
const channel = host === "desktop" ? "main" : "stable";
const mode = host === "desktop" ? "local" : "release";
const previous = readJson(statusPath);
const gitDirty = detectGitDirty(dotfiles);
const currentBranch = detectGitBranch(dotfiles);
const lastLockAt = statMtime(flakeLockPath);
const pendingApps = detectPendingApps(appcenterCatalogPath);
const rebuildPending = detectAppCenterRebuildPending(appcenterStatusPath) || pendingApps > 0;
const configuredRepo = readReleaseRepo(releaseConfPath);
const upstreamInfo = mode === "release"
  ? detectReleaseUpdate(configuredRepo, channel)
  : detectBranchUpdate(dotfiles, currentBranch);
const lastSuccessAt = previous && previous.lastSuccessAt ? previous.lastSuccessAt : null;
const flakeLockChanged = !!(lastSuccessAt && lastLockAt && new Date(lastLockAt).getTime() > new Date(lastSuccessAt).getTime());
const localChangesAvailable = mode === "local" && (flakeLockChanged || pendingApps > 0);
const blockedReason = mode === "local" && gitDirty
  ? "A worktree local esta alterada. Commit ou stash antes de atualizar o sistema."
  : "";
const rebootState = detectRebootState();

let payload = {
  host,
  channel,
  mode,
  status: "clean",
  summaryCount: 0,
  currentStep: "idle",
  currentStepLabel: mode === "release"
    ? "Pronto para verificar e aplicar a release do Strata."
    : "Pronto para aplicar o rebuild local do sistema.",
  rebuildRequired: false,
  pendingApps,
  gitDirty,
  currentBranch,
  flakeLockChanged,
  releaseUpdateAvailable: mode === "release" && !!upstreamInfo.available,
  upstreamUpdateAvailable: !!upstreamInfo.available,
  upstreamSummary: upstreamInfo.summary || "",
  localChangesAvailable,
  blockedReason,
  rebootRecommended: rebootState.recommended,
  rebootReason: rebootState.reason,
  lastSuccessAt,
  lastLockAt,
  finishedAt: previous && previous.finishedAt ? previous.finishedAt : lastSuccessAt,
  startedAt: previous && previous.startedAt ? previous.startedAt : null,
  lastError: "",
  progressValue: 0,
  logPath,
  logPreview: buildLogPreview({
    mode,
    upstreamSummary: upstreamInfo.summary,
    localChangesAvailable,
    pendingApps,
    gitDirty,
    currentBranch,
    flakeLockChanged,
    lastSuccessAt,
    blockedReason,
    rebootReason: rebootState.reason
  })
};

if (previous && previous.status === "running") {
  payload = {
    ...payload,
    ...previous,
    host,
    channel,
    mode,
    currentBranch,
    gitDirty,
    flakeLockChanged,
    pendingApps,
    releaseUpdateAvailable: mode === "release" && !!upstreamInfo.available,
    upstreamUpdateAvailable: !!upstreamInfo.available,
    upstreamSummary: upstreamInfo.summary || "",
    localChangesAvailable,
    blockedReason,
    rebootRecommended: rebootState.recommended,
    rebootReason: rebootState.reason,
    logPreview: tailLog(logPath, 4)
  };
  writeAndPrint(payload);
  process.exit(0);
}

if (previous && previous.status === "error" && !hasNewerSuccess(previous.lastFailureAt, previous.lastSuccessAt)) {
  payload.status = "error";
  payload.currentStep = previous.currentStep || "switch";
  payload.currentStepLabel = previous.currentStepLabel || "A última tentativa falhou.";
  payload.lastError = previous.lastError || "A última atualização falhou.";
  payload.finishedAt = previous.finishedAt || payload.finishedAt;
  payload.lastFailureAt = previous.lastFailureAt || payload.finishedAt;
  payload.progressValue = previous.progressValue !== undefined ? previous.progressValue : progressForStep(payload.currentStep);
  payload.summaryCount = summarizeCount({
    flakeLockChanged,
    pendingApps,
    upstreamAvailable: !!upstreamInfo.available
  });
  payload.rebuildRequired = payload.summaryCount > 0 || rebuildPending;
  payload.logPreview = tailLog(logPath, 4);
  writeAndPrint(payload);
  process.exit(0);
}

const summaryCount = summarizeCount({
  flakeLockChanged,
  pendingApps,
  upstreamAvailable: !!upstreamInfo.available
});

payload.summaryCount = summaryCount;
payload.rebuildRequired = summaryCount > 0 || rebuildPending;

if (summaryCount > 0) {
  payload.status = "updates";
}

if (payload.status === "updates") {
  if (blockedReason) {
    payload.currentStepLabel = blockedReason;
  } else {
    payload.currentStepLabel = mode === "release"
      ? "A release configurada para este host pode ser aplicada diretamente deste painel."
      : "O painel separa upstream remoto de mudancas locais prontas para rebuild.";
  }
}

writeAndPrint(payload);

function writeAndPrint(data) {
  fs.mkdirSync(cacheDir, { recursive: true });
  fs.writeFileSync(statusPath, JSON.stringify(data, null, 2) + "\n", "utf8");
  process.stdout.write(JSON.stringify(data) + "\n");
}

function detectHost() {
  const result = spawnSync("hostname", [], { encoding: "utf8" });
  return (result.stdout || "").trim() || "desktop";
}

function detectGitDirty(repo) {
  const result = spawnSync("git", [
    "-C", repo,
    "status",
    "--porcelain",
    "--",
    ".",
    ":(exclude)codex memories/**"
  ], { encoding: "utf8" });
  return result.status === 0 && (result.stdout || "").trim() !== "";
}

function detectGitBranch(repo) {
  const result = spawnSync("git", ["-C", repo, "branch", "--show-current"], { encoding: "utf8" });
  return result.status === 0 ? ((result.stdout || "").trim() || "-") : "-";
}

function detectPendingApps(catalogPath) {
  const catalog = readJson(catalogPath);
  if (!Array.isArray(catalog)) return 0;
  return catalog.filter(item => item && item.source === "nix" && item.managed === true && item.installed !== true).length;
}

function detectAppCenterRebuildPending(filePath) {
  try {
    const raw = fs.readFileSync(filePath, "utf8");
    return raw.includes("running") || raw.includes("opening");
  } catch {
    return false;
  }
}

function detectReleaseUpdate(repoName, channel) {
  const curl = spawnSync("/run/current-system/sw/bin/curl", [
    "-sf",
    `https://api.github.com/repos/${repoName}/commits/${channel}`
  ], {
    encoding: "utf8",
    timeout: 2500
  });

  if (curl.status !== 0) {
    return { available: false, summary: "" };
  }

  const match = (curl.stdout || "").match(/"sha"\s*:\s*"([a-f0-9]{7,40})"/i);
  const remoteSha = match ? match[1] : "";
  if (remoteSha === "") return { available: false, summary: "" };

  const cachePath = `/var/cache/strata-last-commit-${channel}`;
  const localSha = safeRead(cachePath).trim();
  return {
    available: localSha === "" || remoteSha !== localSha,
    summary: localSha === ""
      ? `github:${repoName}/${channel} ainda nao foi aplicado neste host.`
      : (remoteSha !== localSha ? `github:${repoName}/${channel} possui um commit novo.` : "")
  };
}

function detectBranchUpdate(repo, branch) {
  if (!branch || branch === "-") return { available: false, summary: "" };

  const remote = spawnSync("git", ["-C", repo, "ls-remote", "--heads", "origin", branch], {
    encoding: "utf8",
    timeout: 2500
  });

  if (remote.status !== 0) {
    return { available: false, summary: "" };
  }

  const remoteSha = ((remote.stdout || "").trim().split(/\s+/)[0] || "").trim();
  if (remoteSha === "") return { available: false, summary: "" };

  const local = spawnSync("git", ["-C", repo, "rev-parse", "HEAD"], { encoding: "utf8" });
  const localSha = (local.stdout || "").trim();
  return {
    available: localSha !== "" && remoteSha !== localSha,
    summary: localSha !== "" && remoteSha !== localSha
      ? `origin/${branch} difere do commit local deste host.`
      : ""
  };
}

function statMtime(filePath) {
  try {
    return fs.statSync(filePath).mtime.toISOString();
  } catch {
    return null;
  }
}

function readJson(filePath) {
  try {
    return JSON.parse(fs.readFileSync(filePath, "utf8"));
  } catch {
    return null;
  }
}

function safeRead(filePath) {
  try {
    return fs.readFileSync(filePath, "utf8");
  } catch {
    return "";
  }
}

function readReleaseRepo(filePath) {
  const raw = safeRead(filePath);
  const match = raw.match(/^\s*STRATA_UPDATE_REPO=(?:"([^"]+)"|'([^']+)'|([^\s#]+))/m);
  return (match && (match[1] || match[2] || match[3])) || "PedroAugustoOK/Strata-Habitus";
}

function detectRebootState() {
  const booted = realpath("/run/booted-system");
  const current = realpath("/nix/var/nix/profiles/system");
  if (booted !== "" && current !== "" && booted !== current) {
    return {
      recommended: true,
      reason: "Uma geracao mais nova ja foi ativada. Reinicie para entrar no sistema atualizado."
    };
  }
  return { recommended: false, reason: "" };
}

function realpath(target) {
  const result = spawnSync("readlink", ["-f", target], { encoding: "utf8" });
  return result.status === 0 ? (result.stdout || "").trim() : "";
}

function tailLog(filePath, count) {
  try {
    const lines = fs.readFileSync(filePath, "utf8").trim().split(/\r?\n/).filter(Boolean);
    return lines.slice(-count);
  } catch {
    return [];
  }
}

function buildLogPreview(input) {
  const lines = [];
  if (input.mode === "release") {
    lines.push("modo release ativo para este host");
    if (input.upstreamSummary) lines.push(input.upstreamSummary);
  } else {
    lines.push("modo local ativo para o ambiente de desenvolvimento");
    lines.push("branch atual: " + input.currentBranch);
    if (input.upstreamSummary) lines.push(input.upstreamSummary);
    if (input.localChangesAvailable) lines.push("estado local pronto para rebuild");
  }
  if (input.pendingApps > 0) lines.push(input.pendingApps + " apps aguardando rebuild do App Center");
  if (input.flakeLockChanged) lines.push("flake.lock mudou desde o último sucesso");
  if (input.gitDirty) lines.push("worktree local contém alterações");
  if (input.blockedReason) lines.push("update bloqueado ate limpar a worktree");
  if (input.rebootReason) lines.push(input.rebootReason);
  if (lines.length === 0 && input.lastSuccessAt) lines.push("último sucesso registrado em " + input.lastSuccessAt);
  return lines.slice(0, 4);
}

function summarizeCount(input) {
  let count = 0;
  if (input.flakeLockChanged) count += 1;
  if (input.pendingApps > 0) count += 1;
  if (input.upstreamAvailable) count += 1;
  return count;
}

function progressForStep(stepKey) {
  if (stepKey === "inputs") return 0.16;
  if (stepKey === "build") return 0.46;
  if (stepKey === "switch") return 0.77;
  if (stepKey === "refresh") return 0.94;
  return 0;
}

function hasNewerSuccess(lastFailureAt, lastSuccessAt) {
  if (!lastFailureAt || !lastSuccessAt) return false;
  return new Date(lastSuccessAt).getTime() >= new Date(lastFailureAt).getTime();
}
