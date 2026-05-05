import QtQuick
import QtQuick.Controls
import ".."

Item {
  id: root
  width: 20
  height: 20

  property int  value:    100
  property bool charging: false

  readonly property color ringColor: charging
    ? Colors.success
    : value > 50 ? Colors.success
    : value > 20 ? Colors.warning
    :               Colors.danger

  Canvas {
    id: cv
    anchors.fill: parent
    onPaint: {
      var ctx = getContext("2d")
      ctx.clearRect(0, 0, width, height)
      var cx = width / 2, cy = height / 2, r = width / 2 - 2
      ctx.beginPath()
      ctx.arc(cx, cy, r, 0, 2 * Math.PI)
      ctx.strokeStyle = "#2a2a2e"
      ctx.lineWidth   = 2
      ctx.stroke()
      ctx.beginPath()
      ctx.arc(cx, cy, r, -Math.PI / 2,
              -Math.PI / 2 + 2 * Math.PI * root.value / 100)
      ctx.strokeStyle = root.ringColor
      ctx.lineWidth   = 2
      ctx.lineCap     = "round"
      ctx.stroke()
    }
  }

  Text {
    anchors.centerIn: parent
    text:  root.charging ? "\uE1A3" : "\uEBDC"
    font { family: "Material Symbols Rounded"; pixelSize: 10 }
    color: root.ringColor
  }

  // Tooltip com porcentagem
  MouseArea {
    id: batMa
    anchors.fill: parent
    hoverEnabled: true
    cursorShape:  Qt.ArrowCursor
  }

  Rectangle {
    id: tooltip
    visible: batMa.containsMouse
    anchors { bottom: parent.top; horizontalCenter: parent.horizontalCenter; bottomMargin: 4 }
    width:  tipText.implicitWidth + 12
    height: 20
    radius: 6
    color:  Colors.panelRaised
    z: 100

    Text {
      id: tipText
      anchors.centerIn: parent
      text:  (root.charging ? "⚡ " : "") + root.value + "%"
      color: root.ringColor
      font { pixelSize: 11; family: "Roboto" }
    }
  }

  onValueChanged:     cv.requestPaint()
  onChargingChanged:  cv.requestPaint()
  onRingColorChanged: cv.requestPaint()
}
