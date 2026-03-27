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
  focusable: true
  visible: false
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

  property int selectedIdx: 0
  readonly property real pillW: row.implicitWidth + 32
  readonly property real pillH: 52
  readonly property real pillX: (width / 2) - (pillW / 2)

  readonly property var actions: [
    { icon: "⏻",  danger: true,  proc: poweroffProc },
    { icon: "󰜉", danger: false, proc: rebootProc   },
    { icon: "󰤄", danger: false, proc: suspendProc  },
    { icon: "󰌾", danger: false, proc: lockProc     },
    { icon: "󰍃", danger: false, proc: logoutProc   },
  ]

  function toggle() {
    if (visible) {
      closeAnim.start()
    } else {
      visible = true
      selectedIdx = 0
      focusItem.forceActiveFocus()
      clipper.height = 0
      openAnim.start()
    }
  }

  function close() { closeAnim.start() }

  NumberAnimation {
    id: openAnim
    target: clipper; property: "height"
    from: 0; to: pillH
    duration: 260; easing.type: Easing.OutCubic
  }

  SequentialAnimation {
    id: closeAnim
    NumberAnimation {
      target: clipper; property: "height"
      to: 0; duration: 200; easing.type: Easing.InCubic
    }
    ScriptAction { script: root.visible = false }
  }

  Item {
    id: focusItem
    focus: true
    Keys.onPressed: function(e) {
      if (e.key === Qt.Key_Escape) {
        root.close()
      } else if (e.key === Qt.Key_Left || e.key === Qt.Key_Up) {
        root.selectedIdx = (root.selectedIdx - 1 + root.actions.length) % root.actions.length
      } else if (e.key === Qt.Key_Right || e.key === Qt.Key_Down) {
        root.selectedIdx = (root.selectedIdx + 1) % root.actions.length
      } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Space) {
        var a = root.actions[root.selectedIdx]
        root.close(); a.proc.running = true
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    onClicked: root.close()
  }

  Item {
    id: clipper
    x: pillX
    y: 34
    width: pillW
    height: 0
    clip: true
    z: 1

    Rectangle {
      id: pill
      width: pillW
      height: pillH
      radius: 14
      color: "#16161a"

      MouseArea { anchors.fill: parent }

      RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 4

        Repeater {
          model: root.actions
          delegate: Rectangle {
            required property var modelData
            required property int index

            readonly property bool selected: root.selectedIdx === index
            readonly property bool hov: ma.containsMouse

            width: 50; height: 44; radius: 10
            color: selected
              ? (modelData.danger ? "#ff6b6b" : Colors.accent)
              : hov
                ? (modelData.danger ? "#ff6b6b33" : Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.15))
                : "transparent"
            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
              anchors.centerIn: parent
              text: modelData.icon
              font { pixelSize: 18; family: "JetBrainsMono Nerd Font" }
              color: selected
                ? "#0d0d0f"
                : hov
                  ? (modelData.danger ? "#ff6b6b" : Colors.accent)
                  : Colors.text3
              Behavior on color { ColorAnimation { duration: 150 } }
            }

            MouseArea {
              id: ma; anchors.fill: parent
              hoverEnabled: true; cursorShape: Qt.PointingHandCursor
              onEntered: root.selectedIdx = index
              onClicked: { root.close(); modelData.proc.running = true }
            }
          }
        }
      }
    }
  }

  Process { id: lockProc;     command: ["/run/current-system/sw/bin/hyprlock"] }
  Process { id: logoutProc;   command: ["sh", "-c", "hyprctl dispatch exit"] }
  Process { id: suspendProc;  command: ["systemctl", "suspend"] }
  Process { id: rebootProc;   command: ["systemctl", "reboot"] }
  Process { id: poweroffProc; command: ["systemctl", "poweroff"] }
}
