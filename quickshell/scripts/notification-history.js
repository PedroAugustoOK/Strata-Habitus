#!/run/current-system/sw/bin/node

const fs = require("fs");
const os = require("os");
const path = require("path");
const { spawnSync } = require("child_process");

const HOME = process.env.HOME || os.homedir();
const XDG_DATA_HOME = process.env.XDG_DATA_HOME || path.join(HOME, ".local/share");
const XDG_DATA_DIRS = (process.env.XDG_DATA_DIRS || "/usr/local/share:/usr/share")
  .split(":")
  .filter(Boolean);
const CACHE_DIR = path.join(HOME, ".cache", "strata", "notifications");
const ICON_ROOTS = discoverIconRoots();
const ICON_MAP = buildIconMap();

fs.mkdirSync(CACHE_DIR, { recursive: true });

const history = readNotifications(["history", "-j"]);
const active = readNotifications(["list", "-j"]);
const merged = new Map();

for (const item of [...active, ...history]) {
  if (!merged.has(item.key))
    merged.set(item.key, item);
}

const items = Array.from(merged.values())
  .sort((a, b) => (b.id || 0) - (a.id || 0));

process.stdout.write(JSON.stringify(items) + "\n");

function readNotifications(args) {
  const result = spawnSync("makoctl", args, { encoding: "utf8" });
  if (result.status !== 0)
    return [];

  const text = (result.stdout || "").trim();
  if (!text)
    return [];

  let data;
  try {
    data = JSON.parse(text);
  } catch {
    return [];
  }

  const out = [];
  collectNotifications(data, out);
  return out
    .map(normalizeNotification)
    .filter(Boolean);
}

function collectNotifications(node, out) {
  if (!node)
    return;

  if (Array.isArray(node)) {
    for (const item of node)
      collectNotifications(item, out);
    return;
  }

  if (typeof node !== "object")
    return;

  if (looksLikeNotification(node))
    out.push(node);

  for (const value of Object.values(node))
    collectNotifications(value, out);
}

function looksLikeNotification(node) {
  return (
    typeof node === "object" &&
    node !== null &&
    (
      "summary" in node ||
      "body" in node ||
      "app-name" in node ||
      "app_name" in node ||
      "appName" in node ||
      "desktop-entry" in node ||
      "desktop_entry" in node
    )
  );
}

function normalizeNotification(node) {
  const summary = asString(node.summary);
  const rawBody = asString(node.body);
  const desktopEntryRaw = asString(node["desktop-entry"] || node.desktop_entry || node.desktopEntry);
  const desktopEntry = desktopEntryRaw.endsWith(".desktop")
    ? desktopEntryRaw.slice(0, -8)
    : desktopEntryRaw;
  const appName = asString(node["app-name"] || node.app_name || node.appName || desktopEntryRaw);
  const id = Number(node.id || 0);
  const actions = Array.isArray(node.actions)
    ? node.actions.length
    : (node.actions && typeof node.actions === "object" ? Object.keys(node.actions).length : 0);
  const urgency = asString(node.urgency || node["urgency-level"] || node.urgencyLevel || "normal").toLowerCase();
  const body = sanitizeBody(rawBody, appName, summary);
  const groupKey = classifyGroupKey(appName, desktopEntry, summary);

  if (isMediaNotification(appName, desktopEntry, summary, body))
    return null;

  const iconName = firstNonEmpty([
    node["app-icon"],
    node.app_icon,
    node.appIcon,
    node.icon,
    desktopEntryRaw,
    desktopEntry,
    appName,
    appName.toLowerCase().replace(/\s+/g, "-")
  ]);
  const iconPath = resolveNotificationIcon(iconName, appName, summary, body);

  if (!summary && !body && !appName)
    return null;

  return {
    id,
    key: groupKey || buildKey(appName, summary, body),
    groupKey,
    appName,
    summary,
    body,
    actionsCount: actions,
    iconPath,
    urgency: urgency || "normal"
  };
}

function isMediaNotification(appName, desktopEntry, summary, body) {
  const text = `${appName} ${desktopEntry} ${summary} ${body}`.toLowerCase();
  return (
    text.includes("spotify") ||
    text.includes("spotify-client")
  );
}

function asString(value) {
  return typeof value === "string" ? value : "";
}

function buildKey(appName, summary, body) {
  return `${appName}\u0000${summary}\u0000${body}`;
}

function buildCacheKey(appName, summary, body) {
  const crypto = require("crypto");
  return crypto
    .createHash("sha1")
    .update(buildKey(appName, summary, body))
    .digest("hex");
}

function firstNonEmpty(values) {
  for (const value of values) {
    const text = asString(value).trim();
    if (text)
      return text;
  }
  return "";
}

function resolveIcon(iconName) {
  if (!iconName)
    return "";
  if (path.isAbsolute(iconName) && fs.existsSync(iconName))
    return `file://${iconName}`;

  const direct = ICON_MAP.get(iconName);
  if (direct)
    return `file://${direct}`;

  const normalized = iconName.toLowerCase().replace(/\.desktop$/i, "").replace(/\s+/g, "-");
  const fallbackNames = [
    normalized,
    normalized.replace(/[^a-z0-9-_.]/g, ""),
    normalized.replace(/-/g, ""),
    normalized.replace(/\./g, "-"),
    ...iconAliasesFor(normalized)
  ];

  for (const name of fallbackNames) {
    if (ICON_MAP.has(name))
      return `file://${ICON_MAP.get(name)}`;
  }

  if (normalized.includes("spotify") && ICON_MAP.has("spotify-client"))
    return `file://${ICON_MAP.get("spotify-client")}`;

  return "";
}

