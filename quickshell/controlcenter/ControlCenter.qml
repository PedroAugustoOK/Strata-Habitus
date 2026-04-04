import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import ".."

PanelWindow {
  id: root
  anchors { top: true; right: true }
  implicitWidth: 340
  implicitHeight: visible ? panel.implicitHeight + 34 : 0
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
  focusable: true
  visible: false

  function toggle() {
    visible = !visible
    if (visible) { refreshAll(); keyGrabber.forceActiveFocus() }
  }
  function close() { visible = false }
  function refreshAll() {
    volProc.running       = true
    brightProc.running    = true
    uptimeProc.running    = true
    wifiNameProc.running  = true
    wifiCheck.running     = true
    btCheck.running       = true
    powerModeProc.running = true
    ccBatProc.running    = true
  }

  property int    powerMode:     1
  property bool   wifiActive:    true
  property bool   btActive:      false
  property bool   btConnected:   false
  property int    volValue:      0
  property int    brightValue:   100
  property string wifiName:      "—"
  property string uptimeStr:     "—"
  property int    batValue:      100
  property bool   batCharging:   false
  property bool   showBrightPct: false
  property bool   showVolPct:    false

  Item {
    id: keyGrabber
    focus: true
    Keys.onPressed: function(e) {
      if (e.key === Qt.Key_Escape) root.close()
    }
  }

  MouseArea { anchors.fill: parent; onClicked: root.close() }

  Canvas {
    x: panel.x + panel.width - 12; y: 22; z: 10
    width: 12; height: 12
    onPaint: {
      var ctx = getContext("2d")
      ctx.clearRect(0, 0, 12, 12)
      ctx.fillStyle = "#111113"
      ctx.beginPath()
      ctx.moveTo(0, 12); ctx.lineTo(12, 12); ctx.lineTo(12, 0)
      ctx.arc(0, 12, 12, -Math.PI/2, 0, false)
      ctx.closePath(); ctx.fill()
    }
    Component.onCompleted: requestPaint()
  }

  Item {
    id: panel
    anchors { top: parent.top; right: parent.right; topMargin: 34 }
    width: 340
    implicitHeight: col.implicitHeight + 28

    Shape {
      anchors.fill: parent
      layer.enabled: true; layer.smooth: true
      preferredRendererType: Shape.CurveRenderer
      ShapePath {
        strokeWidth: 0; fillColor: "#111113"
        startX: 0; startY: 0
        PathLine { x: panel.width; y: 0 }
        PathLine { x: panel.width; y: panel.implicitHeight - 16 }
        PathArc  { x: panel.width - 16; y: panel.implicitHeight; radiusX: 16; radiusY: 16 }
        PathLine { x: 16; y: panel.implicitHeight }
        PathArc  { x: 0; y: panel.implicitHeight - 16; radiusX: 16; radiusY: 16 }
        PathLine { x: 0; y: 0 }
      }
    }

    MouseArea { anchors.fill: parent }

    Column {
      id: col
      anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
      spacing: 14

      RowLayout {
        width: parent.width
        Text {
          text: "Up " + root.uptimeStr; color: "#888"
          font { pixelSize: 12; family: "Roboto" }
        }
        Item { Layout.fillWidth: true }
        Row {
          spacing: 6
          Text {
            text: root.batCharging ? "⚡" : ""
            color: Colors.accent
            font { pixelSize: 11; family: "Roboto" }
            verticalAlignment: Text.AlignVCenter
          }
          Text {
            text: root.batValue + "%"
            color: root.batValue < 20 ? "#f28779" : root.batValue < 50 ? "#d9bc8c" : Colors.text2
            font { pixelSize: 12; family: "Roboto" }
            verticalAlignment: Text.AlignVCenter
          }
        }
      }

      Column {
        width: parent.width; spacing: 8

        // Brilho
        Rectangle {
          width: parent.width; height: 44; radius: 12; color: "#252528"; clip: true
          Rectangle {
            id: brightFill
            width: parent.width * (root.brightValue / 100)
            height: parent.height; radius: 12
            color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.22)
            Behavior on width { NumberAnimation { duration: 80 } }
            Rectangle {
              anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: -1 }
              width: 5; height: parent.height + 2; radius: 3
              color: Colors.accent; border.color: "#111113"; border.width: 2
            }
          }
          RowLayout {
            anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
            Text { text: "󰃠"; color: Colors.accent; font { pixelSize: 16; family: "JetBrainsMono Nerd Font" } }
            Item { Layout.fillWidth: true }
            Text {
              text: root.brightValue + "%"; color: "#ffffff80"
              font { pixelSize: 11; family: "Roboto" }
              opacity: root.showBrightPct ? 1 : 0
              Behavior on opacity { NumberAnimation { duration: 200 } }
            }
          }
          Timer { id: brightHideTimer; interval: 1200; onTriggered: root.showBrightPct = false }
          MouseArea {
            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
            onClicked: function(m) {
              var v = Math.round(Math.max(0, Math.min(100, (m.x / width) * 100)))
              root.brightValue = v; root.showBrightPct = true; brightHideTimer.restart()
              brightSetProc.command = ["/run/current-system/sw/bin/brightnessctl", "set", v + "%"]
              brightSetProc.running = true
            }
            onPositionChanged: function(m) {
              if (pressed) {
                var v = Math.round(Math.max(0, Math.min(100, (m.x / width) * 100)))
                root.brightValue = v; root.showBrightPct = true; brightHideTimer.restart()
                brightSetProc.command = ["/run/current-system/sw/bin/brightnessctl", "set", v + "%"]
                brightSetProc.running = true
              }
            }
          }
        }

        // Volume
        Rectangle {
          width: parent.width; height: 44; radius: 12; color: "#252528"; clip: true
          Rectangle {
            id: volFill
            width: parent.width * (root.volValue / 100)
            height: parent.height; radius: 12
            color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.22)
            Behavior on width { NumberAnimation { duration: 80 } }
            Rectangle {
              anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: -1 }
              width: 5; height: parent.height + 2; radius: 3
              color: Colors.accent; border.color: "#111113"; border.width: 2
            }
          }
          RowLayout {
            anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
            Text {
              text: root.volValue === 0 ? "󰝟" : root.volValue < 40 ? "󰕿" : root.volValue < 70 ? "󰖀" : "󰕾"
              color: Colors.accent; font { pixelSize: 16; family: "JetBrainsMono Nerd Font" }
            }
            Item { Layout.fillWidth: true }
            Text {
              text: root.volValue + "%"; color: "#ffffff80"
              font { pixelSize: 11; family: "Roboto" }
              opacity: root.showVolPct ? 1 : 0
              Behavior on opacity { NumberAnimation { duration: 200 } }
            }
          }
          Timer { id: volHideTimer; interval: 1200; onTriggered: root.showVolPct = false }
          MouseArea {
            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
            onClicked: function(m) {
              var v = Math.round(Math.max(0, Math.min(100, (m.x / width) * 100)))
              root.volValue = v; root.showVolPct = true; volHideTimer.restart()
              volSetProc.command = ["/run/current-system/sw/bin/wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (v/100).toFixed(2)]
              volSetProc.running = true
            }
            onPositionChanged: function(m) {
              if (pressed) {
                var v = Math.round(Math.max(0, Math.min(100, (m.x / width) * 100)))
                root.volValue = v; root.showVolPct = true; volHideTimer.restart()
                volSetProc.command = ["/run/current-system/sw/bin/wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (v/100).toFixed(2)]
                volSetProc.running = true
              }
            }
          }
        }
      }

      Column {
        width: parent.width; spacing: 8

        Row {
          width: parent.width; spacing: 8

          BigTile {
            width: (parent.width - 16) / 2
            icon:     root.wifiActive ? "" : ""
            iconFont: "Material Symbols Rounded"
            title:    root.wifiActive ? (root.wifiName !== "—" ? root.wifiName : "WiFi") : "WiFi"
            subtitle: root.wifiActive ? "Conectado" : "Desativado"
            active:   root.wifiActive
            onClicked: {
              root.wifiActive = !root.wifiActive
              wifiToggleProc.command = ["sh", "-c",
                "/run/current-system/sw/bin/nmcli radio wifi " + (root.wifiActive ? "on" : "off")]
              wifiToggleProc.running = true
            }
            onSettingsClicked: { root.close(); wifiAppProc.running = true }
          }

          // Caffeine — xícara cheia = ativo, vazia = inativo
          IconTile {
            width: (parent.width - 16) / 4
            icon:     SystemState.caffeine ? "󰅶" : "󰄰"
            iconFont: "JetBrainsMono Nerd Font"
            active:   SystemState.caffeine
            onClicked: {
              SystemState.caffeine = !SystemState.caffeine
              caffeineProc.command = SystemState.caffeine
                ? ["sh", "-c", "pkill -STOP hypridle"]
                : ["sh", "-c", "pkill -CONT hypridle"]
              caffeineProc.running = true
            }
          }

          // Audio — abre pavucontrol
          IconTile {
            width: (parent.width - 16) / 4
            icon:     "󰓃"
            iconFont: "JetBrainsMono Nerd Font"
            active:   false
            onClicked: {
              root.close()
              audioProc.running = true
            }
          }
        }

        Row {
          width: parent.width; spacing: 8

          BigTile {
            width: (parent.width - 16) / 2
            icon:     root.btConnected ? "󰂱" : root.btActive ? "󰂯" : "󰂯"
            iconFont: "JetBrainsMono Nerd Font"
            title:    "Bluetooth"
            subtitle: root.btActive ? "Ativado" : "Desativado"
            active:   root.btActive
            onClicked: {
              root.btActive = !root.btActive
              btToggleProc.command = ["sh", "-c",
                "/run/current-system/sw/bin/bluetoothctl power " + (root.btActive ? "on" : "off")]
              btToggleProc.running = true
            }
            onSettingsClicked: { root.close(); btAppProc.running = true }
          }

          IconTile {
            width: (parent.width - 16) / 4
            icon:     SystemState.dnd ? "󰂛" : "󰂚"
            iconFont: "JetBrainsMono Nerd Font"
            active:   SystemState.dnd
            onClicked: {
              SystemState.dnd = !SystemState.dnd
              NotificationService.dnd = SystemState.dnd
            }
          }

          PowerModeTile { width: (parent.width - 16) / 4 }
        }
      }

      Rectangle { width: parent.width; height: 1; color: "#ffffff08" }

      RowLayout {
        width: parent.width
        Text {
          text: "Notificações"; color: "#888"
          font { pixelSize: 11; family: "Roboto" }
          Layout.fillWidth: true
        }
        Row {
          spacing: 6
          Chip {
            label: "Silenciar"; active: SystemState.dnd
            onClicked: { SystemState.dnd = !SystemState.dnd; NotificationService.dnd = SystemState.dnd }
          }
          Chip { label: "Limpar"; active: false; onClicked: NotificationService.dismissAll() }
        }
      }

      Column {
        width: parent.width; spacing: 6; bottomPadding: 4
        Text {
          visible: NotificationService.notifications.length === 0
          text: "Sem notificações"; color: "#333"
          font { pixelSize: 11; family: "Roboto" }
          anchors.horizontalCenter: parent.horizontalCenter
        }
        Repeater {
          model: NotificationService.notifications
          delegate: Rectangle {
            required property Notification modelData
            width: parent.width; height: nc.implicitHeight + 16; radius: 10; color: "#252528"
            Column {
              id: nc
              anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
              spacing: 2
              RowLayout {
                width: parent.width
                Text {
                  text: modelData.appName; color: Colors.accent
                  font { pixelSize: 9; family: "Roboto" }
                  Layout.fillWidth: true
                }
                Text {
                  text: "✕"; color: "#444"; font.pixelSize: 10
                  MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: modelData.dismiss() }
                }
              }
              Text {
                text: modelData.summary; color: "#ddd"
                font { pixelSize: 11; family: "Roboto"; weight: Font.DemiBold }
                width: parent.width; wrapMode: Text.WordWrap; maximumLineCount: 1; elide: Text.ElideRight
              }
              Text {
                visible: modelData.body !== ""; text: modelData.body; color: "#666"
                font { pixelSize: 10; family: "Roboto" }
                width: parent.width; wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight
              }
            }
          }
        }
      }
    }
  }

  Process { id: wifiToggleProc; command: [] }
  Process { id: btToggleProc;   command: [] }
  Process { id: volSetProc;     command: [] }
  Process { id: brightSetProc;  command: [] }
  Process { id: caffeineProc;   command: [] }
  Process { id: rebootProc;     command: ["systemctl", "reboot"] }
  Process { id: poweroffProc;   command: ["systemctl", "poweroff"] }
  Process {
    id: audioProc
    command: ["sh", "-c", "/run/current-system/sw/bin/pwvucontrol &"]
  }
  Process {
    id: wifiAppProc
    command: ["sh", "-c", "kitty --title impala /run/current-system/sw/bin/impala &"]
  }
  Process {
    id: btAppProc
    command: ["sh", "-c", "kitty --title bluetui /run/current-system/sw/bin/bluetui &"]
  }
  Process {
    id: volProc
    command: ["sh", "-c", "/run/current-system/sw/bin/wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{printf \"%d\", $2*100}'"]
    stdout: SplitParser { onRead: data => root.volValue = parseInt(data.trim()) || 0 }
  }
  Process {
    id: brightProc
    command: ["sh", "-c", "/run/current-system/sw/bin/brightnessctl -m | awk -F, '{print int($4)}'"]
    stdout: SplitParser { onRead: data => root.brightValue = parseInt(data.trim()) || 100 }
  }
  Process {
    id: uptimeProc
    command: ["sh", "-c", "awk '{d=int($1/86400);h=int($1%86400/3600);m=int($1%3600/60); if(d>0) printf \"%dd %dh\",d,h; else if(h>0) printf \"%dh %dm\",h,m; else printf \"%dm\",m}' /proc/uptime"]
    stdout: SplitParser { onRead: data => root.uptimeStr = data.trim() }
  }
  Process {
    id: ccBatProc
    command: ["sh", "-c", "paste /sys/class/power_supply/BAT1/capacity /sys/class/power_supply/BAT1/status 2>/dev/null || echo '100	Discharging'"]
    stdout: SplitParser {
      onRead: data => {
        var p = data.trim().split("\t")
        root.batValue    = parseInt(p[0]) || 100
        root.batCharging = (p[1] || "").trim() === "Charging"
      }
    }
  }
  Process {
    id: wifiNameProc
    command: ["sh", "-c", "/run/current-system/sw/bin/nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | head -1 | cut -d: -f2"]
    stdout: SplitParser { onRead: data => { if (data.trim() !== "") root.wifiName = data.trim() } }
  }
  Process {
    id: wifiCheck
    command: ["sh", "-c", "/run/current-system/sw/bin/nmcli radio wifi"]
    stdout: SplitParser { onRead: data => root.wifiActive = data.trim() === "enabled" }
  }
  Process {
    id: btCheck
    command: ["sh", "-c", "POWERED=$(/run/current-system/sw/bin/bluetoothctl show 2>/dev/null | grep 'Powered:' | awk '{print $2}'); if [ \"$POWERED\" != \"yes\" ]; then echo off; exit; fi; CONN=$(/run/current-system/sw/bin/bluetoothctl devices Connected 2>/dev/null | wc -l); if [ \"$CONN\" -gt 0 ]; then echo connected; else echo on; fi"]
    stdout: SplitParser {
      onRead: data => {
        var s = data.trim()
        root.btActive    = s !== "off"
        root.btConnected = s === "connected"
      }
    }
  }
  Process {
    id: powerModeProc
    command: ["sh", "-c", "/run/current-system/sw/bin/powerprofilesctl get 2>/dev/null || echo balanced"]
    stdout: SplitParser {
      onRead: data => {
        var p = data.trim()
        if      (p === "power-saver")  root.powerMode = 0
        else if (p === "balanced")     root.powerMode = 1
        else if (p === "performance")  root.powerMode = 2
      }
    }
  }
  Process { id: powerSetProc; command: [] }

  Timer { interval: 500; running: root.visible; repeat: true; onTriggered: { volProc.running = true; brightProc.running = true } }
  Timer {
    interval: 5000; running: root.visible; repeat: true; triggeredOnStart: true
    onTriggered: { uptimeProc.running = true; wifiCheck.running = true; wifiNameProc.running = true; btCheck.running = true; ccBatProc.running = true }
  }

  component PowerModeTile: Rectangle {
    height: 76; radius: 20; color: "#252528"
    readonly property var modes:    ["󰾅", "󰓅", "󰌪"]
    readonly property var labels:   ["Economia", "Balanceado", "Performance"]
    readonly property var cols:     ["#69c880", Colors.accent, "#ffb347"]

    Column {
      anchors.centerIn: parent
      spacing: 4
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text:  modes[root.powerMode]
        color: cols[root.powerMode]
        font { pixelSize: 22; family: "JetBrainsMono Nerd Font" }
        Behavior on color { ColorAnimation { duration: 150 } }
      }
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text:  labels[root.powerMode]
        color: cols[root.powerMode]
        font { pixelSize: 9; family: "Roboto" }
        Behavior on color { ColorAnimation { duration: 150 } }
      }
    }

    MouseArea {
      anchors.fill: parent; cursorShape: Qt.PointingHandCursor
      onClicked: {
        root.powerMode = (root.powerMode + 1) % 3
        powerSetProc.command = ["/run/current-system/sw/bin/powerprofilesctl",
          "set", ["power-saver", "balanced", "performance"][root.powerMode]]
        powerSetProc.running = true
      }
    }
  }

  component HdrBtn: Rectangle {
    property string icon; property bool danger: false
    signal clicked()
    signal settingsClicked()
    width: 30; height: 30; radius: 8
    color: ma.containsMouse ? (danger ? "#ff6b6b22" : "#ffffff0f") : "transparent"
    Behavior on color { ColorAnimation { duration: 100 } }
    Text {
      anchors.centerIn: parent; text: icon
      color: danger ? (ma.containsMouse ? "#ff6b6b" : "#555") : (ma.containsMouse ? "#ccc" : "#555")
      font { pixelSize: 14; family: "JetBrainsMono Nerd Font" }
      Behavior on color { ColorAnimation { duration: 100 } }
    }
    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.clicked() }
  }

  component BigTile: Rectangle {
    property string icon
    property string iconFont: "JetBrainsMono Nerd Font"
    property string title
    property string subtitle
    property bool   active: false
    signal clicked()
    signal settingsClicked()
    height: 76; radius: 20
    color: active ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.18) : "#252528"
    Behavior on color { ColorAnimation { duration: 150 } }
    RowLayout {
      anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
      spacing: 14
      Rectangle {
        width: 42; height: 42; radius: 21
        color: active ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.25) : "#1a1a1d"
        Behavior on color { ColorAnimation { duration: 150 } }
        Text {
          anchors.centerIn: parent; text: icon
          color: active ? Colors.accent : "#666"
          font { pixelSize: 20; family: iconFont }
          Behavior on color { ColorAnimation { duration: 150 } }
        }
      }
      Column {
        spacing: 2; Layout.fillWidth: true
        Item {
          width: parent.width; height: 18; clip: true
          Text {
            id: titleTxt
            text: title; color: active ? "#eee" : "#888"
            font { pixelSize: 13; family: "Roboto"; weight: Font.DemiBold }
            Behavior on color { ColorAnimation { duration: 150 } }
            SequentialAnimation on x {
              running: titleTxt.implicitWidth > parent.width
              loops: Animation.Infinite
              NumberAnimation { to: 0; duration: 0 }
              PauseAnimation { duration: 1500 }
              NumberAnimation { to: -(titleTxt.implicitWidth - parent.width + 8); duration: 2000; easing.type: Easing.InOutQuad }
              PauseAnimation { duration: 1500 }
              NumberAnimation { to: 0; duration: 500; easing.type: Easing.InOutQuad }
            }
          }
        }
        Text {
          text: subtitle
          color: active ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.8) : "#555"
          font { pixelSize: 10; family: "Roboto" }
          Behavior on color { ColorAnimation { duration: 150 } }
        }
      }
    }
    Rectangle {
      id: sBtn
      z: 10
      anchors { top: parent.top; right: parent.right; topMargin: 6; rightMargin: 6 }
      width: 22; height: 22; radius: 11
      color: sMa.containsMouse ? "#ffffff18" : "transparent"
      Behavior on color { ColorAnimation { duration: 100 } }
      Text {
        anchors.centerIn: parent; text: "󰏖"
        font { pixelSize: 11; family: "JetBrainsMono Nerd Font" }
        color: sMa.containsMouse ? "#ccc" : "#444"
      }
      MouseArea {
        id: sMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
        onClicked: function(m) { m.accepted = true; parent.parent.settingsClicked() }
      }
    }
    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: function(m) { if (!sBtn.contains(Qt.point(m.x - sBtn.x, m.y - sBtn.y))) parent.clicked() } }
  }

  component IconTile: Rectangle {
    property string icon
    property string iconFont: "JetBrainsMono Nerd Font"
    property bool   active: false
    signal clicked()
    signal settingsClicked()
    height: 76; radius: 20
    color: active ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.18) : "#252528"
    Behavior on color { ColorAnimation { duration: 150 } }
    Text {
      anchors.centerIn: parent; text: icon
      color: active ? Colors.accent : "#666"
      font { pixelSize: 22; family: iconFont }
      Behavior on color { ColorAnimation { duration: 150 } }
    }
    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: parent.clicked() }
  }

  component Chip: Rectangle {
    property string label; property bool active: false
    signal clicked()
    signal settingsClicked()
    width: ct.implicitWidth + 20; height: 26; radius: 13
    color: active ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.2) : "#252528"
    Behavior on color { ColorAnimation { duration: 150 } }
    Text { id: ct; anchors.centerIn: parent; text: label; color: active ? Colors.accent : "#555"; font { pixelSize: 10; family: "Roboto" } }
    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: parent.clicked() }
  }
}
