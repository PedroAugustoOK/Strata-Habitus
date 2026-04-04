pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
  id: root

  // Fixos — não mudam entre temas
  readonly property color bg1: "#111113"

  // Dinâmicos — carregados do tema
  property color bg0:      "#0d0d0f"
  property color bg2:      "#161618"
  property color text0:    "#f5f5f5"
  property color text1:    "#e0e0e0"
  property color text2:    "#cecece"
  property color text3:    "#888888"
  property color border:   "#ffffff10"
  property color accent:   "#d79921"
  property color accentDim:"#2a2000"
  property bool  darkMode: true

  property var _themeFile: FileView {
    path: Quickshell.env("HOME") + "/.config/quickshell/themes/current.json"
    watchChanges: true
    onLoaded: {
      try {
        var t = JSON.parse(text())
        root.accent    = t.accent    || "#d79921"
        root.accentDim = t.accentDim || "#2a2000"
        root.bg0       = t.bg0       || "#0d0d0f"
        root.bg2       = t.bg2       || "#161618"
        root.text0     = t.text0     || "#f5f5f5"
        root.text1     = t.text1     || "#e0e0e0"
        root.text2     = t.text2     || "#cecece"
        root.text3     = t.text3     || "#888888"
        root.darkMode  = (t.mode !== "light")
        console.log("Tema carregado:", t.name)
      } catch(e) {
        console.log("Erro ao carregar tema:", e.message)
      }
    }
  }
}
