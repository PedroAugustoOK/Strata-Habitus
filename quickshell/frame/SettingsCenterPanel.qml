import QtQuick
import ".."

ExactRightPanelWindow {
  id: root

  signal openControlCenter()
  signal openThemePicker()
  signal openWallPickr()
  signal openAppCenter()
  signal openWebApps()
  signal openUpdateCenter()

  panelWidth: settingsContent.panelWidth
  panelHeight: settingsContent.panelHeight
  panelOpen: settingsContent.open
  panelVisible: settingsContent.open || settingsContent.drawerVisible
  onToggleRequested: settingsContent.toggle()
  onCloseRequested: if (settingsContent.open) settingsContent.close()

  FrameSettingsCenter {
    id: settingsContent
    anchors.fill: parent
    onOpenControlCenter: root.openControlCenter()
    onOpenThemePicker: root.openThemePicker()
    onOpenWallPickr: root.openWallPickr()
    onOpenAppCenter: root.openAppCenter()
    onOpenWebApps: root.openWebApps()
    onOpenUpdateCenter: root.openUpdateCenter()
  }
}
