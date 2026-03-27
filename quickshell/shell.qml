import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import "bar"
import "launcher"
import "notifications"
import "osd"
import "controlcenter"
import "powermenu"

ShellRoot {
  Bar {}
  Launcher { id: launcher }
  Notifications {}
  OSD {}
  ControlCenter { id: controlCenter }
  PowerMenu { id: powerMenu }

  readonly property int barH: 34
  readonly property int brd: 10
  readonly property int r: 12

  // Overlay PowerMenu
  PanelWindow {
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    focusable: true
    visible: powerMenu.visible
    mask: Region {}
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    Keys.onPressed: function(e) {
      if (e.key === Qt.Key_Escape) powerMenu.close()
    }
    MouseArea {
      anchors.fill: parent
      onClicked: powerMenu.close()
    }
  }

  // Borda esquerda — exatamente brd de largura, sem arco
  PanelWindow {
    anchors { top: true; left: true; bottom: true }
    implicitWidth: brd
    color: "#111113"
    exclusionMode: ExclusionMode.Ignore
  }

  // Arco superior esquerdo — janela separada
  PanelWindow {
    anchors { top: true; left: true }
    implicitWidth: brd + r
    implicitHeight: barH + r
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    Canvas {
      anchors.fill: parent
      Component.onCompleted: requestPaint()
      onPaint: {
        const ctx = getContext("2d")
        const bh = barH, b = brd, rv = r
        ctx.clearRect(0, 0, width, height)
        ctx.fillStyle = "#111113"
        ctx.fillRect(0, 0, b, bh)
        ctx.beginPath()
        ctx.moveTo(b, bh); ctx.lineTo(b, bh + rv)
        ctx.arc(b + rv, bh + rv, rv, Math.PI, -Math.PI / 2, false)
        ctx.lineTo(b, bh); ctx.closePath(); ctx.fill()
      }
    }
  }

  // Borda direita — exatamente brd de largura, sem arco
  PanelWindow {
    anchors { top: true; right: true; bottom: true }
    implicitWidth: brd
    color: "#111113"
    exclusionMode: ExclusionMode.Ignore
  }

  // Arco superior direito — janela separada
  PanelWindow {
    anchors { top: true; right: true }
    implicitWidth: brd + r
    implicitHeight: barH + r
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    Canvas {
      anchors.fill: parent
      Component.onCompleted: requestPaint()
      onPaint: {
        const ctx = getContext("2d")
        const bh = barH, b = brd, rv = r, w = width
        ctx.clearRect(0, 0, w, height)
        ctx.fillStyle = "#111113"
        ctx.fillRect(rv, 0, b, bh)
        ctx.beginPath()
        ctx.moveTo(rv, bh); ctx.lineTo(rv, bh + rv)
        ctx.arc(0, bh + rv, rv, 0, -Math.PI / 2, true)
        ctx.lineTo(rv, bh); ctx.closePath(); ctx.fill()
      }
    }
  }

  // Borda inferior
  PanelWindow {
    anchors { left: true; right: true; bottom: true }
    implicitHeight: brd
    color: "#111113"
    exclusionMode: ExclusionMode.Ignore
  }

  // Canto inferior esquerdo
  PanelWindow {
    anchors { left: true; bottom: true }
    implicitWidth: brd + r
    implicitHeight: brd + r
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    Canvas {
      anchors.fill: parent
      Component.onCompleted: requestPaint()
      onPaint: {
        const ctx = getContext("2d")
        const b = brd, rv = r, h = height
        ctx.clearRect(0, 0, width, h)
        ctx.fillStyle = "#111113"
        ctx.fillRect(0, 0, b, h - b)
        ctx.fillRect(b, h - b, rv, b)
        ctx.beginPath()
        ctx.moveTo(b, h - b)
        ctx.arc(b + rv, h - b - rv, rv, Math.PI / 2, Math.PI, false)
        ctx.closePath(); ctx.fill()
      }
    }
  }

  // Canto inferior direito
  PanelWindow {
    anchors { right: true; bottom: true }
    implicitWidth: brd + r
    implicitHeight: brd + r
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    Canvas {
      anchors.fill: parent
      Component.onCompleted: requestPaint()
      onPaint: {
        const ctx = getContext("2d")
        const b = brd, rv = r, w = width, h = height
        ctx.clearRect(0, 0, w, h)
        ctx.fillStyle = "#111113"
        ctx.fillRect(rv, 0, b, h - b)
        ctx.fillRect(0, h - b, rv, b)
        ctx.beginPath()
        ctx.moveTo(rv, h - b)
        ctx.arc(0, h - b - rv, rv, Math.PI / 2, 0, true)
        ctx.closePath(); ctx.fill()
      }
    }
  }

  IpcHandler {
    target: "launcher"
    function toggle(): void { launcher.toggle() }
  }

  IpcHandler {
    target: "controlcenter"
    function toggle(): void { controlCenter.toggle() }
  }

  IpcHandler {
    target: "powermenu"
    function toggle(): void { powerMenu.toggle() }
  }
}
