import Quickshell
import Quickshell.Wayland
import QtQuick

Item {
  // Borda esquerda
  PanelWindow {
    anchors { top: true; left: true; bottom: true }
    implicitWidth: 2
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    Canvas {
      anchors.fill: parent
      onPaint: {
        const ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)
        ctx.strokeStyle = "rgba(255,255,255,0.08)"
        ctx.lineWidth = 1
        ctx.beginPath()
        ctx.moveTo(1, 34)
        ctx.lineTo(1, height)
        ctx.stroke()
      }
    }
  }

  // Borda direita
  PanelWindow {
    anchors { top: true; right: true; bottom: true }
    implicitWidth: 2
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    Canvas {
      anchors.fill: parent
      onPaint: {
        const ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)
        ctx.strokeStyle = "rgba(255,255,255,0.08)"
        ctx.lineWidth = 1
        ctx.beginPath()
        ctx.moveTo(1, 34)
        ctx.lineTo(1, height)
        ctx.stroke()
      }
    }
  }

  // Borda inferior com cantos
  PanelWindow {
    anchors { left: true; right: true; bottom: true }
    implicitHeight: 2
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    Canvas {
      anchors.fill: parent
      onPaint: {
        const ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)
        ctx.strokeStyle = "rgba(255,255,255,0.08)"
        ctx.lineWidth = 1
        ctx.beginPath()
        ctx.moveTo(0, 1)
        ctx.lineTo(width, 1)
        ctx.stroke()
      }
    }
  }
}
