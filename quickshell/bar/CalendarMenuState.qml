pragma Singleton

import QtQuick

QtObject {
  property bool visible: false
  property real anchorX: 0
  property real anchorY: 0
  property int monthOffset: 0

  function open(x, y) {
    anchorX = x
    anchorY = y
    visible = true
  }

  function close() {
    visible = false
  }

  function toggle(x, y) {
    if (visible) {
      close()
      return
    }

    monthOffset = 0
    open(x, y)
  }
}
