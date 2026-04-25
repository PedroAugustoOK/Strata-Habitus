pragma Singleton

import QtQuick

QtObject {
  id: state

  property bool visible: false
  property real anchorX: 0
  property real anchorY: 0
  property string label: ""
  property var item: null

  function open(itemRef, labelText, x, y) {
    item = itemRef
    label = labelText || "App"
    anchorX = x
    anchorY = y
    visible = true
  }

  function close() {
    visible = false
    item = null
    label = ""
  }
}
