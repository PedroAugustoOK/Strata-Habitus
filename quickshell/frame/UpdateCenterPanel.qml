import QtQuick
import ".."

ExactRightPanelWindow {
  id: root

  panelWidth: updateContent.panelWidth
  panelHeight: updateContent.panelHeight
  panelOpen: updateContent.open
  panelVisible: updateContent.open || updateContent.drawerVisible
  onToggleRequested: updateContent.toggle()
  onCloseRequested: if (updateContent.open) updateContent.close()

  FrameUpdateCenter {
    id: updateContent
    anchors.fill: parent
  }
}
