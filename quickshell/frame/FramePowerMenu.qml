import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import ".."

Item {
  id: root

  property bool open: false
  property int selectedIdx: 0

  readonly property var actions: [
    { icon: "⏻",  label: "Desligar", danger: true,  proc: poweroffProc },
    { icon: "󰜉", label: "Reiniciar", danger: false, proc: rebootProc },
    { icon: "󰤄", label: "Suspender", danger: false, proc: suspendProc },
    { icon: "󰌾", label: "Bloquear", danger: false, proc: lockProc },
    { icon: "󰍃", label: "Sair", danger: false, proc: logoutProc }
  ]

  function toggle() {
    if (open) {
      close()
      return
    }

    selectedIdx = 0
    open = true
    OverlayState.setActive("powermenu")
    focusTimer.restart()
  }

  function close() {
    open = false
    OverlayState.clear("powermenu")
  }

  function activateSelected() {
    const action = actions[selectedIdx]
    if (!action) return
    close()
    action.proc.running = true
  }

  anchors.fill: parent

  BottomDrawer {
    id: drawer
    width: row.implicitWidth + 26
    height: 58
    gutter: 22
    open: root.open

    FrameSurface {
      anchors.fill: parent
      radius: 16
      attachedEdge: "bottom"
      borderColor: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.14)
      gradientEnabled: false

      Item {
        id: keyGrabber
        anchors.fill: parent
        focus: root.open
        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Escape) {
            root.close()
            event.accepted = true
          } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
            root.selectedIdx = (root.selectedIdx - 1 + root.actions.length) % root.actions.length
            event.accepted = true
          } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down) {
            root.selectedIdx = (root.selectedIdx + 1) % root.actions.length
            event.accepted = true
          } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            root.activateSelected()
            event.accepted = true
          }
        }
      }

      RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 3

        Repeater {
          model: root.actions
          delegate: Rectangle {
            required property var modelData
            required property int index

            readonly property bool selected: root.selectedIdx === index
            readonly property bool hovered: mouse.containsMouse

            Layout.preferredWidth: 50
            Layout.preferredHeight: 42
            radius: 12
            color: selected
              ? (modelData.danger ? Colors.danger : Colors.accent)
              : hovered
                ? (modelData.danger ? Qt.rgba(Colors.danger.r, Colors.danger.g, Colors.danger.b, 0.15) : Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.12))
                : "transparent"

            Behavior on color {
              ColorAnimation { duration: 130 }
            }

            Text {
              anchors.centerIn: parent
              text: modelData.icon
              font { pixelSize: 16; family: "JetBrainsMono Nerd Font" }
              color: selected ? Colors.bg0 : hovered ? (modelData.danger ? Colors.danger : Colors.accent) : Colors.text3
            }

            MouseArea {
              id: mouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onEntered: root.selectedIdx = index
              onClicked: {
                root.selectedIdx = index
                root.activateSelected()
              }
            }
          }
        }
      }
    }
  }

  Timer {
    id: focusTimer
    interval: 20
    repeat: false
    onTriggered: keyGrabber.forceActiveFocus()
  }

  Process { id: lockProc;     command: ["/run/current-system/sw/bin/hyprlock"] }
  Process { id: logoutProc;   command: ["sh", "-c", "hyprctl dispatch exit"] }
  Process { id: suspendProc;  command: ["systemctl", "suspend"] }
  Process { id: rebootProc;   command: ["systemctl", "reboot"] }
  Process { id: poweroffProc; command: ["systemctl", "poweroff"] }
}
