import QtQuick
import ".."

ExactBottomPanelWindow {
  id: root

  panelWidth: launcherContent.panelWidth
  panelHeight: launcherContent.panelHeight
  windowHeight: launcherContent.panelHeight + FrameTokens.rightWindowPad
  bottomInset: 0
  centerContent: false
  panelOpen: launcherContent.open
  panelVisible: launcherContent.open || launcherContent.drawerVisible
  onToggleRequested: launcherContent.toggle()
  onCloseRequested: if (launcherContent.open) launcherContent.close()

  FrameLauncher {
    id: launcherContent
    anchors.fill: parent
  }
}
