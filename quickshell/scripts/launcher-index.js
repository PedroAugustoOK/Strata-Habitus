#!/run/current-system/sw/bin/node

const fs = require("fs");
const path = require("path");
const os = require("os");

const HOME = process.env.HOME || os.homedir();
const CACHE_DIR = path.join(HOME, ".cache", "strata", "launcher");
const INDEX_PATH = path.join(CACHE_DIR, "index.json");
const META_PATH = path.join(CACHE_DIR, "index.meta.json");
const XDG_DATA_HOME = process.env.XDG_DATA_HOME || path.join(HOME, ".local/share");
const XDG_DATA_DIRS = (process.env.XDG_DATA_DIRS || "/usr/local/share:/usr/share")
  .split(":")
  .filter(Boolean);

const APP_DIRS = discoverAppDirs();

const ICON_ROOTS = discoverIconRoots();

const DESKTOP_NAMES = currentDesktopNames();
const LOCALE_PREFS = localePreferences();

function main() {
  fs.mkdirSync(CACHE_DIR, { recursive: true });

  const iconMap = buildIconMap();
  const entries = [];

  for (const source of APP_DIRS) {
    for (const file of walkDesktopFiles(source.dir)) {
      const entry = parseDesktopEntry(file, source.source, iconMap);
      if (entry) entries.push(entry);
    }
  }

  const deduped = dedupeEntries(entries).sort((a, b) => a.name.localeCompare(b.name));

  writeAtomic(INDEX_PATH, JSON.stringify(deduped));
  writeAtomic(
    META_PATH,
    JSON.stringify({
      version: 1,
      generatedAt: new Date().toISOString(),
      entryCount: deduped.length,
      sources: APP_DIRS.map(item => item.dir)
    })
  );

  process.stdout.write(JSON.stringify({ ok: true, entryCount: deduped.length }) + "\n");
}

function currentDesktopNames() {
  const raw = `${process.env.XDG_CURRENT_DESKTOP || ""}:${process.env.DESKTOP_SESSION || ""}`;
  return new Set(
    raw
      .split(":")
      .map(part => part.trim().toLowerCase())
      .filter(Boolean)
  );
}

function discoverAppDirs() {
  const ordered = [];
  const seen = new Set();

  function push(dir, source) {
    if (!dir || seen.has(dir)) return;
    seen.add(dir);
    ordered.push({ dir, source });
  }

  push("/run/current-system/sw/share/applications", "system");
  push(path.join(XDG_DATA_HOME, "applications"), "user");
  push(path.join(HOME, ".local/share/flatpak/exports/share/applications"), "flatpak");
  push("/var/lib/flatpak/exports/share/applications", "flatpak");
  push(path.join(HOME, ".nix-profile/share/applications"), "user");
  push(path.join(HOME, ".local/state/nix/profile/share/applications"), "user");
  push(`/etc/profiles/per-user/${path.basename(HOME)}/share/applications`, "user");

  for (const dataDir of XDG_DATA_DIRS) {
    const source = dataDir.includes("flatpak") ? "flatpak" : "system";
    push(path.join(dataDir, "applications"), source);
  }

  return ordered;
}

function discoverIconRoots() {
  const roots = [];
  const seen = new Set();

  function push(dir) {
    if (!dir || seen.has(dir)) return;
    seen.add(dir);
    roots.push(dir);
  }

  push(path.join(XDG_DATA_HOME, "icons"));
  push(path.join(HOME, ".icons"));
  push(path.join(HOME, ".local/share/flatpak/exports/share/icons"));
  push("/var/lib/flatpak/exports/share/icons");
  push(path.join(HOME, ".nix-profile/share/icons"));
  push(path.join(HOME, ".local/state/nix/profile/share/icons"));
  push(`/etc/profiles/per-user/${path.basename(HOME)}/share/icons`);
  push("/nix/var/nix/profiles/default/share/icons");
  push("/run/current-system/sw/share/icons/Papirus-Dark");
  push("/run/current-system/sw/share/icons/Papirus");
  push("/run/current-system/sw/share/icons/hicolor");

  for (const dataDir of XDG_DATA_DIRS) {
    push(path.join(dataDir, "icons"));
  }

  return roots;
}

function localePreferences() {
  const lang = (process.env.LANG || "en_US.UTF-8").split(".")[0];
  const base = lang.split("@")[0];
  const short = base.split("_")[0];
  const prefs = [];
  if (base) prefs.push(base);
  if (short && short !== base) prefs.push(short);
  return prefs;
}

function walkDesktopFiles(root) {
  if (!root || !fs.existsSync(root)) return [];
  const out = [];
  const stack = [root];

  while (stack.length > 0) {
    const current = stack.pop();
    let dirents = [];

    try {
      dirents = fs.readdirSync(current, { withFileTypes: true });
    } catch {
      continue;
    }

    for (const dirent of dirents) {
      const full = path.join(current, dirent.name);
      if (dirent.isDirectory()) {
        stack.push(full);
        continue;
      }

      if (!(dirent.isFile() || dirent.isSymbolicLink())) continue;
      if (!dirent.name.endsWith(".desktop")) continue;
      if (fs.existsSync(full)) out.push(full);
    }
  }

  return out;
}

