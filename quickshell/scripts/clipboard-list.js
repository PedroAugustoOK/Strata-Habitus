#!/run/current-system/sw/bin/node

const { spawnSync } = require("child_process");

const result = spawnSync("/run/current-system/sw/bin/cliphist", ["list"], {
  encoding: "utf8",
  maxBuffer: 1024 * 1024 * 16
});

if (result.status !== 0) {
  write({ ok: false, error: (result.stderr || result.stdout || "falha ao listar clipboard").trim() });
  process.exit(0);
}

const items = result.stdout
  .split(/\r?\n/)
  .map(line => line.trimEnd())
  .filter(Boolean)
  .map(parseLine)
  .filter(Boolean)
  .slice(0, 200);

write({ ok: true, items });

function parseLine(line) {
  const tab = line.indexOf("\t");
  const id = tab >= 0 ? line.slice(0, tab).trim() : line.trim();
  const raw = tab >= 0 ? line.slice(tab + 1) : line.trim();
  if (!id) return null;

  const isBinary = raw.startsWith("[[ binary");
  const imageFormat = extractImageFormat(raw);
  const isImage = isBinary && imageFormat !== "";
  const normalizedRaw = isBinary ? raw : normalizePossiblyBrokenText(raw);
  const textMeta = isBinary ? { label: isImage ? "Imagem" : "Binário", kind: isImage ? "image" : "binary" } : classifyText(normalizedRaw);
  const preview = isBinary
    ? raw
    : normalizedRaw.replace(/\s+/g, " ").trim();

  return {
    id,
    entry: line,
    raw: normalizedRaw,
    preview,
    label: textMeta.label,
    kind: textMeta.kind,
    isBinary,
    isImage,
    imageFormat
  };
}

function extractImageFormat(raw) {
  const match = raw.match(/\b(png|jpe?g|webp|gif|bmp|svg)\b/i);
  return match ? match[1].toLowerCase() : "";
}

function classifyText(text) {
  const lines = text
    .split(/\r?\n/)
    .map(line => line.trim())
    .filter(Boolean);

  const urlLines = lines.filter(line => /^https?:\/\//i.test(line));
  if (urlLines.length >= 2) return { label: "Links", kind: "links" };
  if (urlLines.length === 1 && lines.length <= 2) return { label: "Link", kind: "link" };
  return { label: "Texto", kind: "text" };
}

function normalizePossiblyBrokenText(text) {
  if (!text || text.indexOf("\u0000") === -1) return text;

  const raw = Buffer.from(text, "utf8");
  const candidates = [
    { text: stripNulls(text), score: scoreText(stripNulls(text)) },
    { text: stripNulls(raw.toString("utf16le")), score: scoreText(stripNulls(raw.toString("utf16le"))) + (looksLikeUtf16Le(raw) ? 10 : 0) },
    { text: stripNulls(decodeUtf16Be(raw)), score: scoreText(stripNulls(decodeUtf16Be(raw))) + (looksLikeUtf16Be(raw) ? 10 : 0) }
  ];
  candidates.sort((a, b) => b.score - a.score);
  return candidates[0].text;
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

function stripNulls(text) {
  return text.replace(/\u0000+/g, "");
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
