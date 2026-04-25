import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
  id: itemRoot

  property var item: ({ name: "", subtitle: "", iconPath: "", badges: [] })
  property bool selected: false
  property int itemIndex: -1

  signal hovered(int index)
  signal triggered(int index)

  radius: 12
  color: selected
    ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.12)
    : mouse.containsMouse
      ? Qt.rgba(1, 1, 1, 0.03)
      : "transparent"

  Behavior on color { ColorAnimation { duration: 90 } }

  RowLayout {
    anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
    spacing: 12

    Rectangle {
      Layout.preferredWidth: 34
      Layout.preferredHeight: 34
      radius: 10
      color: selected
        ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.14)
        : Qt.rgba(1, 1, 1, 0.04)

      Image {
        id: iconImage
        anchors.centerIn: parent
        width: 20
        height: 20
        source: item.iconPath || ""
        fillMode: Image.PreserveAspectFit
        smooth: true
        visible: source !== ""
      }

      Text {
        anchors.centerIn: parent
        text: (item.name || "?").charAt(0).toUpperCase()
        color: Colors.text2
        font { pixelSize: 12; family: "JetBrainsMono Nerd Font" }
        visible: !iconImage.visible
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 2

      Text {
        text: item.name || ""
        color: selected ? Colors.text0 : Colors.text1
        font { pixelSize: 14; family: "JetBrainsMono Nerd Font" }
        elide: Text.ElideRight
        Layout.fillWidth: true
      }

      Text {
        text: item.subtitle || ""
        color: Colors.text3
        font { pixelSize: 11; family: "JetBrainsMono Nerd Font" }
        elide: Text.ElideRight
        Layout.fillWidth: true
        visible: text !== ""
      }
    }

    RowLayout {
      spacing: 6

      Rectangle {
        radius: 7
        color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.10)
        Layout.preferredHeight: 22
        Layout.preferredWidth: actionBadge.implicitWidth + 14
        visible: (item.actionCount || 0) > 0

        Text {
          id: actionBadge
          anchors.centerIn: parent
          text: (item.actionCount || 0) + " acoes"
          color: Colors.accent
          font { pixelSize: 10; family: "JetBrainsMono Nerd Font" }
        }
      }

      Repeater {
        model: item.badges || []
        delegate: Rectangle {
          radius: 7
          color: Qt.rgba(1, 1, 1, 0.05)
          Layout.preferredHeight: 22
          Layout.preferredWidth: badgeText.implicitWidth + 14

          Text {
            id: badgeText
            anchors.centerIn: parent
            text: modelData
            color: Colors.text3
            font { pixelSize: 10; family: "JetBrainsMono Nerd Font" }
          }
        }
      }

      Text {
        text: "↵"
        color: Colors.accent
        font { pixelSize: 12; family: "JetBrainsMono Nerd Font" }
        opacity: selected ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 80 } }
      }
    }
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    onEntered: itemRoot.hovered(itemRoot.itemIndex)
    onClicked: itemRoot.triggered(itemRoot.itemIndex)
  }
}
