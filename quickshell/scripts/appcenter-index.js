#!/run/current-system/sw/bin/node

const fs = require("fs");
const path = require("path");
const os = require("os");
const { spawnSync } = require("child_process");

const HOME = process.env.HOME || os.homedir();
const APPS_STATE = path.join(HOME, "dotfiles", "state", "apps.nix");
const PACKAGES_MODULE = path.join(HOME, "dotfiles", "modules", "packages.nix");
const CACHE_DIR = path.join(HOME, ".cache", "strata", "appcenter");
const CATALOG_PATH = path.join(CACHE_DIR, "catalog.json");
const NIX_CACHE_PATH = path.join(CACHE_DIR, "nix-catalog.json");
const FLATPAK_CACHE_PATH = path.join(CACHE_DIR, "flatpak-catalog.json");
const TTL_MS = 1000 * 60 * 60 * 24;
const POPULAR_IDS = new Set([
  "firefox",
  "chromium",
  "kitty",
  "wezterm",
  "ghostty",
  "vscode",
  "zed-editor",
  "obsidian",
  "spotify",
  "vesktop",
  "discord",
  "telegram-desktop",
  "signal-desktop",
  "libreoffice",
  "gimp",
  "krita",
  "inkscape",
  "vlc",
  "mpv",
  "zathura",
  "nautilus",
  "keepassxc",
  "bitwarden-desktop",
  "obs-studio",
  "thunderbird",
  "pavucontrol",
  "blender",
  "steam",
  "heroic",
  "lutris",
  "standardnotes",
  "qgis"
]);

fs.mkdirSync(CACHE_DIR, { recursive: true });

const nixManaged = new Set(readManagedNixApps(APPS_STATE));
const nixBase = new Set(readBaseNixApps(PACKAGES_MODULE));
const nixActive = readActiveSystemPackages();
const nixDesktopHints = readActiveDesktopHints();
const flatpakInstalled = readFlatpakInstalled();

const nixCatalog = loadCachedCatalog(NIX_CACHE_PATH, buildNixCatalog);
const flatpakBuild = loadFlatpakCatalog();
const flatpakCatalog = Array.isArray(flatpakBuild) ? flatpakBuild : flatpakBuild.items;
const flatpakWarning = Array.isArray(flatpakBuild) ? "" : (flatpakBuild.warning || "");

const items = mergeCatalogs(nixCatalog, flatpakCatalog, nixManaged, nixBase, nixActive, nixDesktopHints, flatpakInstalled)
  .sort(compareItems);

fs.writeFileSync(CATALOG_PATH, JSON.stringify(items, null, 2), "utf8");
process.stdout.write(JSON.stringify({
  ok: true,
  count: items.length,
  cachePath: CATALOG_PATH,
  flatpakWarning
}) + "\n");

function mergeCatalogs(nixItems, flatpakItems, nixManagedSet, nixBaseSet, nixActiveSet, nixDesktopHintSet, flatpakInstalledSet) {
  const merged = new Map();

  for (const item of nixItems) {
    const managed = nixManagedSet.has(item.packageId);
    const baseInstalled = nixBaseSet.has(item.packageId);
    const activeInstalled = nixActiveSet.has(item.packageId) || nixDesktopHintSet.has(item.packageId);
    const installed = baseInstalled || activeInstalled;
    const relevance = relevanceScore(item);
    merged.set(item.id, {
      ...item,
      installed,
      managed,
      removable: managed,
      installedKind: managed ? "managed" : installed ? "base" : "",
      action: managed ? "remove" : installed ? "none" : "install",
      relevance,
      discoverable: installed || managed || relevance >= 4
    });
  }

  for (const item of flatpakItems) {
    const installedScope = flatpakInstalledSet.get(item.packageId) || "";
    const installed = installedScope !== "";
    merged.set(item.id, {
      ...item,
      installed,
      installedScope,
      managed: installed,
      removable: installed,
      installedKind: installed ? `flatpak-${installedScope}` : "",
      action: installed ? "remove" : "install",
      relevance: 10,
      discoverable: true
    });
  }

  return [...merged.values()];
}

function compareItems(a, b) {
  if (a.installed !== b.installed) return a.installed ? -1 : 1;
  if ((b.relevance || 0) !== (a.relevance || 0)) return (b.relevance || 0) - (a.relevance || 0);
  if (a.source !== b.source) return a.source.localeCompare(b.source);
  return a.name.localeCompare(b.name);
}

function loadCachedCatalog(file, builder) {
  if (isFresh(file)) {
    try {
      return JSON.parse(fs.readFileSync(file, "utf8"));
    } catch {}
  }

  const built = builder();
  try {
    fs.writeFileSync(file, JSON.stringify(built, null, 2), "utf8");
  } catch {}
  return built;
}

function readCachedCatalog(file) {
  try {
    return JSON.parse(fs.readFileSync(file, "utf8"));
  } catch {
    return null;
  }
}

