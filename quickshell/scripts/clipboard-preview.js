#!/run/current-system/sw/bin/node

const fs = require("fs");
const os = require("os");
const path = require("path");
const { spawnSync } = require("child_process");

const entry = process.argv[2] || "";
const hint = (process.argv[3] || "").toLowerCase();
if (!entry) {
  write({ ok: false, error: "item ausente" });
  process.exit(0);
}

const cacheDir = path.join(process.env.XDG_CACHE_HOME || path.join(os.homedir(), ".cache"), "strata", "clipboard");
fs.mkdirSync(cacheDir, { recursive: true });

const result = spawnSync("/run/current-system/sw/bin/bash", ["-lc", "printf '%s' \"$CLIPBOARD_ENTRY\" | /run/current-system/sw/bin/cliphist decode"], {
  env: { ...process.env, CLIPBOARD_ENTRY: entry },
  encoding: null,
  maxBuffer: 1024 * 1024 * 32
});

if (result.status !== 0 || !result.stdout || result.stdout.length === 0) {
  write({ ok: false, error: "falha ao gerar preview" });
  process.exit(0);
}

const ext = detectImageExtension(result.stdout, hint);
const cacheKey = Buffer.from(entry).toString("base64url").slice(0, 48);
const outputPath = path.join(cacheDir, `preview-${cacheKey}.${ext}`);

fs.writeFileSync(outputPath, result.stdout);
write({ ok: true, path: outputPath });

function detectImageExtension(buffer, hint) {
  if (hint === "jpg") return "jpeg";
  if (["png", "jpeg", "webp", "gif", "bmp", "svg"].includes(hint)) return hint;

  if (buffer.subarray(0, 8).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]))) return "png";
  if (buffer.subarray(0, 3).equals(Buffer.from([0xff, 0xd8, 0xff]))) return "jpeg";
  if (buffer.subarray(0, 6).toString("ascii") === "GIF87a" || buffer.subarray(0, 6).toString("ascii") === "GIF89a") return "gif";
  if (buffer.subarray(0, 2).toString("ascii") === "BM") return "bmp";
  if (buffer.subarray(0, 12).toString("ascii", 0, 4) === "RIFF" && buffer.subarray(0, 12).toString("ascii", 8, 12) === "WEBP") return "webp";
  if (buffer.subarray(0, 256).toString("utf8").includes("<svg")) return "svg";
  return "png";
}

function write(payload) {
  process.stdout.write(JSON.stringify(payload) + "\n");
}
