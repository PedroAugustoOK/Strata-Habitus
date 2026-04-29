const fs = require("fs");
const path = require("path");
const os = require("os");
const { spawnSync } = require("child_process");

const HOME = process.env.HOME || os.homedir();
const XDG_DATA_HOME = process.env.XDG_DATA_HOME || path.join(HOME, ".local", "share");
const WEBAPP_STATE = path.join(HOME, "dotfiles", "state", "webapps.json");
const APPS_DIR = path.join(XDG_DATA_HOME, "applications");
const WEBAPP_ROOT = path.join(XDG_DATA_HOME, "strata", "webapps");
const BIN_DIR = path.join(WEBAPP_ROOT, "bin");
const ICONS_256_DIR = path.join(XDG_DATA_HOME, "icons", "hicolor", "256x256", "apps");
const ICONS_SCALABLE_DIR = path.join(XDG_DATA_HOME, "icons", "hicolor", "scalable", "apps");
const LAUNCHER_INDEX = path.join(HOME, "dotfiles", "quickshell", "scripts", "launcher-index.js");
const DEFAULT_BROWSER = "chromium";

const DEFAULT_CATALOG = [
  {
    packageId: "google-calendar",
    name: "Google Calendar",
    description: "Agenda do Google em modo app.",
    url: "https://calendar.google.com/",
    iconUrl: "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/google-calendar.png",
    keywords: ["agenda", "calendario", "google"]
  },
  {
    packageId: "google-drive",
    name: "Google Drive",
    description: "Drive em janela dedicada.",
    url: "https://drive.google.com/",
    iconUrl: "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/google-drive.png",
    keywords: ["arquivos", "drive", "google", "nuvem"]
  },
  {
    packageId: "gmail",
    name: "Gmail",
    description: "Caixa de entrada do Gmail como app.",
    url: "https://mail.google.com/",
    iconUrl: "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/gmail.png",
    keywords: ["email", "google", "mail"]
  },
  {
    packageId: "google-chat",
    name: "Google Chat",
    description: "Mensagens do Google Workspace.",
    url: "https://chat.google.com/",
    iconUrl: "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/google-chat.png",
    keywords: ["chat", "google", "workspace"]
  },
  {
    packageId: "slack",
    name: "Slack",
    description: "Slack em modo app.",
    url: "https://app.slack.com/client",
    iconUrl: "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/slack.png",
    keywords: ["chat", "workspace", "times"]
  },
  {
    packageId: "discord-web",
    name: "Discord Web",
    description: "Discord no navegador em janela dedicada.",
    url: "https://discord.com/app",
    iconUrl: "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/discord.png",
    keywords: ["chat", "voz", "comunidade"]
  },
  {
    packageId: "figma",
    name: "Figma",
    description: "Editor colaborativo em modo app.",
    url: "https://www.figma.com/files/",
    iconUrl: "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/figma.png",
    keywords: ["design", "ui", "ux", "prototipo"]
  },
  {
    packageId: "notion",
    name: "Notion",
    description: "Workspace do Notion em janela dedicada.",
    url: "https://www.notion.so/",
    iconUrl: "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/notion.png",
    keywords: ["notas", "wiki", "tarefas"]
  },
  {
    packageId: "excalidraw",
    name: "Excalidraw",
    description: "Quadro branco em modo app.",
    url: "https://excalidraw.com/",
    iconUrl: "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/excalidraw.png",
    keywords: ["diagramas", "whiteboard", "desenho"]
  },
  {
    packageId: "tailscale-admin",
    name: "Tailscale Admin",
    description: "Painel de maquinas do Tailscale.",
    url: "https://login.tailscale.com/admin/machines",
    iconUrl: "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/tailscale-light.png",
    keywords: ["vpn", "mesh", "rede"]
  },
  {
    packageId: "youtube-music",
    name: "YouTube Music",
    description: "Player do YouTube Music em modo app.",
    url: "https://music.youtube.com/",
    iconUrl: "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/youtube-music.png",
    keywords: ["musica", "player", "streaming"]
  },
  {
    packageId: "whatsapp-web",
    name: "WhatsApp Web",
    description: "WhatsApp em janela dedicada.",
    url: "https://web.whatsapp.com/",
    iconUrl: "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/whatsapp.png",
    keywords: ["mensagens", "chat", "telefone"]
  }
];

