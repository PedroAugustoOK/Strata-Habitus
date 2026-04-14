import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import ".."
RowLayout {
  enabled: false
  spacing: 8
  height:  parent.height
  Text {
    visible: SystemState.dnd
    text:    "󰂛"
    color:   Colors.accent
    font { family: "JetBrainsMono Nerd Font"; pixelSize: 13 }
    verticalAlignment: Text.AlignVCenter
  }
  Text {
    visible: SystemState.caffeine
    text:    "󰅶"
    color:   Colors.accent
    font { family: "JetBrainsMono Nerd Font"; pixelSize: 13 }
    verticalAlignment: Text.AlignVCenter
  }
  Text {
    id: btLabel
    color: Colors.text3
    font { family: "Material Symbols Rounded"; pixelSize: 14 }
    text:  "\uE1A9"
    verticalAlignment: Text.AlignVCenter
  }
  Text {
    id: wifiLabel
    color: Colors.text3
    font { family: "Material Symbols Rounded"; pixelSize: 14 }
    text:  "\uE648"
    verticalAlignment: Text.AlignVCenter
  }
  BatteryRing {
    id: batRing
    value:    100
    charging: false
  }
  Process {
    id: batProc
    command: ["sh", "-c",
      "paste /sys/class/power_supply/BAT1/capacity /sys/class/power_supply/BAT1/status 2>/dev/null || echo '100\tDischarging'"]
    stdout: SplitParser {
      onRead: data => {
        var parts = data.trim().split("\t")
        batRing.value    = parseInt(parts[0]) || 100
        batRing.charging = (parts[1] || "").trim() === "Charging"
      }
    }
  }
  Process {
    id: netProc
    command: ["sh", "-c",
      "RADIO=$(/run/current-system/sw/bin/nmcli radio wifi 2>/dev/null | tr -d ' \n');" +
      "if [ \"$RADIO\" != \"enabled\" ]; then echo 'off'; exit; fi;" +
      "SIG=$(/run/current-system/sw/bin/nmcli -t -f ACTIVE,SIGNAL dev wifi 2>/dev/null | head -1 | cut -d: -f2);" +
      "if [ -z \"$SIG\" ]; then echo 'on:0'; else echo \"on:$SIG\"; fi"
    ]
    stdout: SplitParser {
      onRead: data => {
        var t = data.trim()
        if (t === "off") {
          wifiLabel.text  = "\uE648"
          wifiLabel.color = Colors.text3
          return
        }
        var sig = parseInt(t.split(":")[1]) || 0
        if (sig === 0) {
          wifiLabel.text  = "\uE648"
          wifiLabel.color = Colors.text3
        } else if (sig > 75) {
          wifiLabel.text  = "\uE63E"
          wifiLabel.color = Colors.accent
        } else if (sig > 50) {
          wifiLabel.text  = "\uE4D9"
          wifiLabel.color = Colors.accent
        } else if (sig > 25) {
          wifiLabel.text  = "\uE4D9"
          wifiLabel.color = Colors.accent
        } else {
          wifiLabel.text  = "\uE4CA"
          wifiLabel.color = "#d9bc8c"
        }
      }
    }
  }
  Process {
    id: btProc
    command: ["sh", "-c",
      "POWERED=$(/run/current-system/sw/bin/bluetoothctl show 2>/dev/null | grep 'Powered:' | awk '{print $2}');" +
      "if [ \"$POWERED\" != \"yes\" ]; then echo 'off'; exit; fi;" +
      "CONN=$(/run/current-system/sw/bin/bluetoothctl devices Connected 2>/dev/null | wc -l);" +
      "if [ \"$CONN\" -gt 0 ]; then echo 'connected'; else echo 'on'; fi"
    ]
    stdout: SplitParser {
      onRead: data => {
        var s = data.trim()
        if (s === "off") {
          btLabel.text  = "\uE1A9"
          btLabel.color = Colors.text3
        } else if (s === "connected") {
          btLabel.text  = "\uE1A8"
          btLabel.color = Colors.accent
        } else {
          btLabel.text  = "\uE1A7"
          btLabel.color = Colors.accent
        }
      }
    }
  }
  Timer {
    interval: 500; running: true; repeat: true; triggeredOnStart: true
    onTriggered: {
      batProc.running = true
      netProc.running = true
      btProc.running  = true
    }
  }
}
