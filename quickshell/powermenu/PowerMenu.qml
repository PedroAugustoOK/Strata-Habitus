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
  readonly property real pillW: row.implicitWidth + 10
  readonly property real pillH: 44
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
      pill.width = 8
      pill.opacity = 0
      openAnim.start()
    }
  }

  function close() {
    closeAnim.start()
  }

  SequentialAnimation {
    id: openAnim
    NumberAnimation {
      target: pill; property: "opacity"
      from: 0; to: 1
      duration: 60
    }
    NumberAnimation {
      target: pill; property: "width"
      from: 8; to: pillW * 1.06
      duration: 160; easing.type: Easing.OutCubic
    }
    NumberAnimation {
      target: pill; property: "width"
      to: pillW
      duration: 80; easing.type: Easing.InOutQuad
    }
    ScriptAction { script: focusItem.forceActiveFocus() }
  }

  SequentialAnimation {
    id: closeAnim
    NumberAnimation {
      target: pill; property: "width"
      to: pillH
      duration: 140; easing.type: Easing.InCubic
    }
    NumberAnimation {
      target: pill; property: "opacity"
      to: 0; duration: 60
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
        root.close()
        a.proc.running = true
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    onClicked: root.close()
  }

  Rectangle {
    id: pill
    x: pillX + (pillW - width) / 2
    y: 60
    width: pillH
    height: pillH
    radius: 14
    color: Colors.bg1
    border.color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.12)
    border.width: 1
    clip: true
    opacity: 0

    MouseArea { anchors.fill: parent }

    RowLayout {
      id: row
      anchors.centerIn: parent
      spacing: 2

      Repeater {
        model: root.actions
        delegate: Rectangle {
          required property var modelData
          required property int index

          readonly property bool selected: root.selectedIdx === index
          readonly property bool hov: ma.containsMouse

          width: 44; height: 36; radius: 10
          color: selected
            ? (modelData.danger ? "#e06c75" : Colors.accent)
            : hov
              ? (modelData.danger
                  ? Qt.rgba(0.88, 0.42, 0.45, 0.15)
                  : Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.12))
              : "transparent"
          Behavior on color { ColorAnimation { duration: 130 } }

          Text {
            anchors.centerIn: parent
            text: modelData.icon
            font { pixelSize: 16; family: "JetBrainsMono Nerd Font" }
            color: selected
              ? Colors.bg0
              : hov
                ? (modelData.danger ? "#e06c75" : Colors.accent)
                : Colors.text3
            Behavior on color { ColorAnimation { duration: 130 } }
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

  Process { id: lockProc;     command: ["/run/current-system/sw/bin/hyprlock"] }
  Process { id: logoutProc;   command: ["sh", "-c", "hyprctl dispatch exit"] }
  Process { id: suspendProc;  command: ["systemctl", "suspend"] }
  Process { id: rebootProc;   command: ["systemctl", "reboot"] }
  Process { id: poweroffProc; command: ["systemctl", "poweroff"] }
}
