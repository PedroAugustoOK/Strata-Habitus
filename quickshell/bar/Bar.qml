import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

PanelWindow {
  anchors { top: true; left: true; right: true }
  implicitHeight: 32
  color: "#0d0d0f"

  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: 14
    anchors.rightMargin: 14
    spacing: 0

    Workspaces {}

    Item { Layout.fillWidth: true }

    Clock {}

    Item { Layout.fillWidth: true }

    StatusRight {}
  }
}