function buildIconMap() {
  const map = new Map();

  for (const root of ICON_ROOTS) {
    if (!fs.existsSync(root)) continue;
    const stack = [root];

    while (stack.length > 0) {
      const current = stack.pop();
      let dirents = [];

      try {
        dirents = fs.readdirSync(current, { withFileTypes: true });
      } catch {
        continue;
      }

      for (const dirent of dirents) {
        const full = path.join(current, dirent.name);
        if (dirent.isDirectory()) {
          stack.push(full);
          continue;
        }

        if (!(dirent.isFile() || dirent.isSymbolicLink())) continue;
        if (!/\.(svg|png|xpm)$/i.test(dirent.name)) continue;
        if (!fs.existsSync(full)) continue;

        const name = dirent.name.replace(/\.(svg|png|xpm)$/i, "");
        if (!map.has(name)) map.set(name, full);
      }
    }
  }

  return map;
}

function parseDesktopEntry(file, source, iconMap) {
  let raw = "";
  try {
    raw = fs.readFileSync(file, "utf8");
  } catch {
    return null;
  }

  const parsed = parseIniLike(raw);
  const entry = parsed["Desktop Entry"];
  if (!entry) return null;
  if ((entry.Type || "Application") !== "Application") return null;
  if (isTrue(entry.Hidden) || isTrue(entry.NoDisplay)) return null;
  if (!showInDesktop(entry)) return null;
  if (!tryExecAllowed(entry.TryExec)) return null;

  const name = localizedValue(entry, "Name");
  if (!name) return null;

  const desktopId = path.basename(file);
  const genericName = localizedValue(entry, "GenericName");
  const iconName = entry.Icon || "";
  const actions = parseActions(parsed, entry.Actions || "");

  return {
    id: desktopId,
    name,
    localizedName: name,
    genericName,
    keywords: splitList(localizedValue(entry, "Keywords")),
    categories: splitList(entry.Categories || ""),
    desktopFile: file,
    exec: entry.Exec || "",
    iconName,
    iconPath: resolveIcon(iconName, iconMap),
    terminal: isTrue(entry.Terminal),
    startupWmClass: entry.StartupWMClass || "",
    source,
    actions,
    hidden: isTrue(entry.Hidden),
    noDisplay: isTrue(entry.NoDisplay)
  };
}

function parseIniLike(raw) {
  const sections = {};
  let current = null;
  let pending = "";

  for (const originalLine of raw.split(/\r?\n/)) {
    let line = originalLine;
    if (!line) continue;

    if (pending) {
      line = pending + line;
      pending = "";
    }

    if (line.endsWith("\\")) {
      pending = line.slice(0, -1);
      continue;
    }

    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) continue;

    const sectionMatch = trimmed.match(/^\[(.+)\]$/);
    if (sectionMatch) {
      current = sectionMatch[1];
      sections[current] = sections[current] || {};
      continue;
    }

    if (!current) continue;
    const eq = line.indexOf("=");
    if (eq === -1) continue;

    const key = line.slice(0, eq).trim();
    const value = line.slice(eq + 1).trim();
    sections[current][key] = value;
  }

  return sections;
}

function localizedValue(section, key) {
  for (const locale of LOCALE_PREFS) {
    const localized = section[`${key}[${locale}]`];
    if (localized) return localized;
  }
  return section[key] || "";
}

function parseActions(parsed, actionListRaw) {
  const actionIds = splitList(actionListRaw);
  const actions = [];

  for (const actionId of actionIds) {
    const section = parsed[`Desktop Action ${actionId}`];
    if (!section) continue;

    const name = localizedValue(section, "Name");
    const exec = section.Exec || "";
    if (!name || !exec) continue;

    actions.push({ id: actionId, name, exec });
  }

  return actions;
}

function splitList(value) {
  return `${value || ""}`
    .split(";")
    .map(item => item.trim())
    .filter(Boolean);
}

function isTrue(value) {
  return `${value || ""}`.toLowerCase() === "true";
}

function showInDesktop(entry) {
  if (DESKTOP_NAMES.size === 0) return true;

  const onlyShowIn = splitList(entry.OnlyShowIn);
  if (onlyShowIn.length > 0) {
    const allowed = onlyShowIn.some(item => DESKTOP_NAMES.has(item.toLowerCase()));
    if (!allowed) return false;
  }

  const notShowIn = splitList(entry.NotShowIn);
  if (notShowIn.some(item => DESKTOP_NAMES.has(item.toLowerCase()))) return false;

  return true;
}

function tryExecAllowed(command) {
  const candidate = `${command || ""}`.trim();
  if (!candidate) return true;

  const bin = candidate.split(/\s+/)[0];
  if (bin.startsWith("/")) return fs.existsSync(bin);

  const pathDirs = (process.env.PATH || "").split(":").filter(Boolean);
  return pathDirs.some(dir => fs.existsSync(path.join(dir, bin)));
}

function resolveIcon(iconName, iconMap) {
  if (!iconName) return "";
  if (path.isAbsolute(iconName) && fs.existsSync(iconName)) return iconName;
  return iconMap.get(iconName) || "";
}

function dedupeEntries(entries) {
  const seenFiles = new Set();
  const byId = new Map();

  for (const entry of entries) {
    if (seenFiles.has(entry.desktopFile)) continue;
    seenFiles.add(entry.desktopFile);

    const existing = byId.get(entry.id);
    if (!existing) {
      byId.set(entry.id, entry);
      continue;
    }

    const rank = sourceRank(entry.source);
    const existingRank = sourceRank(existing.source);
    if (rank > existingRank) byId.set(entry.id, entry);
  }

  return [...byId.values()];
}

function sourceRank(source) {
  if (source === "user") return 3;
  if (source === "flatpak") return 2;
  return 1;
}

function writeAtomic(target, content) {
  const temp = `${target}.tmp-${process.pid}`;
  fs.writeFileSync(temp, content, "utf8");
  fs.renameSync(temp, target);
}

main();
