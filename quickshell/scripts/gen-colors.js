#!/usr/bin/env node
const fs   = require("fs")
const path = require("path")
const home = process.env.HOME

const src  = path.join(home, ".cache/matugen/colors.json")
const dest = path.join(home, ".cache/matugen/colors.qml")

if (!fs.existsSync(src)) {
  console.error("colors.json não encontrado")
  process.exit(0)
}

let raw
try {
  raw = JSON.parse(fs.readFileSync(src, "utf8"))
} catch(e) {
  console.error("Erro ao parsear colors.json:", e.message)
  process.exit(1)
}

// matugen exporta cores em raw.colors.dark ou raw.colors
const dark = raw?.colors?.dark_scheme ?? raw?.colors?.dark ?? {}

const accent    = dark.primary          ?? "#cf9fff"
const accentDim = dark.primary_container ?? "#1e1a2e"
const onAccent  = dark.on_primary       ?? "#1a1225"
const outline   = dark.outline          ?? "#444444"

const qml = `// Gerado automaticamente pelo wallpaper.sh — não editar
pragma Singleton
import QtQuick

QtObject {
  readonly property color accent:    "${accent}"
  readonly property color accentDim: "${accentDim}"
  readonly property color onAccent:  "${onAccent}"
  readonly property color outline:   "${outline}"
}
`

fs.writeFileSync(dest, qml)
console.log("Cores escritas em", dest)
