import Quickshell
import Quickshell.Wayland
import QtQuick
import ".."

PanelWindow {
  id: root

  anchors { bottom: true }
  implicitWidth: launcherContent.panelWidth
  implicitHeight: launcherContent.panelHeight + 18
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  focusable: launcherContent.open
  visible: launcherContent.open || launcherContent.drawerVisible
  mask: Region { item: inputRegion }
  WlrLayershell.keyboardFocus: launcherContent.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

  Binding { target: FrameDrawerState; property: "launcherOpen"; value: launcherContent.open }
  Binding { target: FrameDrawerState; property: "launcherVisible"; value: root.visible }
  Binding { target: FrameDrawerState; property: "launcherOffsetScale"; value: launcherContent.drawerOffsetScale }
  Binding { target: FrameDrawerState; property: "launcherX"; value: Math.max(0, (Screen.width - launcherContent.panelWidth) / 2) }
  Binding { target: FrameDrawerState; property: "launcherY"; value: Math.max(0, Screen.height - launcherContent.panelHeight) }
  Binding { target: FrameDrawerState; property: "launcherWidth"; value: launcherContent.panelWidth }
  Binding { target: FrameDrawerState; property: "launcherHeight"; value: launcherContent.panelHeight }

  function toggle() {
    launcherContent.toggle()
  }

  function close() {
    if (launcherContent.open) launcherContent.close()
  }

  Item {
    id: inputRegion
    x: 0
    y: Math.max(0, root.height - launcherContent.panelHeight)
    width: launcherContent.panelWidth
    height: launcherContent.panelHeight
  }

  FrameLauncher {
    id: launcherContent
    anchors.fill: parent
  }
}
