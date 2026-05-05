import QtQuick

Item {
  id: root

  property bool open: false
  property int gutter: 10
  property int animationDuration: 260
  property real offsetScale: open ? 0 : 1

  visible: offsetScale < 1
  opacity: 1 - offsetScale
  anchors.verticalCenter: parent ? parent.verticalCenter : undefined
  anchors.right: parent ? parent.right : undefined
  anchors.rightMargin: (-width - gutter) * offsetScale

  Behavior on offsetScale {
    NumberAnimation {
      duration: root.animationDuration
      easing.type: Easing.OutCubic
    }
  }
}
