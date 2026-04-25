import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
  id: actionRoot

  property var action: ({ name: "" })
  property bool selected: false
  property int actionIndex: -1

  signal hovered(int index)
  signal triggered(int index)

  radius: 10
  color: selected
    ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.12)
    : mouse.containsMouse
      ? Qt.rgba(1, 1, 1, 0.03)
      : "transparent"

  Behavior on color { ColorAnimation { duration: 90 } }

  RowLayout {
    anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
    spacing: 10

    Text {
      text: "↳"
      color: selected ? Colors.accent : Colors.text3
      font { pixelSize: 12; family: "JetBrainsMono Nerd Font" }
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 2

      Text {
        text: action.name || ""
        color: selected ? Colors.text0 : Colors.text1
        font { pixelSize: 12; family: "JetBrainsMono Nerd Font" }
        elide: Text.ElideRight
        Layout.fillWidth: true
      }

      Text {
        text: "Acao secundaria"
        color: Colors.text3
        font { pixelSize: 10; family: "JetBrainsMono Nerd Font" }
      }
    }

    Text {
      text: "↵"
      color: Colors.accent
      font { pixelSize: 11; family: "JetBrainsMono Nerd Font" }
      opacity: selected ? 1 : 0
      Behavior on opacity { NumberAnimation { duration: 80 } }
    }
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    onEntered: actionRoot.hovered(actionRoot.actionIndex)
    onClicked: actionRoot.triggered(actionRoot.actionIndex)
  }
}
