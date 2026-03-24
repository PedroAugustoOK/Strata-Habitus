import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import ".."

Item {
  id: wsRoot
  width: wsRow.width
  height: 34

  property var wsIcons: ({})
  property int currentIdx: Hyprland.focusedWorkspace !== null ? Hyprland.focusedWorkspace.id - 1 : 0

  onCurrentIdxChanged: {
    // para qualquer animação em andamento
    moveAnim.stop()
    bounceAnim.stop()
    // reseta scale
    slider.scale = 0.5
    // move direto pra nova posição
    moveAnim.to = posForIdx(currentIdx)
    moveAnim.start()
  }

  function posForIdx(idx) {
    return idx * (28 + 6) + (28 - 26) / 2
  }

  Row {
    id: wsRow
    spacing: 6
    height: 34

    Repeater {
      model: 5
      delegate: Item {
        required property int index
        width: 28
        height: 34

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
          width:  occupied || focused ? 26 : 6
          height: occupied || focused ? 26 : 6
          radius: width / 2
          color:  occupied || focused ? "#333338" : "#2a2a2e"

          Behavior on width  { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
          Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
          Behavior on color  { ColorAnimation  { duration: 200 } }

          Text {
            anchors.centerIn: parent
            visible: occupied
            text: wsRoot.wsIcons[wsId] || ""
            color: "#aaaaaa"
            font { pixelSize: 13; family: "JetBrainsMono Nerd Font" }
          }
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: Hyprland.dispatch("workspace " + wsId)
        }
      }
    }
  }

  // slider
  Rectangle {
    id: slider
    z: 10
    width: 26
    height: 26
    radius: 13
    color: Colors.accent
    y: (parent.height - height) / 2
    x: posForIdx(currentIdx)
    scale: 1
    transformOrigin: Item.Center
  }

  // move pro destino
  NumberAnimation {
    id: moveAnim
    target: slider
    property: "x"
    duration: 200
    easing.type: Easing.InOutCubic
    onFinished: bounceAnim.start()
  }

  // bounce na chegada
  SequentialAnimation {
    id: bounceAnim
    NumberAnimation {
      target: slider; property: "scale"
      from: 0.5; to: 1.1
      duration: 100; easing.type: Easing.OutQuad
    }
    NumberAnimation {
      target: slider; property: "scale"
      from: 1.1; to: 1.0
      duration: 80; easing.type: Easing.InOutQuad
    }
  }

 // ícone no slider
  Text {
    id: sliderIcon
    z: 11
    anchors.centerIn: slider
    text: wsRoot.wsIcons[currentIdx + 1] || ""
    color: "#0d0d0f"
    font { pixelSize: 13; family: "JetBrainsMono Nerd Font" }
    visible: !moveAnim.running
  }

  Component.onCompleted: slider.x = posForIdx(currentIdx)

  Process {
    id: iconProc
    command: ["/home/ankh/.config/quickshell/scripts/ws-icons.sh"]
    stdout: SplitParser {
      onRead: data => {
        var icons = {}
        var entries = data.trim().split("|")
        for (var i = 0; i < entries.length; i++) {
          var parts = entries[i].split(":")
          if (parts.length >= 2) {
            icons[parseInt(parts[0])] = parts.slice(1).join(":")
          }
        }
        wsRoot.wsIcons = icons
      }
    }
  }

  Timer {
    interval: 1000; running: true; repeat: true; triggeredOnStart: true
    onTriggered: iconProc.running = true
  }
}
