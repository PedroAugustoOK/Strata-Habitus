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
  signal closeControlCenter()

  property bool active: false
  readonly property int barH: 34
  readonly property int brd: 10
  readonly property int r: 12
  property bool drawerOpen: anyDrawerOpen()
  property real bottomDrawerProgress: (
    frameLauncher.open ||
    frameThemePicker.open ||
    frameWallPickr.open ||
    frameClipboard.open ||
    framePowerMenu.open
  ) ? 1 : 0
  property real rightDrawerProgress: (
    frameSettingsCenter.open ||
    frameUpdateCenter.open ||
    frameAppCenter.open ||
    OverlayState.activeOverlay === "controlcenter"
  ) ? 1 : 0
  readonly property color frameFill: Qt.rgba(
    Colors.barBackground.r,
    Colors.barBackground.g,
    Colors.barBackground.b,
    1
  )
  readonly property color frameLine: Qt.rgba(
    Colors.panelBorder.r,
    Colors.panelBorder.g,
    Colors.panelBorder.b,
    Colors.darkMode ? 0.18 : 0.26
  )
  readonly property color bottomFrameGlow: Qt.rgba(
    Colors.primary.r,
    Colors.primary.g,
    Colors.primary.b,
    (Colors.darkMode ? 0.18 : 0.14) * bottomDrawerProgress
  )
  readonly property color rightFrameGlow: Qt.rgba(
    Colors.primary.r,
    Colors.primary.g,
    Colors.primary.b,
    (Colors.darkMode ? 0.18 : 0.14) * rightDrawerProgress
  )

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

  function prepareDrawer(except) {
    closeControlCenter()
    closeDrawers(except)
  }

  function toggleLauncher() {
    prepareDrawer("launcher")
    frameLauncher.toggle()
  }

  function toggleSettingsCenter() {
    prepareDrawer("settings")
    frameSettingsCenter.toggle()
  }

  function toggleUpdateCenter() {
    prepareDrawer("update")
    frameUpdateCenter.toggle()
  }

  function toggleThemePicker() {
    prepareDrawer("theme")
    frameThemePicker.toggle()
  }

  function toggleWallPickr() {
    prepareDrawer("wall")
    frameWallPickr.toggle()
  }

  function toggleAppCenter() {
    prepareDrawer("app")
    frameAppCenter.toggle()
  }

  function toggleClipboard() {
    prepareDrawer("clipboard")
    frameClipboard.toggle()
  }

  function togglePowerMenu() {
    prepareDrawer("power")
    framePowerMenu.toggle()
  }

  PanelWindow {
    id: frame
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    visible: root.active
    mask: Region { item: root.drawerOpen ? inputRegion : emptyInputRegion }
    focusable: root.drawerOpen
    WlrLayershell.keyboardFocus: root.drawerOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Item {
      anchors.fill: parent

      Item {
        id: frameKeyGrabber
        anchors.fill: parent
        focus: root.drawerOpen
        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Escape && root.drawerOpen) {
            root.closeDrawers("")
            event.accepted = true
          }
        }
      }

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
        enabled: root.drawerOpen
        onClicked: root.closeDrawers("")
      }

      Rectangle {
        x: 0
        y: root.barH
        width: root.brd
        height: parent.height - root.barH
        color: root.frameFill
      }

      Rectangle {
        x: parent.width - root.brd
        y: root.barH
        width: root.brd
        height: parent.height - root.barH
        color: root.frameFill
      }

      Rectangle {
        x: 0
        y: parent.height - root.brd
        width: parent.width
        height: root.brd
        color: root.frameFill
      }

      Rectangle {
        x: root.brd - 1
        y: root.barH
        width: 1
        height: parent.height - root.barH - root.brd
        color: root.frameLine
        opacity: 0.78
      }

      Rectangle {
        x: parent.width - root.brd
        y: root.barH
        width: 1
        height: parent.height - root.barH - root.brd
        color: root.frameLine
        opacity: 0.78
      }

      Rectangle {
        x: root.brd
        y: parent.height - root.brd
        width: parent.width - root.brd * 2
        height: 1
        color: root.frameLine
        opacity: 0.78
      }

      Rectangle {
        x: parent.width - root.brd - 1
        y: root.barH
        width: 1
        height: parent.height - root.barH - root.brd
        color: root.rightFrameGlow
      }

      Rectangle {
        x: root.brd
        y: parent.height - root.brd - 1
        width: parent.width - root.brd * 2
        height: 1
        color: root.bottomFrameGlow
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
          ctx.fillStyle = root.frameFill.toString()

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
          function onBarBackgroundChanged() { frameCanvas.requestPaint() }
          function onPanelBorderChanged() { frameCanvas.requestPaint() }
          function onDarkModeChanged() { frameCanvas.requestPaint() }
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

  Behavior on bottomDrawerProgress {
    NumberAnimation {
      duration: 180
      easing.type: Easing.OutCubic
    }
  }

  Behavior on rightDrawerProgress {
    NumberAnimation {
      duration: 180
      easing.type: Easing.OutCubic
    }
  }

  onDrawerOpenChanged: {
    if (drawerOpen)
      frameFocusTimer.restart()
  }

  Timer {
    id: frameFocusTimer
    interval: 20
    repeat: false
    onTriggered: frameKeyGrabber.forceActiveFocus()
  }
}
