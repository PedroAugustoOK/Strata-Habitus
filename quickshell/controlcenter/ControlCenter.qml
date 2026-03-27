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
  focusable: true
  visible: false

  function toggle() {
    visible = !visible
    if (visible) { refreshAll(); keyGrabber.forceActiveFocus() }
  }
  function close() { visible = false }
  function refreshAll() {
    volProc.running = true
    brightProc.running = true
    uptimeProc.running = true
    wifiNameProc.running = true
    wifiCheck.running = true
    btCheck.running = true
  }

  property bool keepAwake: false
  property int  powerMode: 0
  property bool wifiActive: true
  property bool btActive: false
  property bool dndActive: false
  property int  volValue: 0
  property int  brightValue: 100
  property string wifiName: "—"
  property string uptimeStr: "—"
  property bool showBrightPct: false
  property bool showVolPct: false

  Item {
    id: keyGrabber
    focus: true
    Keys.onPressed: function(e) {
      if (e.key === Qt.Key_Escape) root.close()
    }
  }

  MouseArea {
    anchors.fill: parent
    onClicked: root.close()
  }

  Canvas {
    x: panel.x + panel.width - 12; y: 22; z: 10
    width: 12; height: 12
    onPaint: {
      var ctx = getContext("2d")
      ctx.clearRect(0, 0, 12, 12)
      ctx.fillStyle = "#1c1c1f"
      ctx.beginPath()
      ctx.moveTo(0, 12)
      ctx.lineTo(12, 12)
      ctx.lineTo(12, 0)
      ctx.arc(0, 12, 12, -Math.PI/2, 0, false)
      ctx.closePath()
      ctx.fill()
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
        strokeWidth: 0
        fillColor: "#1c1c1f"
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
          text: "Up " + root.uptimeStr
          color: "#888"
          font { pixelSize: 12; family: "JetBrainsMono Nerd Font" }
        }
        Item { Layout.fillWidth: true }
        Row {
          spacing: 2
          HdrBtn { icon: "󰏖" }
          HdrBtn { icon: "󰜉"; onClicked: rebootProc.running = true }
          HdrBtn { icon: "󰒓" }
          HdrBtn { icon: "⏻"; danger: true; onClicked: { root.close(); poweroffProc.running = true } }
        }
      }

      Column {
        width: parent.width
        spacing: 8

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
              width: 5
              height: parent.height + 2
              radius: 3
              color: Colors.accent
              border.color: "#1c1c1f"
              border.width: 2
            }
          }

          RowLayout {
            anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
            Text { text: "󰃠"; color: Colors.accent; font { pixelSize: 16; family: "JetBrainsMono Nerd Font" } }
            Item { Layout.fillWidth: true }
            Text {
              text: root.brightValue + "%"; color: "#ffffff80"
              font { pixelSize: 11; family: "JetBrainsMono Nerd Font" }
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
              width: 5
              height: parent.height + 2
              radius: 3
              color: Colors.accent
              border.color: "#1c1c1f"
              border.width: 2
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
              font { pixelSize: 11; family: "JetBrainsMono Nerd Font" }
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
        width: parent.width
        spacing: 8

        Row {
          width: parent.width
          spacing: 8

          BigTile {
            width: (parent.width - 16) / 2
            icon: root.wifiActive ? "󰤨" : "󰤭"
            title: root.wifiActive ? (root.wifiName !== "—" ? root.wifiName : "WiFi") : "WiFi"
            subtitle: root.wifiActive ? "Conectado" : "Desativado"
            active: root.wifiActive
            onClicked: {
              root.wifiActive = !root.wifiActive
              wifiToggleProc.command = ["sh", "-c",
                "/run/current-system/sw/bin/nmcli radio wifi " + (root.wifiActive ? "on" : "off")]
              wifiToggleProc.running = true
            }
          }

          IconTile {
            width: (parent.width - 16) / 4
            icon: "󰛊"
            active: root.keepAwake
            onClicked: {
              root.keepAwake = !root.keepAwake
              keepAwakeProc.command = root.keepAwake
                ? ["sh", "-c", "/run/current-system/sw/bin/systemctl --user mask sleep.target 2>/dev/null || true"]
                : ["sh", "-c", "/run/current-system/sw/bin/systemctl --user unmask sleep.target 2>/dev/null || true"]
              keepAwakeProc.running = true
            }
          }

          IconTile {
            width: (parent.width - 16) / 4
            icon: "󰓃"
            active: false
            onClicked: audioSinkProc.running = true
          }
        }

        Row {
          width: parent.width
          spacing: 8

          BigTile {
            width: (parent.width - 16) / 2
            icon: root.btActive ? "󰂱" : "󰂯"
            title: "Bluetooth"
            subtitle: root.btActive ? "Ativado" : "Desativado"
            active: root.btActive
            onClicked: {
              root.btActive = !root.btActive
              btToggleProc.command = ["sh", "-c",
                "/run/current-system/sw/bin/bluetoothctl power " + (root.btActive ? "on" : "off")]
              btToggleProc.running = true
            }
          }

          IconTile {
            width: (parent.width - 16) / 4
            icon: root.dndActive ? "󰂛" : "󰂚"
            active: root.dndActive
            onClicked: {
              root.dndActive = !root.dndActive
              NotificationService.dnd = root.dndActive
            }
          }

          PowerModeTile {
            width: (parent.width - 16) / 4
          }
        }
      }

      Rectangle { width: parent.width; height: 1; color: "#ffffff08" }

      RowLayout {
        width: parent.width
        Text {
          text: "Notificações"; color: "#888"
          font { pixelSize: 11; family: "JetBrainsMono Nerd Font" }
          Layout.fillWidth: true
        }
        Row {
          spacing: 6
          Chip {
            label: "Silenciar"; active: root.dndActive
            onClicked: { root.dndActive = !root.dndActive; NotificationService.dnd = root.dndActive }
          }
          Chip { label: "Limpar"; active: false; onClicked: NotificationService.dismissAll() }
        }
      }

      Column {
        width: parent.width; spacing: 6; bottomPadding: 4
        Text {
          visible: NotificationService.notifications.length === 0
          text: "Sem notificações"; color: "#333"
          font { pixelSize: 11; family: "JetBrainsMono Nerd Font" }
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
                  text: modelData.appName
                  color: Colors.accent
                  font { pixelSize: 9; family: "JetBrainsMono Nerd Font" }
                  Layout.fillWidth: true
                }
                Text {
                  text: "✕"; color: "#444"; font.pixelSize: 10
                  MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: modelData.dismiss() }
                }
              }
              Text {
                text: modelData.summary; color: "#ddd"
                font { pixelSize: 11; family: "JetBrainsMono Nerd Font"; weight: Font.DemiBold }
                width: parent.width; wrapMode: Text.WordWrap; maximumLineCount: 1; elide: Text.ElideRight
              }
              Text {
                visible: modelData.body !== ""; text: modelData.body; color: "#666"
                font { pixelSize: 10; family: "JetBrainsMono Nerd Font" }
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
  Process { id: keepAwakeProc;  command: [] }
  Process { id: rebootProc;     command: ["systemctl", "reboot"] }
  Process { id: poweroffProc;   command: ["systemctl", "poweroff"] }
  Process {
    id: audioSinkProc
    command: ["sh", "-c", "/run/current-system/sw/bin/pactl list short sinks | awk 'NR==2{print $1}' | xargs -I{} /run/current-system/sw/bin/pactl set-default-sink {}"]
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
    id: wifiNameProc
    command: ["sh", "-c", "/run/current-system/sw/bin/nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2 | head -1"]
    stdout: SplitParser { onRead: data => { if (data.trim() !== "") root.wifiName = data.trim() } }
  }
  Process {
    id: wifiCheck
    command: ["sh", "-c", "/run/current-system/sw/bin/nmcli radio wifi"]
    stdout: SplitParser { onRead: data => root.wifiActive = data.trim() === "enabled" }
  }
  Process {
    id: btCheck
    command: ["sh", "-c", "/run/current-system/sw/bin/bluetoothctl show | grep -q 'Powered: yes' && echo on || echo off"]
    stdout: SplitParser { onRead: data => root.btActive = data.trim() === "on" }
  }

  Timer { interval: 500; running: root.visible; repeat: true; onTriggered: { volProc.running = true; brightProc.running = true } }
  Timer {
    interval: 5000; running: root.visible; repeat: true; triggeredOnStart: true
    onTriggered: { uptimeProc.running = true; wifiCheck.running = true; wifiNameProc.running = true; btCheck.running = true }
  }

  component PowerModeTile: Rectangle {
    height: 76; radius: 20; color: "#252528"
    readonly property var modes: ["󰾅", "󰓅", "󰌪"]
    readonly property var cols:  ["#888888", "#ffb347", "#69c880"]
    Text {
      anchors.centerIn: parent
      text: modes[root.powerMode]
      color: cols[root.powerMode]
      font { pixelSize: 22; family: "JetBrainsMono Nerd Font" }
      Behavior on color { ColorAnimation { duration: 150 } }
    }
    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.powerMode = (root.powerMode + 1) % 3 }
  }

  component HdrBtn: Rectangle {
    property string icon; property bool danger: false
    signal clicked()
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
    property string title
    property string subtitle
    property bool active: false
    signal clicked()
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
          font { pixelSize: 20; family: "JetBrainsMono Nerd Font" }
          Behavior on color { ColorAnimation { duration: 150 } }
        }
      }
      Column {
        spacing: 2
        Layout.fillWidth: true
        Text {
          text: title; color: active ? "#eee" : "#888"
          font { pixelSize: 13; family: "JetBrainsMono Nerd Font"; weight: Font.DemiBold }
          Behavior on color { ColorAnimation { duration: 150 } }
        }
        Text {
          text: subtitle
          color: active ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.8) : "#555"
          font { pixelSize: 10; family: "JetBrainsMono Nerd Font" }
          Behavior on color { ColorAnimation { duration: 150 } }
        }
      }
    }
    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: parent.clicked() }
  }

  component IconTile: Rectangle {
    property string icon; property bool active: false
    signal clicked()
    height: 76; radius: 20
    color: active ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.18) : "#252528"
    Behavior on color { ColorAnimation { duration: 150 } }
    Text {
      anchors.centerIn: parent; text: icon
      color: active ? Colors.accent : "#666"
      font { pixelSize: 22; family: "JetBrainsMono Nerd Font" }
      Behavior on color { ColorAnimation { duration: 150 } }
    }
    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: parent.clicked() }
  }

  component Chip: Rectangle {
    property string label; property bool active: false
    signal clicked()
    width: ct.implicitWidth + 20; height: 26; radius: 13
    color: active ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.2) : "#252528"
    Behavior on color { ColorAnimation { duration: 150 } }
    Text { id: ct; anchors.centerIn: parent; text: label; color: active ? Colors.accent : "#555"; font { pixelSize: 10; family: "JetBrainsMono Nerd Font" } }
    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: parent.clicked() }
  }
}
