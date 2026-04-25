#!/run/current-system/sw/bin/node

const fs = require("fs");
const os = require("os");
const path = require("path");
const { spawnSync, spawn } = require("child_process");

const mode = process.argv[2] || "";
const entry = process.argv[3] || "";
const kind = process.argv[4] || "text";
const format = (process.argv[5] || "").toLowerCase();

if (!mode || !entry) {
  write({ ok: false, error: "uso invalido" });
  process.exit(0);
}

if (mode === "delete") {
  const result = spawnSync("/run/current-system/sw/bin/cliphist", ["delete-query"], {
    input: entry,
    encoding: "utf8"
  });

  write({
    ok: result.status === 0,
    error: result.status === 0 ? "" : (result.stderr || result.stdout || "falha ao apagar").trim()
  });
  process.exit(0);
}

if (mode === "copy") {
  const decoded = spawnSync("/run/current-system/sw/bin/bash", ["-lc", "printf '%s' \"$CLIPBOARD_ENTRY\" | /run/current-system/sw/bin/cliphist decode"], {
    env: {
      ...process.env,
      CLIPBOARD_ENTRY: entry
    },
    encoding: null,
    maxBuffer: 1024 * 1024 * 32
  });

  if (decoded.status !== 0 || !decoded.stdout || decoded.stdout.length === 0) {
    write({ ok: false, error: (decoded.stderr || "falha ao decodificar item").toString().trim() });
    process.exit(0);
  }

  const cacheDir = path.join(process.env.XDG_CACHE_HOME || path.join(os.homedir(), ".cache"), "strata", "clipboard");
  fs.mkdirSync(cacheDir, { recursive: true });

  const tmpPath = path.join(cacheDir, `copy-${process.pid}-${Date.now()}`);
  fs.writeFileSync(tmpPath, decoded.stdout);

  const copy = spawn("/run/current-system/sw/bin/bash", [
    "-lc",
    "cat \"$CLIPBOARD_FILE\" | /run/current-system/sw/bin/wl-copy --type \"$CLIPBOARD_MIME\"; rm -f \"$CLIPBOARD_FILE\""
  ], {
    env: {
      ...process.env,
      CLIPBOARD_FILE: tmpPath,
      CLIPBOARD_MIME: kind === "image" ? getImageMime(format) : "text/plain;charset=utf-8"
    },
    detached: true,
    stdio: "ignore"
  });

  copy.unref();

  write({
    ok: true,
    error: ""
  });
  process.exit(0);
}

write({ ok: false, error: "modo invalido" });

function getImageMime(format) {
  if (format === "jpg") return "image/jpeg";
  if (["png", "jpeg", "webp", "gif", "bmp", "svg"].includes(format)) return `image/${format}`;
  return "image/png";
}

function write(payload) {
  process.stdout.write(JSON.stringify(payload) + "\n");
}
