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
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
  focusable: true
  visible: false
  onVisibleChanged: {
    if (visible) OverlayState.setActive("wallpickr")
    else OverlayState.clear("wallpickr")
  }

  property string wallpapersDir: Paths.wallpapers
  property string currentTheme: "gruvbox"
  property var wallpapers: []
  property string currentWall: ""
  property int selectedIdx: 0
  property real cardYOffset: 18
  readonly property int gridColumns: 3
  readonly property var selectedWallpaper: wallpapers.length > 0
    ? wallpapers[Math.max(0, Math.min(selectedIdx, wallpapers.length - 1))]
    : ""

  function previewAt(index) {
    if (index < 0 || index >= wallpapers.length) return ""
    return wallpapers[index].preview || wallpapers[index].path || ""
  }

  function wallpaperAt(index) {
    if (index < 0 || index >= wallpapers.length) return ""
    return wallpapers[index].path || ""
  }

  function toggle() {
    if (visible) {
      closeAnim.start()
      return
    }

    wallpapers = []
    selectedIdx = 0
    visible = true
    card.opacity = 0
    cardScale.xScale = 0.985
    cardScale.yScale = 0.985
    cardYOffset = 16
    themeProc.running = true
    currentWallProc.running = true
    openAnim.start()
  }

  function close() {
    closeAnim.start()
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
    closeAnim.start()
  }

  SequentialAnimation {
    id: openAnim
    ParallelAnimation {
      NumberAnimation { target: root; property: "cardYOffset"; from: 16; to: 0; duration: 170; easing.type: Easing.OutCubic }
      NumberAnimation { target: card; property: "opacity"; from: 0; to: 1; duration: 120; easing.type: Easing.OutQuad }
      NumberAnimation { target: cardScale; property: "xScale"; from: 0.985; to: 1; duration: 170; easing.type: Easing.OutCubic }
      NumberAnimation { target: cardScale; property: "yScale"; from: 0.985; to: 1; duration: 170; easing.type: Easing.OutCubic }
    }
    ScriptAction { script: keyGrabber.forceActiveFocus() }
  }

  SequentialAnimation {
    id: closeAnim
    ParallelAnimation {
      NumberAnimation { target: root; property: "cardYOffset"; to: 10; duration: 100; easing.type: Easing.InCubic }
      NumberAnimation { target: cardScale; property: "xScale"; to: 0.992; duration: 100; easing.type: Easing.InCubic }
      NumberAnimation { target: cardScale; property: "yScale"; to: 0.992; duration: 100; easing.type: Easing.InCubic }
      NumberAnimation { target: card; property: "opacity"; to: 0; duration: 80; easing.type: Easing.InQuad }
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
    width: 740
    height: Math.min(460, root.height - 90)
    radius: 18
    antialiasing: true
    color: Colors.bg1
    border.width: 1
    border.color: Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, Colors.darkMode ? 0.10 : 0.14)
    clip: true
    opacity: 0
    transform: Scale {
      id: cardScale
      origin.x: Math.max(0, Math.min(card.width, OverlayState.islandCenterX - card.x))
      origin.y: Math.max(0, Math.min(card.height, OverlayState.islandCenterY - card.y))
      xScale: 1
      yScale: 1
    }

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

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
      onPressed: function(mouse) { mouse.accepted = true }
      onClicked: function(mouse) { mouse.accepted = true }
      onWheel: function(wheel) { wheel.accepted = true }
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
        } else if (e.key === Qt.Key_Up) {
          root.moveSelection(-root.gridColumns)
          e.accepted = true
        } else if (e.key === Qt.Key_Down) {
          root.moveSelection(root.gridColumns)
          e.accepted = true
        } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
          root.applyWallpaper(root.selectedWallpaper.path)
          e.accepted = true
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
          spacing: 3
          Text {
            text: "Wallpapers"
            color: Colors.text1
            font { pixelSize: 18; family: "Inter"; weight: Font.DemiBold }
          }
          Text {
            text: currentTheme
            color: Colors.text3
            font { pixelSize: 9; family: "JetBrains Mono" }
          }
        }

        Item { Layout.fillWidth: true }

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

            Rectangle {
              id: roundedMask
              anchors.fill: parent
              anchors.margins: selected || active ? 3 : 0
              radius: Math.max(0, tileRadius - (selected || active ? 3 : 0))
              antialiasing: true
              color: "white"
              z: -1
            }

            Rectangle {
              anchors.fill: parent
              anchors.margins: selected || active ? 3 : 0
              radius: roundedMask.radius
              antialiasing: true
              color: Colors.bg2
            }

            Image {
              id: wallpaperPreview
              anchors.fill: parent
              anchors.margins: selected || active ? 3 : 0
              source: modelData.preview ? "file://" + modelData.preview : ""
              fillMode: Image.PreserveAspectCrop
              asynchronous: true
              smooth: true
              cache: true
            }

            Canvas {
              anchors.fill: wallpaperPreview
              z: 1
              property real cornerRadius: roundedMask.radius
              property color coverColor: Colors.bg2
              onPaint: {
                const ctx = getContext("2d")
                const r = Math.max(0, cornerRadius)
                const w = width
                const h = height
                ctx.clearRect(0, 0, w, h)
                ctx.fillStyle = coverColor

                ctx.beginPath()
                ctx.moveTo(0, 0)
                ctx.lineTo(r, 0)
                ctx.arc(r, r, r, -Math.PI / 2, Math.PI, true)
                ctx.closePath()
                ctx.fill()

                ctx.beginPath()
                ctx.moveTo(w, 0)
                ctx.lineTo(w - r, 0)
                ctx.arc(w - r, r, r, -Math.PI / 2, 0, false)
                ctx.closePath()
                ctx.fill()

                ctx.beginPath()
                ctx.moveTo(0, h)
                ctx.lineTo(0, h - r)
                ctx.arc(r, h - r, r, Math.PI, Math.PI / 2, true)
                ctx.closePath()
                ctx.fill()

                ctx.beginPath()
                ctx.moveTo(w, h)
                ctx.lineTo(w - r, h)
                ctx.arc(w - r, h - r, r, Math.PI / 2, 0, true)
                ctx.closePath()
                ctx.fill()
              }
              onCornerRadiusChanged: requestPaint()
              onCoverColorChanged: requestPaint()
              onWidthChanged: requestPaint()
              onHeightChanged: requestPaint()
            }

            Rectangle {
              anchors.fill: wallpaperPreview
              radius: roundedMask.radius
              antialiasing: true
              color: mouse.containsMouse
                ? Qt.rgba(0, 0, 0, Colors.darkMode ? 0.08 : 0.03)
                : "transparent"
              Behavior on color { ColorAnimation { duration: 120 } }
            }

            Rectangle {
              anchors.fill: parent
              radius: tileRadius
              antialiasing: true
              color: "transparent"
              border.width: selected || active ? 2 : 0
              border.color: selected
                ? Colors.primary
                : active
                  ? Colors.success
                  : "transparent"
              z: 2
              Behavior on border.color { ColorAnimation { duration: 140 } }
            }

            Rectangle {
              anchors.fill: parent
              anchors.margins: selected || active ? 2 : 0
              radius: Math.max(0, tileRadius - (selected || active ? 2 : 0))
              antialiasing: true
              color: "transparent"
              border.width: selected || active ? 1 : 0
              border.color: Qt.rgba(Colors.bg0.r, Colors.bg0.g, Colors.bg0.b, Colors.darkMode ? 0.34 : 0.22)
              z: 2
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
              z: 3

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
              z: 4
              onEntered: root.selectIndex(index)
              onClicked: {
                root.selectIndex(index)
                root.applyWallpaper(modelData.path)
              }
            }
          }
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
        const p = data.trim()
        if (p !== "") root.currentWall = p
      }
    }
  }

  Process {
    id: applyProc
    command: []
  }
}
