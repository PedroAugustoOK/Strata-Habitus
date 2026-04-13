import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import ".."

PanelWindow {
  id: osdWindow
  anchors { top: true; bottom: true; left: true }
  implicitWidth: 130
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  mask: Region { item: showing ? osdBox : null }

  property real   value:     100
  property bool   showing:   false
  property real   lastValue: -1

  Timer {
    id: hideTimer
    interval: 2000
    onTriggered: closeAnim.start()
  }

  function show(val) {
    if (val === lastValue) return
    lastValue = val
    value = val
    if (!showing) {
      showing = true
      osdBox.height = 46
      osdBox.opacity = 0
      openAnim.start()
    }
    hideTimer.restart()
  }

  SequentialAnimation {
    id: openAnim
    NumberAnimation { target: osdBox; property: "opacity"; to: 1; duration: 20 }
    NumberAnimation { target: osdBox; property: "height"; to: 190; duration: 260; easing.type: Easing.OutCubic }
    NumberAnimation { target: osdBox; property: "height"; to: 180; duration: 80; easing.type: Easing.InOutQuad }
  }

  SequentialAnimation {
    id: closeAnim
    NumberAnimation { target: osdBox; property: "height"; to: 46; duration: 160; easing.type: Easing.InCubic }
    NumberAnimation { target: osdBox; property: "opacity"; to: 0; duration: 60 }
    ScriptAction { script: osdWindow.showing = false }
  }

  Process {
    id: brightWatcher
    command: ["sh", "-c", "while true; do /run/current-system/sw/bin/brightnessctl -m | awk -F, '{print int($4)}'; sleep 0.1; done"]
    running: true
    stdout: SplitParser {
      onRead: data => {
        const val = parseInt(data.trim())
        if (!isNaN(val)) osdWindow.show(val)
      }
    }
  }

  Rectangle {
    id: osdBox
    width:  46
    height: 46
    anchors {
      left:                 parent.left
      verticalCenter:       parent.verticalCenter
      leftMargin:           20
      verticalCenterOffset: -110
    }
    radius:  16
    color:   Colors.bg1
    opacity: 0
    clip:    false

    Text {
      anchors {
        horizontalCenter: parent.horizontalCenter
        top:              parent.top
        topMargin:        14
      }
      text:  "󰃠"
      color: Colors.accent
      font { pixelSize: 15; family: "JetBrainsMono Nerd Font" }
    }

    Rectangle {
      width:  6
      height: 96
      radius: 3
      color:  Colors.bg2
      anchors {
        horizontalCenter:     parent.horizontalCenter
        verticalCenter:       parent.verticalCenter
        verticalCenterOffset: 4
      }
      Rectangle {
        anchors.bottom: parent.bottom
        width:  parent.width
        height: parent.height * (osdWindow.value / 100)
        radius: 3
        color:  Colors.accent
        Behavior on height { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
      }
    }

    Text {
      anchors {
        horizontalCenter: parent.horizontalCenter
        bottom:           parent.bottom
        bottomMargin:     12
      }
      text:  osdWindow.value + "%"
      color: Colors.text3
      font { pixelSize: 10; family: "JetBrainsMono Nerd Font" }
    }
  }
}
