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
  color:          "#111113"

  // ── Zona esquerda (do início até as workspaces) ─────────
  Item {
    id: leftZone
    anchors {
      left:           parent.left
      verticalCenter: parent.verticalCenter
    }
    width:  wsPill.x - 6
    height: 34

    // Título — fixo à esquerda da zona
    Rectangle {
      id: titlePill
      anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
      height: 24
      radius: 12
      color:  Colors.bg2
      width:  winText.implicitWidth + 24
      visible: winText.text !== ""

      ActiveWindow {
        id: winText
        anchors.centerIn: parent
      }
    }

    // Spotify — centralizado na zona, independente do título
    SpotifyPlayer {
      id: spotify
      anchors.centerIn: parent
    }
  }

  // ── Centro: Workspaces ──────────────────────────────────
  Rectangle {
    id: wsPill
    anchors.centerIn: parent
    height: 28
    radius: 14
    color:  Colors.bg2
    width:  ws.width + 20

    Workspaces {
      id: ws
      anchors.centerIn: parent
    }
  }

  // ── Zona direita (das workspaces até o fim) ─────────────
  Item {
    id: rightZone
    anchors {
      left:           wsPill.right
      leftMargin:     6
      right:          parent.right
      verticalCenter: parent.verticalCenter
    }
    height: 34

    // Stats — CPU e RAM
    Rectangle {
      id: statsPill
      anchors { right: clockPill.left; rightMargin: 6; verticalCenter: parent.verticalCenter }
      height: 24
      radius: 12
      color:  Colors.bg2
      width:  stats.implicitWidth + 24
      SysStats {
        id: stats
        anchors.centerIn: parent
      }
    }
    // Relógio — centralizado na zona
    Rectangle {
      id: clockPill
      anchors.centerIn: parent
      height: 24
      radius: 12
      color:  Colors.bg2
      width:  clk.implicitWidth + 24

      Clock {
        id: clk
        anchors.centerIn: parent
      }
    }

    // Status — fixo à direita da zona
    Rectangle {
    // Tray — apps em background
    Tray {
      id: trayPill
      anchors { right: statusPill.left; rightMargin: 6; verticalCenter: parent.verticalCenter }
    }
      id: statusPill
      anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
      height: 24
      radius: 12
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
