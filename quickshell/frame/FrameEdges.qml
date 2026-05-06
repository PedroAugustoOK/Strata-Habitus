import Quickshell
import Quickshell.Wayland
import QtQuick
import ".."

Scope {
  id: root

  // Experimental fallback only. The production frame should follow the
  // Caelestia-style masked drawer surface, not stacked edge bars.
  property bool visible: true
  property int thickness: 10
  property int barHeight: 34
  property int cornerRadius: 12
  readonly property color edgeFill: Qt.rgba(
    Colors.barBackground.r,
    Colors.barBackground.g,
    Colors.barBackground.b,
    1
  )
  readonly property color accentLine: Qt.rgba(
    Colors.primary.r,
    Colors.primary.g,
    Colors.primary.b,
    Colors.darkMode ? 0.34 : 0.24
  )

  function requestCornerPaint() {
    topLeftCorner.requestPaint()
    topRightCorner.requestPaint()
    bottomLeftCorner.requestPaint()
    bottomRightCorner.requestPaint()
  }

  Connections {
    target: Colors
    function onBarBackgroundChanged() { root.requestCornerPaint() }
    function onPrimaryChanged() { root.requestCornerPaint() }
    function onDarkModeChanged() { root.requestCornerPaint() }
  }

  PanelWindow {
    anchors { left: true; right: true; bottom: true }
    implicitHeight: root.thickness
    color: "transparent"
    visible: root.visible
    exclusionMode: ExclusionMode.Ignore
    focusable: false
    mask: Region {}
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Rectangle {
      anchors.fill: parent
      color: root.edgeFill
    }

    Rectangle {
      anchors { left: parent.left; right: parent.right; top: parent.top }
      height: 1
      color: root.accentLine
    }
  }

  PanelWindow {
    anchors { left: true; bottom: true }
    implicitWidth: root.thickness
    implicitHeight: Screen.height - root.barHeight
    color: "transparent"
    visible: root.visible
    exclusionMode: ExclusionMode.Ignore
    focusable: false
    mask: Region {}
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Rectangle {
      anchors.fill: parent
      color: root.edgeFill
    }

    Rectangle {
      anchors { top: parent.top; right: parent.right; bottom: parent.bottom }
      width: 1
      color: root.accentLine
    }
  }

  PanelWindow {
    anchors { right: true; bottom: true }
    implicitWidth: root.thickness
    implicitHeight: Screen.height - root.barHeight
    color: "transparent"
    visible: root.visible
    exclusionMode: ExclusionMode.Ignore
    focusable: false
    mask: Region {}
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Rectangle {
      anchors.fill: parent
      color: root.edgeFill
    }

    Rectangle {
      anchors { top: parent.top; left: parent.left; bottom: parent.bottom }
      width: 1
      color: root.accentLine
    }
  }

  PanelWindow {
    anchors { top: true; left: true }
    implicitWidth: root.thickness + root.cornerRadius
    implicitHeight: root.barHeight + root.cornerRadius
    color: "transparent"
    visible: root.visible
    exclusionMode: ExclusionMode.Ignore
    focusable: false
    mask: Region {}
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Canvas {
      id: topLeftCorner
      anchors.fill: parent
      Component.onCompleted: requestPaint()
      onWidthChanged: requestPaint()
      onHeightChanged: requestPaint()
      onPaint: {
        const ctx = getContext("2d")
        const b = root.thickness
        const r = root.cornerRadius
        const bh = root.barHeight
        ctx.clearRect(0, 0, width, height)
        ctx.fillStyle = root.edgeFill.toString()
        ctx.fillRect(0, bh, b, height - bh)
        ctx.beginPath()
        ctx.moveTo(b, bh)
        ctx.lineTo(b, bh + r)
        ctx.arc(b + r, bh + r, r, Math.PI, -Math.PI / 2, false)
        ctx.lineTo(b, bh)
        ctx.closePath()
        ctx.fill()
        ctx.strokeStyle = root.accentLine.toString()
        ctx.lineWidth = 1
        ctx.beginPath()
        ctx.moveTo(b - 0.5, bh)
        ctx.lineTo(b - 0.5, bh + r)
        ctx.arc(b + r, bh + r, r + 0.5, Math.PI, -Math.PI / 2, false)
        ctx.stroke()
      }
    }
  }

  PanelWindow {
    anchors { top: true; right: true }
    implicitWidth: root.thickness + root.cornerRadius
    implicitHeight: root.barHeight + root.cornerRadius
    color: "transparent"
    visible: root.visible
    exclusionMode: ExclusionMode.Ignore
    focusable: false
    mask: Region {}
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Canvas {
      id: topRightCorner
      anchors.fill: parent
      Component.onCompleted: requestPaint()
      onWidthChanged: requestPaint()
      onHeightChanged: requestPaint()
      onPaint: {
        const ctx = getContext("2d")
        const b = root.thickness
        const r = root.cornerRadius
        const bh = root.barHeight
        const w = width
        ctx.clearRect(0, 0, width, height)
        ctx.fillStyle = root.edgeFill.toString()
        ctx.fillRect(w - b, bh, b, height - bh)
        ctx.beginPath()
        ctx.moveTo(w - b, bh)
        ctx.lineTo(w - b, bh + r)
        ctx.arc(w - b - r, bh + r, r, 0, -Math.PI / 2, true)
        ctx.lineTo(w - b, bh)
        ctx.closePath()
        ctx.fill()
        ctx.strokeStyle = root.accentLine.toString()
        ctx.lineWidth = 1
        ctx.beginPath()
        ctx.moveTo(w - b + 0.5, bh)
        ctx.lineTo(w - b + 0.5, bh + r)
        ctx.arc(w - b - r, bh + r, r + 0.5, 0, -Math.PI / 2, true)
        ctx.stroke()
      }
    }
  }

  PanelWindow {
    anchors { left: true; bottom: true }
    implicitWidth: root.thickness + root.cornerRadius
    implicitHeight: root.thickness + root.cornerRadius
    color: "transparent"
    visible: root.visible
    exclusionMode: ExclusionMode.Ignore
    focusable: false
    mask: Region {}
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Canvas {
      id: bottomLeftCorner
      anchors.fill: parent
      Component.onCompleted: requestPaint()
      onWidthChanged: requestPaint()
      onHeightChanged: requestPaint()
      onPaint: {
        const ctx = getContext("2d")
        const b = root.thickness
        const r = root.cornerRadius
        const h = height
        ctx.clearRect(0, 0, width, height)
        ctx.fillStyle = root.edgeFill.toString()
        ctx.fillRect(0, 0, b, h - b)
        ctx.fillRect(b, h - b, width - b, b)
        ctx.beginPath()
        ctx.moveTo(b, h - b)
        ctx.arc(b + r, h - b - r, r, Math.PI / 2, Math.PI, false)
        ctx.closePath()
        ctx.fill()
        ctx.strokeStyle = root.accentLine.toString()
        ctx.lineWidth = 1
        ctx.beginPath()
        ctx.moveTo(b - 0.5, h - b)
        ctx.arc(b + r, h - b - r, r + 0.5, Math.PI / 2, Math.PI, false)
        ctx.stroke()
      }
    }
  }

  PanelWindow {
    anchors { right: true; bottom: true }
    implicitWidth: root.thickness + root.cornerRadius
    implicitHeight: root.thickness + root.cornerRadius
    color: "transparent"
    visible: root.visible
    exclusionMode: ExclusionMode.Ignore
    focusable: false
    mask: Region {}
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Canvas {
      id: bottomRightCorner
      anchors.fill: parent
      Component.onCompleted: requestPaint()
      onWidthChanged: requestPaint()
      onHeightChanged: requestPaint()
      onPaint: {
        const ctx = getContext("2d")
        const b = root.thickness
        const r = root.cornerRadius
        const w = width
        const h = height
        ctx.clearRect(0, 0, width, height)
        ctx.fillStyle = root.edgeFill.toString()
        ctx.fillRect(w - b, 0, b, h - b)
        ctx.fillRect(0, h - b, w - b, b)
        ctx.beginPath()
        ctx.moveTo(w - b, h - b)
        ctx.arc(w - b - r, h - b - r, r, Math.PI / 2, 0, true)
        ctx.closePath()
        ctx.fill()
        ctx.strokeStyle = root.accentLine.toString()
        ctx.lineWidth = 1
        ctx.beginPath()
        ctx.moveTo(w - b + 0.5, h - b)
        ctx.arc(w - b - r, h - b - r, r + 0.5, Math.PI / 2, 0, true)
        ctx.stroke()
      }
    }
  }
}
