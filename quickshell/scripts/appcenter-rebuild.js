#!/run/current-system/sw/bin/node

const fs = require("fs");
const path = require("path");
const os = require("os");
const { spawnSync, spawn } = require("child_process");

const HOME = process.env.HOME || os.homedir();
const hostResult = spawnSync("hostname", [], { encoding: "utf8" });
const host = (hostResult.stdout || "").trim() || "desktop";
const kitty = "/run/current-system/sw/bin/kitty";
const shell = "/run/current-system/sw/bin/bash";
const node = "/run/current-system/sw/bin/node";
const appcenterIndex = `${HOME}/dotfiles/quickshell/scripts/appcenter-index.js`;
const launcherIndex = `${HOME}/dotfiles/quickshell/scripts/launcher-index.js`;
const cacheDir = path.join(HOME, ".cache", "strata", "appcenter");
const statusPath = path.join(cacheDir, "rebuild-status.txt");
const logPath = path.join(cacheDir, "rebuild.log");
const flake = `path:${HOME}/dotfiles#${host}`;
const command = [
  `mkdir -p ${sh(cacheDir)}`,
  `: > ${sh(logPath)}`,
  `printf 'running\\n%s\\n%s\\n%s\\n' ${sh(host)} ${sh(flake)} ${sh(logPath)} > ${sh(statusPath)}`,
  "set -o pipefail",
  `sudo nixos-rebuild switch --flake ${sh(flake)} 2>&1 | tee ${sh(logPath)}`,
  "code=$?",
  "printf '\\n\\n'",
  "if [ \"$code\" -eq 0 ]; then",
  `  printf 'success\\n%s\\n%s\\n%s\\n' ${sh(host)} ${sh(flake)} ${sh(logPath)} > ${sh(statusPath)}`,
  "  printf 'Rebuild concluido com sucesso.\\n'",
  `  (${node} ${sh(appcenterIndex)} >/dev/null 2>&1 || true; ${node} ${sh(launcherIndex)} >/dev/null 2>&1 || true) &`,
  "  printf 'Atualizacao de indices iniciada em background.\\n'",
  "else",
  "  printf 'Rebuild falhou com codigo %s.\\n' \"$code\"",
  `  printf 'failed\\n%s\\n%s\\n%s\\n%s\\n' ${sh(host)} ${sh(flake)} ${sh(logPath)} \"$code\" > ${sh(statusPath)}`,
  "fi",
  "printf 'Pressione qualquer tecla para fechar...'",
  "read -r -n 1 _"
].join("\n");

fs.mkdirSync(cacheDir, { recursive: true });
fs.writeFileSync(statusPath, `opening\n${host}\n${flake}\n${logPath}\n`, "utf8");

const checkKitty = spawnSync(kitty, ["--version"], { encoding: "utf8" });
if (checkKitty.status !== 0) {
  write({ ok: false, error: "kitty nao encontrado para abrir o rebuild" });
  process.exit(0);
}

try {
  const child = spawn(kitty, [
    "--class",
    "strata-rebuild",
    "--title",
    `strata-rebuild-${host}`,
    shell,
    "-lc",
    command
  ], {
    detached: true,
    stdio: "ignore"
  });

  child.unref();

  write({
    ok: true,
    host,
    flake,
    message: `Terminal de rebuild aberto para ${host}`
  });
} catch (error) {
  fs.writeFileSync(statusPath, `failed\n${host}\n${flake}\n${logPath}\nspawn-error\n`, "utf8");
  write({
    ok: false,
    error: error && error.message ? error.message : "falha ao abrir terminal de rebuild"
  });
}

function write(payload) {
  process.stdout.write(JSON.stringify(payload) + "\n");
}

function sh(value) {
  return `'${String(value).replace(/'/g, `'\"'\"'`)}'`;
}
