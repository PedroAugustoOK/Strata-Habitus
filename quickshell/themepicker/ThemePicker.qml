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
  property color transitionColor: Colors.primary
  property real transitionOpacity: 0

  readonly property var fallbackTheme: ({
    name: "gruvbox", label: "Gruvbox", mode: "dark", modeLabel: "Escuro",
    bg0: "#0d0d0f", bg1: "#111113", bg2: "#1a1a1c", bg3: "#252527", mid: "#504945",
    text0: "#f5f5f5", text1: "#e0e0e0", text2: "#cecece", text3: "#888888",
    accent: "#d79921", primary: "#d79921", secondary: "#7bafd4",
    success: "#87c181", warning: "#d9bc8c", danger: "#f28779", info: "#7bafd4",
    barBackground: "#111113", barPill: "#161618", barActive: "#d79921",
    barBorder: "#ffffff10",
    panelBackground: "#111113", panelRaised: "#161618", panelBorder: "#ffffff12",
    barStyle: "solid", radiusScale: 1, accentStrength: 1
  })
  readonly property var selectedTheme: themes.length > 0
    ? themes[Math.max(0, Math.min(selectedIdx, themes.length - 1))]
    : fallbackTheme

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

  readonly property string themeListScript: Qt.resolvedUrl("../scripts/theme-list.js").toString().replace("file://", "")
  readonly property string nodeBin: "/run/current-system/sw/bin/node"
  property var themes: []

  function loadThemes() {
    if (themeListProc.running) return
    themeListProc.command = [nodeBin, themeListScript]
    themeListProc.running = true
  }

  function selectCurrentTheme() {
    selectedIdx = 0
    for (let i = 0; i < themes.length; i += 1) {
      if (themes[i].name === currentTheme) {
        selectedIdx = i
        break
      }
    }
    if (visible && themeStrip) themeStrip.positionViewAtIndex(selectedIdx, ListView.Center)
  }

  function toggle() {
    if (visible) {
      closeAnim.start()
      return
    }

    loadThemes()
    selectCurrentTheme()

    visible = true
    transitionOpacity = 0
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
    transitionColor = theme.primary || theme.accent
    Colors.applyTheme(theme)
    currentTheme = theme.name
    themeProc.command = [
      "/run/current-system/sw/bin/bash",
      Paths.scripts + "/set-theme.sh",
      theme.name
    ]
    themeProc.running = true
    applyTransition.start()
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

  SequentialAnimation {
    id: applyTransition
    NumberAnimation { target: root; property: "transitionOpacity"; from: 0; to: 0.18; duration: 70; easing.type: Easing.OutQuad }
    NumberAnimation { target: root; property: "transitionOpacity"; to: 0; duration: 120; easing.type: Easing.InQuad }
    ScriptAction { script: closeAnim.start() }
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
      border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.10)
    }

    Rectangle {
      anchors.fill: parent
      radius: parent.radius
      color: root.transitionColor
      opacity: root.transitionOpacity
      visible: opacity > 0
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
            height: active ? 336 : 306
            radius: 24
            antialiasing: true
            color: modelData.bg0
            border.width: 1
            border.color: active
                ? root.alphaColor(modelData.primary, 0.42)
                : root.alphaColor(modelData.text1, modelData.mode === "light" ? 0.10 : 0.14)
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
                  model: [modelData.primary, modelData.secondary, modelData.info]
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
              spacing: 8

              Text {
                text: modelData.label
                color: modelData.text1
                font { pixelSize: 24; family: "Inter"; weight: Font.DemiBold }
              }

              Text {
                text: modelData.mode === "light" ? "Open daylight" : "Quiet low-light"
                color: modelData.text3
                font { pixelSize: 10; family: "JetBrains Mono" }
              }

              Rectangle {
                width: parent.width
                height: 86
                radius: 18
                antialiasing: true
                color: modelData.panelBackground
                border.width: 1
                border.color: root.alphaColor(modelData.text1, 0.10)

                Column {
                  anchors.fill: parent
                  anchors.margins: 12
                  spacing: 10

                  Rectangle {
                    width: parent.width
                    height: 24
                    radius: 12
                    antialiasing: true
                    color: modelData.barBackground
                    border.width: 1
                    border.color: modelData.barBorder

                    Row {
                      anchors.centerIn: parent
                      spacing: 8

                      Rectangle {
                        width: 58
                        height: 16
                        radius: 8
                        color: modelData.barPill
                        border.width: 1
                        border.color: modelData.barBorder
                        Row {
                          anchors.centerIn: parent
                          spacing: 4
                          Rectangle { width: 12; height: 12; radius: 6; color: modelData.barActive }
                          Rectangle { width: 5; height: 5; radius: 2.5; anchors.verticalCenter: parent.verticalCenter; color: root.alphaColor(modelData.text3, 0.45) }
                          Rectangle { width: 5; height: 5; radius: 2.5; anchors.verticalCenter: parent.verticalCenter; color: root.alphaColor(modelData.text3, 0.45) }
                        }
                      }

                      Rectangle {
                        width: 48
                        height: 16
                        radius: 8
                        color: modelData.barPill
                        border.width: 1
                        border.color: modelData.barBorder
                        Text {
                          anchors.centerIn: parent
                          text: "12:40"
                          color: modelData.secondary
                          font { pixelSize: 8; family: "JetBrains Mono"; weight: Font.DemiBold }
                        }
                      }

                      Rectangle {
                        width: 62
                        height: 16
                        radius: 8
                        color: modelData.barPill
                        border.width: 1
                        border.color: modelData.barBorder
                        Row {
                          anchors.centerIn: parent
                          spacing: 5
                          Rectangle { width: 6; height: 6; radius: 3; color: modelData.info }
                          Rectangle { width: 6; height: 6; radius: 3; color: modelData.success }
                          Rectangle { width: 6; height: 6; radius: 3; color: modelData.warning }
                        }
                      }
                    }
                  }

                  Row {
                    spacing: 8
                    Repeater {
                      model: [modelData.primary, modelData.secondary, modelData.success, modelData.warning, modelData.danger, modelData.info]
                      delegate: Rectangle {
                        required property var modelData
                        width: 24
                        height: 24
                        radius: 12
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
                width: parent.width
                height: 40
                radius: 16
                antialiasing: true
                color: modelData.panelRaised
                border.width: 1
                border.color: root.alphaColor(modelData.info, 0.24)

                Row {
                  anchors.fill: parent
                  anchors.margins: 10
                  spacing: 10
                  Rectangle { width: 4; height: parent.height; radius: 2; color: modelData.info }
                  Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Text { text: "Sistema"; color: modelData.text3; font { pixelSize: 8; family: "JetBrains Mono" } }
                    Text { text: modelData.barStyle + " / " + (modelData.modeLabel || modelData.mode); color: modelData.text1; font { pixelSize: 11; family: "Inter"; weight: Font.Medium } }
                  }
                }
              }

              Rectangle {
                width: 132
                height: 30
                radius: 17
                antialiasing: true
                color: modelData.primary
                visible: active

                Text {
                  anchors.centerIn: parent
                  text: "Pressione Enter"
                  color: modelData.bg0
                  font { pixelSize: 10; family: "JetBrains Mono"; weight: Font.Medium }
                }
              }
            }
          }
        }
      }

      RowLayout {
        Layout.fillWidth: true

        Text {
          text: root.selectedTheme.label + "  •  " + (root.selectedTheme.modeLabel || root.selectedTheme.mode)
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

  Component.onCompleted: loadThemes()

  Process {
    id: themeListProc
    command: []
    stdout: SplitParser {
      onRead: data => {
        const line = data.trim()
        if (line === "") return
        try {
          root.themes = JSON.parse(line)
          root.selectCurrentTheme()
        } catch (e) {
          console.log("theme list parse error:", e.message)
        }
      }
    }
  }

  Process {
    id: themeProc
    command: []
  }
}
