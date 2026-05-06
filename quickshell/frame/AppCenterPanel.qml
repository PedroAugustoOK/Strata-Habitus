import QtQuick
import ".."

ExactRightPanelWindow {
  id: root

  panelWidth: appContent.panelWidth
  panelHeight: appContent.panelHeight
  panelOpen: appContent.open
  panelVisible: appContent.open || appContent.drawerVisible
  onToggleRequested: appContent.toggle()
  onCloseRequested: if (appContent.open) appContent.close()

  FrameAppCenter {
    id: appContent
    anchors.fill: parent
  }
}