function isFresh(file) {
  try {
    const stat = fs.statSync(file);
    return (Date.now() - stat.mtimeMs) < TTL_MS;
  } catch {
    return false;
  }
}

function buildNixCatalog() {
  const result = spawnSync("/run/current-system/sw/bin/nix-env", [
    "-qaP",
    "--description"
  ], { encoding: "utf8", maxBuffer: 1024 * 1024 * 32 });

  if (result.status !== 0) return [];

  return result.stdout
    .split(/\r?\n/)
    .map(line => line.trim())
    .filter(Boolean)
    .map(parseNixLine)
    .filter(Boolean);
}

function parseNixLine(line) {
  const parts = line.split(/\s+/);
  if (parts.length < 2) return null;

  const attrPath = parts[0];
  const packageId = attrPath.replace(/^nixos\./, "");
  const version = parts[1];
  const description = line.slice(line.indexOf(version) + version.length).trim();

  if (!packageId || packageId.includes(".")) return null;
  if (!/^[a-zA-Z0-9+_-]+$/.test(packageId)) return null;
  if (isInternalNixPackage(packageId, description)) return null;

  return {
    id: `nix:${packageId}`,
    name: packageId,
    description: description || `Pacote Nix ${packageId}`,
    source: "nix",
    packageId,
    version
  };
}

function isInternalNixPackage(packageId, description) {
  const id = packageId.toLowerCase();
  const desc = `${description || ""}`.toLowerCase();

  if (id.startsWith("_")) return true;
  if (id.includes("hook")) return true;
  if (id.includes("stdenv")) return true;
  if (id.includes("bootstrap")) return true;
  if (id.includes("debug") && desc.includes("symbols")) return true;
  if (desc.startsWith("python package")) return true;
  if (desc.startsWith("perl package")) return true;
  if (desc.startsWith("ruby package")) return true;
  if (desc.startsWith("haskell")) return true;
  if (desc.startsWith("ocaml library")) return true;
  if (desc.startsWith("c library")) return true;
  if (desc.startsWith("c++ library")) return true;
  if (desc.includes("library for")) return true;

  return false;
}

function relevanceScore(item) {
  const id = item.packageId.toLowerCase();
  const desc = `${item.description || ""}`.toLowerCase();
  let score = 0;

  if (POPULAR_IDS.has(id)) score += 8;
  if (/\b(browser|editor|viewer|player|client|manager|terminal|emulator|notes|office|mail|chat|music|video|image|pdf|wallet|calendar|camera|download|recorder|vpn|launcher|shell|paint|design|code)\b/.test(desc)) score += 4;
  if (/\b(game|desktop|application|app)\b/.test(desc)) score += 2;
  if (/\b(cli|command line|daemon|server|library|binding|plugin|module|sdk|api|header|firmware|driver)\b/.test(desc)) score -= 4;
  if (id.endsWith("-dev") || id.endsWith("-doc") || id.endsWith("-docs") || id.endsWith("-data") || id.endsWith("-debug")) score -= 5;
  if (/^(python|perl|ruby|lua|ghc|libre?)(-|$)/.test(id) && !POPULAR_IDS.has(id)) score -= 3;

  return score;
}

function loadFlatpakCatalog() {
  const built = buildFlatpakCatalog();
  if (built.items.length > 0) {
    try {
      fs.writeFileSync(FLATPAK_CACHE_PATH, JSON.stringify(built, null, 2), "utf8");
    } catch {}
    return built;
  }

  const cached = readCachedCatalog(FLATPAK_CACHE_PATH);
  if (cached && Array.isArray(cached.items) && cached.items.length > 0) {
    return {
      items: cached.items,
      warning: built.warning || cached.warning || ""
    };
  }

  return built;
}

function buildFlatpakCatalog() {
  const scopes = ["user", "system"];
  const merged = new Map();
  const warnings = [];
  let configured = false;

  for (const scope of scopes) {
    const result = spawnSync("/run/current-system/sw/bin/flatpak", [
      "remote-ls",
      `--${scope}`,
      "flathub",
      "--app",
      "--columns=name,description,application"
    ], { encoding: "utf8", maxBuffer: 1024 * 1024 * 16 });

    if (result.status !== 0) {
      const stderr = `${result.stderr || ""}`.trim();
      if (stderr.includes('Remote "flathub" not found')) {
        continue;
      }
      if (stderr !== "") warnings.push(stderr);
      continue;
    }

    configured = true;
    for (const item of parseFlatpakOutput(result.stdout)) {
      merged.set(item.id, item);
    }
  }

  if (merged.size > 0) {
    return {
      items: [...merged.values()],
      warning: ""
    };
  }

  if (!configured) {
    return {
      items: [],
      warning: "Flatpak disponivel, mas o flathub ainda nao foi configurado."
    };
  }

  return {
    items: [],
    warning: warnings.length > 0 ? "Catalogo Flatpak indisponivel no momento." : ""
  };
}

