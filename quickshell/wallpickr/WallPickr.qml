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
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
  focusable: true
  visible: false

  property string wallpapersDir: "/home/ankh/dotfiles/wallpapers"
  property string currentTheme:  "gruvbox"
  property var    wallpapers:    []
  property string currentWall:   ""

  function toggle() {
    if (visible) {
      closeAnim.start()
    } else {
      wallpapers = []
      themeProc.running = true
      currentWallProc.running = true
      visible = true
      pill.width = 120
      pill.opacity = 0
      openAnim.start()
    }
  }

  function applyWallpaper(path) {
    currentWall = path
    saveProc.command = ["sh", "-c", "echo '" + path + "' > /home/ankh/.config/quickshell/themes/current-wallpaper"]
    saveProc.running = true
    applyProc.command = ["swww", "img", path,
      "--transition-type", "wave",
      "--transition-duration", "1.5",
      "--transition-wave", "80,80"]
    applyProc.running = true
    closeAnim.start()
  }

  function close() { closeAnim.start() }

  SequentialAnimation {
    id: openAnim
    NumberAnimation { target: pill; property: "opacity"; to: 1; duration: 10 }
    NumberAnimation { target: pill; property: "width"; to: 627; duration: 180; easing.type: Easing.OutCubic }
    NumberAnimation { target: pill; property: "width"; to: 612; duration: 60; easing.type: Easing.InOutQuad }
  }

  SequentialAnimation {
    id: closeAnim
    NumberAnimation { target: pill; property: "width"; to: 120; duration: 120; easing.type: Easing.InCubic }
    NumberAnimation { target: pill; property: "opacity"; to: 0; duration: 40 }
    ScriptAction { script: root.visible = false }
  }

  Item {
    id: wallKeyGrabber
    focus: true
    Keys.onPressed: function(e) {
      if (e.key === Qt.Key_Escape) {
        root.close()
      } else if (e.key === Qt.Key_Left) {
        var idx = root.wallpapers.indexOf(root.currentWall)
        if (idx > 0) root.currentWall = root.wallpapers[idx - 1]
      } else if (e.key === Qt.Key_Right) {
        var idx = root.wallpapers.indexOf(root.currentWall)
        if (idx < root.wallpapers.length - 1) root.currentWall = root.wallpapers[idx + 1]
      } else if (e.key === Qt.Key_Return) {
        root.applyWallpaper(root.currentWall)
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    onClicked: root.close()
  }

  Process {
    id: themeProc
    command: ["sh", "-c", "grep -o '\"name\"[[:space:]]*:[[:space:]]*\"[^\"]*\"' /home/ankh/.config/quickshell/themes/current.json | grep -o '\"[^\"]*\"$' | tr -d '\"'"]
    stdout: SplitParser {
      onRead: data => {
        var t = data.trim()
        if (t !== "") {
          root.currentTheme = t
          listProc.running = true
        }
      }
    }
  }

  Process {
    id: listProc
    command: ["sh", "-c", "find " + root.wallpapersDir + "/" + root.currentTheme + " -type f \\( -iname '*.jpg' -o -iname '*.png' \\) | sort"]
    stdout: SplitParser {
      onRead: data => {
        var p = data.trim()
        if (p !== "") root.wallpapers = [...root.wallpapers, p]
      }
    }
  }

  Process {
    id: currentWallProc
    command: ["sh", "-c", "cat /home/ankh/.config/quickshell/themes/current-wallpaper 2>/dev/null || echo ''"]
    stdout: SplitParser {
      onRead: data => {
        var p = data.trim()
        if (p !== "") root.currentWall = p
      }
    }
  }

  Process { id: applyProc; command: [] }
  Process { id: saveProc;  command: [] }

  Rectangle {
    id: pill
    anchors.centerIn: parent
    height: 160
    width: 120
    radius: 0
    color: Colors.bg1
    border.color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.15)
    border.width: 1
    clip: false
    opacity: 0

    MouseArea { anchors.fill: parent }

    Row {
      anchors.centerIn: parent
      spacing: 8
      leftPadding: 16
      rightPadding: 16

      Repeater {
        model: root.wallpapers
        delegate: Item {
          required property string modelData
          required property int index
          width: 186
          height: 128

          Rectangle {
            id: imgClip
            anchors.fill: parent
            radius: 10
            clip: true
            color: "transparent"

            Image {
              anchors.fill: parent
              source: "file://" + modelData
              fillMode: Image.PreserveAspectCrop
              smooth: true
            }

            Rectangle {
              anchors.fill: parent
              color: root.currentWall === modelData ? "transparent" : "#00000055"
              Behavior on color { ColorAnimation { duration: 150 } }
            }
          }

          Rectangle {
            anchors { fill: parent; margins: -2 }
            radius: 0
            color: "transparent"
            border.color: root.currentWall === modelData ? Colors.accent : Qt.rgba(1,1,1,0.06)
            border.width: 2
            Behavior on border.color { ColorAnimation { duration: 150 } }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.applyWallpaper(modelData)
          }
        }
      }
    }
  }
}
