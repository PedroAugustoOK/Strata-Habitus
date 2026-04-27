import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
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
  property int selectedIdx: 0
  property real cardYOffset: 18

  readonly property var selectedTheme: themes[Math.max(0, Math.min(selectedIdx, themes.length - 1))]

  function alphaColor(hex, alpha) {
    const value = String(hex || "#000000")
    if (value.length < 7 || value[0] !== "#") return Qt.rgba(0, 0, 0, alpha)
    return Qt.rgba(
      parseInt(value.slice(1, 3), 16) / 255,
      parseInt(value.slice(3, 5), 16) / 255,
      parseInt(value.slice(5, 7), 16) / 255,
      alpha
    )
  }

  readonly property var themes: [
    { name: "gruvbox",  label: "Gruvbox", mode: "Escuro",
      bg0: "#0d0d0f", bg1: "#111113", bg2: "#1a1a1c", bg3: "#252527", mid: "#504945",
      text0: "#f5f5f5", text1: "#e0e0e0", text2: "#cecece", text3: "#888888",
      accent: "#d79921", accentDim: "#2a2000" },
    { name: "rosepine", label: "Rose Pine", mode: "Claro",
      bg0: "#f0ece4", bg1: "#e8e4dc", bg2: "#dedad2", bg3: "#d5d0c8", mid: "#9893a5",
      text0: "#2a2a2e", text1: "#2a2a2a", text2: "#3a3a3e", text3: "#6e6a78",
      accent: "#b4637a", accentDim: "#f1d4dc" },
    { name: "nord", label: "Nord", mode: "Escuro",
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

  function toggle() {
    if (visible) {
      closeAnim.start()
      return
    }

    selectedIdx = 0
    for (let i = 0; i < themes.length; i += 1) {
      if (themes[i].name === currentTheme) {
        selectedIdx = i
        break
      }
    }

    visible = true
    card.opacity = 0
    card.scale = 0.985
    cardYOffset = 16
    openAnim.start()
  }

  function close() {
    closeAnim.start()
  }

  function moveSelection(delta) {
    selectedIdx = Math.max(0, Math.min(themes.length - 1, selectedIdx + delta))
    themeStrip.positionViewAtIndex(selectedIdx, ListView.Center)
  }

  onSelectedIdxChanged: {
    if (visible && themeStrip) themeStrip.positionViewAtIndex(selectedIdx, ListView.Center)
  }

  function applyThemeSelection(theme) {
    if (!theme) return
    Colors.applyTheme(theme)
    currentTheme = theme.name
    themeProc.command = ["/run/current-system/sw/bin/bash", Paths.scripts + "/set-theme.sh", theme.name]
    themeProc.running = true
    closeAnim.start()
  }

  SequentialAnimation {
    id: openAnim
    ParallelAnimation {
      NumberAnimation { target: root; property: "cardYOffset"; from: 16; to: 0; duration: 190; easing.type: Easing.OutCubic }
      NumberAnimation { target: card; property: "opacity"; from: 0; to: 1; duration: 140; easing.type: Easing.OutQuad }
      NumberAnimation { target: card; property: "scale"; from: 0.985; to: 1; duration: 190; easing.type: Easing.OutCubic }
    }
    ScriptAction { script: keyGrabber.forceActiveFocus() }
  }

  SequentialAnimation {
    id: closeAnim
    ParallelAnimation {
      NumberAnimation { target: root; property: "cardYOffset"; to: 10; duration: 120; easing.type: Easing.InCubic }
      NumberAnimation { target: card; property: "scale"; to: 0.992; duration: 120; easing.type: Easing.InCubic }
      NumberAnimation { target: card; property: "opacity"; to: 0; duration: 95; easing.type: Easing.InQuad }
    }
    ScriptAction { script: root.visible = false }
  }

  MouseArea {
    anchors.fill: parent
    onClicked: root.close()
  }

  Rectangle {
    id: card
    anchors.centerIn: parent
    anchors.verticalCenterOffset: cardYOffset
    width: 1240
    height: 470
    radius: 28
    antialiasing: true
    color: Colors.bg1
    border.width: 1
    border.color: Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, Colors.darkMode ? 0.18 : 0.22)
    clip: true
    opacity: 0

    Rectangle {
      anchors.fill: parent
      radius: parent.radius
      antialiasing: true
      gradient: Gradient {
        GradientStop { position: 0.0; color: Qt.rgba(Colors.bg2.r, Colors.bg2.g, Colors.bg2.b, Colors.darkMode ? 0.95 : 0.92) }
        GradientStop { position: 1.0; color: Qt.rgba(Colors.bg1.r, Colors.bg1.g, Colors.bg1.b, 0.98) }
      }
    }

    Rectangle {
      anchors.fill: parent
      anchors.margins: 1
      radius: parent.radius - 1
      color: "transparent"
      border.width: 1
      border.color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.10)
    }

    Item {
      id: keyGrabber
      anchors.fill: parent
      focus: true
      Keys.onPressed: function(e) {
        if (e.key === Qt.Key_Escape) {
          root.close()
          e.accepted = true
        } else if (e.key === Qt.Key_Left) {
          root.moveSelection(-1)
          e.accepted = true
        } else if (e.key === Qt.Key_Right) {
          root.moveSelection(1)
          e.accepted = true
        } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
          root.applyThemeSelection(root.selectedTheme)
          e.accepted = true
        }
      }
    }

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 24
      spacing: 20

      RowLayout {
        Layout.fillWidth: true
        spacing: 14

        ColumnLayout {
          spacing: 4
          Text {
            text: "Faixa de Temas"
            color: Colors.text1
            font { pixelSize: 28; family: "Inter"; weight: Font.DemiBold }
          }
          Text {
            text: "Uma faixa curada de atmosferas visuais."
            color: Colors.text3
            font { pixelSize: 11; family: "JetBrains Mono" }
          }
        }

        Item { Layout.fillWidth: true }

        Rectangle {
          radius: 12
          antialiasing: true
          color: root.alphaColor(root.selectedTheme.accent, 0.14)
          border.width: 1
          border.color: root.alphaColor(root.selectedTheme.accent, 0.24)
          implicitWidth: themeCount.implicitWidth + 18
          implicitHeight: 28

          Text {
            id: themeCount
            anchors.centerIn: parent
            text: (root.selectedIdx + 1) + " / " + root.themes.length
            color: root.selectedTheme.accent
            font { pixelSize: 10; family: "JetBrains Mono" }
          }
        }
      }

      ListView {
        id: themeStrip
        Layout.fillWidth: true
        Layout.fillHeight: true
        orientation: ListView.Horizontal
        leftMargin: Math.max(0, width / 2 - 160)
        rightMargin: Math.max(0, width / 2 - 160)
        spacing: 18
        model: root.themes
        clip: false
        snapMode: ListView.SnapToItem
        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: width / 2 - 160
        preferredHighlightEnd: width / 2 + 160
        cacheBuffer: 2400

        Component.onCompleted: positionViewAtIndex(root.selectedIdx, ListView.Center)

        delegate: Item {
          required property var modelData
          required property int index

          width: 320
          height: themeStrip.height

          readonly property bool active: root.selectedIdx === index

          scale: active ? 1.0 : 0.92
          opacity: active ? 1.0 : 0.72

          Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
          Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }

          Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            width: 296
            height: active ? 314 : 286
            radius: 24
            antialiasing: true
            color: modelData.bg0
            border.width: 1
            border.color: active
              ? root.alphaColor(modelData.accent, 0.42)
              : root.alphaColor(modelData.text1, modelData.mode === "Claro" ? 0.10 : 0.14)
            clip: true

            Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            Rectangle {
              anchors.fill: parent
              radius: parent.radius
              antialiasing: true
              gradient: Gradient {
                GradientStop { position: 0.0; color: modelData.bg1 }
                GradientStop { position: 1.0; color: modelData.bg0 }
              }
            }

            Rectangle {
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.top: parent.top
              height: 44
              color: modelData.bg1
              radius: parent.radius

              Row {
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                Repeater {
                  model: [modelData.accent, modelData.mid, modelData.bg3]
                  delegate: Rectangle {
                    required property var modelData
                    width: 9
                    height: 9
                    radius: 4.5
                    antialiasing: true
                    color: modelData
                  }
                }
              }
            }

            Column {
              anchors.fill: parent
              anchors.topMargin: 66
              anchors.leftMargin: 18
              anchors.rightMargin: 18
              anchors.bottomMargin: 18
              spacing: 14

              Text {
                text: modelData.label
                color: modelData.text1
                font { pixelSize: 24; family: "Inter"; weight: Font.DemiBold }
              }

              Text {
                text: modelData.mode === "Claro" ? "Open daylight" : "Quiet low-light"
                color: modelData.text3
                font { pixelSize: 10; family: "JetBrains Mono" }
              }

              Row {
                spacing: 10

                Rectangle {
                  width: 116
                  height: 42
                  radius: 14
                  antialiasing: true
                  color: modelData.bg2
                  border.width: 1
                  border.color: root.alphaColor(modelData.text1, 0.10)

                  Column {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 2
                    Text {
                      text: "Modo"
                      color: modelData.text3
                      font { pixelSize: 9; family: "JetBrains Mono" }
                    }
                    Text {
                      text: modelData.mode
                      color: modelData.text1
                      font { pixelSize: 12; family: "Inter"; weight: Font.Medium }
                    }
                  }
                }

                Rectangle {
                  width: 134
                  height: 42
                  radius: 14
                  antialiasing: true
                  color: root.alphaColor(modelData.accent, 0.18)
                  border.width: 1
                  border.color: root.alphaColor(modelData.accent, 0.24)

                  Column {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 2
                    Text {
                      text: "Destaque"
                      color: modelData.text3
                      font { pixelSize: 9; family: "JetBrains Mono" }
                    }
                    Text {
                      text: modelData.accent.toUpperCase()
                      color: modelData.accent
                      font { pixelSize: 11; family: "JetBrains Mono"; weight: Font.Medium }
                    }
                  }
                }
              }

              Rectangle {
                width: parent.width
                height: 70
                radius: 18
                antialiasing: true
                color: modelData.bg2
                border.width: 1
                border.color: root.alphaColor(modelData.text1, 0.10)

                Column {
                  anchors.fill: parent
                  anchors.margins: 14
                  spacing: 8

                  Text {
                    text: "Tom da interface"
                    color: modelData.text3
                    font { pixelSize: 9; family: "JetBrains Mono" }
                  }

                  Row {
                    spacing: 8
                    Repeater {
                      model: [modelData.bg0, modelData.bg1, modelData.bg2, modelData.bg3, modelData.text1, modelData.accent]
                      delegate: Rectangle {
                        required property var modelData
                        width: 28
                        height: 28
                        radius: 14
                        antialiasing: true
                        color: modelData
                        border.width: 1
                        border.color: Qt.rgba(0, 0, 0, 0.10)
                      }
                    }
                  }
                }
              }

              Rectangle {
                width: 132
                height: 34
                radius: 17
                antialiasing: true
                color: modelData.accent
                visible: active

                Text {
                  anchors.centerIn: parent
                  text: "Pressione Enter"
                  color: modelData.bg0
                  font { pixelSize: 10; family: "JetBrains Mono"; weight: Font.Medium }
                }
              }
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              onEntered: {
                root.selectedIdx = index
                themeStrip.positionViewAtIndex(index, ListView.Center)
              }
              onClicked: {
                if (root.selectedIdx === index) root.applyThemeSelection(modelData)
                else {
                  root.selectedIdx = index
                  themeStrip.positionViewAtIndex(index, ListView.Center)
                }
              }
            }
          }
        }
      }

      RowLayout {
        Layout.fillWidth: true

        Text {
          text: root.selectedTheme.label + "  •  " + root.selectedTheme.mode
          color: Colors.text1
          font { pixelSize: 13; family: "Inter"; weight: Font.Medium }
        }

        Item { Layout.fillWidth: true }

        Text {
          text: "← → navegar  •  Enter aplicar  •  Esc fechar"
          color: Colors.text3
          font { pixelSize: 10; family: "JetBrains Mono" }
        }
      }
    }
  }

  FileView {
    path: Paths.state + "/current-theme.json"
    watchChanges: true
    onFileChanged: reload()
    onLoaded: {
      try {
        const t = JSON.parse(text())
        root.currentTheme = t.name || "gruvbox"
      } catch (e) {}
    }
  }

  Process {
    id: themeProc
    command: []
  }
}
