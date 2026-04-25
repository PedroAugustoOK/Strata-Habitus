#!/run/current-system/sw/bin/node

const fs = require("fs");
const path = require("path");
const os = require("os");
const { spawnSync } = require("child_process");

const HOME = process.env.HOME || os.homedir();
const mode = process.argv[2] || "";
const source = process.argv[3] || "";
const packageId = process.argv[4] || "";
const scope = process.argv[5] || "";
const appsFile = path.join(HOME, "dotfiles", "state", "apps.nix");

if (!mode || !source || !packageId) {
  write({ ok: false, error: "uso invalido" });
  process.exit(0);
}

if (source === "nix") {
  const changed = applyNix(mode, packageId, appsFile);
  write({ ok: changed, changed, source, packageId });
  process.exit(0);
}

if (source === "flatpak") {
  const installScope = scope === "system" ? "--system" : "--user";
  const uninstallScope = scope === "system" ? "--system" : "--user";
  const args = mode === "install"
    ? ["install", installScope, "-y", "flathub", packageId]
    : ["uninstall", uninstallScope, "-y", packageId];
  const result = spawnSync("/run/current-system/sw/bin/flatpak", args, { encoding: "utf8" });
  write({
    ok: result.status === 0,
    source,
    packageId,
    scope,
    changed: result.status === 0,
    error: result.status === 0 ? "" : (result.stderr || result.stdout || "falha no flatpak").trim()
  });
  process.exit(0);
}

write({ ok: false, error: "fonte invalida" });

function applyNix(modeName, pkg, file) {
  ensureAppsFile(file);
  const lines = fs.readFileSync(file, "utf8").split(/\r?\n/);
  const entry = `  pkgs.${pkg}`;
  const existing = lines.some(line => line.trim() === `pkgs.${pkg}`);

  if (modeName === "install") {
    if (existing) return false;
    const insertAt = lines.findIndex(line => line.trim() === "]");
    lines.splice(insertAt, 0, entry);
  } else {
    if (!existing) return false;
    const filtered = lines.filter(line => line.trim() !== `pkgs.${pkg}`);
    fs.writeFileSync(file, filtered.join("\n"), "utf8");
    return true;
  }

  fs.writeFileSync(file, lines.join("\n"), "utf8");
  return true;
}

function ensureAppsFile(file) {
  const dir = path.dirname(file);
  fs.mkdirSync(dir, { recursive: true });
  if (!fs.existsSync(file)) {
    fs.writeFileSync(file, "{ pkgs }:\n[\n]\n", "utf8");
  }
}

function write(payload) {
  process.stdout.write(JSON.stringify(payload) + "\n");
}