module.exports = {
  WEBAPP_STATE,
  DEFAULT_CATALOG,
  buildCatalog,
  readState,
  readInstalledSet,
  installWebApp,
  removeWebApp
};

function buildCatalog() {
  return readState().sort((a, b) => a.name.localeCompare(b.name));
}

function readState() {
  try {
    const parsed = JSON.parse(fs.readFileSync(WEBAPP_STATE, "utf8"));
    if (!Array.isArray(parsed)) return [];
    return parsed
      .map(normalizeEntry)
      .filter(item => item.packageId && item.name && item.url);
  } catch {
    return [];
  }
}

function readInstalledSet() {
  const installed = new Set();
  if (!fs.existsSync(APPS_DIR)) return installed;

  for (const name of fs.readdirSync(APPS_DIR)) {
    const match = name.match(/^strata-webapp-(.+)\.desktop$/);
    if (match) installed.add(match[1]);
  }
  return installed;
}

function installWebApp(rawEntry) {
  const entry = normalizeEntry(rawEntry);
  if (!entry.packageId || !entry.name || !entry.url) {
    throw new Error("webapp invalido");
  }

  ensureDirs();

  const state = upsertStateEntry(entry);
  const iconName = `strata-webapp-${entry.packageId}`;
  const wmClass = iconName;
  const launcherScript = path.join(BIN_DIR, `${entry.packageId}.sh`);
  const desktopFile = path.join(APPS_DIR, `${iconName}.desktop`);
  const iconSource = ensureIcon(iconName, entry);
  const browserExec = resolveBrowserExec(entry.browser);

  fs.writeFileSync(launcherScript, launcherScriptBody(browserExec, wmClass, entry.url), "utf8");
  fs.chmodSync(launcherScript, 0o755);

  fs.writeFileSync(desktopFile, desktopFileBody(entry, iconName, wmClass, launcherScript), "utf8");
  refreshDesktopCaches();
  reindexLauncher();

  return {
    changed: true,
    packageId: entry.packageId,
    source: "webapp",
    iconSource,
    stateCount: state.length
  };
}

function removeWebApp(packageId) {
  const id = `${packageId || ""}`.trim();
  if (!id) throw new Error("webapp invalido");

  const iconName = `strata-webapp-${id}`;
  deleteIfExists(path.join(APPS_DIR, `${iconName}.desktop`));
  deleteIfExists(path.join(BIN_DIR, `${id}.sh`));
  deleteIfExists(path.join(ICONS_256_DIR, `${iconName}.png`));
  deleteIfExists(path.join(ICONS_256_DIR, `${iconName}.svg`));
  deleteIfExists(path.join(ICONS_SCALABLE_DIR, `${iconName}.svg`));
  writeState(readState().filter(item => item.packageId !== id));
  refreshDesktopCaches();
  reindexLauncher();

  return {
    changed: true,
    packageId: id,
    source: "webapp"
  };
}

function normalizeEntry(input) {
  const packageId = slugify(input.packageId || input.slug || input.name || input.url || "");
  const url = normalizeUrl(input.url || "");
  const keywords = Array.isArray(input.keywords)
    ? input.keywords.map(item => `${item}`.trim()).filter(Boolean)
    : `${input.keywords || ""}`.split(/[;,]/).map(item => item.trim()).filter(Boolean);

  return {
    packageId,
    name: `${input.name || packageId}`.trim(),
    description: `${input.description || `Web app para ${input.name || packageId}`}`.trim(),
    url,
    iconUrl: `${input.iconUrl || ""}`.trim(),
    browser: `${input.browser || ""}`.trim(),
    keywords
  };
}

