import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import ".."

PanelWindow {
  id: root

  anchors { top: true; bottom: true; left: true; right: true }
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  focusable: true
  visible: false
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
  WlrLayershell.layer: WlrLayer.Overlay

  property string requestId: ""
  property real originX: width / 2
  property real originY: height / 2
  property real startX: width / 2
  property real startY: height / 2
  property real endX: width / 2
  property real endY: height / 2
  property bool dragging: false
  property bool completed: false
  property real overlayOpacity: 0

  readonly property real x1: Math.min(startX, endX)
  readonly property real y1: Math.min(startY, endY)
  readonly property real x2: Math.max(startX, endX)
  readonly property real y2: Math.max(startY, endY)
  readonly property real selectionW: Math.max(0, x2 - x1)
  readonly property real selectionH: Math.max(0, y2 - y1)
  readonly property bool hasSelection: selectionW >= 8 && selectionH >= 8
  readonly property string geometry: Math.round(x1) + "," + Math.round(y1) + " " + Math.round(selectionW) + "x" + Math.round(selectionH)

  function select(id) {
    if (visible && requestId !== "" && !completed) {
      cancelProc.command = ["/run/current-system/sw/bin/bash", Paths.scripts + "/screenshot-geometry.sh", "cancel", requestId]
      cancelProc.running = true
    }

    fadeIn.stop()
    fadeOut.stop()
    requestId = id || String(Date.now())
    startX = width / 2
    startY = height / 2
    endX = startX
    endY = startY
    originX = startX
    originY = startY
    dragging = false
    completed = false
    visible = true
    overlayOpacity = 0
    selectionCanvas.requestPaint()
    fadeIn.start()
    keyGrabber.forceActiveFocus()
  }

  function finish() {
    if (completed) return
    if (selectionW < 8 || selectionH < 8) {
      cancel()
      return
    }

    completed = true
    resultProc.command = ["/run/current-system/sw/bin/bash", Paths.scripts + "/screenshot-geometry.sh", "finish", requestId, geometry]
    resultProc.running = true
    close()
  }

  function cancel() {
    if (completed) return
    completed = true
    if (requestId !== "") {
      resultProc.command = ["/run/current-system/sw/bin/bash", Paths.scripts + "/screenshot-geometry.sh", "cancel", requestId]
      resultProc.running = true
    }
    close()
  }

  function close() {
    fadeIn.stop()
    fadeOut.start()
  }

  NumberAnimation {
    id: fadeIn
    target: root
    property: "overlayOpacity"
    from: 0
    to: 1
    duration: 90
    easing.type: Easing.OutQuad
  }

  SequentialAnimation {
    id: fadeOut
    NumberAnimation {
      target: root
      property: "overlayOpacity"
      to: 0
      duration: 70
      easing.type: Easing.InQuad
    }
    ScriptAction {
      script: {
        root.visible = false
        root.dragging = false
        root.requestId = ""
        root.completed = false
      }
    }
  }

  Item {
    id: keyGrabber
    anchors.fill: parent
    focus: true
    Keys.onPressed: function(e) {
      if (e.key === Qt.Key_Escape) {
        root.cancel()
        e.accepted = true
      }
    }
  }

  Canvas {
    id: selectionCanvas
    anchors.fill: parent
    opacity: root.overlayOpacity

    onPaint: {
      const ctx = getContext("2d")
      ctx.reset()
      ctx.clearRect(0, 0, width, height)

      const bw = 4
      const r = 15
      const accent = Colors.primary.toString()
      const bg = Colors.bg0
      const w = root.selectionW
      const h = root.selectionH
      const x = root.x1
      const y = root.y1

      ctx.fillStyle = Qt.rgba(bg.r, bg.g, bg.b, Colors.darkMode ? 0.74 : 0.58).toString()
      ctx.fillRect(0, 0, width, height)

      if (!root.hasSelection) return

      ctx.globalCompositeOperation = "destination-out"
      ctx.fillRect(x, y, w, h)
      ctx.globalCompositeOperation = "source-over"

      ctx.fillStyle = accent
      ctx.fillRect(x - bw, y - bw, w + bw * 2, h + bw * 2)

      ctx.globalCompositeOperation = "destination-out"
      ctx.fillRect(x, y, w, h)
      ctx.globalCompositeOperation = "source-over"

      ctx.fillStyle = accent
      ctx.beginPath()
      ctx.arc(x, y, r, 0, Math.PI * 2)
      ctx.fill()
      ctx.beginPath()
      ctx.arc(x + w, y, r, 0, Math.PI * 2)
      ctx.fill()
      ctx.beginPath()
      ctx.arc(x, y + h, r, 0, Math.PI * 2)
      ctx.fill()
      ctx.beginPath()
      ctx.arc(x + w, y + h, r, 0, Math.PI * 2)
      ctx.fill()
    }
  }

  Rope {
    visible: root.visible && root.hasSelection
    opacity: root.overlayOpacity
    lineColor: Colors.primary
    anchorX: 0
    anchorY: 0
    pullX: root.x1
    pullY: root.y1
  }

  Rope {
    visible: root.visible && root.hasSelection
    opacity: root.overlayOpacity
    lineColor: Colors.primary
    anchorX: parent.width
    anchorY: 0
    pullX: root.x2
    pullY: root.y1
  }

  Rope {
    visible: root.visible && root.hasSelection
    opacity: root.overlayOpacity
    lineColor: Colors.primary
    anchorX: 0
    anchorY: parent.height
    pullX: root.x1
    pullY: root.y2
  }

  Rope {
    visible: root.visible && root.hasSelection
    opacity: root.overlayOpacity
    lineColor: Colors.primary
    anchorX: parent.width
    anchorY: parent.height
    pullX: root.x2
    pullY: root.y2
  }

  Rectangle {
    x: root.x1
    y: root.y1
    width: root.selectionW
    height: root.selectionH
    color: "transparent"
    border.width: 1
    border.color: Qt.rgba(Colors.text0.r, Colors.text0.g, Colors.text0.b, 0.28)
    opacity: root.overlayOpacity
    visible: root.hasSelection
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.CrossCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    onPressed: function(mouse) {
      if (mouse.button === Qt.RightButton) {
        root.cancel()
        mouse.accepted = true
        return
      }

      root.dragging = true
      root.originX = mouse.x
      root.originY = mouse.y
      root.startX = mouse.x
      root.startY = mouse.y
      root.endX = mouse.x
      root.endY = mouse.y
      selectionCanvas.requestPaint()
    }

    onPositionChanged: function(mouse) {
      if (!root.dragging) return
      root.startX = root.originX
      root.startY = root.originY
      root.endX = Math.max(0, Math.min(root.width, mouse.x))
      root.endY = Math.max(0, Math.min(root.height, mouse.y))
      selectionCanvas.requestPaint()
    }

    onReleased: function(mouse) {
      if (mouse.button !== Qt.LeftButton) return
      root.dragging = false
      selectionCanvas.requestPaint()
      root.finish()
    }
  }

  Connections {
    target: Colors
    function onPrimaryChanged() { selectionCanvas.requestPaint() }
    function onBg0Changed() { selectionCanvas.requestPaint() }
  }

  onX1Changed: selectionCanvas.requestPaint()
  onY1Changed: selectionCanvas.requestPaint()
  onX2Changed: selectionCanvas.requestPaint()
  onY2Changed: selectionCanvas.requestPaint()

  Process {
    id: resultProc
    command: []
  }

  Process {
    id: cancelProc
    command: []
  }
}
