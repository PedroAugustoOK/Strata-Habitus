import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import ".."

PanelWindow {
  id: ccRoot
  anchors { top: true; left: true; right: true }
  implicitHeight: visible ? ccPanel.implicitHeight + 42 : 0
  color: "transparent"
  visible: false
  exclusionMode: ExclusionMode.Ignore
  focusable: true

  function toggle() {
    visible = !visible
    if (visible) {
      keyGrabber.forceActiveFocus()
      refreshAll()
    }
  }

  function close() { visible = false }

  function refreshAll() {
    volProc.running = true
    brightProc.running = true
    uptimeProc.running = true
    wifiCheck.running = true
    btCheck.running = true
  }

  MouseArea {
    anchors.fill: parent
    onClicked: ccRoot.close()
  }

  Item {
    id: keyGrabber
    focus: true
    Keys.onPressed: function(event) {
      if (event.key === Qt.Key_Escape) ccRoot.close()
    }
  }

  Item {
    id: ccPanel
    anchors { top: parent.top; right: parent.right; topMargin: 34; rightMargin: 10 }
    width: 310
    implicitHeight: ccCol.implicitHeight + 24

    MouseArea { anchors.fill: parent }

    // fundo com cantos inferiores arredondados
    Shape {
      anchors.fill: parent
      layer.enabled: true
      layer.smooth: true
      preferredRendererType: Shape.CurveRenderer
      ShapePath {
        strokeWidth: 0
        fillColor: Colors.bg1
        startX: 0
        startY: 0
        PathLine { x: ccPanel.width; y: 0 }
        PathLine { x: ccPanel.width; y: ccPanel.implicitHeight - 14 }
        PathArc { x: ccPanel.width - 14; y: ccPanel.implicitHeight; radiusX: 14; radiusY: 14 }
        PathLine { x: 14; y: ccPanel.implicitHeight }
        PathArc { x: 0; y: ccPanel.implicitHeight - 14; radiusX: 14; radiusY: 14 }
        PathLine { x: 0; y: 0 }
      }
    }

   // orelha top-left (bar → painel)
    Canvas {
      x: -4
      y: 0
      width: 12
      height: 12
      onPaint: {
        var ctx = getContext("2d")
        ctx.clearRect(0, 0, 12, 12)
        ctx.fillStyle = "#111113"
        ctx.beginPath()
        ctx.moveTo(12, 0)
        ctx.lineTo(12, 12)
        ctx.arc(12, 0, 12, Math.PI / 2, Math.PI, false)
        ctx.closePath()
        ctx.fill()
      }
      Component.onCompleted: requestPaint()
    }

    // orelha bottom-right (painel → borda direita)
    Canvas {
      x: ccPanel.width
      y: ccPanel.implicitHeight
      width: 12
      height: 12
      onPaint: {
        var ctx = getContext("2d")
        ctx.clearRect(0, 0, 12, 12)
        ctx.fillStyle = "#111113"
        ctx.beginPath()
        ctx.moveTo(0, 0)
        ctx.lineTo(0, 12)
        ctx.arc(0, 0, 12, Math.PI / 2, 0, true)
        ctx.closePath()
        ctx.fill()
      }
      Component.onCompleted: requestPaint()
    }

    Column {
      id: ccCol
      anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
      spacing: 10

      // ── Header ──
      RowLayout {
        width: parent.width
        spacing: 8

        Text {
          id: uptimeLabel
          color: Colors.text3
          font { pixelSize: 10; family: "JetBrainsMono Nerd Font" }
          text: "⏻ –"
          Layout.fillWidth: true
        }

        CcIconBtn { icon: "⏻"; danger: true; onClicked: powerMenu.visible = !powerMenu.visible }
      }

      // ── Toggles ──
      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 8

        ToggleBtn {
          icon: "󱚽"; label: "WiFi"; active: wifiActive
          onClicked: { wifiActive = !wifiActive; wifiToggle.running = true }
        }
        ToggleBtn {
          icon: "󰂯"; label: "Bluetooth"; active: btActive
          onClicked: { btActive = !btActive; btToggle.running = true }
        }
        ToggleBtn {
          icon: "󰍶"; label: "DND"; active: dndActive
          onClicked: dndActive = !dndActive
        }
        ToggleBtn {
          icon: "󰖔"; label: "Noite"; active: false
        }
      }

      // ── Brilho ──
      SliderBar {
        icon: "󰃠"
        value: brightValue
        onAdjust: function(v) {
          brightValue = v
          brightSetProc.command = ["brightnessctl", "set", v + "%"]
          brightSetProc.running = true
        }
      }

      // ── Volume ──
      SliderBar {
        icon: "󰕾"
        value: volValue
        onAdjust: function(v) {
          volValue = v
          volSetProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (v / 100).toFixed(2)]
          volSetProc.running = true
        }
      }

      // ── Separador ──
      Rectangle { width: parent.width; height: 1; color: "#222225" }

      // ── Notificações ──
      RowLayout {
        width: parent.width

        Text {
          text: "󰂚 Notificações"
          color: Colors.text2
          font { pixelSize: 11; family: "JetBrainsMono Nerd Font" }
          Layout.fillWidth: true
        }

        Text {
          text: "Limpar"
          color: Colors.text3
          font { pixelSize: 9; family: "JetBrainsMono Nerd Font" }
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              for (var i = notifServer.trackedNotifications.length - 1; i >= 0; i--)
                notifServer.trackedNotifications[i].dismiss()
            }
          }
        }
      }

      Column {
        width: parent.width
        spacing: 4

        Text {
          visible: notifServer.trackedNotifications.length === 0
          text: "Nenhuma notificação"
          color: Colors.text3
          font { pixelSize: 10; family: "JetBrainsMono Nerd Font" }
          anchors.horizontalCenter: parent.horizontalCenter
        }

        Repeater {
          model: notifServer.trackedNotifications
          delegate: Rectangle {
            required property Notification modelData
            width: parent.width
            height: nCol.implicitHeight + 14
            radius: 8
            color: Colors.bg2

            Column {
              id: nCol
              anchors {
                left: parent.left; right: parent.right
                top: parent.top; margins: 8
              }
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
                  text: "✕"
                  color: Colors.text3
                  font { pixelSize: 10 }
                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: modelData.dismiss()
                  }
                }
              }

              Text {
                text: modelData.summary
                color: Colors.text1
                font {
                  pixelSize: 10
                  family: "JetBrainsMono Nerd Font"
                  weight: Font.DemiBold
                }
                width: parent.width
                wrapMode: Text.WordWrap
                maximumLineCount: 1
                elide: Text.ElideRight
              }

              Text {
                visible: modelData.body !== ""
                text: modelData.body
                color: Colors.text3
                font { pixelSize: 9; family: "JetBrainsMono Nerd Font" }
                width: parent.width
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
              }
            }
          }
        }
      }

      // ── Power Menu ──
      Column {
        id: powerMenu
        visible: false
        width: parent.width
        spacing: 6

        Rectangle { width: parent.width; height: 1; color: "#222225" }

        Row {
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: 10

          PowerBtn { icon: "󰤄"; label: "Suspender"; onClicked: suspendProc.running = true }
          PowerBtn { icon: "󰜉"; label: "Reiniciar"; onClicked: rebootProc.running = true }
          PowerBtn { icon: "⏻"; label: "Desligar"; danger: true; onClicked: poweroffProc.running = true }
          PowerBtn { icon: "󰍃"; label: "Sair"; onClicked: logoutProc.running = true }
        }
      }
    }
  }

  // ── Estado ──
  property bool wifiActive: true
  property bool btActive: false
  property bool dndActive: false
  property int volValue: 0
  property int brightValue: 100

  NotificationServer {
    id: notifServer
    keepOnReload: true
    onNotification: notif => {
      if (!dndActive) notif.tracked = true
      else notif.dismiss()
    }
  }

  Process { id: wifiToggle; command: ["sh", "-c", "nmcli radio wifi " + (wifiActive ? "on" : "off")] }
  Process { id: btToggle; command: ["sh", "-c", "bluetoothctl power " + (btActive ? "on" : "off")] }
  Process { id: suspendProc; command: ["systemctl", "suspend"] }
  Process { id: rebootProc; command: ["systemctl", "reboot"] }
  Process { id: poweroffProc; command: ["systemctl", "poweroff"] }
  Process { id: logoutProc; command: ["sh", "-c", "hyprctl dispatch exit"] }
  Process { id: volSetProc; command: [] }
  Process { id: brightSetProc; command: [] }

  Process {
    id: volProc
    command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{printf \"%d\", $2*100}'"]
    stdout: SplitParser { onRead: data => volValue = parseInt(data.trim()) || 0 }
  }

  Process {
    id: brightProc
    command: ["sh", "-c", "brightnessctl -m | awk -F, '{print int($4)}'"]
    stdout: SplitParser { onRead: data => brightValue = parseInt(data.trim()) || 100 }
  }

  Process {
    id: uptimeProc
    command: ["sh", "-c", "awk '{d=int($1/86400);h=int($1%86400/3600);m=int($1%3600/60); if(d>0) printf \"%dd %dh\",d,h; else if(h>0) printf \"%dh %dm\",h,m; else printf \"%dm\",m}' /proc/uptime"]
    stdout: SplitParser { onRead: data => uptimeLabel.text = "⏻ " + data.trim() }
  }

  Process {
    id: wifiCheck
    command: ["sh", "-c", "nmcli radio wifi"]
    stdout: SplitParser { onRead: data => wifiActive = data.trim() === "enabled" }
  }

  Process {
    id: btCheck
    command: ["sh", "-c", "bluetoothctl show | grep -q 'Powered: yes' && echo on || echo off"]
    stdout: SplitParser { onRead: data => btActive = data.trim() === "on" }
  }

  Timer {
    interval: 500; running: ccRoot.visible; repeat: true
    onTriggered: { volProc.running = true; brightProc.running = true }
  }

  Timer {
    interval: 5000; running: ccRoot.visible; repeat: true; triggeredOnStart: true
    onTriggered: { uptimeProc.running = true; wifiCheck.running = true; btCheck.running = true }
  }

  component CcIconBtn: Rectangle {
    property string icon
    property bool danger: false
    signal clicked()
    width: 26; height: 26; radius: 13
    color: ma_ic.containsMouse ? (danger ? "#ff6b6b20" : "#ffffff10") : "transparent"

    Text {
      anchors.centerIn: parent
      text: icon
      color: danger ? "#ff6b6b" : Colors.text3
      font { pixelSize: 13; family: "JetBrainsMono Nerd Font" }
    }

    MouseArea {
      id: ma_ic
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: parent.clicked()
    }
  }

  component ToggleBtn: Rectangle {
    property string icon
    property string label
    property bool active: false
    signal clicked()
    width: 66; height: 66; radius: 12
    color: active ? Colors.accentDim : Colors.bg2

    Behavior on color { ColorAnimation { duration: 150 } }

    Text {
      anchors.centerIn: parent
      anchors.verticalCenterOffset: -8
      text: icon
      color: active ? Colors.accent : Colors.text3
      font { pixelSize: 20; family: "JetBrainsMono Nerd Font" }
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      anchors.bottomMargin: 6
      text: label
      color: active ? Colors.text2 : Colors.text3
      font { pixelSize: 8; family: "JetBrainsMono Nerd Font" }
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: parent.clicked()
    }
  }

  component SliderBar: Rectangle {
    property string icon
    property int value: 0
    signal adjust(int v)

    width: parent.width
    height: 36
    radius: 8
    color: Colors.bg2

    RowLayout {
      anchors.fill: parent
      anchors.margins: 8
      spacing: 8

      Text {
        text: icon
        color: Colors.accent
        font { pixelSize: 14; family: "JetBrainsMono Nerd Font" }
      }

      Rectangle {
        Layout.fillWidth: true
        height: 6
        radius: 3
        color: "#333338"

        Rectangle {
          width: parent.width * (value / 100)
          height: parent.height
          radius: 3
          color: Colors.accent
          Behavior on width { NumberAnimation { duration: 80 } }
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: function(mouse) {
            var pct = Math.round(Math.max(0, Math.min(100, (mouse.x / parent.width) * 100)))
            adjust(pct)
          }
          onPositionChanged: function(mouse) {
            if (pressed) {
              var pct = Math.round(Math.max(0, Math.min(100, (mouse.x / parent.width) * 100)))
              adjust(pct)
            }
          }
        }
      }

      Text {
        text: value + "%"
        color: Colors.text3
        font { pixelSize: 10; family: "JetBrainsMono Nerd Font" }
        Layout.preferredWidth: 30
      }
    }
  }

  component PowerBtn: Rectangle {
    property string icon
    property string label
    property bool danger: false
    signal clicked()
    width: 66; height: 50; radius: 10
    color: ma_pw.containsMouse ? (danger ? "#ff6b6b20" : "#ffffff08") : Colors.bg2

    Column {
      anchors.centerIn: parent
      spacing: 2

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: icon
        color: danger ? "#ff6b6b" : Colors.text2
        font { pixelSize: 16; family: "JetBrainsMono Nerd Font" }
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: label
        color: Colors.text3
        font { pixelSize: 8; family: "JetBrainsMono Nerd Font" }
      }
    }

    MouseArea {
      id: ma_pw
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: parent.clicked()
    }
  }
}
