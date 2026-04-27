#!/run/current-system/sw/bin/node

const fs = require("fs");
const path = require("path");
const os = require("os");

const HOME = process.env.HOME || os.homedir();
const CACHE_DIR = path.join(HOME, ".cache", "strata", "launcher");
const INDEX_PATH = process.argv[2] || path.join(CACHE_DIR, "index.json");
const HISTORY_PATH = process.argv[3] || path.join(HOME, "dotfiles", "state", "launcher-history.json");
const PINS_PATH = process.argv[4] || path.join(HOME, "dotfiles", "state", "launcher-pins.json");
const MODE = process.argv[5] || "default";
const QUERY = process.argv[6] || "";
const LIMIT = Number(process.argv[7] || 8);

const index = readJson(INDEX_PATH, []);
const history = readJson(HISTORY_PATH, {});
const pins = new Set(readJson(PINS_PATH, []));

const results = MODE === "all"
  ? allResults(index, history, pins, QUERY, LIMIT)
  : QUERY.trim()
    ? searchResults(index, history, pins, QUERY, LIMIT)
    : defaultResults(index, history, pins, LIMIT);

process.stdout.write(JSON.stringify({ ok: true, results }) + "\n");

function searchResults(entries, historyMap, pinSet, query, limit) {
  const q = normalize(query);
  const ranked = [];

  for (const entry of entries) {
    const score = scoreEntry(entry, historyMap[entry.id], pinSet.has(entry.id), q);
    if (score <= 0) continue;
    ranked.push({ entry, score });
  }

  ranked.sort((a, b) => {
    if (b.score !== a.score) return b.score - a.score;
    return a.entry.name.localeCompare(b.entry.name);
  });

  return ranked
    .slice(0, limit)
    .map(item => present(item.entry, historyMap[item.entry.id], pinSet.has(item.entry.id), {
      context: "search",
      score: item.score
    }));
}

function defaultResults(entries, historyMap, pinSet, limit) {
  const pool = entries
    .map(entry => ({
      entry,
      pin: pinSet.has(entry.id),
      launchCount: historyMap[entry.id]?.launchCount || 0,
      lastLaunchedAt: historyMap[entry.id]?.lastLaunchedAt || "",
      frecency: historyBoost(historyMap[entry.id])
    }))
    .sort((a, b) => {
      if (a.pin !== b.pin) return a.pin ? -1 : 1;
      if (a.frecency !== b.frecency) return b.frecency - a.frecency;
      if (a.lastLaunchedAt !== b.lastLaunchedAt) return b.lastLaunchedAt.localeCompare(a.lastLaunchedAt);
      if (a.launchCount !== b.launchCount) return b.launchCount - a.launchCount;
      return a.entry.name.localeCompare(b.entry.name);
    });

  return pool.slice(0, limit).map(item => present(item.entry, historyMap[item.entry.id], item.pin, {
    context: "default",
    reason: defaultReason(item)
  }));
}

function allResults(entries, historyMap, pinSet, query, limit) {
  const q = normalize(query);
  const filtered = q
    ? entries.filter(entry => scoreEntry(entry, historyMap[entry.id], pinSet.has(entry.id), q) > 0)
    : entries.slice();

  filtered.sort((a, b) => {
    const aPinned = pinSet.has(a.id);
    const bPinned = pinSet.has(b.id);
    if (aPinned !== bPinned) return aPinned ? -1 : 1;
    return a.name.localeCompare(b.name);
  });

  return filtered
    .slice(0, limit)
    .map(entry => present(entry, historyMap[entry.id], pinSet.has(entry.id), {
      context: "all",
      reason: "Instalado"
    }));
}

function scoreEntry(entry, historyEntry, isPinned, query) {
  const name = normalize(entry.name);
  const generic = normalize(entry.genericName);
  const keywordList = entry.keywords.map(normalize).filter(Boolean);
  const categoryList = entry.categories.map(normalize).filter(Boolean);
  const id = normalize(entry.id);
  const desktopBase = normalize(path.basename(entry.desktopFile || "", ".desktop"));
  const execBase = normalize(execBasename(entry.exec || ""));
  const queryTerms = query.split(/\s+/).filter(Boolean);
  const expandedTerms = expandTerms(queryTerms);

  let score = 0;
  let matched = false;

  if (name === query) {
    score += 220;
    matched = true;
  }
  if (name.startsWith(query)) {
    score += 180;
    matched = true;
  } else if (name.includes(query)) {
    score += 95;
    matched = true;
  }

  const fuzzy = fuzzyScore(name, query);
  if (fuzzy > 0) {
    score += fuzzy;
    matched = true;
  }

  if (generic.startsWith(query)) {
    score += 70;
    matched = true;
  } else if (generic.includes(query)) {
    score += 40;
    matched = true;
  }

  if (id.includes(query)) {
    score += 35;
    matched = true;
  }

  if (desktopBase && desktopBase.includes(query)) {
    score += 32;
    matched = true;
  }

  if (execBase && execBase.includes(query)) {
    score += 28;
    matched = true;
  }

  const keywordHits = expandedTerms.filter(term => keywordList.some(keyword => tokenMatches(keyword, term)));
  if (keywordHits.length > 0) {
    score += keywordHits.length * 18;
    matched = true;
  }

  const categoryHits = expandedTerms.filter(term => categoryList.some(category => category === term));
  if (categoryHits.length > 0) {
    score += categoryHits.length * 6;
    matched = true;
  }

  if (!matched) return 0;

  if (isPinned) score += 60;
  score += historyBoost(historyEntry);

  return score;
}