function resolveNotificationIcon(iconName, appName, summary, body) {
  const text = asString(iconName).trim();
  const cacheKey = buildCacheKey(appName, summary, body);

  if (text && path.isAbsolute(text) && fs.existsSync(text)) {
    const cached = cacheNotificationIcon(text, cacheKey);
    if (cached)
      return cached;
    return `file://${text}`;
  }

  const persisted = findCachedIcon(cacheKey);
  if (persisted)
    return persisted;

  return resolveIcon(text);
}

function discoverIconRoots() {
  const roots = [];
  const seen = new Set();

  function push(dir) {
    if (!dir || seen.has(dir))
      return;
    seen.add(dir);
    roots.push(dir);
  }

  push(path.join(XDG_DATA_HOME, "icons"));
  push(path.join(XDG_DATA_HOME, "pixmaps"));
  push(path.join(HOME, ".icons"));
  push(path.join(HOME, ".local/share/pixmaps"));
  push(path.join(HOME, ".local/share/flatpak/exports/share/icons"));
  push("/var/lib/flatpak/exports/share/icons");
  push(path.join(HOME, ".nix-profile/share/icons"));
  push(path.join(HOME, ".nix-profile/share/pixmaps"));
  push(path.join(HOME, ".local/state/nix/profile/share/icons"));
  push(path.join(HOME, ".local/state/nix/profile/share/pixmaps"));
  push(`/etc/profiles/per-user/${path.basename(HOME)}/share/icons`);
  push(`/etc/profiles/per-user/${path.basename(HOME)}/share/pixmaps`);
  push("/nix/var/nix/profiles/default/share/icons");
  push("/nix/var/nix/profiles/default/share/pixmaps");
  push(path.join(HOME, ".local/share/icons"));
  push(path.join(HOME, ".local/share/pixmaps"));
  push("/run/current-system/sw/share/icons");
  push("/run/current-system/sw/share/icons/hicolor");
  push("/run/current-system/sw/share/pixmaps");

  for (const dataDir of XDG_DATA_DIRS) {
    push(path.join(dataDir, "icons"));
    push(path.join(dataDir, "pixmaps"));
  }

  return roots;
}

function buildIconMap() {
  const map = new Map();

  for (const root of ICON_ROOTS) {
    if (!fs.existsSync(root))
      continue;

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

        if (!(dirent.isFile() || dirent.isSymbolicLink()))
          continue;
        if (!/\.(svg|png|xpm)$/i.test(dirent.name))
          continue;
        if (!fs.existsSync(full))
          continue;

        const name = dirent.name.replace(/\.(svg|png|xpm)$/i, "");
        if (!map.has(name))
          map.set(name, full);
      }
    }
  }

  return map;
}

function iconAliasesFor(name) {
  const aliases = [];

  if (name.includes("chromium")) {
    aliases.push("chromium", "chromium-browser", "org.chromium.Chromium");
  }
  if (name.includes("chrome")) {
    aliases.push("google-chrome", "google-chrome-stable", "chrome");
  }
  if (name.includes("firefox")) {
    aliases.push("firefox", "org.mozilla.firefox");
  }
  if (name.includes("spotify")) {
    aliases.push("spotify", "spotify-client");
  }
  if (name.includes("kitty")) {
    aliases.push("kitty");
  }

  return aliases;
}

function classifyGroupKey(appName, desktopEntry, summary) {
  const bag = `${appName} ${desktopEntry} ${summary}`.toLowerCase();
  if (bag.includes("spotify"))
    return "spotify";
  return "";
}

function sanitizeBody(body, appName, summary) {
  let text = body || "";
  if (!text)
    return "";

  const siteLike = /\b(chromium|chrome|firefox|brave|edge|opera|web)\b/i.test(appName)
    || /^https?:\/\//i.test(summary.trim())
    || /^https?:\/\//i.test(text.trim());

  if (siteLike) {
    text = text
      .split(/\r?\n/)
      .filter(line => {
        const trimmed = line.trim();
        if (!trimmed)
          return true;
        if (/^https?:\/\/\S+$/i.test(trimmed))
          return false;
        if (/^[a-z0-9.-]+\.[a-z]{2,}(\/.*)?$/i.test(trimmed))
          return false;
        return true;
      })
      .join("\n");

    text = text.replace(/\bhttps?:\/\/\S+/gi, "").replace(/\s{2,}/g, " ").trim();
  }

  return text;
}

function cacheNotificationIcon(sourcePath, cacheKey) {
  const ext = path.extname(sourcePath).toLowerCase();
  if (!ext || ![".png", ".jpg", ".jpeg", ".svg", ".xpm", ".webp"].includes(ext))
    return "";

  const target = path.join(CACHE_DIR, `${cacheKey}${ext}`);
  try {
    if (!fs.existsSync(target))
      fs.copyFileSync(sourcePath, target);
    return `file://${target}`;
  } catch {
    return "";
  }
}

function findCachedIcon(cacheKey) {
  for (const ext of [".png", ".jpg", ".jpeg", ".svg", ".xpm", ".webp"]) {
    const candidate = path.join(CACHE_DIR, `${cacheKey}${ext}`);
    if (fs.existsSync(candidate))
      return `file://${candidate}`;
  }
  return "";
}
