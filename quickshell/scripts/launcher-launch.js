#!/run/current-system/sw/bin/node

const fs = require("fs");
const path = require("path");
const os = require("os");
const { spawn, spawnSync } = require("child_process");

const HOME = process.env.HOME || os.homedir();
const mode = process.argv[2] || "main";
const desktopFile = process.argv[3] || "";
const entryId = process.argv[4] || path.basename(desktopFile);
const historyPath = process.argv[5] || path.join(HOME, "dotfiles", "state", "launcher-history.json");
const mainExec = process.argv[6] || "";
const mainTerminal = (process.argv[7] || "").toLowerCase() === "true";
const actionExec = process.argv[8] || "";
const actionName = process.argv[9] || "";

if (!desktopFile) {
  writeResult({ ok: false, error: "desktopFile ausente" });
  process.exit(0);
}

const result = mode === "action"
  ? runAction(actionExec, false)
  : runMain();

if (result.status !== 0) {
  writeResult({
    ok: false,
    error: (result.stderr || result.stdout || "falha ao abrir aplicativo").trim()
  });
  process.exit(0);
}

updateHistory(historyPath, entryId);
writeResult({ ok: true, mode, actionName });

function runMain() {
  const execLine = readExecFromDesktop(desktopFile) || mainExec;
  const terminal = readTerminalFromDesktop(desktopFile, mainTerminal);

  if (execLine) {
    return runAction(execLine, terminal);
  }

  return spawnSync("/run/current-system/sw/bin/gio", ["launch", desktopFile], {
    encoding: "utf8"
  });
}

function runAction(execLine, useTerminal) {
  const command = sanitizeExec(execLine);
  if (!command) {
    return { status: 1, stderr: "acao invalida" };
  }

  const args = useTerminal
    ? ["--class", "strata-launcher-terminal", "/run/current-system/sw/bin/sh", "-lc", command]
    : ["-lc", command];
  const bin = useTerminal ? "/run/current-system/sw/bin/kitty" : "/run/current-system/sw/bin/sh";

  try {
    const child = spawn(bin, args, {
      detached: true,
      stdio: "ignore"
    });
    child.unref();
    return { status: 0, stdout: "", stderr: "" };
  } catch (error) {
    return {
      status: 1,
      stderr: error && error.message ? error.message : "falha ao executar comando"
    };
  }
}

function sanitizeExec(execLine) {
  return `${execLine || ""}`
    .replace(/%%/g, "%")
    .replace(/%[fFuUdDnNickvm]/g, "")
    .replace(/%[0-9]*[FfUu]/g, "")
    .replace(/\s+/g, " ")
    .trim();
}

function updateHistory(file, id) {
  const dir = path.dirname(file);
  fs.mkdirSync(dir, { recursive: true });

  let history = {};
  try {
    history = JSON.parse(fs.readFileSync(file, "utf8"));
  } catch {}

  const current = history[id] || { launchCount: 0, lastLaunchedAt: "" };
  history[id] = {
    launchCount: Number(current.launchCount || 0) + 1,
    lastLaunchedAt: new Date().toISOString()
  };

  const tmp = `${file}.tmp-${process.pid}`;
  fs.writeFileSync(tmp, JSON.stringify(history, null, 2), "utf8");
  fs.renameSync(tmp, file);
}

function readExecFromDesktop(file) {
  try {
    const text = fs.readFileSync(file, "utf8");
    let inDesktopEntry = false;

    for (const rawLine of text.split(/\r?\n/)) {
      const line = rawLine.trim();
      if (!line || line.startsWith("#")) continue;
      if (line.startsWith("[")) {
        inDesktopEntry = line === "[Desktop Entry]";
        continue;
      }
      if (!inDesktopEntry) continue;
      if (line.startsWith("Exec=")) return line.slice(5).trim();
    }
  } catch {}

  return "";
}

function readTerminalFromDesktop(file, fallback) {
  try {
    const text = fs.readFileSync(file, "utf8");
    let inDesktopEntry = false;

    for (const rawLine of text.split(/\r?\n/)) {
      const line = rawLine.trim();
      if (!line || line.startsWith("#")) continue;
      if (line.startsWith("[")) {
        inDesktopEntry = line === "[Desktop Entry]";
        continue;
      }
      if (!inDesktopEntry) continue;
      if (line.startsWith("Terminal=")) return line.slice(9).trim().toLowerCase() === "true";
    }
  } catch {}

  return fallback;
}

function writeResult(payload) {
  process.stdout.write(JSON.stringify(payload) + "\n");
}
