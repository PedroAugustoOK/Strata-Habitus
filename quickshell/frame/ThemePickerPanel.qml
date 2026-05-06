import QtQuick
import ".."

ExactBottomPanelWindow {
  id: root

  readonly property int contentWidth: FrameTokens.themePickerContentWidth
  readonly property int contentHeight: FrameTokens.themePickerContentHeight

  panelWidth: contentWidth
  panelHeight: contentHeight + FrameTokens.bottomInset
  windowWidth: FrameTokens.themePickerWindowWidth
  windowHeight: FrameTokens.themePickerWindowHeight
  bottomInset: 0
  panelOpen: themeContent.open
  panelVisible: themeContent.open || themeContent.drawerVisible
  onToggleRequested: themeContent.toggle()
  onCloseRequested: if (themeContent.open) themeContent.close()

  FrameThemePicker {
    id: themeContent
    anchors.fill: parent
    anchors.bottomMargin: root.bottomInset
  }
}
