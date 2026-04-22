import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import ".."
Item {
  id: root
  implicitWidth:  row.implicitWidth
  implicitHeight: row.implicitHeight

  RowLayout {
    id: row
    anchors.fill: parent
    spacing: 8

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
  }

  MouseArea {
    anchors.fill: parent
    cursorShape:  Qt.PointingHandCursor
    onClicked:    ccToggle.running = true
  }

  Process { id: ccToggle; command: ["quickshell", "ipc", "call", "controlcenter", "toggle"] }

  Process {
    id: batProc
    command: ["bash", Paths.scripts + "/battery-status.sh"]
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
    command: ["bash", Paths.scripts + "/wifi-status.sh"]
    stdout: SplitParser {
      onRead: data => {
        var t = data.trim()
        if (t === "off") {
          wifiLabel.text  = "\uE648"
          wifiLabel.color = Colors.text3
          return
        }
        var sig = parseInt(t.split(":")[1]) || 50
        if (sig > 75) {
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
      "POWERED=$(bluetoothctl show 2>/dev/null | grep 'Powered:' | awk '{print $2}');" +
      "if [ \"$POWERED\" != 'yes' ]; then echo 'off'; exit; fi;" +
      "CONN=$(bluetoothctl devices Connected 2>/dev/null | wc -l);" +
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
    interval: 3000; running: true; repeat: true; triggeredOnStart: true
    onTriggered: {
      batProc.running = true
      netProc.running = true
      btProc.running  = true
    }
  }
}
