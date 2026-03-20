import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

ShellRoot {
  Process {
    id: volProc
    command: ["sh", "-c", "/run/current-system/sw/bin/wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{printf \"%d\", $2*100}'"]
    stdout: SplitParser {
      onRead: data => volLabel.text = "󰕾 " + data.trim() + "%"
    }
  }

  Process {
    id: batProc
    command: ["sh", "-c", "cat /sys/class/power_supply/BAT1/capacity 2>/dev/null || echo '–'"]
    stdout: SplitParser {
      onRead: data => batLabel.text = "󰁹 " + data.trim() + "%"
    }
  }

  Timer {
    interval: 500; running: true; repeat: true; triggeredOnStart: true
    onTriggered: volProc.running = true
  }

  Timer {
    interval: 30000; running: true; repeat: true; triggeredOnStart: true
    onTriggered: batProc.running = true
  }

  PanelWindow {
    id: bar
    anchors { top: true; left: true; right: true }
    implicitHeight: 32
    color: "#0d0d0f"

    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: 14
      anchors.rightMargin: 14
      spacing: 0

      // ── Workspaces ─────────────────────────────────────────
      RowLayout {
        spacing: 0
        Repeater {
          model: 5
          delegate: Item {
            required property int index
            width: 16
            height: 32

            readonly property int wsId: index + 1
            readonly property bool focused: Hyprland.focusedWorkspace !== null
                                         && Hyprland.focusedWorkspace.id === wsId
            readonly property bool occupied: {
              for (let i = 0; i < Hyprland.workspaces.values.length; i++)
                if (Hyprland.workspaces.values[i].id === wsId) return true
              return false
            }

            Rectangle {
              anchors.centerIn: parent
              width:  focused ? 18 : 6
              height: 6
              radius: 3
              color:  focused ? "#cf9fff" : (occupied ? "#555" : "#2a2a2e")
              Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
              Behavior on color { ColorAnimation   { duration: 150 } }
            }

            MouseArea {
              anchors.fill: parent
              onClicked: Hyprland.dispatch("workspace " + wsId)
            }
          }
        }
      }

      Item { Layout.fillWidth: true }

      // ── Relógio ────────────────────────────────────────────
      Text {
        id: clock
        color: "#e0e0e0"
        font.pixelSize: 12
        font.family: "JetBrainsMono Nerd Font"
        Timer {
          interval: 1000; running: true; repeat: true; triggeredOnStart: true
          onTriggered: clock.text = Qt.formatTime(new Date(), "hh:mm")
        }
      }

      Item { Layout.fillWidth: true }

      // ── Direita ────────────────────────────────────────────
      RowLayout {
        spacing: 12

        Text {
          id: volLabel
          color: "#666"
          font.pixelSize: 11
          font.family: "JetBrainsMono Nerd Font"
          text: "󰕾 –"
        }

        Text {
          id: batLabel
          color: "#666"
          font.pixelSize: 11
          font.family: "JetBrainsMono Nerd Font"
          text: "󰁹 –"
        }
      }
    }
  }
}
