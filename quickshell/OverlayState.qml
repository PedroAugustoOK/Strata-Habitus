pragma Singleton
import QtQuick

QtObject {
  property string activeOverlay: ""
  property string previousOverlay: ""
  property real islandX: 0
  property real islandY: 0
  property real islandWidth: 0
  property real islandHeight: 0
  readonly property real islandCenterX: islandX + islandWidth / 2
  readonly property real islandCenterY: islandY + islandHeight / 2

  function setActive(name) {
    if (activeOverlay === name) return
    previousOverlay = activeOverlay
    activeOverlay = name
  }

  function clear(name) {
    if (activeOverlay === name) {
      previousOverlay = activeOverlay
      activeOverlay = ""
    }
  }

  function setIslandGeometry(x, y, width, height) {
    islandX = x
    islandY = y
    islandWidth = width
    islandHeight = height
  }
}
