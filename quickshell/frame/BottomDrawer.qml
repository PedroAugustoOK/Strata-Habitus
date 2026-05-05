import QtQuick

Item {
  id: root

  property bool open: false
  property int gutter: 10
  property int animationDuration: 260
  property real offsetScale: open ? 0 : 1

  visible: offsetScale < 1
  opacity: 1 - offsetScale
  anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
  anchors.bottom: parent ? parent.bottom : undefined
  anchors.bottomMargin: (-height - gutter) * offsetScale

  Behavior on offsetScale {
    NumberAnimation {
      duration: root.animationDuration
      easing.type: Easing.OutCubic
    }
  }
}
