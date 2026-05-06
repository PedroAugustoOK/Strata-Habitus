import QtQuick
import ".."

Item {
  id: root

  property bool open: false
  property int gutter: -10
  property int animationDuration: 320
  property real offsetScale: open ? 0 : 1
  property int frameBlend: 12

  visible: offsetScale < 1
  opacity: 1 - offsetScale
  scale: 1 - (offsetScale * 0.035)
  transformOrigin: Item.Bottom
  anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
  anchors.bottom: parent ? parent.bottom : undefined
  anchors.bottomMargin: (-height - gutter) * offsetScale

  Rectangle {
    x: -root.frameBlend
    y: Math.max(0, root.height - root.frameBlend)
    width: root.width + root.frameBlend * 2
    height: root.frameBlend * 2
    radius: 0
    color: Colors.panelBackground
    opacity: (1 - root.offsetScale) * Colors.panelOpacity
  }

  Rectangle {
    x: -root.frameBlend
    y: Math.max(0, root.height - root.frameBlend - 1)
    width: root.width + root.frameBlend * 2
    height: 1
    color: Qt.rgba(Colors.panelBorder.r, Colors.panelBorder.g, Colors.panelBorder.b, Colors.darkMode ? 0.18 : 0.26)
    opacity: 1 - root.offsetScale
  }

  Behavior on offsetScale {
    NumberAnimation {
      duration: root.animationDuration
      easing.type: Easing.BezierSpline
      easing.bezierCurve: [0.23, 1, 0.61, 1, 1, 1]
    }
  }

  Behavior on opacity {
    NumberAnimation {
      duration: 180
      easing.type: Easing.OutCubic
    }
  }

  Behavior on scale {
    NumberAnimation {
      duration: root.animationDuration
      easing.type: Easing.BezierSpline
      easing.bezierCurve: [0.23, 1, 0.61, 1, 1, 1]
    }
  }
}
