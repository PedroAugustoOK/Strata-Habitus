pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
  id: root

  readonly property color bg0:    "#0d0d0f"
  readonly property color bg1:    "#111113"
  readonly property color bg2:    "#161618"
  readonly property color text0:  "#f5f5f5"
  readonly property color text1:  "#e0e0e0"
  readonly property color text2:  "#cecece"
  readonly property color text3:  "#888888"
  readonly property color border: "#ffffff10"

  property color accent:    "#cf9fff"
  property color accentDim: "#1e1a2e"

  property var _file: FileView {
    path: Quickshell.env("HOME") + "/.cache/matugen/colors.json"
    watchChanges: true
    onLoaded: {
      try {
        const data = JSON.parse(text())
        if (data?.colors?.primary?.dark?.color)
          root.accent = data.colors.primary.dark.color
        if (data?.colors?.primary_container?.dark?.color)
          root.accentDim = data.colors.primary_container.dark.color
        console.log("Acento aplicado:", root.accent)
      } catch(e) {
        console.log("Erro:", e.message)
      }
    }
  }
}
