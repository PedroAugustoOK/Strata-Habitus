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

  const detectedImageFormat = detectImageFormat(decoded.stdout);
  const effectiveKind = detectedImageFormat ? "image" : kind;
  const effectiveFormat = detectedImageFormat || format;
  const payload = effectiveKind === "image"
    ? decoded.stdout
    : normalizeTextBuffer(decoded.stdout);

  const tmpPath = path.join(cacheDir, `copy-${process.pid}-${Date.now()}`);
  fs.writeFileSync(tmpPath, payload);

  const copy = spawn("/run/current-system/sw/bin/bash", [
    "-lc",
    "cat \"$CLIPBOARD_FILE\" | /run/current-system/sw/bin/wl-copy --type \"$CLIPBOARD_MIME\"; rm -f \"$CLIPBOARD_FILE\""
  ], {
    env: {
      ...process.env,
      CLIPBOARD_FILE: tmpPath,
      CLIPBOARD_MIME: effectiveKind === "image" ? getImageMime(effectiveFormat) : "text/plain;charset=utf-8"
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

function detectImageFormat(buffer) {
  if (!buffer || buffer.length < 4) return "";
  if (buffer.subarray(0, 8).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]))) return "png";
  if (buffer.subarray(0, 3).equals(Buffer.from([0xff, 0xd8, 0xff]))) return "jpeg";
  if (buffer.subarray(0, 6).toString("ascii") === "GIF87a" || buffer.subarray(0, 6).toString("ascii") === "GIF89a") return "gif";
  if (buffer.subarray(0, 2).toString("ascii") === "BM") return "bmp";
  if (buffer.subarray(0, 12).toString("ascii", 0, 4) === "RIFF" && buffer.subarray(0, 12).toString("ascii", 8, 12) === "WEBP") return "webp";
  if (buffer.subarray(0, 256).toString("utf8").includes("<svg")) return "svg";
  return "";
}

function normalizeTextBuffer(buffer) {
  if (!buffer || buffer.length === 0) return Buffer.from("", "utf8");

  const candidates = [];
  const utf8Text = stripNulls(buffer.toString("utf8"));
  candidates.push({ text: utf8Text, score: scoreText(utf8Text) });

  if (hasUtf16LeBom(buffer)) {
    const text = stripNulls(buffer.subarray(2).toString("utf16le"));
    candidates.push({ text, score: scoreText(text) + 20 });
  } else {
    const text = stripNulls(buffer.toString("utf16le"));
    candidates.push({ text, score: scoreText(text) + (looksLikeUtf16Le(buffer) ? 10 : 0) });
  }

  if (hasUtf16BeBom(buffer)) {
    const text = stripNulls(decodeUtf16Be(buffer.subarray(2)));
    candidates.push({ text, score: scoreText(text) + 20 });
  } else {
    const text = stripNulls(decodeUtf16Be(buffer));
    candidates.push({ text, score: scoreText(text) + (looksLikeUtf16Be(buffer) ? 10 : 0) });
  }

  candidates.sort((a, b) => b.score - a.score);
  return Buffer.from(candidates[0].text, "utf8");
}

function hasUtf16LeBom(buffer) {
  return buffer.length >= 2 && buffer[0] === 0xff && buffer[1] === 0xfe;
}

function hasUtf16BeBom(buffer) {
  return buffer.length >= 2 && buffer[0] === 0xfe && buffer[1] === 0xff;
}

function looksLikeUtf16Le(buffer) {
  if (buffer.length < 4 || buffer.length % 2 !== 0) return false;
  let oddNuls = 0;
  for (let i = 1; i < buffer.length; i += 2) {
    if (buffer[i] === 0x00) oddNuls += 1;
  }
  return oddNuls >= Math.floor(buffer.length / 4);
}

function looksLikeUtf16Be(buffer) {
  if (buffer.length < 4 || buffer.length % 2 !== 0) return false;
  let evenNuls = 0;
  for (let i = 0; i < buffer.length; i += 2) {
    if (buffer[i] === 0x00) evenNuls += 1;
  }
  return evenNuls >= Math.floor(buffer.length / 4);
}

function decodeUtf16Be(buffer) {
  const swapped = Buffer.allocUnsafe(buffer.length);
  for (let i = 0; i < buffer.length - 1; i += 2) {
    swapped[i] = buffer[i + 1];
    swapped[i + 1] = buffer[i];
  }
  if (buffer.length % 2 === 1) swapped[buffer.length - 1] = buffer[buffer.length - 1];
  return swapped.toString("utf16le");
}

function countNuls(buffer) {
  let count = 0;
  for (const byte of buffer) {
    if (byte === 0x00) count += 1;
  }
  return count;
}

function stripTrailingNulls(text) {
  return text.replace(/\u0000+$/g, "");
}

function stripNulls(text) {
  return stripTrailingNulls(text).replace(/\u0000+/g, "");
}

function scoreText(text) {
  if (!text) return -1000;
  let score = 0;
  let printable = 0;

  for (const ch of text) {
    const code = ch.charCodeAt(0);
    if (ch === "\uFFFD") score -= 8;
    else if (ch === "\n" || ch === "\r" || ch === "\t") printable += 1;
    else if (code >= 32 && code < 127) printable += 1;
    else if (code >= 160) printable += 1;
    else score -= 2;
  }

  score += printable;
  if (/https?:\/\//i.test(text)) score += 12;
  if (/[A-Za-zÀ-ÿ]{3,}/.test(text)) score += 8;
  return score;
}

function write(payload) {
  process.stdout.write(JSON.stringify(payload) + "\n");
}
