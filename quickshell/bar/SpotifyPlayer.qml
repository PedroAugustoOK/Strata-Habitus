import Quickshell.Io
import QtQuick
import ".."

Item {
  id: root
  property string title:    ""
  property bool   playing:  false
  property bool   hasTrack: title !== ""

  height: 24
  width:  hasTrack ? pill.implicitWidth : 0
  opacity: hasTrack ? 1 : 0
  visible: width > 1

  Behavior on width   { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }
  Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }

  Rectangle {
    id: pill
    anchors.fill: parent
    radius: 12
    color:  Colors.bg2
    implicitWidth: innerRow.implicitWidth + 24
    clip: false

    Row {
      id: innerRow
      anchors.centerIn: parent
      spacing: 6

      Text {
        text:  "\uF1BC"
        font { family: "JetBrainsMono Nerd Font"; pixelSize: 12 }
        color: playing ? "#1db954" : Colors.text3
        anchors.verticalCenter: parent.verticalCenter
        Behavior on color { ColorAnimation { duration: 200 } }
      }

      Text {
        text:  root.title
        font { family: "Roboto"; pixelSize: 11 }
        color: Colors.text2
        anchors.verticalCenter: parent.verticalCenter
      }
    }

    // Fade esquerda
    Rectangle {
      z: 2
      anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
      width: 22
      radius: 12
      gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0.0; color: Colors.bg2 }
        GradientStop { position: 1.0; color: "transparent" }
      }
    }

    // Fade direita
    Rectangle {
      z: 2
      anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
      width: 22
      radius: 12
      gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0.0; color: "transparent" }
        GradientStop { position: 1.0; color: Colors.bg2 }
      }
    }

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
      onClicked: function(m) {
        if      (m.button === Qt.LeftButton)   nextProc.running  = true
        else if (m.button === Qt.RightButton)  pauseProc.running = true
        else if (m.button === Qt.MiddleButton) focusProc.running = true
      }
      onWheel: function(w) {
        if (w.angleDelta.y > 0) volUpProc.running  = true
        else                    volDownProc.running = true
      }
    }
  }

  Process {
    id: trackProc
    command: ["sh", "-c",
      "playerctl -p spotify metadata --format '{{status}}|{{title}}' 2>/dev/null || echo ''"]
    stdout: SplitParser {
      onRead: data => {
        var t = data.trim()
        if (t === "" || t.indexOf("|") === -1) {
          root.title = ""; root.playing = false; return
        }
        var parts    = t.split("|")
        root.playing = parts[0] === "Playing"
        var song     = parts.slice(1).join("|")
        root.title   = song.length > 30 ? song.substring(0, 28) + "…" : song
      }
    }
  }

  Process { id: nextProc;    command: ["playerctl", "-p", "spotify", "next"] }
  Process { id: pauseProc;   command: ["playerctl", "-p", "spotify", "play-pause"] }
  Process { id: focusProc;   command: ["sh", "-c", "hyprctl dispatch focuswindow spotify"] }
  Process { id: volUpProc;   command: ["playerctl", "-p", "spotify", "volume", "0.05+"] }
  Process { id: volDownProc; command: ["playerctl", "-p", "spotify", "volume", "0.05-"] }

  Timer {
    interval: 2000; running: true; repeat: true; triggeredOnStart: true
    onTriggered: trackProc.running = true
  }
}
