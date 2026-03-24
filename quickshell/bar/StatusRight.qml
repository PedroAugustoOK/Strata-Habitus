import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import ".."

RowLayout {
  spacing: 14

  // WiFi + BT clicáveis para abrir CC
  Text {
    id: btLabel
    color: Colors.accent
    font { pixelSize: 12; family: "JetBrainsMono Nerd Font" }
    text: "󰂯"
    visible: false

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: ccToggle.running = true
    }
  }

  Text {
    id: netLabel
    color: "#aaaaaa"
    font { pixelSize: 12; family: "JetBrainsMono Nerd Font" }
    text: "󱚽"

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: ccToggle.running = true
    }
  }

  Text {
    id: volLabel
    color: "#aaaaaa"
    font { pixelSize: 12; family: "JetBrainsMono Nerd Font" }
    text: "󰕾 –"
  }

  Text {
    id: batLabel
    color: "#aaaaaa"
    font { pixelSize: 12; family: "JetBrainsMono Nerd Font" }
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

  Process {
    id: netProc
    command: ["sh", "-c", "/run/current-system/sw/bin/nmcli -t -f active,signal,ssid dev wifi 2>/dev/null | grep '^yes' | awk -F: '{s=$2; i=(s>75?\"󱚽\":s>50?\"󱚿\":s>25?\"󱛀\":\"󱛁\"); print i\" \"$3}'"]
    stdout: SplitParser {
      onRead: data => netLabel.text = data.trim() === "" ? "󱚽" : data.trim()
    }
  }

  Process {
    id: btProc
    command: ["sh", "-c", "/run/current-system/sw/bin/bluetoothctl show | grep -q 'Powered: yes' && echo 'on' || echo 'off'"]
    stdout: SplitParser {
      onRead: data => btLabel.visible = data.trim() === "on"
    }
  }

  Process {
    id: btConnProc
    command: ["sh", "-c", "/run/current-system/sw/bin/bluetoothctl info 2>/dev/null | grep -q 'Connected: yes' && echo 'connected' || echo 'off'"]
    stdout: SplitParser {
      onRead: data => btLabel.text = data.trim() === "connected" ? "󰂱" : "󰂯"
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

  Timer {
    interval: 10000; running: true; repeat: true; triggeredOnStart: true
    onTriggered: { netProc.running = true; btProc.running = true; btConnProc.running = true }
  }

  Process {
    id: ccToggle
    command: ["quickshell", "ipc", "call", "controlcenter", "toggle"]
  }

}

