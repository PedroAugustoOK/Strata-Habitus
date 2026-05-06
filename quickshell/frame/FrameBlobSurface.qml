import QtQuick
import Caelestia.Blobs
import ".."

Item {
  id: root

  default property alias content: contentHost.data

  property int radius: FrameTokens.surfaceRadius
  property color fillColor: Colors.panelBackground
  property color borderColor: Colors.panelBorder
  property string attachedEdge: "none"
  property int smoothing: 8
  property real deformScale: 0.000018
  property real stiffness: 185
  property real damping: 18

  BlobGroup {
    id: blobGroup
    color: root.fillColor
    smoothing: root.smoothing
  }

  BlobRect {
    id: blobSurface
    anchors.fill: parent
    group: blobGroup
    radius: root.radius
    bottomLeftRadius: root.attachedEdge === "bottom" ? 0 : root.radius
    topRightRadius: root.attachedEdge === "right" ? 0 : root.radius
    bottomRightRadius: root.attachedEdge === "right" ? 0 : (root.attachedEdge === "bottom" ? 0 : root.radius)
    deformScale: root.deformScale
    stiffness: root.stiffness
    damping: root.damping
  }

  Rectangle {
    anchors.fill: parent
    radius: root.radius
    color: "transparent"
    border.width: 1
    border.color: root.borderColor

    Rectangle {
      anchors { left: parent.left; right: parent.right; top: parent.top }
      height: 1
      color: Qt.rgba(Colors.text0.r, Colors.text0.g, Colors.text0.b, Colors.darkMode ? 0.045 : 0.22)
    }

    Rectangle {
      anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
      height: FrameTokens.attachedEdgeDepth
      visible: root.attachedEdge === "bottom"
      color: root.fillColor
    }

    Rectangle {
      anchors { left: parent.left; right: parent.right; bottom: parent.bottom; bottomMargin: FrameTokens.attachedEdgeStrokeOffset }
      height: 1
      visible: root.attachedEdge === "bottom"
      color: Qt.rgba(Colors.panelBorder.r, Colors.panelBorder.g, Colors.panelBorder.b, Colors.darkMode ? 0.28 : 0.34)
    }

    Rectangle {
      anchors { top: parent.top; right: parent.right; bottom: parent.bottom }
      width: FrameTokens.attachedEdgeDepth
      visible: root.attachedEdge === "right"
      color: root.fillColor
    }
  }

  Item {
    id: contentHost
    anchors.fill: parent
  }
}