function historyBoost(historyEntry) {
  if (!historyEntry) return 0;
  const launchCount = Number(historyEntry.launchCount || 0);
  const recent = recencyBoost(historyEntry.lastLaunchedAt);
  return Math.min(launchCount, 24) * 3 + recent;
}

function recencyBoost(timestamp) {
  if (!timestamp) return 0;
  const launchedAt = Date.parse(timestamp);
  if (Number.isNaN(launchedAt)) return 0;

  const hours = Math.max(1, (Date.now() - launchedAt) / (1000 * 60 * 60));
  if (hours <= 6) return 35;
  if (hours <= 24) return 22;
  if (hours <= 72) return 12;
  return 4;
}

function fuzzyScore(text, query) {
  if (!text || !query) return 0;
  let qi = 0;
  let consecutive = 0;
  let score = 0;

  for (let i = 0; i < text.length && qi < query.length; i += 1) {
    if (text[i] !== query[qi]) {
      consecutive = 0;
      continue;
    }

    qi += 1;
    consecutive += 1;
    score += consecutive >= 2 ? 10 : 6;
  }

  return qi === query.length ? score : 0;
}

function defaultReason(item) {
  if (item.pin) return "Fixado";
  if (item.lastLaunchedAt && item.launchCount > 0) return "Recente";
  if (item.launchCount > 0) return "Frequente";
  return "Sugerido";
}

function present(entry, historyEntry, isPinned, meta = {}) {
  const badges = [];
  if (isPinned) badges.push("Pinned");
  if (entry.source === "flatpak") badges.push("Flatpak");
  else if (entry.source === "user") badges.push("Local");
  if (entry.terminal) badges.push("Terminal");
  if (meta.context === "default" && meta.reason && !isPinned) badges.push(meta.reason);

  return {
    id: entry.id,
    name: entry.name,
    genericName: entry.genericName,
    subtitle: entry.genericName || entry.categories[0] || meta.reason || labelSource(entry.source),
    iconPath: entry.iconPath,
    desktopFile: entry.desktopFile,
    exec: entry.exec || "",
    source: entry.source,
    terminal: entry.terminal,
    actions: entry.actions || [],
    actionCount: (entry.actions || []).length,
    badges,
    pinned: isPinned,
    launchCount: historyEntry?.launchCount || 0,
    lastLaunchedAt: historyEntry?.lastLaunchedAt || "",
    reason: meta.reason || "",
    score: meta.score || 0
  };
}

function labelSource(source) {
  if (source === "flatpak") return "Flatpak";
  if (source === "user") return "Aplicativo local";
  return "Sistema";
}

function normalize(value) {
  return `${value || ""}`
    .normalize("NFKD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .trim();
}

function execBasename(exec) {
  const token = `${exec || ""}`
    .replace(/%.?/g, " ")
    .trim()
    .split(/\s+/)[0] || "";

  return path.basename(token);
}

function expandTerms(queryTerms) {
  const aliases = {
    files: ["arquivo", "arquivos", "nautilus", "file", "files"],
    file: ["arquivo", "arquivos", "nautilus", "file", "files"],
    settings: ["config", "configuracoes", "configuracao", "settings", "preferences"],
    setting: ["config", "configuracoes", "configuracao", "settings", "preferences"],
    browser: ["navegador", "browser", "web"],
    music: ["musica", "music", "player", "spotify"],
    video: ["video", "player", "mpv"],
    notes: ["notas", "notes", "standard", "obsidian"],
    terminal: ["terminal", "shell", "kitty", "ghostty"],
    store: ["loja", "store", "appcenter", "software"],
    bottles: ["bottles", "garrafas", "wine"],
    garrafas: ["bottles", "garrafas", "wine"],
    steam: ["steam", "jogos", "games"],
    games: ["jogos", "games", "steam"],
    discord: ["discord", "vesktop", "chat"],
    chat: ["chat", "discord", "telegram", "vesktop"]
  };

  const expanded = new Set(queryTerms);
  for (const term of queryTerms) {
    const mapped = aliases[term];
    if (!mapped) continue;
    for (const alias of mapped) expanded.add(alias);
  }
  return [...expanded];
}

function tokenMatches(token, query) {
  if (!token || !query) return false;
  return token === query || token.startsWith(query);
}

function readJson(file, fallback) {
  try {
    return JSON.parse(fs.readFileSync(file, "utf8"));
  } catch {
    return fallback;
  }
}
