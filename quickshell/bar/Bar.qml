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

  // esquerda: janela ativa
  ActiveWindow {
    anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
  }

  // centro absoluto: workspaces
  Workspaces {
    anchors.centerIn: parent
  }

  // direita: status + relógio
  Row {
    anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
    spacing: 16

    StatusRight {}
    Clock {}
  }
}
