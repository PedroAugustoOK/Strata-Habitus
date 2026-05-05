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

  property int visibleCount: {
    var max = 5
    for (var i = 0; i < Hyprland.workspaces.values.length; i++) {
      var id = Hyprland.workspaces.values[i].id
      if (id > max) max = id
    }
    if (Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id > max)
      max = Hyprland.focusedWorkspace.id
    return max
  }

  onCurrentIdxChanged: {
    moveAnim.stop()
    bounceAnim.stop()
    slider.scale = 0.5
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
      model: wsRoot.visibleCount
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
          color: focused ? Colors.barActive : Qt.rgba(Colors.text3.r, Colors.text3.g, Colors.text3.b, 0.3)
          Behavior on width  { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
          Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
          Behavior on color  { ColorAnimation  { duration: 200 } }
          Text {
            anchors.centerIn: parent
            visible: occupied
            text: wsRoot.wsIcons[wsId] || ""
            color: Colors.text3
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

  Rectangle {
    id: slider
    z: 10
    width: 26
    height: 26
    radius: 13
    color: Colors.barActive
    y: (parent.height - height) / 2
    x: posForIdx(currentIdx)
    scale: 1
    transformOrigin: Item.Center
  }

  NumberAnimation {
    id: moveAnim
    target: slider
    property: "x"
    duration: 570
    easing.type: Easing.BezierSpline
    easing.bezierCurve: [0.23, 1, 0.61, 1, 1, 1]
    onFinished: bounceAnim.start()
  }

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

  Text {
    id: sliderIcon
    z: 11
    anchors.centerIn: slider
    text: wsRoot.wsIcons[currentIdx + 1] || ""
    color: Colors.bg0
    font { pixelSize: 13; family: "JetBrainsMono Nerd Font" }
    visible: !moveAnim.running
  }

  Component.onCompleted: slider.x = posForIdx(currentIdx)

  Process {
    id: iconProc
    command: ["/run/current-system/sw/bin/node", Paths.scripts + "/ws-icons.js"]
    stdout: SplitParser {
      onRead: data => {
        const line = data.trim()
        if (line === "") return
        try {
          wsRoot.wsIcons = JSON.parse(line)
        } catch (error) {
          console.log("workspace icon parse error:", error.message)
        }
      }
    }
  }

  Timer {
    interval: 1000; running: true; repeat: true; triggeredOnStart: true
    onTriggered: iconProc.running = true
  }
}
