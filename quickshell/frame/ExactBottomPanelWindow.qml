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
  property int windowHeight: panelHeight + FrameTokens.bottomInset
  property int bottomInset: FrameTokens.bottomInset
  property bool centerContent: true
  property bool panelOpen: false
  property bool panelVisible: panelOpen

  signal toggleRequested()
  signal closeRequested()

  anchors { bottom: true }
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
    x: root.centerContent ? Math.max(0, (root.width - root.panelWidth) / 2) : 0
    y: Math.max(0, root.height - root.panelHeight - root.bottomInset)
    width: root.panelWidth
    height: root.panelHeight
  }

  Item {
    id: contentHost
    anchors.fill: parent
  }
}
