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
    anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
    spacing: 0

    // ── Esquerda: janela ativa ──────────────────────────────
    Item {
      Layout.fillWidth: true
      Layout.preferredWidth: 1
      height: parent.height

      Pill {
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
        ActiveWindow {}
      }
    }

    // ── Centro: workspaces ──────────────────────────────────
    Pill {
      anchors.centerIn: undefined
      Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
      paddingH: 10
      Workspaces {}
    }

    // ── Direita: status + relógio ───────────────────────────
    Item {
      Layout.fillWidth: true
      Layout.preferredWidth: 1
      height: parent.height

      Row {
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        spacing: 6

        Pill { StatusRight {} }
        Pill { Clock {} }
      }
    }
  }
}
