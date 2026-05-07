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
  property bool deformContent: true
  property bool edgeSocketEnabled: attachedEdge !== "none"
  property bool drawSurface: true

  readonly property alias deformMatrix: blobSurface.deformMatrix
  readonly property alias rawDeformMatrix: blobSurface.rawDeformMatrix

  BlobGroup {
    id: blobGroup
    color: root.fillColor
    smoothing: root.smoothing
  }

  BlobRect {
    id: blobSurface
    visible: root.drawSurface
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

  BlobRect {
    id: bottomSocket
    visible: root.drawSurface && root.edgeSocketEnabled && root.attachedEdge === "bottom"
    x: -FrameTokens.frameBlend
    y: root.height - FrameTokens.attachedEdgeDepth - 2
    implicitWidth: root.width + FrameTokens.frameBlend * 2
    implicitHeight: FrameTokens.attachedEdgeDepth + FrameTokens.frameBlend + 2
    group: blobGroup
    radius: Math.max(4, root.radius - 4)
    bottomLeftRadius: 0
    bottomRightRadius: 0
    deformScale: root.deformScale
    stiffness: root.stiffness
    damping: root.damping
  }

  BlobRect {
    id: rightSocket
    visible: root.drawSurface && root.edgeSocketEnabled && root.attachedEdge === "right"
    x: root.width - FrameTokens.attachedEdgeDepth - 2
    y: -FrameTokens.frameBlend
    implicitWidth: FrameTokens.attachedEdgeDepth + FrameTokens.frameBlend + 2
    implicitHeight: root.height + FrameTokens.frameBlend * 2
    group: blobGroup
    radius: Math.max(4, root.radius - 4)
    topRightRadius: 0
    bottomRightRadius: 0
    deformScale: root.deformScale
    stiffness: root.stiffness
    damping: root.damping
  }

  Rectangle {
    visible: root.drawSurface
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

    transform: Matrix4x4 {
      matrix: root.deformContent ? blobSurface.deformMatrix : identityMatrix.matrix
    }
  }

  Matrix4x4 {
    id: identityMatrix
  }
}
