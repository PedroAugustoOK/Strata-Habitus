#!/run/current-system/sw/bin/node

const fs = require("fs");
const path = require("path");
const os = require("os");
const { spawnSync, spawn } = require("child_process");

const HOME = process.env.HOME || os.homedir();
const dotfiles = path.join(HOME, "dotfiles");
const cacheDir = path.join(HOME, ".cache", "strata", "update-center");
const statusPath = path.join(cacheDir, "status.json");
const logPath = path.join(cacheDir, "update.log");
const host = detectHost();
const channel = host === "desktop" ? "main" : "stable";
const mode = host === "desktop" ? "local" : "release";
const kitty = "/run/current-system/sw/bin/kitty";
const bash = "/run/current-system/sw/bin/bash";
const statusScript = path.join(dotfiles, "quickshell", "scripts", "update-center-status.js");
const appcenterIndex = path.join(dotfiles, "quickshell", "scripts", "appcenter-index.js");
const launcherIndex = path.join(dotfiles, "quickshell", "scripts", "launcher-index.js");
const node = "/run/current-system/sw/bin/node";
const flake = `path:${dotfiles}#${host}`;
const currentBranch = detectBranch(dotfiles);
const gitDirty = detectGitDirty(dotfiles);

fs.mkdirSync(cacheDir, { recursive: true });
fs.writeFileSync(logPath, "", "utf8");

if (mode === "local" && gitDirty) {
  fail("A worktree local esta alterada. Commit ou stash antes de atualizar o sistema.");
}

writeStatus({
  host,
  channel,
  mode,
  status: "running",
  currentStep: "inputs",
  currentStepLabel: mode === "release"
    ? "Preparando o fluxo de release deste host."
    : "Preparando o rebuild local deste host.",
  startedAt: new Date().toISOString(),
  finishedAt: null,
  lastSuccessAt: readExistingSuccess(statusPath),
  lastFailureAt: null,
  progressValue: 0.16,
  summaryCount: 1,
  rebuildRequired: true,
  pendingApps: 0,
  currentBranch,
  gitDirty,
  flakeLockChanged: false,
  releaseUpdateAvailable: false,
  upstreamUpdateAvailable: false,
  upstreamSummary: "",
  localChangesAvailable: false,
  blockedReason: "",
  rebootRecommended: false,
  rebootReason: "",
  lastError: "",
  logPreview: ["preparando terminal de update"]
});

const shellCommand = buildCommand({
  host,
  channel,
  mode,
  dotfiles,
  cacheDir,
  statusPath,
  logPath,
  statusScript,
  appcenterIndex,
  launcherIndex,
  node,
  flake
});

const checkKitty = spawnSync(kitty, ["--version"], { encoding: "utf8" });
if (checkKitty.status !== 0) {
  fail("kitty não encontrado para abrir a atualização");
}

try {
  const child = spawn(kitty, [
    "--class",
    "strata-rebuild",
    "--title",
    `strata-update-${host}`,
    bash,
    "-lc",
    shellCommand
  ], {
    detached: true,
    stdio: "ignore"
  });
  child.unref();
  process.stdout.write(JSON.stringify({ ok: true, host, channel, mode }) + "\n");
} catch (error) {
  fail(error && error.message ? error.message : "falha ao abrir terminal de update");
}

function buildCommand(context) {
  const updateAction = context.mode === "release"
    ? `sudo env STRATA_UPDATE_HOST=${sh(context.host)} STRATA_UPDATE_CHANNEL=${sh(context.channel)} ${sh(path.join(context.dotfiles, "strata-update.sh"))}`
    : `cd ${sh(context.dotfiles)}\n${writeStep("inputs", "Sincronizando branch e inputs locais.", 0.18)}\ngit fetch origin 2>&1 | tee -a ${sh(context.logPath)}\nbranch=$(git branch --show-current)\nif [ -n "$branch" ] && git ls-remote --exit-code --heads origin "$branch" >/dev/null 2>&1; then\n  git pull --ff-only origin "$branch" 2>&1 | tee -a ${sh(context.logPath)}\nelse\n  printf 'Branch sem remoto correspondente; mantendo estado local atual.\\n' | tee -a ${sh(context.logPath)}\nfi\nnix flake update 2>&1 | tee -a ${sh(context.logPath)}\n${writeStep("build", "Montando a nova geração do sistema.", 0.46)}\nsudo nixos-rebuild switch --flake ${sh(context.flake)} 2>&1 | tee -a ${sh(context.logPath)}`;

  const commandLines = [
    `mkdir -p ${sh(context.cacheDir)}`,
    `: > ${sh(context.logPath)}`,
    "set -o pipefail",
    writeStep("inputs", context.mode === "release" ? "Verificando release do host atual." : "Preparando update local.", 0.16),
    context.mode === "release"
      ? `${updateAction} 2>&1 | tee -a ${sh(context.logPath)}`
      : updateAction,
    "code=$?",
    "if [ \"$code\" -eq 0 ]; then",
    `  ${writeStep("refresh", "Atualizando índices e estado local.", 0.94)}`,
    `  (${context.node} ${sh(context.appcenterIndex)} >/dev/null 2>&1 || true; ${context.node} ${sh(context.launcherIndex)} >/dev/null 2>&1 || true; ${context.node} ${sh(context.statusScript)} >/dev/null 2>&1 || true)`,
    `  cat > ${sh(context.statusPath)} <<'EOF'`,
    successJson(context),
    "EOF",
    "  printf 'Atualização concluída com sucesso.\\n' | tee -a " + sh(context.logPath),
    "else",
    `  cat > ${sh(context.statusPath)} <<'EOF'`,
    errorJson(context),
    "EOF",
    "  printf 'Atualização falhou.\\n' | tee -a " + sh(context.logPath),
    "fi",
    "printf '\\nPressione qualquer tecla para fechar...'",
    "read -r -n 1 _"
  ];

  return commandLines.join("\n");
}

