import Quickshell.Io
import QtQuick
import ".."

Row {
  id: root
  spacing: 5
  height: parent.height

  property string cpu: "0%"
  property string ram: "0%"

  Text {
    anchors.verticalCenter: parent.verticalCenter
    text: "󰍛"
    color: Colors.accent
    font { pixelSize: 13; family: "JetBrainsMono Nerd Font" }
  }

  Text {
    anchors.verticalCenter: parent.verticalCenter
    text: root.cpu
    color: Colors.accent
    font { pixelSize: 12; family: "Roboto"; weight: Font.Bold }
  }

  Rectangle {
    width: 1; height: 12
    color: Qt.rgba(1,1,1,0.08)
    anchors.verticalCenter: parent.verticalCenter
  }

  Text {
    anchors.verticalCenter: parent.verticalCenter
    text: "󰘚"
    color: Colors.accent
    font { pixelSize: 13; family: "JetBrainsMono Nerd Font" }
  }

  Text {
    anchors.verticalCenter: parent.verticalCenter
    text: root.ram
    color: Colors.accent
    font { pixelSize: 12; family: "Roboto"; weight: Font.Bold }
  }

  Process {
    id: statsProc
    command: ["sh", "-c", "awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{printf \"%d\", (t-a)/t*100}' /proc/meminfo"]
    stdout: SplitParser {
      onRead: data => {
        root.ram = data.trim() + "%"
      }
    }
  }

  Process {
    id: cpuProc
    command: ["sh", "-c", "grep -m1 'cpu ' /proc/stat | awk '{u=$2+$4; t=$2+$3+$4+$5; if(t>0) printf \"%d\", u*100/t}'"]
    stdout: SplitParser {
      onRead: data => {
        if (data.trim() !== "") root.cpu = data.trim() + "%"
      }
    }
  }

  Timer {
    interval: 2000; running: true; repeat: true; triggeredOnStart: true
    onTriggered: {
      statsProc.running = true
      cpuProc.running = true
    }
  }
}
