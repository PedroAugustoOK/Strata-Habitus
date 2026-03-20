import Quickshell.Io
import QtQuick
import QtQuick.Layouts

RowLayout {
  spacing: 12

  Text {
    id: volLabel
    color: "#666"
    font.pixelSize: 11
    font.family: "JetBrainsMono Nerd Font"
    text: "󰕾 –"
  }

  Text {
    id: batLabel
    color: "#666"
    font.pixelSize: 11
    font.family: "JetBrainsMono Nerd Font"
    text: "󰁹 –"
  }

  Process {
    id: volProc
    command: ["sh", "-c", "/run/current-system/sw/bin/wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{printf \"%d\", $2*100}'"]
    stdout: SplitParser {
      onRead: data => volLabel.text = "󰕾 " + data.trim() + "%"
    }
  }

  Process {
    id: batProc
    command: ["sh", "-c", "cat /sys/class/power_supply/BAT1/capacity 2>/dev/null || echo '–'"]
    stdout: SplitParser {
      onRead: data => batLabel.text = "󰁹 " + data.trim() + "%"
    }
  }

  Timer {
    interval: 500; running: true; repeat: true; triggeredOnStart: true
    onTriggered: volProc.running = true
  }

  Timer {
    interval: 30000; running: true; repeat: true; triggeredOnStart: true
    onTriggered: batProc.running = true
  }
}
