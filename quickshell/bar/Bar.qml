import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import ".."

PanelWindow {
  anchors { top: true; left: true; right: true }
  implicitHeight: 34
  exclusiveZone: 34
  color: "#111113"

  Rectangle {
    anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
    height: 1
    color: "#ffffff10"
  }

  RowLayout {
    anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
    spacing: 0
    Workspaces {}
    Item { Layout.fillWidth: true }
    Clock {}
    Item { Layout.fillWidth: true }
    StatusRight {}
  }
}
