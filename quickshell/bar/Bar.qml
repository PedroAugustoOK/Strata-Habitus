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

  RowLayout {
    anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
    spacing: 0

    // esquerda: workspaces
    Workspaces {}

    Item { Layout.fillWidth: true }

    // centro: janela ativa
    ActiveWindow {}

    Item { Layout.fillWidth: true }

    // direita: status + relógio
    StatusRight {}

    Item { width: 14 }

    Clock {}
  }
}
