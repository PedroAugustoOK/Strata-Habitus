import Quickshell
import Quickshell.Wayland
import QtQuick
import Caelestia.Blobs
import ".."

Scope {
  id: root

  property bool active: false
  property int barHeight: 34
  property int thickness: 15
  property int cornerRadius: 16

  readonly property color frameFill: Qt.rgba(
    Colors.barBackground.r,
    Colors.barBackground.g,
    Colors.barBackground.b,
    1
  )
  readonly property color frameLine: Qt.rgba(
    Colors.primary.r,
    Colors.primary.g,
    Colors.primary.b,
    Colors.darkMode ? 0.42 : 0.30
  )
  readonly property color frameShadow: Qt.rgba(0, 0, 0, Colors.darkMode ? 0.20 : 0.08)

  StrataFrameExclusions {
    active: root.active
    thickness: root.thickness
    barHeight: root.barHeight
  }

  PanelWindow {
    id: frameWindow

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    visible: root.active
    exclusionMode: ExclusionMode.Ignore
    focusable: false
    WlrLayershell.layer: WlrLayer.Bottom
    mask: StrataFrameRegions {
      win: frameWindow
      barHeight: root.barHeight
      thickness: root.thickness
    }
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Item {
      anchors.fill: parent

      BlobGroup {
        id: blobGroup
        color: root.frameFill
        smoothing: 8
      }

      BlobInvertedRect {
        anchors.fill: parent
        anchors.margins: -48
        group: blobGroup
        radius: root.cornerRadius
        borderLeft: root.thickness - anchors.margins
        borderRight: root.thickness - anchors.margins
        borderTop: root.barHeight - anchors.margins
        borderBottom: root.thickness - anchors.margins
      }

    }
  }
}
