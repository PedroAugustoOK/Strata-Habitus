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
  const label = isImage ? "Imagem" : isBinary ? "Binario" : "Texto";
  const preview = isBinary
    ? raw
    : raw.replace(/\s+/g, " ").trim();

  return {
    id,
    entry: line,
    raw,
    preview,
    label,
    isBinary,
    isImage,
    imageFormat
  };
}

function extractImageFormat(raw) {
  const match = raw.match(/\b(png|jpe?g|webp|gif|bmp|svg)\b/i);
  return match ? match[1].toLowerCase() : "";
}

function write(payload) {
  process.stdout.write(JSON.stringify(payload) + "\n");
}
