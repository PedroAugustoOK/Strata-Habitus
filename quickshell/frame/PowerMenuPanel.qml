import QtQuick
import ".."

ExactBottomPanelWindow {
  id: root

  panelWidth: powerContent.panelWidth
  panelHeight: powerContent.panelHeight
  windowWidth: powerContent.panelWidth
  centerContent: false
  panelOpen: powerContent.open
  panelVisible: powerContent.open || powerContent.drawerVisible
  onToggleRequested: powerContent.toggle()
  onCloseRequested: if (powerContent.open) powerContent.close()

  FramePowerMenu {
    id: powerContent
    anchors.fill: parent
    anchors.bottomMargin: root.bottomInset
  }
}
