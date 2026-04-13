import Quickshell.Io
import QtQuick
import ".."

Item {
  id: root
  property string title:    ""
  property string artist:   ""
  property bool   playing:  false
  property bool   hasTrack: title !== ""

  height: 28
  width:  hasTrack ? pill.implicitWidth : 0
  opacity: hasTrack ? 1 : 0
  visible: width > 1

  Behavior on width   { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }
  Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }

  Rectangle {
    id: pill
    anchors.fill: parent
    radius: 14
    color:  Colors.bg2
    implicitWidth: innerRow.implicitWidth + 24

    Row {
      id: innerRow
      anchors.centerIn: parent
      spacing: 8

      Text {
        text:  "\uF1BC"
        font { family: "JetBrainsMono Nerd Font"; pixelSize: 12 }
        color: playing ? "#1db954" : Colors.text3
        anchors.verticalCenter: parent.verticalCenter
        Behavior on color { ColorAnimation { duration: 200 } }
      }

      Column {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1

        Text {
          text:  root.title
          font { family: "Roboto"; pixelSize: 10 }
          color: Colors.text1
        }

        Text {
          text:  root.artist
          font { family: "Roboto"; pixelSize: 8 }
          color: Colors.text3
          visible: root.artist !== ""
        }
      }
    }

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
      onClicked: function(m) {
        if      (m.button === Qt.LeftButton)   focusProc.running = true
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
      "playerctl -p spotify metadata --format '{{status}}|{{title}}|{{artist}}' 2>/dev/null || echo ''"]
    stdout: SplitParser {
      onRead: data => {
        var t = data.trim()
        if (t === "" || t.indexOf("|") === -1) {
          root.title = ""; root.artist = ""; root.playing = false; return
        }
        var parts    = t.split("|")
        root.playing = parts[0] === "Playing"
        var song     = parts[1] || ""
        root.title   = song.length > 28 ? song.substring(0, 26) + "…" : song
        var art      = parts[2] || ""
        root.artist  = art.length > 22 ? art.substring(0, 20) + "…" : art
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
