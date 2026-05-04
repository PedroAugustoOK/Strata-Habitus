#!/usr/bin/env node

const fs = require("fs");
const path = require("path");

const home = process.env.HOME || "/home/ankh";
const themesDir = path.join(home, "dotfiles", "quickshell", "themes");
const preferredOrder = [
  "gruvbox",
  "rosepine",
  "nord",
  "tokyonight",
  "everforest",
  "kanagawa",
  "catppuccinlatte",
  "flexoki",
  "oxocarbon",
];

const labels = {
  gruvbox: "Gruvbox",
  rosepine: "Rose Pine",
  nord: "Nord",
  tokyonight: "Tokyo Night",
  everforest: "Everforest",
  kanagawa: "Kanagawa",
  catppuccinlatte: "Catppuccin Latte",
  flexoki: "Flexoki",
  oxocarbon: "Oxocarbon",
};

function clamp(value, min, max) {
  return Math.max(min, Math.min(max, value));
}

function parseHex(hex) {
  const value = String(hex || "").trim();
  if (!/^#[0-9a-fA-F]{6}$/.test(value)) return null;
  return {
    r: parseInt(value.slice(1, 3), 16),
    g: parseInt(value.slice(3, 5), 16),
    b: parseInt(value.slice(5, 7), 16),
  };
}

function toHex(channel) {
  return clamp(Math.round(channel), 0, 255).toString(16).padStart(2, "0");
}

function mix(a, b, weight = 0.5) {
  const ca = parseHex(a);
  const cb = parseHex(b);
  if (!ca || !cb) return a || b || "#000000";
  const w = clamp(weight, 0, 1);
  return `#${toHex(ca.r * (1 - w) + cb.r * w)}${toHex(ca.g * (1 - w) + cb.g * w)}${toHex(ca.b * (1 - w) + cb.b * w)}`;
}

function titleize(name) {
  return String(name || "theme")
    .replace(/[-_]+/g, " ")
    .replace(/\b\w/g, c => c.toUpperCase());
}

function normalize(theme) {
  const name = theme.name || "theme";
  const mode = theme.mode === "light" ? "light" : "dark";
  const semantic = theme.semantic || {};
  const ui = theme.ui || {};

  return {
    ...theme,
    name,
    label: theme.label || labels[name] || titleize(name),
    mode,
    modeLabel: mode === "light" ? "Claro" : "Escuro",
    bg0: theme.bg0 || "#0d0d0f",
    bg1: theme.bg1 || "#111113",
    bg2: theme.bg2 || "#161618",
    bg3: theme.bg3 || mix(theme.bg2 || "#161618", theme.text1 || "#e0e0e0", mode === "light" ? 0.14 : 0.18),
    mid: theme.mid || mix(theme.bg2 || "#161618", theme.text1 || "#e0e0e0", 0.38),
    text0: theme.text0 || "#f5f5f5",
    text1: theme.text1 || "#e0e0e0",
    text2: theme.text2 || "#cecece",
    text3: theme.text3 || "#888888",
    accent: theme.accent || "#d79921",
    accentDim: theme.accentDim || mix(theme.accent || "#d79921", theme.bg1 || "#111113", 0.78),
    primary: semantic.primary || theme.primary || theme.accent || "#d79921",
    secondary: semantic.secondary || theme.secondary || semantic.info || theme.accent || "#d79921",
    success: semantic.success || theme.success || "#87c181",
    warning: semantic.warning || theme.warning || "#d9bc8c",
    danger: semantic.danger || theme.danger || "#f28779",
    info: semantic.info || theme.info || semantic.secondary || theme.accent || "#d79921",
    barStyle: ui.barStyle || ui.bar?.style || "solid",
    barBackground: ui.barBackground || ui.bar?.background || theme.bg1 || "#111113",
    barPill: ui.barPill || ui.bar?.pill || theme.bg2 || "#161618",
    barBorder: ui.barBorder || ui.bar?.border || "transparent",
    barActive: ui.barActive || ui.bar?.active || semantic.primary || theme.accent || "#d79921",
    panelBackground: ui.panelBackground || ui.panel?.background || theme.bg1 || "#111113",
    panelRaised: ui.panelRaised || ui.panel?.raised || theme.bg2 || "#161618",
    panelBorder: ui.panelBorder || ui.panel?.border || (mode === "light" ? "#00000018" : "#ffffff12"),
    radiusScale: Number(ui.radiusScale || 1),
    accentStrength: Number(ui.accentStrength || 1),
  };
}

function readTheme(file) {
  const raw = fs.readFileSync(path.join(themesDir, file), "utf8");
  return normalize(JSON.parse(raw));
}

const files = fs.readdirSync(themesDir)
  .filter(file => file.endsWith(".json") && file !== "current.json");

const themes = files
  .map(readTheme)
  .sort((a, b) => {
    const ai = preferredOrder.indexOf(a.name);
    const bi = preferredOrder.indexOf(b.name);
    if (ai !== -1 || bi !== -1) return (ai === -1 ? 999 : ai) - (bi === -1 ? 999 : bi);
    return a.label.localeCompare(b.label);
  });

process.stdout.write(`${JSON.stringify(themes)}\n`);
