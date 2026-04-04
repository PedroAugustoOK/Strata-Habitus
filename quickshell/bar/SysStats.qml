import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import ".."

RowLayout {
  spacing: 8
  height: parent.height

  Text {
    id: cpuLabel
    text: "CPU 0%"
    color: Colors.text3
    font { pixelSize: 11; family: "Roboto" }
    verticalAlignment: Text.AlignVCenter
  }

  Text {
    text: "·"
    color: Colors.text3
    font { pixelSize: 11; family: "Roboto" }
    verticalAlignment: Text.AlignVCenter
  }

  Text {
    id: ramLabel
    text: "RAM 0%"
    color: Colors.text3
    font { pixelSize: 11; family: "Roboto" }
    verticalAlignment: Text.AlignVCenter
  }

  Process {
    id: cpuProc
    command: ["sh", "-c",
      "awk '/^cpu /{u=$2+$4; t=$2+$3+$4+$5; print int(u*100/t)}' /proc/stat"]
    stdout: SplitParser {
      onRead: data => {
        var v = parseInt(data.trim()) || 0
        cpuLabel.text  = "CPU " + v + "%"
        cpuLabel.color = v > 80 ? "#f28779" : v > 50 ? "#d9bc8c" : Colors.text3
      }
    }
  }

  Process {
    id: ramProc
    command: ["sh", "-c",
      "awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{print int((t-a)*100/t)}' /proc/meminfo"]
    stdout: SplitParser {
      onRead: data => {
        var v = parseInt(data.trim()) || 0
        ramLabel.text  = "RAM " + v + "%"
        ramLabel.color = v > 80 ? "#f28779" : v > 50 ? "#d9bc8c" : Colors.text3
      }
    }
  }

  Timer {
    interval: 2000; running: true; repeat: true; triggeredOnStart: true
    onTriggered: { cpuProc.running = true; ramProc.running = true }
  }
}
