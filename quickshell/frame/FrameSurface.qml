import QtQuick
import ".."

Item {
  id: root

  default property alias content: contentHost.data

  property int radius: Math.round(18 * Colors.radiusScale)
  property color fillColor: Colors.panelBackground
  property color borderColor: Colors.panelBorder
  property bool gradientEnabled: true
  property string attachedEdge: "none"
  property real topToneOpacity: Colors.darkMode ? 0.56 : 0.42
  property real bottomToneOpacity: Colors.darkMode ? 0.96 : 0.90

  Rectangle {
    id: surface
    anchors.fill: parent
    radius: root.radius
    antialiasing: true
    color: root.fillColor
    border.width: 1
    border.color: root.borderColor
    clip: false

    Rectangle {
      anchors.fill: parent
      radius: parent.radius
      antialiasing: true
      visible: root.gradientEnabled
      gradient: Gradient {
        GradientStop {
          position: 0.0
          color: Qt.rgba(Colors.panelRaised.r, Colors.panelRaised.g, Colors.panelRaised.b, root.topToneOpacity)
        }
        GradientStop {
          position: 1.0
          color: Qt.rgba(Colors.panelBackground.r, Colors.panelBackground.g, Colors.panelBackground.b, root.bottomToneOpacity)
        }
      }
    }

    Rectangle {
      anchors { left: parent.left; right: parent.right; top: parent.top }
      height: 1
      color: Qt.rgba(Colors.text0.r, Colors.text0.g, Colors.text0.b, Colors.darkMode ? 0.045 : 0.28)
    }

    Rectangle {
      anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
      height: root.radius + 2
      visible: root.attachedEdge === "bottom"
      color: root.fillColor
    }

    Rectangle {
      anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
      height: 2
      visible: root.attachedEdge === "bottom"
      color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, Colors.darkMode ? 0.14 : 0.11)
    }

    Rectangle {
      anchors { top: parent.top; right: parent.right; bottom: parent.bottom }
      width: root.radius + 2
      visible: root.attachedEdge === "right"
      color: root.fillColor
    }

    Rectangle {
      anchors { top: parent.top; right: parent.right; bottom: parent.bottom }
      width: 2
      visible: root.attachedEdge === "right"
      color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, Colors.darkMode ? 0.14 : 0.11)
    }

    Item {
      id: contentHost
      anchors.fill: parent
    }
  }
}