function writeStep(step, label, progress) {
  return `cat > ${sh(statusPath)} <<'EOF'\n${JSON.stringify({
    host,
    channel,
    mode,
    status: "running",
    currentStep: step,
    currentStepLabel: label,
    startedAt: new Date().toISOString(),
    finishedAt: null,
    lastSuccessAt: readExistingSuccess(statusPath),
    lastFailureAt: null,
    progressValue: progress,
    summaryCount: 1,
    rebuildRequired: true,
    pendingApps: 0,
    currentBranch,
    gitDirty,
    flakeLockChanged: false,
    releaseUpdateAvailable: false,
    upstreamUpdateAvailable: false,
    upstreamSummary: "",
    localChangesAvailable: false,
    blockedReason: "",
    rebootRecommended: false,
    rebootReason: "",
    lastError: "",
    logPreview: []
  }, null, 2)}\nEOF`;
}

function successJson(context) {
  const rebootState = detectRebootState();
  return JSON.stringify({
    host: context.host,
    channel: context.channel,
    mode: context.mode,
    status: "success",
    currentStep: "refresh",
    currentStepLabel: "Atualização concluída.",
    startedAt: new Date().toISOString(),
    finishedAt: new Date().toISOString(),
    lastSuccessAt: new Date().toISOString(),
    lastFailureAt: null,
    progressValue: 1,
    summaryCount: 0,
    rebuildRequired: false,
    pendingApps: 0,
    currentBranch: detectBranch(context.dotfiles),
    gitDirty: false,
    flakeLockChanged: false,
    releaseUpdateAvailable: false,
    upstreamUpdateAvailable: false,
    upstreamSummary: "",
    localChangesAvailable: false,
    blockedReason: "",
    rebootRecommended: rebootState.recommended,
    rebootReason: rebootState.reason,
    lastError: "",
    logPreview: [
      "nova geração aplicada",
      "índices atualizados",
      rebootState.recommended ? rebootState.reason : "sistema pronto para uso"
    ].filter(Boolean)
  }, null, 2);
}

function errorJson(context) {
  return JSON.stringify({
    host: context.host,
    channel: context.channel,
    mode: context.mode,
    status: "error",
    currentStep: context.mode === "release" ? "switch" : "build",
    currentStepLabel: "A atualização não foi concluída.",
    startedAt: new Date().toISOString(),
    finishedAt: new Date().toISOString(),
    lastSuccessAt: readExistingSuccess(statusPath),
    lastFailureAt: new Date().toISOString(),
    progressValue: context.mode === "release" ? 0.72 : 0.46,
    summaryCount: 1,
    rebuildRequired: true,
    pendingApps: 0,
    currentBranch: detectBranch(context.dotfiles),
    gitDirty: detectGitDirty(context.dotfiles),
    flakeLockChanged: false,
    releaseUpdateAvailable: false,
    upstreamUpdateAvailable: false,
    upstreamSummary: "",
    localChangesAvailable: false,
    blockedReason: "",
    rebootRecommended: false,
    rebootReason: "",
    lastError: "A atualização falhou. Abra o log para revisar o terminal.",
    logPreview: tailLog(logPath, 4)
  }, null, 2);
}

function writeStatus(payload) {
  fs.writeFileSync(statusPath, JSON.stringify(payload, null, 2) + "\n", "utf8");
}

function readExistingSuccess(filePath) {
  try {
    return JSON.parse(fs.readFileSync(filePath, "utf8")).lastSuccessAt || null;
  } catch {
    return null;
  }
}

function detectHost() {
  const result = spawnSync("hostname", [], { encoding: "utf8" });
  return (result.stdout || "").trim() || "desktop";
}

function detectBranch(repo) {
  const result = spawnSync("git", ["-C", repo, "branch", "--show-current"], { encoding: "utf8" });
  return result.status === 0 ? ((result.stdout || "").trim() || "-") : "-";
}

function detectGitDirty(repo) {
  const result = spawnSync("git", ["-C", repo, "status", "--short"], { encoding: "utf8" });
  return result.status === 0 && (result.stdout || "").trim() !== "";
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

function fail(message) {
  writeStatus({
    host,
    channel,
    mode,
    status: "error",
    currentStep: "inputs",
    currentStepLabel: "Falha ao iniciar a atualização.",
    startedAt: new Date().toISOString(),
    finishedAt: new Date().toISOString(),
    lastSuccessAt: readExistingSuccess(statusPath),
    lastFailureAt: new Date().toISOString(),
    progressValue: 0,
    summaryCount: 1,
    rebuildRequired: true,
    pendingApps: 0,
    currentBranch,
    gitDirty,
    flakeLockChanged: false,
    releaseUpdateAvailable: false,
    upstreamUpdateAvailable: false,
    upstreamSummary: "",
    localChangesAvailable: false,
    blockedReason: "",
    rebootRecommended: false,
    rebootReason: "",
    lastError: message,
    logPreview: [message]
  });
  process.stdout.write(JSON.stringify({ ok: false, error: message }) + "\n");
  process.exit(0);
}

function sh(value) {
  return `'${String(value).replace(/'/g, `'\"'\"'`)}'`;
}
