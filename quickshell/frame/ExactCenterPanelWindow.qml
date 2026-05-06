import Quickshell
import Quickshell.Wayland
import QtQuick
import ".."

PanelWindow {
  id: root

  default property alias content: contentHost.data

  property int panelWidth: 1
  property int panelHeight: 1
  property int windowWidth: panelWidth
  property int windowHeight: panelHeight
  property int inputWidth: panelWidth
  property int inputHeight: panelHeight
  property bool panelOpen: false
  property bool panelVisible: panelOpen

  signal toggleRequested()
  signal closeRequested()

  implicitWidth: windowWidth
  implicitHeight: windowHeight
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  focusable: panelOpen
  visible: panelVisible
  mask: Region { item: inputRegion }
  WlrLayershell.keyboardFocus: panelOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

  function toggle() {
    toggleRequested()
  }

  function close() {
    closeRequested()
  }

  Item {
    id: inputRegion
    x: Math.max(0, (root.width - root.inputWidth) / 2)
    y: Math.max(0, (root.height - root.inputHeight) / 2)
    width: root.inputWidth
    height: root.inputHeight
  }

  Item {
    id: contentHost
    anchors.fill: parent
  }
}
