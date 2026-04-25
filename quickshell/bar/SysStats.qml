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
    command: ["bash", "-c", "read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat; prev_idle=$((idle + iowait)); prev_nonidle=$((user + nice + system + irq + softirq + steal)); prev_total=$((prev_idle + prev_nonidle)); sleep 0.35; read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat; idle_now=$((idle + iowait)); nonidle_now=$((user + nice + system + irq + softirq + steal)); total_now=$((idle_now + nonidle_now)); total_delta=$((total_now - prev_total)); idle_delta=$((idle_now - prev_idle)); if [ \"$total_delta\" -gt 0 ]; then printf \"%d\" $(((100 * (total_delta - idle_delta)) / total_delta)); else printf \"0\"; fi"]
    stdout: SplitParser {
      onRead: data => {
        if (data.trim() !== "") root.cpu = data.trim() + "%"
      }
    }
  }

  Timer {
    interval: 1000; running: true; repeat: true; triggeredOnStart: true
    onTriggered: {
      if (!statsProc.running) statsProc.running = true
      if (!cpuProc.running) cpuProc.running = true
    }
  }
}
