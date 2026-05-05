import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import ".."

Item {
  id: root

  property bool open: false
  property string currentTheme: "gruvbox"
  property int selectedIdx: 0
  property color transitionColor: Colors.primary
  property real transitionOpacity: 0
  property var themes: []

  readonly property string themeListScript: Qt.resolvedUrl("../scripts/theme-list.js").toString().replace("file://", "")
  readonly property string nodeBin: "/run/current-system/sw/bin/node"
  readonly property var selectedTheme: themes.length > 0 ? themes[Math.max(0, Math.min(selectedIdx, themes.length - 1))] : null

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
    if (themeGrid) themeGrid.positionViewAtIndex(selectedIdx, GridView.Contain)
  }

  function toggle() {
    if (open) {
      close()
      return
    }

    loadThemes()
    selectCurrentTheme()
    transitionOpacity = 0
    open = true
    OverlayState.setActive("themepicker")
    focusTimer.restart()
  }

  function close() {
    open = false
    OverlayState.clear("themepicker")
  }

  function moveSelection(delta) {
    if (themes.length === 0) return
    selectedIdx = Math.max(0, Math.min(themes.length - 1, selectedIdx + delta))
    themeGrid.positionViewAtIndex(selectedIdx, GridView.Contain)
  }

  function applyThemeSelection(theme) {
    if (!theme) return
    transitionColor = theme.primary || theme.accent
    Colors.applyTheme(theme)
    currentTheme = theme.name
    themeProc.command = ["/run/current-system/sw/bin/bash", Paths.scripts + "/set-theme.sh", theme.name]
    themeProc.running = true
    applyTransition.start()
  }

  onSelectedIdxChanged: {
    if (open && themeGrid) themeGrid.positionViewAtIndex(selectedIdx, GridView.Contain)
  }

  anchors.fill: parent

  BottomDrawer {
    id: drawer
    width: Math.min(1040, parent.width - 96)
    height: 430
    gutter: 10
    open: root.open

    FrameSurface {
      anchors.fill: parent
      radius: 18
      attachedEdge: "bottom"
      borderColor: Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, Colors.darkMode ? 0.18 : 0.22)

      Rectangle {
        anchors.fill: parent
        radius: 18
        color: root.transitionColor
        opacity: root.transitionOpacity
        visible: opacity > 0
      }

      Item {
        id: keyGrabber
        anchors.fill: parent
        focus: root.open
        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Escape) {
            root.close()
            event.accepted = true
          } else if (event.key === Qt.Key_Left) {
            root.moveSelection(-1)
            event.accepted = true
          } else if (event.key === Qt.Key_Right) {
            root.moveSelection(1)
            event.accepted = true
          } else if (event.key === Qt.Key_Up) {
            root.moveSelection(-3)
            event.accepted = true
          } else if (event.key === Qt.Key_Down) {
            root.moveSelection(3)
            event.accepted = true
          } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.applyThemeSelection(root.selectedTheme)
            event.accepted = true
          }
        }
      }

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 22
        spacing: 16

        RowLayout {
          Layout.fillWidth: true
          spacing: 12

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
              Layout.fillWidth: true
              text: "Faixa de Temas"
              color: Colors.text1
              font { pixelSize: 24; family: "Inter"; weight: Font.DemiBold }
              elide: Text.ElideRight
            }

            Text {
              Layout.fillWidth: true
              text: "Escolha a identidade visual do Strata."
              color: Colors.text3
              font { pixelSize: 11; family: "JetBrains Mono" }
              elide: Text.ElideRight
            }
          }

          Rectangle {
            radius: 12
            implicitWidth: themeCount.implicitWidth + 18
            implicitHeight: 28
            color: root.selectedTheme ? root.alphaColor(root.selectedTheme.accent, 0.14) : Qt.rgba(1, 1, 1, 0.06)
            border.width: 1
            border.color: root.selectedTheme ? root.alphaColor(root.selectedTheme.accent, 0.24) : Qt.rgba(1, 1, 1, 0.08)

            Text {
              id: themeCount
              anchors.centerIn: parent
              text: root.themes.length > 0 ? ((root.selectedIdx + 1) + " / " + root.themes.length) : "0 / 0"
              color: root.selectedTheme ? root.selectedTheme.accent : Colors.text3
              font { pixelSize: 10; family: "JetBrains Mono" }
            }
          }
        }

        GridView {
          id: themeGrid
          Layout.fillWidth: true
          Layout.fillHeight: true
          cellWidth: Math.max(240, Math.floor(width / 3))
          cellHeight: 230
          clip: true
          boundsBehavior: Flickable.StopAtBounds
          model: root.themes

          delegate: Item {
            required property var modelData
            required property int index
            readonly property bool active: root.selectedIdx === index

            width: themeGrid.cellWidth
            height: themeGrid.cellHeight
            opacity: active ? 1 : 0.76

            Behavior on opacity {
              NumberAnimation { duration: 140; easing.type: Easing.OutQuad }
            }

            Rectangle {
              anchors { fill: parent; margins: 8 }
              radius: 16
              antialiasing: true
              color: modelData.bg0
              border.width: 1
              border.color: active
                ? root.alphaColor(modelData.primary, 0.46)
                : root.alphaColor(modelData.text1, modelData.mode === "light" ? 0.10 : 0.14)
              clip: true

              Rectangle {
                anchors.fill: parent
                radius: parent.radius
                gradient: Gradient {
                  GradientStop { position: 0.0; color: modelData.bg1 }
                  GradientStop { position: 1.0; color: modelData.bg0 }
                }
              }

              Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                Row {
                  spacing: 7
                  Repeater {
                    model: [modelData.primary, modelData.secondary, modelData.success, modelData.warning, modelData.danger, modelData.info]
                    delegate: Rectangle {
                      required property var modelData
                      width: 16
                      height: 16
                      radius: 8
                      antialiasing: true
                      color: modelData
                    }
                  }
                }

                Text {
                  width: parent.width
                  text: modelData.label
                  color: modelData.text1
                  font { pixelSize: 20; family: "Inter"; weight: Font.DemiBold }
                  elide: Text.ElideRight
                }

                Text {
                  width: parent.width
                  text: (modelData.modeLabel || modelData.mode) + " / " + modelData.barStyle
                  color: modelData.text3
                  font { pixelSize: 10; family: "JetBrains Mono" }
                  elide: Text.ElideRight
                }

                Rectangle {
                  width: parent.width
                  height: 58
                  radius: 14
                  color: modelData.panelBackground
                  border.width: 1
                  border.color: root.alphaColor(modelData.text1, 0.10)

                  Rectangle {
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                    height: 18
                    radius: 9
                    color: modelData.barBackground
                    border.width: 1
                    border.color: modelData.barBorder
                  }

                  Row {
                    anchors { left: parent.left; bottom: parent.bottom; margins: 10 }
                    spacing: 8
                    Rectangle { width: 44; height: 12; radius: 6; color: modelData.barPill; border.width: 1; border.color: modelData.barBorder }
                    Rectangle { width: 62; height: 12; radius: 6; color: modelData.barActive }
                  }
                }

                Rectangle {
                  width: 118
                  height: 28
                  radius: 14
                  color: modelData.primary
                  visible: active

                  Text {
                    anchors.centerIn: parent
                    text: "Enter aplica"
                    color: modelData.bg0
                    font { pixelSize: 10; family: "JetBrains Mono"; weight: Font.Medium }
                  }
                }
              }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: root.selectedIdx = index
                onClicked: {
                  root.selectedIdx = index
                  root.applyThemeSelection(modelData)
                }
              }
            }
          }
        }

        RowLayout {
          Layout.fillWidth: true

          Text {
            Layout.fillWidth: true
            text: root.selectedTheme ? (root.selectedTheme.label + "  •  " + (root.selectedTheme.modeLabel || root.selectedTheme.mode)) : "Carregando temas"
            color: Colors.text1
            font { pixelSize: 13; family: "Inter"; weight: Font.Medium }
            elide: Text.ElideRight
          }

          Text {
            text: "← → navegar  •  Enter aplicar  •  Esc fechar"
            color: Colors.text3
            font { pixelSize: 10; family: "JetBrains Mono" }
          }
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
        const theme = JSON.parse(text())
        root.currentTheme = theme.name || "gruvbox"
        root.selectCurrentTheme()
      } catch (error) {}
    }
  }

  Component.onCompleted: loadThemes()

  SequentialAnimation {
    id: applyTransition
    NumberAnimation { target: root; property: "transitionOpacity"; from: 0; to: 0.18; duration: 70; easing.type: Easing.OutQuad }
    NumberAnimation { target: root; property: "transitionOpacity"; to: 0; duration: 120; easing.type: Easing.InQuad }
    ScriptAction { script: root.close() }
  }

  Timer {
    id: focusTimer
    interval: 20
    repeat: false
    onTriggered: keyGrabber.forceActiveFocus()
  }

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
        } catch (error) {
          console.log("frame theme list parse error:", error.message)
        }
      }
    }
  }

  Process {
    id: themeProc
    command: []
  }
}
