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
  Item {
    id: rightZone
    anchors {
      left:           wsPill.right
      leftMargin:     6
      right:          parent.right
      verticalCenter: parent.verticalCenter
    }
    height: 34
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
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            const point = clockPill.mapToItem(null, clockPill.width / 2, clockPill.height + 8)
            CalendarMenuState.toggle(point.x, point.y)
          }
        }
        Clock {
          id: clk
          anchors.centerIn: parent
        }
      }
    }
    Tray {
      id: trayPill
      anchors { right: statusPill.left; rightMargin: 6; verticalCenter: parent.verticalCenter }
    }
    Rectangle {
      id: statusPill
      anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
      height: 28; radius: 14
      color:  Colors.bg2
      width:  sr.implicitWidth + 24
      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: { console.log("CLICOU"); ccToggle.running = true }
      }
      StatusRight {
        id: sr
        anchors.centerIn: parent
      }
    }
  }
  Process { id: ccToggle; command: ["quickshell", "ipc", "call", "controlcenter", "toggle"] }
}
