import Quickshell.Io
import QtQuick
import QtQuick.Layouts

RowLayout {
  spacing: 12

  // ── Bluetooth ──────────────────────────────────────────────
  Text {
    id: btLabel
    color: "#666"
    font.pixelSize: 11
    font.family: "JetBrainsMono Nerd Font"
    text: "󰂯"
    visible: false
  }

  // ── Rede ───────────────────────────────────────────────────
  Text {
    id: netLabel
    color: "#666"
    font.pixelSize: 11
    font.family: "JetBrainsMono Nerd Font"
    text: "󰤭"
  }

  // ── Volume ─────────────────────────────────────────────────
  Text {
    id: volLabel
    color: "#666"
    font.pixelSize: 11
    font.family: "JetBrainsMono Nerd Font"
    text: "󰕾 –"
  }

  // ── Bateria ────────────────────────────────────────────────
  Text {
    id: batLabel
    color: "#666"
    font.pixelSize: 11
    font.family: "JetBrainsMono Nerd Font"
    text: "󰁹 –"
  }

  // ── Processos ──────────────────────────────────────────────
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
    command: ["sh", "-c", "/run/current-system/sw/bin/nmcli -t -f active,signal,ssid dev wifi 2>/dev/null | grep '^yes' | awk -F: '{s=$2; i=(s>75?\"󰤨\":s>50?\"󰤥\":s>25?\"󰤢\":\"󰤟\"); print i\" \"$3}'"]
    stdout: SplitParser {
      onRead: data => netLabel.text = data.trim() === "" ? "󰤭" : data.trim()
    }
  }

  Process {
    id: btProc
    command: ["sh", "-c", "/run/current-system/sw/bin/bluetoothctl show | grep -q 'Powered: yes' && echo 'on' || echo 'off'"]
    stdout: SplitParser {
      onRead: data => {
        const on = data.trim() === "on"
        btLabel.visible = on
        btLabel.text = "󰂯"
      }
    }
  }

  Process {
    id: btConnProc
    command: ["sh", "-c", "/run/current-system/sw/bin/bluetoothctl info 2>/dev/null | grep -q 'Connected: yes' && echo 'connected' || echo 'off'"]
    stdout: SplitParser {
      onRead: data => {
        if (data.trim() === "connected") btLabel.text = "󰂱"
      }
    }
  }

  // ── Timers ─────────────────────────────────────────────────
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
    onTriggered: {
      netProc.running = true
      btProc.running = true
      btConnProc.running = true
    }
  }
}