function normalizeUrl(url) {
  const value = `${url || ""}`.trim();
  if (value === "") return "";
  if (/^https?:\/\//i.test(value)) return value;
  return `https://${value}`;
}

function slugify(value) {
  return `${value || ""}`
    .toLowerCase()
    .normalize("NFKD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

function ensureDirs() {
  for (const dir of [path.dirname(WEBAPP_STATE), APPS_DIR, WEBAPP_ROOT, BIN_DIR, ICONS_256_DIR, ICONS_SCALABLE_DIR]) {
    fs.mkdirSync(dir, { recursive: true });
  }
}

function upsertStateEntry(entry) {
  const next = readState().filter(item => item.packageId !== entry.packageId);
  next.push(entry);
  next.sort((a, b) => a.name.localeCompare(b.name));
  writeState(next);
  return next;
}

function writeState(entries) {
  fs.mkdirSync(path.dirname(WEBAPP_STATE), { recursive: true });
  fs.writeFileSync(WEBAPP_STATE, `${JSON.stringify(entries, null, 2)}\n`, "utf8");
}

function ensureIcon(iconName, entry) {
  const pngPath = path.join(ICONS_256_DIR, `${iconName}.png`);
  const svgPath = path.join(ICONS_SCALABLE_DIR, `${iconName}.svg`);

  const iconInput = `${entry.iconUrl || ""}`.trim();
  const localIcon = resolveLocalIconPath(iconInput);

  if (localIcon) {
    const ext = path.extname(localIcon).toLowerCase();
    const target = ext === ".svg" ? svgPath : pngPath;
    fs.copyFileSync(localIcon, target);
    if (fs.existsSync(target) && safeFileSize(target) > 0) {
      return "local";
    }
  }

  if (isRemoteIcon(iconInput)) {
    const result = spawnSync("/run/current-system/sw/bin/curl", [
      "-fsSL",
      "--max-time",
      "20",
      "-o",
      pngPath,
      iconInput
    ], { encoding: "utf8" });

    if (result.status === 0 && fs.existsSync(pngPath) && safeFileSize(pngPath) > 0) {
      return "remote";
    }
  }

  fs.writeFileSync(svgPath, placeholderIcon(entry.name), "utf8");
  return "placeholder";
}

function isRemoteIcon(value) {
  return /^https?:\/\//i.test(`${value || ""}`.trim());
}

function resolveLocalIconPath(value) {
  const raw = `${value || ""}`.trim();
  if (raw === "" || isRemoteIcon(raw)) return "";

  const normalized = raw.startsWith("file://")
    ? decodeURIComponent(raw.slice("file://".length))
    : raw;

  if (!path.isAbsolute(normalized)) return "";
  if (!fs.existsSync(normalized)) return "";
  if (!/\.(png|svg)$/i.test(normalized)) return "";
  return normalized;
}

function resolveBrowserExec(preferredBrowser) {
  const preferred = `${preferredBrowser || ""}`.trim();
  if (preferred) return preferred;

  const desktopId = resolveDefaultBrowserDesktop();
  const supported = desktopId && /(chromium|chrome|brave|vivaldi|opera|edge|helium)/i.test(desktopId);
  const candidate = supported ? readDesktopExecBinary(desktopId) : "";

  return candidate || DEFAULT_BROWSER;
}

function resolveDefaultBrowserDesktop() {
  const result = spawnSync("/run/current-system/sw/bin/xdg-settings", [
    "get",
    "default-web-browser"
  ], { encoding: "utf8" });

  if (result.status !== 0) return "";
  return `${result.stdout || ""}`.trim();
}

function readDesktopExecBinary(desktopId) {
  const roots = [
    APPS_DIR,
    "/run/current-system/sw/share/applications",
    path.join(HOME, ".nix-profile", "share", "applications"),
    path.join(HOME, ".local/state/nix/profile/share/applications"),
    `/etc/profiles/per-user/${path.basename(HOME)}/share/applications`,
    "/usr/share/applications"
  ];

  for (const root of roots) {
    const file = path.join(root, desktopId);
    if (!fs.existsSync(file)) continue;

    try {
      const text = fs.readFileSync(file, "utf8");
      const match = text.match(/^Exec=(.+)$/m);
      if (!match) continue;
      const command = match[1]
        .replace(/%%/g, "%")
        .replace(/%[fFuUdDnNickvm]/g, "")
        .replace(/%[0-9]*[FfUu]/g, "")
        .trim();
      const first = command.match(/^(".*?"|\S+)/);
      if (!first) continue;
      return first[1].replace(/^"|"$/g, "");
    } catch {}
  }

  return "";
}

function launcherScriptBody(browserExec, wmClass, url) {
  return [
    "#!/run/current-system/sw/bin/bash",
    `WM_CLASS=${shellQuote(wmClass)}`,
    "if command -v hyprctl >/dev/null 2>&1; then",
    "  if hyprctl -j clients 2>/dev/null | grep -Fq \"\\\"class\\\":\\\"${WM_CLASS}\\\"\"; then",
    "    hyprctl dispatch focuswindow \"class:^(${WM_CLASS})$\" >/dev/null 2>&1 && exit 0",
    "  fi",
    "fi",
    `exec ${shellQuote(browserExec)} --class=${shellQuote(wmClass)} --app=${shellQuote(url)}`
  ].join("\n") + "\n";
}

function desktopFileBody(entry, iconName, wmClass, launcherScript) {
  const keywords = entry.keywords.length > 0 ? `${entry.keywords.join(";")};` : "";

  return [
    "[Desktop Entry]",
    "Type=Application",
    `Name=${desktopEscape(entry.name)}`,
    `Comment=${desktopEscape(entry.description)}`,
    `Exec=/run/current-system/sw/bin/bash ${desktopQuote(launcherScript)}`,
    `Icon=${iconName}`,
    "Terminal=false",
    "Categories=Network;WebBrowser;",
    `StartupWMClass=${wmClass}`,
    keywords ? `Keywords=${desktopEscape(keywords)}` : ""
  ].filter(Boolean).join("\n") + "\n";
}

function placeholderIcon(name) {
  const initials = `${name || "WA"}`
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map(part => part[0].toUpperCase())
    .join("") || "WA";

  return [
    "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"256\" height=\"256\" viewBox=\"0 0 256 256\">",
    "<rect width=\"256\" height=\"256\" rx=\"56\" fill=\"#1f2937\"/>",
    "<rect x=\"18\" y=\"18\" width=\"220\" height=\"220\" rx=\"42\" fill=\"#2f3d4f\" stroke=\"#8fb7ff\" stroke-opacity=\"0.35\"/>",
    `<text x="128" y="146" text-anchor="middle" font-family="JetBrains Mono, monospace" font-size="88" font-weight="700" fill="#eef2ff">${xmlEscape(initials)}</text>`,
    "</svg>"
  ].join("");
}

function refreshDesktopCaches() {
  spawnSync("/run/current-system/sw/bin/update-desktop-database", [APPS_DIR], { encoding: "utf8" });
  spawnSync("/run/current-system/sw/bin/gtk-update-icon-cache", ["-f", path.join(XDG_DATA_HOME, "icons", "hicolor")], { encoding: "utf8" });
}

function reindexLauncher() {
  spawnSync("/run/current-system/sw/bin/node", [LAUNCHER_INDEX], { encoding: "utf8", maxBuffer: 1024 * 1024 * 16 });
}

function deleteIfExists(file) {
  try {
    fs.unlinkSync(file);
  } catch {}
}

function safeFileSize(file) {
  try {
    return fs.statSync(file).size;
  } catch {
    return 0;
  }
}

function shellQuote(value) {
  return `'${`${value || ""}`.replace(/'/g, `'\\''`)}'`;
}

function desktopEscape(value) {
  return `${value || ""}`.replace(/\n/g, " ").trim();
}

function desktopQuote(value) {
  return `"${`${value || ""}`.replace(/(["\\])/g, "\\$1")}"`;
}

function xmlEscape(value) {
  return `${value || ""}`
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}
