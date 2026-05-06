import QtQuick
import ".."

ExactBottomPanelWindow {
  id: root

  panelWidth: clipboardContent.panelWidth
  panelHeight: clipboardContent.panelHeight
  windowWidth: clipboardContent.panelWidth + FrameTokens.bottomWindowPad
  panelOpen: clipboardContent.open
  panelVisible: clipboardContent.open || clipboardContent.drawerVisible
  onToggleRequested: clipboardContent.toggle()
  onCloseRequested: if (clipboardContent.open) clipboardContent.close()

  FrameClipboard {
    id: clipboardContent
    anchors.fill: parent
    anchors.bottomMargin: root.bottomInset
  }
}
