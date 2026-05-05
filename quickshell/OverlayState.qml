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

  function morphStartYOffset(windowHeight) {
    if (windowHeight <= 0 || islandCenterY <= 0)
      return -260
    return Math.max(-windowHeight * 0.48, Math.min(windowHeight * 0.48, islandCenterY - windowHeight / 2))
  }

  function morphStartXScale(targetWidth) {
    if (targetWidth <= 0 || islandWidth <= 0)
      return 0.22
    return Math.max(0.16, Math.min(0.36, islandWidth / targetWidth))
  }

  function morphStartYScale(targetHeight) {
    if (targetHeight <= 0 || islandHeight <= 0)
      return 0.08
    return Math.max(0.05, Math.min(0.16, islandHeight / targetHeight))
  }
}
