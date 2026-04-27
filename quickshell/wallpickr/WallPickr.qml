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

  property string wallpapersDir: Paths.wallpapers
  property string currentTheme: "gruvbox"
  property var wallpapers: []
  property string currentWall: ""
  property int selectedIdx: 0
  property real cardYOffset: 18
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
    card.scale = 0.985
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
    width: 1180
    height: 700
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
          root.applyWallpaper(root.selectedWallpaper.path)
          e.accepted = true
        }
      }
    }

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 22
      spacing: 16

      RowLayout {
        Layout.fillWidth: true
        Text {
          text: "Palco de Wallpapers"
          color: Colors.text1
          font { pixelSize: 28; family: "Inter"; weight: Font.DemiBold }
        }
        Text {
          text: currentTheme
          color: Colors.text3
          font { pixelSize: 11; family: "JetBrains Mono" }
        }
        Item { Layout.fillWidth: true }
        Text {
          text: wallpapers.length > 0 ? ((selectedIdx + 1) + " / " + wallpapers.length) : "—"
          color: Colors.text3
          font { pixelSize: 11; family: "JetBrains Mono" }
        }
      }

      Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        Rectangle {
          anchors.centerIn: parent
          width: 920
          height: 540
          radius: 28
          antialiasing: true
          color: Qt.rgba(Colors.bg2.r, Colors.bg2.g, Colors.bg2.b, Colors.darkMode ? 0.64 : 0.84)
          border.width: 1
          border.color: Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, Colors.darkMode ? 0.08 : 0.12)
          clip: true

          Image {
            anchors.fill: parent
            source: root.selectedWallpaper && root.selectedWallpaper.preview ? "file://" + root.selectedWallpaper.preview : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            smooth: true
            cache: true
          }

          Rectangle {
            anchors.fill: parent
            gradient: Gradient {
              GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, Colors.darkMode ? 0.03 : 0.01) }
              GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, Colors.darkMode ? 0.14 : 0.05) }
            }
          }

          MouseArea {
            anchors.fill: parent
            onClicked: root.applyWallpaper(root.selectedWallpaper.path)
          }
        }

        Rectangle {
          anchors.left: parent.left
          anchors.leftMargin: 28
          anchors.verticalCenter: parent.verticalCenter
          width: 116
          height: 410
          radius: 24
          antialiasing: true
          color: Colors.bg2
          border.width: 1
          border.color: Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, Colors.darkMode ? 0.08 : 0.12)
          clip: true
          visible: root.selectedIdx > 0
          opacity: 0.78

          Image {
            anchors.fill: parent
            source: root.selectedIdx > 0 ? "file://" + root.previewAt(root.selectedIdx - 1) : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            smooth: true
            cache: true
          }

          Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, Colors.darkMode ? 0.32 : 0.14)
          }

          MouseArea {
            anchors.fill: parent
            onClicked: root.moveSelection(-1)
          }
        }

        Rectangle {
          anchors.right: parent.right
          anchors.rightMargin: 28
          anchors.verticalCenter: parent.verticalCenter
          width: 116
          height: 410
          radius: 24
          antialiasing: true
          color: Colors.bg2
          border.width: 1
          border.color: Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, Colors.darkMode ? 0.08 : 0.12)
          clip: true
          visible: root.selectedIdx < root.wallpapers.length - 1
          opacity: 0.78

          Image {
            anchors.fill: parent
            source: root.selectedIdx < root.wallpapers.length - 1 ? "file://" + root.previewAt(root.selectedIdx + 1) : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            smooth: true
            cache: true
          }

          Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, Colors.darkMode ? 0.32 : 0.14)
          }

          MouseArea {
            anchors.fill: parent
            onClicked: root.moveSelection(1)
          }
        }

        Row {
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 14
          spacing: 10

          Repeater {
            model: root.wallpapers
            delegate: Rectangle {
              required property string modelData
              required property int index

              width: root.selectedIdx === index ? 34 : 10
              height: 10
              radius: 5
              antialiasing: true
              color: root.selectedIdx === index
                ? Colors.accent
                : Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, Colors.darkMode ? 0.18 : 0.22)

              Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
              Behavior on color { ColorAnimation { duration: 140 } }
            }
          }
        }
      }

      RowLayout {
        Layout.fillWidth: true

        Text {
          text: "← → navegar  •  Enter aplicar  •  Esc fechar"
          color: Colors.text3
          font { pixelSize: 10; family: "JetBrains Mono" }
        }

        Item { Layout.fillWidth: true }

        Rectangle {
          radius: 18
          antialiasing: true
          implicitWidth: 136
          implicitHeight: 40
          color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.92)

          Text {
            anchors.centerIn: parent
            text: "Aplicar"
            color: Colors.bg0
            font { pixelSize: 11; family: "JetBrains Mono"; weight: Font.Medium }
          }

          MouseArea {
            anchors.fill: parent
            onClicked: root.applyWallpaper(root.selectedWallpaper.path)
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
