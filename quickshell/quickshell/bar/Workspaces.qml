import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

RowLayout {
  spacing: 0

  Repeater {
    model: 5
    delegate: Item {
      required property int index
      width: 16
      height: 32

      readonly property int wsId: index + 1
      readonly property bool focused: Hyprland.focusedWorkspace !== null
                                   && Hyprland.focusedWorkspace.id === wsId
      readonly property bool occupied: {
        for (let i = 0; i < Hyprland.workspaces.values.length; i++)
          if (Hyprland.workspaces.values[i].id === wsId) return true
        return false
      }

      Rectangle {
        anchors.centerIn: parent
        width:  focused ? 18 : 6
        height: 6
        radius: 3
        color:  focused ? "#cf9fff" : (occupied ? "#555" : "#2a2a2e")
        Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation   { duration: 150 } }
      }

      MouseArea {
        anchors.fill: parent
        onClicked: Hyprland.dispatch("workspace " + wsId)
      }
    }
  }
}
