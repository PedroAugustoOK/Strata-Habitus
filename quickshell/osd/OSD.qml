import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import ".."

PanelWindow {
  id: osdWindow
  anchors { bottom: true; left: true; right: true }
  implicitHeight: 60
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore

  property real value: 0
  property string icon: "󰕾"
  property bool showing: false
  property real lastValue: -1

  Timer {
    id: hideTimer
    interval: 1800
    onTriggered: osdWindow.showing = false
  }

  function show(ic, val) {
    if (val === lastValue) return
    lastValue = val
    icon = ic
    value = val
    showing = true
    hideTimer.restart()
  }

  Process {
    id: volWatcher
    command: ["sh", "-c", "while true; do /run/current-system/sw/bin/wpctl get-volume @DEFAULT_AUDIO_SINK@; sleep 0.5; done"]
    running: true
    stdout: SplitParser {
      onRead: data => {
        const match = data.match(/([\d.]+)/)
        if (match) {
          const vol = Math.round(parseFloat(match[1]) * 100)
          const muted = data.includes("MUTED")
          const ic = muted ? "󰝟" : vol > 60 ? "󰕾" : vol > 30 ? "󰖀" : "󰕿"
          osdWindow.show(ic, vol)
        }
      }
    }
  }

  Item {
    anchors.fill: parent

    Rectangle {
      id: osdBox
      width: 220
      height: 40
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      anchors.bottomMargin: 20
      radius: 8
      color: Colors.bg1
      border.color: Colors.border
      border.width: 1
      opacity: osdWindow.showing ? 1 : 0
      visible: opacity > 0

      Behavior on opacity {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
      }

      RowLayout {
        anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
        spacing: 10

        Text {
          text: osdWindow.icon
          color: Colors.accent
          font.pixelSize: 14
          font.family: "JetBrainsMono Nerd Font"
        }

        Rectangle {
          Layout.fillWidth: true
          height: 3
          radius: 2
          color: Colors.bg2

          Rectangle {
            width: parent.width * (osdWindow.value / 100)
            height: parent.height
            radius: 2
            color: Colors.accent
            Behavior on width {
              NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
            }
          }
        }

        Text {
          text: osdWindow.value + "%"
          color: Colors.text3
          font.pixelSize: 11
          font.family: "JetBrainsMono Nerd Font"
        }
      }
    }
  }
}
