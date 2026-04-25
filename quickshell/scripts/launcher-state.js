#!/run/current-system/sw/bin/node

const fs = require("fs");
const path = require("path");
const os = require("os");

const HOME = process.env.HOME || os.homedir();
const command = process.argv[2] || "";
const entryId = process.argv[3] || "";
const pinsPath = process.argv[4] || path.join(HOME, "dotfiles", "state", "launcher-pins.json");

if (command !== "toggle-pin" || !entryId) {
  process.stdout.write(JSON.stringify({ ok: false, error: "uso invalido" }) + "\n");
  process.exit(0);
}

const dir = path.dirname(pinsPath);
fs.mkdirSync(dir, { recursive: true });

let pins = [];
try {
  pins = JSON.parse(fs.readFileSync(pinsPath, "utf8"));
  if (!Array.isArray(pins)) pins = [];
} catch {}

const set = new Set(pins);
let pinned = false;

if (set.has(entryId)) {
  set.delete(entryId);
} else {
  set.add(entryId);
  pinned = true;
}

const next = [...set].sort();
const tmp = `${pinsPath}.tmp-${process.pid}`;
fs.writeFileSync(tmp, JSON.stringify(next, null, 2), "utf8");
fs.renameSync(tmp, pinsPath);

process.stdout.write(JSON.stringify({ ok: true, pinned }) + "\n");