function parseFlatpakOutput(stdout) {
  return stdout
    .split(/\r?\n/)
    .map(line => line.trim())
    .filter(Boolean)
    .map(line => line.split("\t"))
    .filter(parts => parts.length >= 3)
    .map(parts => ({
      id: `flatpak:${parts[2]}`,
      name: parts[0],
      description: parts[1] || `Flatpak ${parts[2]}`,
      source: "flatpak",
      packageId: parts[2],
      version: ""
    }));
}

function readManagedNixApps(file) {
  try {
    const text = fs.readFileSync(file, "utf8");
    return text
      .split(/\r?\n/)
      .map(line => line.trim())
      .filter(line => line.startsWith("pkgs."))
      .map(line => line.replace(/^pkgs\./, "").replace(/\s+/g, "").replace(/;$/, ""));
  } catch {
    return [];
  }
}

function readBaseNixApps(file) {
  try {
    const text = fs.readFileSync(file, "utf8");
    const match = text.match(/environment\.systemPackages\s*=\s*\(with pkgs;\s*\[(.*?)\]\)\s*\+\+/s);
    if (!match) return [];

    const blacklist = new Set([
      "stdenv",
      "mkDerivation",
      "pname",
      "version",
      "src",
      "dontBuild",
      "installPhase",
      "mkdir",
      "cp",
      "out",
      "share",
      "sddm",
      "themes",
      "strata",
      "background",
      "Main",
      "metadata",
      "desktop",
      "theme",
      "conf",
      "pkgs",
      "vimPlugins",
      "nvim-treesitter",
      "withPlugins",
      "p",
      "nix",
      "lua",
      "bash",
      "python",
      "javascript",
      "typescript",
      "json",
      "yaml",
      "toml",
      "markdown",
      "html",
      "css",
      "c",
      "cpp",
      "rust",
      "go",
      "fish"
    ]);

    return [...new Set(
      (match[1].match(/[a-zA-Z][a-zA-Z0-9+_-]*/g) || [])
        .filter(token => !blacklist.has(token))
        .filter(token => !token.endsWith("Phase"))
        .filter(token => !token.endsWith("Plugin"))
    )];
  } catch {
    return [];
  }
}

function readActiveSystemPackages() {
  const result = spawnSync("/run/current-system/sw/bin/nix-store", [
    "--query",
    "--requisites",
    "/run/current-system"
  ], { encoding: "utf8", maxBuffer: 1024 * 1024 * 16 });

  if (result.status !== 0) return new Set();

  const packages = new Set();
  for (const line of result.stdout.split(/\r?\n/).map(line => line.trim()).filter(Boolean)) {
    const base = path.basename(line).replace(/^[a-z0-9]{32}-/, "");
    const simplified = base.replace(/-[0-9][A-Za-z0-9._+-]*$/, "");
    if (/^[a-zA-Z0-9+_-]+$/.test(simplified)) packages.add(simplified);
  }

  return packages;
}

function readActiveDesktopHints() {
  const root = "/run/current-system/sw/share/applications";
  const hints = new Set();
  if (!fs.existsSync(root)) return hints;

  for (const file of walkFiles(root, ".desktop")) {
    const base = path.basename(file, ".desktop").trim();
    if (isPkgToken(base)) hints.add(base);

    try {
      const text = fs.readFileSync(file, "utf8");
      const execMatch = text.match(/^Exec=(.+)$/m);
      if (!execMatch) continue;
      const cleanExec = execMatch[1]
        .replace(/%%/g, "%")
        .replace(/%[fFuUdDnNickvm]/g, "")
        .replace(/%[0-9]*[FfUu]/g, "")
        .trim();
      const binary = path.basename(cleanExec.split(/\s+/)[0] || "").trim();
      if (isPkgToken(binary)) hints.add(binary);
    } catch {}
  }

  return hints;
}

function walkFiles(root, suffix) {
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
      if (suffix && !dirent.name.endsWith(suffix)) continue;
      out.push(full);
    }
  }

  return out;
}

function isPkgToken(value) {
  return /^[a-zA-Z0-9+_.-]+$/.test(`${value || ""}`);
}

function readFlatpakInstalled() {
  const scopes = ["user", "system"];
  const installed = new Map();

  for (const scope of scopes) {
    const result = spawnSync("/run/current-system/sw/bin/flatpak", [
      "list",
      `--${scope}`,
      "--app",
      "--columns=application"
    ], { encoding: "utf8" });

    if (result.status !== 0) continue;

    for (const appId of result.stdout.split(/\r?\n/).map(line => line.trim()).filter(Boolean)) {
      if (!installed.has(appId)) installed.set(appId, scope);
    }
  }

  return installed;
}
