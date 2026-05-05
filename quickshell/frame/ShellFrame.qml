import Quickshell
import Quickshell.Wayland
import QtQuick
import ".."

Item {
  id: root

  signal openControlCenter()
  signal openThemePicker()
  signal openWallPickr()
  signal openAppCenter()
  signal openUpdateCenter()

  property bool active: false
  readonly property int barH: 34
  readonly property int brd: 10
  readonly property int r: 12

  function anyDrawerOpen() {
    return frameLauncher.open ||
      frameSettingsCenter.open ||
      frameUpdateCenter.open ||
      frameThemePicker.open ||
      frameWallPickr.open ||
      frameAppCenter.open ||
      frameClipboard.open ||
      framePowerMenu.open
  }

  function closeDrawers(except) {
    if (except !== "launcher" && frameLauncher.open) frameLauncher.close()
    if (except !== "settings" && frameSettingsCenter.open) frameSettingsCenter.close()
    if (except !== "update" && frameUpdateCenter.open) frameUpdateCenter.close()
    if (except !== "theme" && frameThemePicker.open) frameThemePicker.close()
    if (except !== "wall" && frameWallPickr.open) frameWallPickr.close()
    if (except !== "app" && frameAppCenter.open) frameAppCenter.close()
    if (except !== "clipboard" && frameClipboard.open) frameClipboard.close()
    if (except !== "power" && framePowerMenu.open) framePowerMenu.close()
  }

  function toggleLauncher() {
    closeDrawers("launcher")
    frameLauncher.toggle()
  }

  function toggleSettingsCenter() {
    closeDrawers("settings")
    frameSettingsCenter.toggle()
  }

  function toggleUpdateCenter() {
    closeDrawers("update")
    frameUpdateCenter.toggle()
  }

  function toggleThemePicker() {
    closeDrawers("theme")
    frameThemePicker.toggle()
  }

  function toggleWallPickr() {
    closeDrawers("wall")
    frameWallPickr.toggle()
  }

  function toggleAppCenter() {
    closeDrawers("app")
    frameAppCenter.toggle()
  }

  function toggleClipboard() {
    closeDrawers("clipboard")
    frameClipboard.toggle()
  }

  function togglePowerMenu() {
    closeDrawers("power")
    framePowerMenu.toggle()
  }

  PanelWindow {
    id: frame
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    visible: root.active
    mask: Region { item: root.anyDrawerOpen() ? inputRegion : emptyInputRegion }
    focusable: root.anyDrawerOpen()
    WlrLayershell.keyboardFocus: root.anyDrawerOpen() ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    Keys.onPressed: function(event) {
      if (event.key === Qt.Key_Escape && root.anyDrawerOpen()) {
        root.closeDrawers("")
        event.accepted = true
      }
    }

    Item {
      anchors.fill: parent

      Item {
        id: inputRegion
        anchors.fill: parent
      }

      Item {
        id: emptyInputRegion
        width: 0
        height: 0
      }

      MouseArea {
        anchors.fill: parent
        enabled: root.anyDrawerOpen()
        onClicked: root.closeDrawers("")
      }

      Rectangle {
        x: 0
        y: root.barH
        width: root.brd
        height: parent.height - root.barH
        color: Colors.bg1
      }

      Rectangle {
        x: parent.width - root.brd
        y: root.barH
        width: root.brd
        height: parent.height - root.barH
        color: Colors.bg1
      }

      Rectangle {
        x: 0
        y: parent.height - root.brd
        width: parent.width
        height: root.brd
        color: Colors.bg1
      }

      Canvas {
        id: frameCanvas
        anchors.fill: parent
        Component.onCompleted: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
          const ctx = getContext("2d")
          const b = root.brd
          const rv = root.r
          const bh = root.barH
          const w = width
          const h = height
          ctx.clearRect(0, 0, w, h)
          ctx.fillStyle = Colors.bg1.toString()

          ctx.beginPath()
          ctx.moveTo(b, bh)
          ctx.lineTo(b, bh + rv)
          ctx.arc(b + rv, bh + rv, rv, Math.PI, -Math.PI / 2, false)
          ctx.lineTo(b, bh)
          ctx.closePath()
          ctx.fill()

          ctx.beginPath()
          ctx.moveTo(w - b, bh)
          ctx.lineTo(w - b, bh + rv)
          ctx.arc(w - b - rv, bh + rv, rv, 0, -Math.PI / 2, true)
          ctx.lineTo(w - b, bh)
          ctx.closePath()
          ctx.fill()

          ctx.beginPath()
          ctx.moveTo(b, h - b)
          ctx.arc(b + rv, h - b - rv, rv, Math.PI / 2, Math.PI, false)
          ctx.closePath()
          ctx.fill()

          ctx.beginPath()
          ctx.moveTo(w - b, h - b)
          ctx.arc(w - b - rv, h - b - rv, rv, Math.PI / 2, 0, true)
          ctx.closePath()
          ctx.fill()
        }

        Connections {
          target: Colors
          function onBg1Changed() { frameCanvas.requestPaint() }
        }
      }

      FrameLauncher {
        id: frameLauncher
      }

      FrameSettingsCenter {
        id: frameSettingsCenter
        onOpenControlCenter: root.openControlCenter()
        onOpenThemePicker: root.toggleThemePicker()
        onOpenWallPickr: root.toggleWallPickr()
        onOpenAppCenter: root.toggleAppCenter()
        onOpenUpdateCenter: root.toggleUpdateCenter()
      }

      FrameUpdateCenter {
        id: frameUpdateCenter
      }

      FrameThemePicker {
        id: frameThemePicker
      }

      FrameWallPickr {
        id: frameWallPickr
      }

      FrameAppCenter {
        id: frameAppCenter
      }

      FrameClipboard {
        id: frameClipboard
      }

      FramePowerMenu {
        id: framePowerMenu
      }
    }
  }
}
