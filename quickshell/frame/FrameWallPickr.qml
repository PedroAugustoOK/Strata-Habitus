import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import ".."

Item {
  id: root

  property bool open: false
  property string wallpapersDir: Paths.wallpapers
  property string currentTheme: "gruvbox"
  property var wallpapers: []
  property string currentWall: ""
  property int selectedIdx: 0
  readonly property bool drawerVisible: drawer.visible

  readonly property int gridColumns: 3
  readonly property int gridRows: Math.max(1, Math.ceil(wallpapers.length / gridColumns))
  readonly property int panelWidth: Math.min(FrameTokens.wallPickrMaxWidth, width > 0 ? width - FrameTokens.bottomWindowPad : FrameTokens.wallPickrMaxWidth)
  readonly property int panelHeight: Math.min(FrameTokens.wallPickrMaxHeight, Math.max(FrameTokens.wallPickrMinHeight, 112 + gridRows * 118))
  readonly property var selectedWallpaper: wallpapers.length > 0
    ? wallpapers[Math.max(0, Math.min(selectedIdx, wallpapers.length - 1))]
    : ({})

  function toggle() {
    if (open) {
      close()
      return
    }

    wallpapers = []
    selectedIdx = 0
    open = true
    OverlayState.setActive("wallpickr")
    themeProc.running = true
    currentWallProc.running = true
    focusTimer.restart()
  }

  function close() {
    open = false
    OverlayState.clear("wallpickr")
  }

  function selectIndex(index) {
    selectedIdx = Math.max(0, Math.min(wallpapers.length - 1, index))
  }

  function moveSelection(delta) {
    selectIndex(selectedIdx + delta)
    wallpaperGrid.positionViewAtIndex(selectedIdx, GridView.Contain)
  }

  function applyWallpaper(path) {
    if (!path) return
    currentWall = path
    applyProc.command = ["/run/current-system/sw/bin/bash", Paths.scripts + "/wallpaper.sh", path]
    applyProc.running = true
    close()
  }

  anchors.fill: parent

  BottomDrawer {
    id: drawer
    width: root.panelWidth
    height: root.panelHeight
    gutter: FrameTokens.rightPanelGutter
    open: root.open

    FrameSurface {
      anchors.fill: parent
      radius: FrameTokens.surfaceRadius
      attachedEdge: "bottom"
      borderColor: Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, Colors.darkMode ? 0.10 : 0.14)
      topToneOpacity: Colors.darkMode ? 0.95 : 0.92
      bottomToneOpacity: 0.98

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
            root.moveSelection(-root.gridColumns)
            event.accepted = true
          } else if (event.key === Qt.Key_Down) {
            root.moveSelection(root.gridColumns)
            event.accepted = true
          } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.applyWallpaper(root.selectedWallpaper.path)
            event.accepted = true
          }
        }
      }

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        RowLayout {
          Layout.fillWidth: true
          spacing: 12

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            Text {
              Layout.fillWidth: true
              text: "Wallpapers"
              color: Colors.text1
              font { pixelSize: 20; family: "Inter"; weight: Font.DemiBold }
              elide: Text.ElideRight
            }

            Text {
              Layout.fillWidth: true
              text: currentTheme
              color: Colors.text3
              font { pixelSize: 9; family: "JetBrains Mono" }
              elide: Text.ElideRight
            }
          }

          Rectangle {
            radius: 12
            antialiasing: true
            implicitWidth: countText.implicitWidth + 18
            implicitHeight: 28
            color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, Colors.darkMode ? 0.13 : 0.10)

            Text {
              id: countText
              anchors.centerIn: parent
              text: wallpapers.length > 0 ? ((selectedIdx + 1) + " / " + wallpapers.length) : "--"
              color: Colors.primary
              font { pixelSize: 10; family: "JetBrains Mono"; weight: Font.DemiBold }
            }
          }
        }

        GridView {
          id: wallpaperGrid
          Layout.fillWidth: true
          Layout.fillHeight: true
          cellWidth: Math.floor(width / root.gridColumns)
          cellHeight: 118
          model: root.wallpapers
          clip: true
          boundsBehavior: Flickable.StopAtBounds

          delegate: Item {
            required property var modelData
            required property int index

            width: wallpaperGrid.cellWidth
            height: wallpaperGrid.cellHeight

            readonly property bool selected: root.selectedIdx === index
            readonly property bool active: modelData.path === root.currentWall
            readonly property int tileRadius: 13

            Item {
              anchors.centerIn: parent
              width: parent.width - 10
              height: 106
              scale: selected ? 1 : 0.975

              Behavior on scale { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }

              Rectangle {
                anchors.fill: parent
                radius: tileRadius
                antialiasing: true
                color: Colors.panelRaised
              }

              Image {
                anchors.fill: parent
                anchors.margins: selected || active ? 3 : 0
                source: modelData.preview ? "file://" + modelData.preview : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                smooth: true
                cache: true
              }

              Rectangle {
                anchors.fill: parent
                radius: tileRadius
                antialiasing: true
                color: mouse.containsMouse ? Qt.rgba(0, 0, 0, Colors.darkMode ? 0.08 : 0.03) : "transparent"
                Behavior on color { ColorAnimation { duration: 120 } }
              }

              Rectangle {
                anchors.fill: parent
                radius: tileRadius
                antialiasing: true
                color: "transparent"
                border.width: selected || active ? 2 : 0
                border.color: selected ? Colors.primary : active ? Colors.success : "transparent"
                Behavior on border.color { ColorAnimation { duration: 140 } }
              }

              Rectangle {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 8
                width: 22
                height: 22
                radius: 11
                visible: active
                color: Qt.rgba(Colors.success.r, Colors.success.g, Colors.success.b, 0.92)

                Text {
                  anchors.centerIn: parent
                  text: "✓"
                  color: Colors.bg0
                  font { pixelSize: 11; family: "Inter"; weight: Font.DemiBold }
                }
              }

              MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: root.selectIndex(index)
                onClicked: {
                  root.selectIndex(index)
                  root.applyWallpaper(modelData.path)
                }
              }
            }
          }
        }

        Text {
          Layout.fillWidth: true
          text: "← → navegar  •  Enter aplicar  •  Esc fechar"
          color: Colors.text3
          horizontalAlignment: Text.AlignRight
          font { pixelSize: 10; family: "JetBrains Mono" }
          elide: Text.ElideRight
        }
      }
    }
  }

  Process {
    id: themeProc
    command: ["sh", "-c", "grep -o '\"name\"[[:space:]]*:[[:space:]]*\"[^\"]*\"' " + Paths.state + "/current-theme.json | grep -o '\"[^\"]*\"$' | tr -d '\"'"]
    stdout: SplitParser {
      onRead: data => {
        const themeName = data.trim()
        if (themeName !== "") {
          root.currentTheme = themeName
          root.wallpapers = []
          listProc.running = true
        }
      }
    }
  }

  Process {
    id: listProc
    command: ["/run/current-system/sw/bin/bash", Paths.scripts + "/wallpickr-index.sh", root.wallpapersDir, root.currentTheme]
    stdout: SplitParser {
      onRead: data => {
        const line = data.trim()
        if (line === "") return
        const parts = line.split("\t")
        if (parts.length < 2) return
        const item = { path: parts[0], preview: parts[1] }
        root.wallpapers = root.wallpapers.concat([item])
        if (root.currentWall !== "") {
          const idx = root.wallpapers.findIndex(entry => entry.path === root.currentWall)
          if (idx >= 0) root.selectedIdx = idx
        }
      }
    }
  }

  Process {
    id: currentWallProc
    command: ["sh", "-c", "cat " + Paths.state + "/current-wallpaper 2>/dev/null || echo ''"]
    stdout: SplitParser {
      onRead: data => {
        const path = data.trim()
        if (path !== "") root.currentWall = path
      }
    }
  }

  Timer {
    id: focusTimer
    interval: 20
    repeat: false
    onTriggered: keyGrabber.forceActiveFocus()
  }

  Process {
    id: applyProc
    command: []
  }
}
