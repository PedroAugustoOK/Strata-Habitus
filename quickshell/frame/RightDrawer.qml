import QtQuick
import ".."

Item {
  id: root

  property bool open: false
  property int gutter: -10
  property int animationDuration: 260
  property real offsetScale: open ? 0 : 1
  property int frameBlend: 12

  visible: offsetScale < 1
  opacity: 1 - offsetScale
  scale: 1 - (offsetScale * 0.025)
  transformOrigin: Item.Right
  anchors.verticalCenter: parent ? parent.verticalCenter : undefined
  anchors.right: parent ? parent.right : undefined
  anchors.rightMargin: (-width - gutter) * offsetScale

  Rectangle {
    x: Math.max(0, root.width - root.frameBlend)
    y: -root.frameBlend
    width: root.frameBlend * 2
    height: root.height + root.frameBlend * 2
    radius: 0
    color: Colors.panelBackground
    opacity: (1 - root.offsetScale) * Colors.panelOpacity
  }

  Rectangle {
    x: Math.max(0, root.width - root.frameBlend - 1)
    y: -root.frameBlend
    width: 1
    height: root.height + root.frameBlend * 2
    color: Qt.rgba(Colors.panelBorder.r, Colors.panelBorder.g, Colors.panelBorder.b, Colors.darkMode ? 0.18 : 0.26)
    opacity: 1 - root.offsetScale
  }

  Behavior on offsetScale {
    NumberAnimation {
      duration: root.animationDuration
      easing.type: Easing.OutCubic
    }
  }

  Behavior on opacity {
    NumberAnimation {
      duration: root.animationDuration
      easing.type: Easing.OutCubic
    }
  }

  Behavior on scale {
    NumberAnimation {
      duration: root.animationDuration
      easing.type: Easing.OutCubic
    }
  }
}
