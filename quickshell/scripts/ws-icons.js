#!/run/current-system/sw/bin/node

const { spawnSync } = require("child_process");
const glyphMap = {
  kitty: "󰄛",
  chromium: "󰊯",
  "chromium-browser": "󰊯",
  firefox: "󰈹",
  nautilus: "󰉋",
  "org.gnome.nautilus": "󰉋",
  pavucontrol: "󰕾",
  "blueman-manager": "󰂯",
  discord: "󰙯",
  spotify: "󰓇",
  steam: "󰓓",
  vlc: "󰕼",
  mpv: "󰐹",
  code: "󰨞",
  codium: "󰨞",
  ghostty: "󰊠",
  "com.mitchellh.ghostty": "󰊠",
  "org.telegram.desktop": "󰎆",
  telegramdesktop: "󰎆",
  tdesktop: "󰎆",
  forkgram: "󰎆",
  "io.github.forkgram.tdesktop": "󰎆",
  thunderbird: "󰴃",
  "proton-mail": "󰴃",
  "proton mail": "󰴃",
  "protonmail": "󰴃",
  "proton-authenticator": "󰌆",
  "proton authenticator": "󰌆",
  authenticator: "󰌆",
  "proton-pass": "󰢬",
  "proton pass": "󰢬",
  protonpass: "󰢬",
  "ch.proton.bridge-gui": "󰴃",
  "protonmail-bridge-gui": "󰴃",
  "org.gnome.calculator": "󰪚",
  "org.gnome.calendar": "󰃭",
  "org.gnome.clocks": "󰥔",
  vesktop: "󰙯",
  "dev.vencord.vesktop": "󰙯",
  obs: "󰐹",
  "com.obsproject.studio": "󰐹",
  "standard-notes": "󰎞",
  standardnotes: "󰎞",
  bottles: "󰡔",
  "com.usebottles.bottles": "󰡔",
  qgis: "󰈙",
  "org.qgis.qgis": "󰈙",
  kooha: "󰕧",
  "io.github.seadve.kooha": "󰕧",
  modrinthapp: "󰍳",
  modrinth: "󰍳",
  "com.modrinth.modrinthapp": "󰍳",
  btop: "󰄪"
};

const heuristicGlyphs = [
  { glyph: "󰊯", terms: ["browser", "chromium", "chrome", "firefox", "brave", "vivaldi", "edge", "zen", "librewolf", "opera"] },
  { glyph: "󰆍", terms: ["terminal", "kitty", "ghostty", "alacritty", "wezterm", "foot", "xterm", "konsole", "rxvt", "st"] },
  { glyph: "󰨞", terms: ["code", "codium", "nvim", "vim", "zed", "editor", "jetbrains", "idea", "pycharm", "webstorm", "android-studio"] },
  { glyph: "󰙯", terms: ["discord", "vesktop", "slack", "teams", "chat", "element", "signal", "whatsapp"] },
  { glyph: "󰎆", terms: ["telegram", "tdesktop", "forkgram"] },
  { glyph: "󰓇", terms: ["spotify", "music", "audacious", "rhythmbox", "lollypop", "cider"] },
  { glyph: "󰐹", terms: ["mpv", "vlc", "video", "obs", "studio", "kooha", "player"] },
  { glyph: "󰓓", terms: ["steam", "lutris", "heroic", "game", "games", "modrinth", "prismlauncher", "minecraft"] },
  { glyph: "󰉋", terms: ["nautilus", "dolphin", "thunar", "nemo", "pcmanfm", "files", "filemanager", "explorer"] },
  { glyph: "󰴃", terms: ["thunderbird", "mail", "evolution", "geary", "outlook"] },
  { glyph: "󰴃", terms: ["protonmail", "proton-mail", "proton mail", "bridge-gui", "proton bridge"] },
  { glyph: "󰢬", terms: ["protonpass", "proton-pass", "proton pass", "password manager", "vault"] },
  { glyph: "󰌆", terms: ["proton-authenticator", "proton authenticator", "authenticator", "2fa", "otp", "totp"] },
  { glyph: "󰪚", terms: ["calculator", "calc", "qalculate"] },
  { glyph: "󰃭", terms: ["calendar", "calendario"] },
  { glyph: "󰥔", terms: ["clock", "clocks", "relogio"] },
  { glyph: "󰈙", terms: ["qgis", "maps", "mapa"] },
  { glyph: "󰡔", terms: ["bottles", "wine"] },
  { glyph: "󰄪", terms: ["btop", "htop", "monitor", "systemmonitor"] },
  { glyph: "󰂯", terms: ["blueman", "bluetooth"] },
  { glyph: "󰕾", terms: ["pavucontrol", "pwvucontrol", "audio", "volume", "sound"] }
];

main();

function main() {
  const clients = readClients();
  const workspaces = {};

  for (const client of clients) {
    const workspaceId = client && client.workspace && Number(client.workspace.id);
    if (!workspaceId || workspaces[workspaceId]) continue;

    const className = String(client.class || client.initialClass || "").trim();
    const title = String(client.title || client.initialTitle || "").trim();
    const normalizedClass = normalize(className);
    const normalizedTitle = normalize(title);

    if (!normalizedClass && !normalizedTitle) continue;

    const glyph = resolveGlyph(normalizedClass, normalizedTitle);
    workspaces[workspaceId] = glyph || fallbackLetter(className || title);
  }

  process.stdout.write(JSON.stringify(workspaces) + "\n");
}

function readClients() {
  const result = spawnSync("hyprctl", ["clients", "-j"], {
    encoding: "utf8",
    maxBuffer: 1024 * 1024 * 16
  });

  if (result.status !== 0) return [];

  try {
    const parsed = JSON.parse(result.stdout || "[]");
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

function resolveGlyph(normalizedClass, normalizedTitle) {
  if (normalizedClass) {
    if (glyphMap[normalizedClass]) return glyphMap[normalizedClass];
    const last = normalizedClass.split(".").pop();
    if (last && glyphMap[last]) return glyphMap[last];
  }

  if (normalizedTitle) {
    if (glyphMap[normalizedTitle]) return glyphMap[normalizedTitle];
    const last = normalizedTitle.split(".").pop();
    if (last && glyphMap[last]) return glyphMap[last];
  }

  for (const rule of heuristicGlyphs) {
    if (matchesTerms(normalizedClass, normalizedTitle, rule.terms)) {
      return rule.glyph;
    }
  }

  return "";
}

function matchesTerms(normalizedClass, normalizedTitle, terms) {
  for (const term of terms) {
    if ((normalizedClass && normalizedClass.includes(term)) ||
        (normalizedTitle && normalizedTitle.includes(term))) {
      return true;
    }
  }

  return false;
}

function fallbackLetter(className) {
  const value = String(className || "").trim();
  return value ? value[0].toUpperCase() : "?";
}

function normalize(value) {
  return String(value || "")
    .normalize("NFKD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .trim();
}
