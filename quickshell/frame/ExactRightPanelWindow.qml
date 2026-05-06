import Quickshell
import Quickshell.Wayland
import QtQuick
import ".."

PanelWindow {
  id: root

  default property alias content: contentHost.data

  property int panelWidth: 1
  property int panelHeight: 1
  property int windowWidth: panelWidth + FrameTokens.rightWindowPad
  property int windowHeight: panelHeight
  property bool panelOpen: false
  property bool panelVisible: panelOpen

  signal toggleRequested()
  signal closeRequested()

  anchors { right: true }
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
    x: root.width - root.panelWidth
    y: 0
    width: root.panelWidth
    height: root.panelHeight
  }

  Item {
    id: contentHost
    anchors.fill: parent
  }
}
