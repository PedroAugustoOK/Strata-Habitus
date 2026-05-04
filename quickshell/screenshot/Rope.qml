import QtQuick
import QtQuick.Shapes
import ".."

Item {
  id: root

  property real anchorX: 0
  property real anchorY: 0
  property real pullX: 100
  property real pullY: 100
  property int segments: 12
  property real segmentLength: 14
  property real gravity: 5.5
  property color lineColor: Colors.primary

  anchors.fill: parent

  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer

    Instantiator {
      model: root.segments
      onObjectAdded: function(index, pathCurve) {
        pathCurves.pathElements.push(pathCurve)
      }
      delegate: PathCurve {
        property int index: model.index
        x: root.anchorX
        y: root.anchorY
      }
    }

    ShapePath {
      id: pathCurves
      strokeColor: root.lineColor
      fillColor: "transparent"
      strokeWidth: 4
      startX: root.anchorX
      startY: root.anchorY
      capStyle: ShapePath.RoundCap
      joinStyle: ShapePath.RoundJoin
    }

    ShapePath {
      id: dotPath

      PathAngleArc {
        id: startPoint
        property real vx: 0
        property real vy: 0
        centerX: root.anchorX
        centerY: root.anchorY
        radiusX: 1
        radiusY: 1
        startAngle: 0
        sweepAngle: 360

        onCenterXChanged: pathCurves.startX = centerX
        onCenterYChanged: pathCurves.startY = centerY
      }
    }

    Instantiator {
      model: root.segments
      onObjectAdded: function(index, pathPoint) {
        dotPath.pathElements.push(pathPoint)
      }
      delegate: PathAngleArc {
        property int index: model.index
        property real vx: 0
        property real vy: 0
        centerX: root.anchorX
        centerY: root.anchorY
        radiusX: 1
        radiusY: 1
        startAngle: 0
        sweepAngle: 360

        onCenterXChanged: {
          if (pathCurves.pathElements[index]) pathCurves.pathElements[index].x = centerX
        }
        onCenterYChanged: {
          if (pathCurves.pathElements[index]) pathCurves.pathElements[index].y = centerY
        }
      }
    }

    Timer {
      interval: 16
      running: root.visible
      repeat: true
      onTriggered: {
        if (dotPath.pathElements.length <= root.segments) return

        for (let i = root.segments; i > 0; i -= 1) {
          const point = dotPath.pathElements[i]
          const prev = dotPath.pathElements[i - 1]

          let dx = prev.centerX - point.centerX
          let dy = prev.centerY - point.centerY
          let dist = Math.max(1, Math.sqrt(dx * dx + dy * dy))
          let extend = dist - root.segmentLength
          let vx = (dx / dist) * extend
          let vy = (dy / dist) * extend + root.gravity

          if (i < root.segments - 2) {
            const next = dotPath.pathElements[i + 1]
            dx = next.centerX - point.centerX
            dy = next.centerY - point.centerY
            dist = Math.max(1, Math.sqrt(dx * dx + dy * dy))
            extend = dist - root.segmentLength
            vx += (dx / dist) * extend
            vy += (dy / dist) * extend
          } else {
            point.centerX = root.pullX
            point.centerY = root.pullY
            vx = 0
            vy = 0
          }

          point.vx = point.vx * 0.48 + vx * 0.42
          point.vy = point.vy * 0.48 + vy * 0.42
          point.centerX += point.vx
          point.centerY += point.vy
        }
      }
    }
  }
}
