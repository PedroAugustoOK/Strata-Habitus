import Quickshell
import Quickshell.Wayland
import QtQuick
import Caelestia.Blobs
import ".."

PanelWindow {
  id: root

  readonly property bool launcherActive: FramePanelState.launcherVisible || FramePanelState.launcherOffsetScale < 1
  readonly property bool themeActive: FramePanelState.themePickerVisible || FramePanelState.themePickerOffsetScale < 1
  readonly property bool anyActive: launcherActive || themeActive
  readonly property int frameThickness: 15
  readonly property int topBarHeight: FrameTokens.barHeight
  readonly property real activeOffsetScale: launcherActive ? FramePanelState.launcherOffsetScale : FramePanelState.themePickerOffsetScale
  readonly property int activeFrameThickness: frameThickness + Math.round(FrameTokens.activeFrameExpansion * activeOpacity)
  readonly property int activeBottomThickness: frameThickness + Math.round(FrameTokens.activeBottomExpansion * activeOpacity)
  readonly property int activePanelWidth: launcherActive ? FramePanelState.launcherWidth : FramePanelState.themePickerWidth
  readonly property int activePanelHeight: launcherActive ? FramePanelState.launcherHeight : FramePanelState.themePickerHeight
  readonly property int activePanelX: Math.round((width - activePanelWidth) / 2)
  readonly property real activePanelY: height - activePanelHeight + activePanelHeight * activeOffsetScale
  readonly property real activeOpacity: anyActive ? Math.max(0, Math.min(1, 1 - activeOffsetScale)) : 0

  anchors { top: true; bottom: true; left: true; right: true }
  color: "transparent"
  visible: true
  exclusionMode: ExclusionMode.Ignore
  focusable: false
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  mask: Region {
    Region {
      x: root.activePanelX
      y: Math.max(0, root.activePanelY - FrameTokens.frameBlend)
      width: root.anyActive ? root.activePanelWidth : 0
      height: root.anyActive ? root.activePanelHeight + FrameTokens.frameBlend * 2 : 0
    }
  }

  Item {
    anchors.fill: parent
    opacity: root.activeOpacity

    Behavior on opacity {
      NumberAnimation {
        duration: 140
        easing.type: Easing.OutCubic
      }
    }

    BlobGroup {
      id: blobGroup
      color: Colors.panelBackground
      smoothing: 10
    }

    BlobRect {
      x: root.activePanelX
      y: root.activePanelY
      implicitWidth: root.activePanelWidth
      implicitHeight: root.activePanelHeight
      group: blobGroup
      radius: root.launcherActive ? FrameTokens.compactSurfaceRadius : FrameTokens.surfaceRadius
      bottomLeftRadius: 0
      bottomRightRadius: 0
      deformScale: root.launcherActive ? 0.000032 : 0.000026
      stiffness: 160
      damping: 20
    }

    Rectangle {
      x: root.activePanelX
      y: root.activePanelY
      width: root.activePanelWidth
      height: root.activePanelHeight
      radius: root.launcherActive ? FrameTokens.compactSurfaceRadius : FrameTokens.surfaceRadius
      color: "transparent"

      Rectangle {
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: 1
        color: root.launcherActive
          ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.20)
          : Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, Colors.darkMode ? 0.18 : 0.22)
      }

      Rectangle {
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom; bottomMargin: root.activeBottomThickness }
        width: 1
        color: Qt.rgba(Colors.panelBorder.r, Colors.panelBorder.g, Colors.panelBorder.b, Colors.darkMode ? 0.16 : 0.22)
      }

      Rectangle {
        anchors { right: parent.right; top: parent.top; bottom: parent.bottom; bottomMargin: root.activeBottomThickness }
        width: 1
        color: Qt.rgba(Colors.panelBorder.r, Colors.panelBorder.g, Colors.panelBorder.b, Colors.darkMode ? 0.16 : 0.22)
      }
    }
  }
}
