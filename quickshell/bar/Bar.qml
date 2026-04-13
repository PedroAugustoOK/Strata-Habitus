import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import Quickshell.Io
import ".."

PanelWindow {
  id: barRoot
  anchors { top: true; left: true; right: true }
  implicitHeight: 34
  exclusiveZone:  34
  color: Colors.bg1

  // ── Esquerda ─────────────────────────────────────────
  Item {
    id: leftZone
    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
    width:  wsPill.x - 6
    height: 34

    Rectangle {
      id: titlePill
      anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
      height: 28; radius: 14
      color:  Colors.bg2
      width:  winText.implicitWidth + 24
      visible: winText.text !== ""
      ActiveWindow {
        id: winText
        anchors.centerIn: parent
      }
    }

    SpotifyPlayer {
      id: spotify
      anchors.centerIn: parent
    }
  }

  // ── Centro: Workspaces ───────────────────────────────
  Rectangle {
    id: wsPill
    anchors.centerIn: parent
    height: 28; radius: 14
    color:  Colors.bg2
    width:  ws.width + 20

    Workspaces {
      id: ws
      anchors.centerIn: parent
    }
  }

  // ── Direita ──────────────────────────────────────────
  Item {
    id: rightZone
    anchors {
      left:           wsPill.right
      leftMargin:     6
      right:          parent.right
      verticalCenter: parent.verticalCenter
    }
    height: 34

    // tray — fixo à esquerda da zona
    Tray {
      id: trayPill
      anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
    }

    // stats + clock — centralizados na zona direita
    Row {
      anchors.centerIn: parent
      spacing: 6

      Rectangle {
        id: statsPill
        height: 28; radius: 14
        color:  Colors.bg2
        width:  stats.implicitWidth + 24

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: btopProc.running = true
        }
        Process {
          id: btopProc
          command: ["kitty", "--title", "btop", "--override", "window_padding_width=0", "btop"]
        }
        SysStats {
          id: stats
          anchors.centerIn: parent
        }
      }

      Rectangle {
        id: clockPill
        height: 28; radius: 14
        color:  Colors.bg2
        width:  clk.implicitWidth + 24

        Clock {
          id: clk
          anchors.centerIn: parent
        }
      }
    }

    // status — fixo à direita
    Rectangle {
      id: statusPill
      anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
      height: 28; radius: 14
      color:  Colors.bg2
      width:  sr.implicitWidth + 24

      StatusRight {
        id: sr
        anchors.centerIn: parent
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: ccToggle.running = true
      }
    }
  }

  Process { id: ccToggle; command: ["quickshell", "ipc", "call", "controlcenter", "toggle"] }
}
