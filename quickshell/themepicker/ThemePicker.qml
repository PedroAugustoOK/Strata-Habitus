import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import ".."

PanelWindow {
  id: root
  anchors { top: true; bottom: true; left: true; right: true }
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  focusable: true
  visible: false
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

  property string currentTheme: "gruvbox"
  property int    selectedIdx:  0
  readonly property int columns: 4
  readonly property int cardW: 196
  readonly property int cardH: 180

  readonly property var themes: [
    { name: "gruvbox",  label: "Gruvbox",   mode: "Escuro",
      bg0: "#0d0d0f", bg1: "#111113", bg2: "#1a1a1c", bg3: "#252527", mid: "#504945",
      text0: "#f5f5f5", text1: "#e0e0e0", text2: "#cecece", text3: "#888888",
      accent: "#d79921", accentDim: "#2a2000" },
    { name: "rosepine", label: "Rose Pine", mode: "Claro",
      bg0: "#f0ece4", bg1: "#e8e4dc", bg2: "#dedad2", bg3: "#d5d0c8", mid: "#9893a5",
      text0: "#2a2a2e", text1: "#2a2a2a", text2: "#3a3a3e", text3: "#6e6a78",
      accent: "#b4637a", accentDim: "#f1d4dc" },
    { name: "nord",     label: "Nord",      mode: "Escuro",
      bg0: "#0d0d0f", bg1: "#111113", bg2: "#161618", bg3: "#2a3140", mid: "#4c566a",
      text0: "#eceff4", text1: "#e5e9f0", text2: "#d8dee9", text3: "#7b88a1",
      accent: "#88c0d0", accentDim: "#1a2a30" },
    { name: "tokyonight", label: "Tokyo Night", mode: "Escuro",
      bg0: "#0b0f14", bg1: "#111827", bg2: "#161d2f", bg3: "#20283b", mid: "#414868",
      text0: "#d5d6db", text1: "#c8d3f5", text2: "#a9b1d6", text3: "#6b7394",
      accent: "#7aa2f7", accentDim: "#1a233a" },
    { name: "everforest", label: "Everforest", mode: "Escuro",
      bg0: "#0d1512", bg1: "#111b18", bg2: "#17221e", bg3: "#22312b", mid: "#56635f",
      text0: "#f0f2e8", text1: "#e5e8dc", text2: "#d3c6aa", text3: "#859289",
      accent: "#a7c080", accentDim: "#243529" },
    { name: "kanagawa", label: "Kanagawa", mode: "Escuro",
      bg0: "#0f0f14", bg1: "#14151d", bg2: "#1b1d27", bg3: "#223249", mid: "#54546d",
      text0: "#f2ecbc", text1: "#dcd7ba", text2: "#c8c093", text3: "#7e9cd8",
      accent: "#7e9cd8", accentDim: "#1e2433" },
    { name: "catppuccinlatte", label: "Catppuccin Latte", mode: "Claro",
      bg0: "#eff1f5", bg1: "#e6e9ef", bg2: "#dce0e8", bg3: "#ccd0da", mid: "#9ca0b0",
      text0: "#303446", text1: "#4c4f69", text2: "#5c5f77", text3: "#7c7f93",
      accent: "#1e66f5", accentDim: "#dfe7fb" },
    { name: "flexoki", label: "Flexoki", mode: "Claro",
      bg0: "#fffcf0", bg1: "#f2f0e5", bg2: "#e6e4d9", bg3: "#d8d4c8", mid: "#878580",
      text0: "#100f0f", text1: "#201f1f", text2: "#575653", text3: "#878580",
      accent: "#bc5215", accentDim: "#f3e1d5" },
    { name: "oxocarbon", label: "Oxocarbon", mode: "Escuro",
      bg0: "#0b0d10", bg1: "#111418", bg2: "#1a1f24", bg3: "#25313b", mid: "#525252",
      text0: "#f2f4f8", text1: "#dde1e6", text2: "#b6c2cf", text3: "#6f7b87",
      accent: "#78a9ff", accentDim: "#1d2633" }
  ]

  function applyThemeSelection(theme) {
    Colors.applyTheme(theme)
    currentTheme = theme.name
    themeProc.command = ["bash", Paths.scripts + "/set-theme.sh", theme.name]
    themeProc.running = true
    root.close()
  }

  function toggle() {
    if (visible) {
      closeAnim.start()
    } else {
      selectedIdx = 0
      for (var i = 0; i < themes.length; i++) {
        if (themes[i].name === currentTheme) { selectedIdx = i; break }
      }
      visible = true
      picker.scale   = 0.88
      picker.opacity = 0
      openAnim.start()
    }
  }

  function close() { closeAnim.start() }

  SequentialAnimation {
    id: openAnim
    NumberAnimation { target: picker; property: "opacity"; to: 1; duration: 60 }
    NumberAnimation { target: picker; property: "scale"; to: 1.02; duration: 180; easing.type: Easing.OutCubic }
    NumberAnimation { target: picker; property: "scale"; to: 1.0; duration: 60; easing.type: Easing.InOutQuad }
  }

  SequentialAnimation {
    id: closeAnim
    NumberAnimation { target: picker; property: "scale"; to: 0.88; duration: 140; easing.type: Easing.InCubic }
    NumberAnimation { target: picker; property: "opacity"; to: 0; duration: 50 }
    ScriptAction { script: root.visible = false }
  }

  MouseArea {
    anchors.fill: parent
    onClicked: root.close()
  }

  Rectangle {
    id: picker
    anchors.centerIn: parent
    width:   columns * cardW + (columns - 1) * 12 + 36
    height:  Math.ceil(themes.length / columns) * cardH + (Math.ceil(themes.length / columns) - 1) * 12 + 40
    radius:  16
    color:   Colors.bg1
    border.color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.12)
    border.width: 1
    scale:   0.88
    opacity: 0
    transformOrigin: Item.Center

    MouseArea { anchors.fill: parent }

    Item {
      id: keyItem
      anchors.fill: parent
      focus: true
      Keys.onPressed: function(e) {
        if (e.key === Qt.Key_Escape) {
          root.close()
        } else if (e.key === Qt.Key_Left) {
          root.selectedIdx = Math.max(0, root.selectedIdx - 1)
        } else if (e.key === Qt.Key_Right) {
          root.selectedIdx = Math.min(root.themes.length - 1, root.selectedIdx + 1)
        } else if (e.key === Qt.Key_Return) {
          var t = root.themes[root.selectedIdx]
          root.applyThemeSelection(t)
        }
      }
    }

    Grid {
      anchors.centerIn: parent
      columns: root.columns
      columnSpacing: 12
      rowSpacing: 12

      Repeater {
        model: root.themes
        delegate: Item {
          required property var modelData
          required property int index

          readonly property bool selected: root.selectedIdx === index

          width:  root.cardW
          height: root.cardH

          // card com clip
          Rectangle {
            id: card
            anchors.fill: parent
            radius: 12
            color:  modelData.bg1
            clip:   true

            Column {
              anchors { top: parent.top; left: parent.left; right: parent.right }
              spacing: 0
              Rectangle { width: parent.width; height: 29; color: modelData.bg0 }
              Rectangle { width: parent.width; height: 29; color: modelData.bg2 }
              Rectangle { width: parent.width; height: 29; color: modelData.bg3 }
              Rectangle { width: parent.width; height: 16; color: modelData.mid }
              Rectangle { width: parent.width; height: 13; color: modelData.accent }
            }

            Rectangle {
              anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
              height: 64
              color:  modelData.bg1

              Rectangle {
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: 1
                color:  Qt.rgba(1,1,1,0.06)
              }

              Text {
                anchors { left: parent.left; leftMargin: 12; top: parent.top; topMargin: 12 }
                text:  modelData.label
                color: selected ? modelData.accent : (modelData.mode === "Claro" ? "#555" : "#ccc")
                font { pixelSize: 13; family: "Roboto"; weight: Font.DemiBold }
                Behavior on color { ColorAnimation { duration: 150 } }
              }

              Text {
                anchors { left: parent.left; leftMargin: 12; bottom: parent.bottom; bottomMargin: 12 }
                text:  modelData.mode.toUpperCase()
                color: "#666"
                font { pixelSize: 9; family: "JetBrainsMono Nerd Font" }
              }

              Row {
                anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                spacing: 5
                Repeater {
                  model: [modelData.bg0, modelData.mid, modelData.accent]
                  delegate: Rectangle {
                    required property var modelData
                    width: 10; height: 10; radius: 5
                    color: modelData
                    border.color: Qt.rgba(1,1,1,0.1)
                    border.width: 1
                  }
                }
              }
            }
          }

          // borda FORA do clip, filho direto do Item delegate
          Rectangle {
            anchors.fill: card
            radius: 0
            color:  "transparent"
            border.color: selected ? modelData.accent : Qt.rgba(1,1,1,0.05)
            border.width: selected ? 2 : 1
            z: 10
            Behavior on border.color { ColorAnimation { duration: 150 } }
          }

          MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape:  Qt.PointingHandCursor
            z: 20
            onEntered: root.selectedIdx = index
            onClicked: root.applyThemeSelection(modelData)
          }
        }
      }
    }
  }

  onVisibleChanged: {
    if (visible) keyItem.forceActiveFocus()
  }

  FileView {
    path: Paths.state + "/current-theme.json"
    watchChanges: true
    onFileChanged: reload()
    onLoaded: {
      try {
        var t = JSON.parse(text())
        root.currentTheme = t.name || "gruvbox"
      } catch(e) {}
    }
  }

  Process { id: themeProc; command: [] }
}
