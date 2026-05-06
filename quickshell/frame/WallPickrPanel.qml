import QtQuick
import ".."

ExactBottomPanelWindow {
  id: root

  panelWidth: wallContent.panelWidth
  panelHeight: wallContent.panelHeight
  windowWidth: wallContent.panelWidth + FrameTokens.bottomWindowPad
  panelOpen: wallContent.open
  panelVisible: wallContent.open || wallContent.drawerVisible
  onToggleRequested: wallContent.toggle()
  onCloseRequested: if (wallContent.open) wallContent.close()

  FrameWallPickr {
    id: wallContent
    anchors.fill: parent
    anchors.bottomMargin: root.bottomInset
  }
}
