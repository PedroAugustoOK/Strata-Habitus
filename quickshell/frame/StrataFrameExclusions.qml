import Quickshell
import Quickshell.Wayland
import QtQuick

Scope {
  id: root

  property bool active: false
  property int thickness: 12
  property int barHeight: 34

  ExclusionZone {
    anchors.left: true
  }

  ExclusionZone {
    anchors.right: true
  }

  ExclusionZone {
    anchors.bottom: true
  }

  component ExclusionZone: PanelWindow {
    implicitWidth: 1
    implicitHeight: 1
    color: "transparent"
    visible: root.active
    exclusiveZone: root.thickness
    focusable: false
    mask: Region {}
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  }
}
