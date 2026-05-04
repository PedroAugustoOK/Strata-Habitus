pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
  id: root

  property color bg0: "#0d0d0f"
  property color bg1: "#111113"
  property color bg2: "#161618"
  property color bg3: "#252527"
  property color text0: "#f5f5f5"
  property color text1: "#e0e0e0"
  property color text2: "#cecece"
  property color text3: "#888888"
  property color border: "#ffffff10"
  property color accent: "#d79921"
  property color accentDim: "#2a2000"
  property color primary: "#d79921"
  property color secondary: "#7bafd4"
  property color success: "#87c181"
  property color warning: "#d9bc8c"
  property color danger: "#f28779"
  property color info: "#7bafd4"
  property color barBackground: "#111113"
  property color barPill: "#161618"
  property color barBorder: "transparent"
  property color barActive: "#d79921"
  property color panelBackground: "#111113"
  property color panelRaised: "#161618"
  property color panelBorder: "#ffffff10"
  property color selection: "#d79921"
  property bool darkMode: true
  property string barStyle: "solid"
  property real accentStrength: 1.0
  property real panelOpacity: 0.98
  property real radiusScale: 1.0
  property int themeTransitionDuration: 220

  Behavior on bg0 { ColorAnimation { duration: root.themeTransitionDuration; easing.type: Easing.OutCubic } }
  Behavior on bg1 { ColorAnimation { duration: root.themeTransitionDuration; easing.type: Easing.OutCubic } }
  Behavior on bg2 { ColorAnimation { duration: root.themeTransitionDuration; easing.type: Easing.OutCubic } }
  Behavior on bg3 { ColorAnimation { duration: root.themeTransitionDuration; easing.type: Easing.OutCubic } }
  Behavior on text0 { ColorAnimation { duration: root.themeTransitionDuration; easing.type: Easing.OutCubic } }
  Behavior on text1 { ColorAnimation { duration: root.themeTransitionDuration; easing.type: Easing.OutCubic } }
  Behavior on text2 { ColorAnimation { duration: root.themeTransitionDuration; easing.type: Easing.OutCubic } }
  Behavior on text3 { ColorAnimation { duration: root.themeTransitionDuration; easing.type: Easing.OutCubic } }
  Behavior on border { ColorAnimation { duration: root.themeTransitionDuration; easing.type: Easing.OutCubic } }
  Behavior on accent { ColorAnimation { duration: root.themeTransitionDuration; easing.type: Easing.OutCubic } }
  Behavior on accentDim { ColorAnimation { duration: root.themeTransitionDuration; easing.type: Easing.OutCubic } }
  Behavior on primary { ColorAnimation { duration: root.themeTransitionDuration; easing.type: Easing.OutCubic } }
  Behavior on secondary { ColorAnimation { duration: root.themeTransitionDuration; easing.type: Easing.OutCubic } }
  Behavior on success { ColorAnimation { duration: root.themeTransitionDuration; easing.type: Easing.OutCubic } }
  Behavior on warning { ColorAnimation { duration: root.themeTransitionDuration; easing.type: Easing.OutCubic } }
  Behavior on danger { ColorAnimation { duration: root.themeTransitionDuration; easing.type: Easing.OutCubic } }
  Behavior on info { ColorAnimation { duration: root.themeTransitionDuration; easing.type: Easing.OutCubic } }
  Behavior on barBackground { ColorAnimation { duration: root.themeTransitionDuration; easing.type: Easing.OutCubic } }
  Behavior on barPill { ColorAnimation { duration: root.themeTransitionDuration; easing.type: Easing.OutCubic } }
  Behavior on barBorder { ColorAnimation { duration: root.themeTransitionDuration; easing.type: Easing.OutCubic } }
  Behavior on barActive { ColorAnimation { duration: root.themeTransitionDuration; easing.type: Easing.OutCubic } }
  Behavior on panelBackground { ColorAnimation { duration: root.themeTransitionDuration; easing.type: Easing.OutCubic } }
  Behavior on panelRaised { ColorAnimation { duration: root.themeTransitionDuration; easing.type: Easing.OutCubic } }
  Behavior on panelBorder { ColorAnimation { duration: root.themeTransitionDuration; easing.type: Easing.OutCubic } }
  Behavior on selection { ColorAnimation { duration: root.themeTransitionDuration; easing.type: Easing.OutCubic } }
  Behavior on accentStrength { NumberAnimation { duration: root.themeTransitionDuration; easing.type: Easing.OutCubic } }
  Behavior on panelOpacity { NumberAnimation { duration: root.themeTransitionDuration; easing.type: Easing.OutCubic } }
  Behavior on radiusScale { NumberAnimation { duration: root.themeTransitionDuration; easing.type: Easing.OutCubic } }

  property var _theme: ({})
  property var _preferences: ({})

  function _hexPart(value, start) {
    return parseInt(String(value).slice(start, start + 2), 16) / 255
  }

  function alpha(hex, amount) {
    const value = String(hex || "#000000")
    if (value.length < 7 || value[0] !== "#") return Qt.rgba(0, 0, 0, amount)
    return Qt.rgba(_hexPart(value, 1), _hexPart(value, 3), _hexPart(value, 5), amount)
  }

  function pick(obj, path, fallback) {
    let value = obj
    const parts = String(path).split(".")
    for (let i = 0; i < parts.length; i += 1) {
      if (!value || value[parts[i]] === undefined) return fallback
      value = value[parts[i]]
    }
    return value === undefined || value === null || value === "" ? fallback : value
  }

  function refresh() {
    const t = _theme || ({})
    const p = _preferences || ({})
    const semantic = t.semantic || ({})
    const ui = t.ui || ({})

    bg0 = t.bg0 || "#0d0d0f"
    bg1 = t.bg1 || "#111113"
    bg2 = t.bg2 || "#161618"
    bg3 = t.bg3 || bg2
    text0 = t.text0 || "#f5f5f5"
    text1 = t.text1 || "#e0e0e0"
    text2 = t.text2 || "#cecece"
    text3 = t.text3 || "#888888"
    accent = t.accent || "#d79921"
    accentDim = t.accentDim || accent
    primary = semantic.primary || t.primary || accent
    secondary = semantic.secondary || t.secondary || semantic.info || accent
    success = semantic.success || t.success || "#87c181"
    warning = semantic.warning || t.warning || "#d9bc8c"
    danger = semantic.danger || t.danger || "#f28779"
    info = semantic.info || t.info || secondary
    darkMode = (t.mode !== "light")

    const preferencesEnabled = p.enabled === true

    barStyle = preferencesEnabled && p.barStyle !== undefined ? p.barStyle : pick(ui, "bar.style", "solid")
    accentStrength = Number(preferencesEnabled && p.accentStrength !== undefined ? p.accentStrength : pick(ui, "accentStrength", 1.0))
    panelOpacity = Number(preferencesEnabled && p.panelOpacity !== undefined ? p.panelOpacity : pick(ui, "panel.opacity", 0.98))
    radiusScale = Number(preferencesEnabled && p.radiusScale !== undefined ? p.radiusScale : pick(ui, "radiusScale", 1.0))

    barBackground = pick(ui, "bar.background", bg1)
    barPill = pick(ui, "bar.pill", bg2)
    barBorder = pick(ui, "bar.border", "transparent")
    barActive = pick(ui, "bar.active", primary)
    panelBackground = pick(ui, "panel.background", bg1)
    panelRaised = pick(ui, "panel.raised", bg2)
    panelBorder = pick(ui, "panel.border", darkMode ? "#ffffff12" : "#00000018")
    selection = pick(ui, "selection.background", primary)
    border = panelBorder

    if (barStyle === "tinted" && pick(ui, "bar.background", "") === "") barBackground = accentDim
  }

  function applyTheme(t) {
    _theme = t || ({})
    refresh()
  }

  property var _themeFile: FileView {
    path: Paths.state + "/current-theme.json"
    watchChanges: true
    onFileChanged: reload()
    onLoaded: {
      try {
        root.applyTheme(JSON.parse(text()))
      } catch(e) {
        console.log("theme parse error:", e.message)
      }
    }
  }

  property var _preferencesFile: FileView {
    path: Paths.state + "/theme-preferences.json"
    watchChanges: true
    onFileChanged: reload()
    onLoaded: {
      try {
        root._preferences = JSON.parse(text())
      } catch(e) {
        root._preferences = ({})
      }
      root.refresh()
    }
  }
}
