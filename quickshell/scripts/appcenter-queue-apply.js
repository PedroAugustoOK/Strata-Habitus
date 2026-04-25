#!/run/current-system/sw/bin/node

const fs = require("fs");
const path = require("path");
const os = require("os");

const HOME = process.env.HOME || os.homedir();
const appsFile = path.join(HOME, "dotfiles", "state", "apps.nix");
const rawOps = process.argv[2] || "[]";

let ops;
try {
  ops = JSON.parse(rawOps);
} catch {
  write({ ok: false, error: "fila invalida" });
  process.exit(0);
}

if (!Array.isArray(ops)) {
  write({ ok: false, error: "fila invalida" });
  process.exit(0);
}

ensureAppsFile(appsFile);

const current = readApps(appsFile);
const set = new Set(current);
let changed = 0;

for (const op of ops) {
  const packageId = `${op && op.packageId ? op.packageId : ""}`.trim();
  const mode = `${op && op.mode ? op.mode : ""}`.trim();
  if (!packageId || !mode) continue;

  if (mode === "install") {
    if (!set.has(packageId)) {
      current.push(packageId);
      set.add(packageId);
      changed += 1;
    }
  } else if (mode === "remove") {
    if (set.has(packageId)) {
      const idx = current.indexOf(packageId);
      if (idx >= 0) current.splice(idx, 1);
      set.delete(packageId);
      changed += 1;
    }
  }
}

writeApps(appsFile, current);
write({ ok: true, changed, count: current.length });

function ensureAppsFile(file) {
  const dir = path.dirname(file);
  fs.mkdirSync(dir, { recursive: true });
  if (!fs.existsSync(file)) {
    fs.writeFileSync(file, "{ pkgs }:\n[\n]\n", "utf8");
  }
}

function readApps(file) {
  const text = fs.readFileSync(file, "utf8");
  return text
    .split(/\r?\n/)
    .map(line => line.trim())
    .filter(line => line.startsWith("pkgs."))
    .map(line => line.replace(/^pkgs\./, "").replace(/;$/, "").trim());
}

function writeApps(file, apps) {
  const lines = ["{ pkgs }:", "["];
  for (const app of apps) lines.push(`  pkgs.${app}`);
  lines.push("]");
  fs.writeFileSync(file, `${lines.join("\n")}\n`, "utf8");
}

function write(payload) {
  process.stdout.write(JSON.stringify(payload) + "\n");
}
