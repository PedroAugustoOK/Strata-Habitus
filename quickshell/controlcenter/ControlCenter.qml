import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import ".."

PanelWindow {
  id: root
  anchors { top: true; right: true; left: true; bottom: true }
  implicitWidth: 370
  implicitHeight: 800
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
  WlrLayershell.layer: WlrLayer.Overlay
  focusable: true
  visible: false

  function toggle() {
    if (visible) {
      closeAnim.start()
    } else {
      visible = true
      refreshAll()
      keyGrabber.forceActiveFocus()
      panel.opacity = 0
      panel.scale = 0.92
      openAnim.start()
    }
  }
  function close() { closeAnim.start() }
  function refreshAll() {
    volProc.running       = true
    uptimeProc.running    = true
    sinkNameProc.running  = true
    if (DeviceState.hasBrightness) {
      brightProc.running = true
    }
    if (DeviceState.hasWifi) {
      wifiNameProc.running = true
      wifiCheck.running = true
    }
    if (DeviceState.hasBluetooth) {
      btCheck.running = true
    }
    if (DeviceState.hasPowerProfiles) {
      powerModeProc.running = true
    }
    if (DeviceState.hasBattery) {
      ccBatProc.running = true
    }
  }

  SequentialAnimation {
    id: openAnim
    NumberAnimation { target: panel; property: "opacity"; to: 1; duration: 80 }
    NumberAnimation { target: panel; property: "scale"; from: 0.92; to: 1.02; duration: 220; easing.type: Easing.OutCubic }
    NumberAnimation { target: panel; property: "scale"; to: 1.0; duration: 80; easing.type: Easing.InOutQuad }
  }
  SequentialAnimation {
    id: closeAnim
    NumberAnimation { target: panel; property: "scale"; to: 0.92; duration: 160; easing.type: Easing.InCubic }
    NumberAnimation { target: panel; property: "opacity"; to: 0; duration: 60 }
    ScriptAction { script: root.visible = false }
  }

  property int    powerMode:    1
  property bool   wifiActive:   true
  property bool   btActive:     false
  property bool   btConnected:  false
  property int    volValue:     0
  property int    brightValue:  100
  property string wifiName:     "—"
  property string uptimeStr:    "—"
  property int    batValue:     100
  property bool   batCharging:  false
  property bool   showBrightPct: false
  property bool   showVolPct:   false
  property string sinkName:     "—"
  readonly property string sessionBus: Quickshell.env("DBUS_SESSION_BUS_ADDRESS")
  readonly property string runtimeDir: Quickshell.env("XDG_RUNTIME_DIR")
  readonly property bool showLaptopHeader: DeviceState.isLaptop && DeviceState.hasBattery
  readonly property bool showDesktopHeader: !showLaptopHeader
  readonly property bool showConnectivity: DeviceState.hasWifi || DeviceState.hasBluetooth
  readonly property int toggleCount: DeviceState.hasPowerProfiles ? 3 : 2

  Item {
    id: keyGrabber
    focus: true
    Keys.onPressed: function(e) {
      if (e.key === Qt.Key_Escape) root.close()
    }
  }
  MouseArea { anchors.fill: parent; onClicked: root.close() }

  Rectangle {
    id: panel
    transformOrigin: Item.TopRight
    anchors { top: parent.top; right: parent.right; topMargin: 44; rightMargin: 20 }
    width: DeviceState.isDesktop ? 332 : 310
    height: col.implicitHeight + 28
    radius: 24
    color: Colors.bg1
    clip: true
    opacity: 0

    MouseArea { anchors.fill: parent }

    Column {
      id: col
      anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
      spacing: 14

      // ── Header: bateria grande + uptime ──────────────────
      Row {
        visible: root.showLaptopHeader
        width: parent.width
        Item {
          width: parent.width / 2
          height: 52
          Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0
            Text {
              text: root.batValue
              font { pixelSize: 38; weight: Font.Bold; family: "Roboto" }
              color: Colors.accent
              anchors.baseline: parent.bottom
              anchors.baselineOffset: -6
            }
            Column {
              anchors.bottom: parent.bottom
              anchors.bottomMargin: 8
              Text {
                text: "%"
                font { pixelSize: 14; weight: Font.Medium; family: "Roboto" }
                color: Colors.accent
              }
              Text {
                text: "BATERIA"
                font { pixelSize: 8; family: "Roboto"; letterSpacing: 1 }
                color: Colors.text3
              }
            }
          }
        }
        Column {
          width: parent.width / 2
          anchors.bottom: undefined
          spacing: 2
          Text {
            text: root.uptimeStr
            font { pixelSize: 13; family: "Roboto" }
            color: Colors.text2
            anchors.right: parent.right
          }
          Text {
            text: "uptime"
            font { pixelSize: 9; family: "Roboto" }
            color: Colors.text3
            anchors.right: parent.right
          }
        }
      }

      Rectangle {
        visible: root.showDesktopHeader
        width: parent.width
        height: 72
        radius: 16
        color: Colors.bg2

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 14
          anchors.rightMargin: 14

          Column {
            Layout.fillWidth: true
            spacing: 4

            Text {
              text: DeviceState.hostname.toUpperCase()
              font { pixelSize: 10; family: "Roboto"; letterSpacing: 1.4; weight: Font.Medium }
              color: Colors.text3
            }
            Text {
              text: DeviceState.isDesktop ? "estação de trabalho" : "sessão principal"
              font { pixelSize: 17; family: "Roboto"; weight: Font.DemiBold }
              color: Colors.text1
            }
            Text {
              text: root.sinkName
              font { pixelSize: 10; family: "Roboto" }
              color: Colors.text3
              elide: Text.ElideRight
            }
          }

          Rectangle {
            Layout.preferredWidth: uptimeDesktop.implicitWidth + 18
            Layout.preferredHeight: 28
            radius: 10
            color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.12)

            Text {
              id: uptimeDesktop
              anchors.centerIn: parent
              text: root.uptimeStr
              font { pixelSize: 10; family: "Roboto"; weight: Font.Medium }
              color: Colors.accent
            }
          }
        }
      }

      // divider accent
      Rectangle { width: parent.width; height: 1; color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.15) }

      // ── Sliders ───────────────────────────────────────────
      Column {
        width: parent.width
        spacing: 10

        // Brilho
        Row {
          visible: DeviceState.hasBrightness
          width: parent.width
          spacing: 10
          Text {
            text: root.brightValue
            font { pixelSize: 20; weight: Font.Bold; family: "Roboto" }
            color: Colors.text1
            width: 34
            horizontalAlignment: Text.AlignRight
            anchors.verticalCenter: parent.verticalCenter
          }
          Item {
            width: parent.width - 34 - 10 - 10 - 14
            height: 8
            anchors.verticalCenter: parent.verticalCenter
            Rectangle {
              anchors.fill: parent
              radius: 4
              color: Colors.bg2
            }
            Rectangle {
              width: parent.width * (root.brightValue / 100)
              height: parent.height
              radius: 4
              color: Colors.accent
              Behavior on width { NumberAnimation { duration: 80 } }
            }
            Rectangle {
              x: parent.width * (root.brightValue / 100) - 7
              y: -3
              width: 14; height: 14; radius: 7
              color: Colors.accent
              Behavior on x { NumberAnimation { duration: 80 } }
            }
            MouseArea {
              anchors { fill: parent; margins: -10 }
              cursorShape: Qt.PointingHandCursor
              onClicked: function(m) { applyBright(m.x) }
              onPositionChanged: function(m) { if (pressed) applyBright(m.x) }
              function applyBright(mx) {
                var v = Math.round(Math.max(0, Math.min(100, (mx / width) * 100)))
                root.brightValue = v
                brightSetProc.command = ["/run/current-system/sw/bin/brightnessctl", "set", v + "%"]
                brightSetProc.running = true
              }
            }
          }
          Text {
            text: "󰖙"
            font { pixelSize: 12; family: "JetBrainsMono Nerd Font" }
            color: Colors.text3
            width: 14
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        // Volume
        Row {
          width: parent.width
          spacing: 10
          Text {
            text: root.volValue
            font { pixelSize: 20; weight: Font.Bold; family: "Roboto" }
            color: Colors.text1
            width: 34
            horizontalAlignment: Text.AlignRight
            anchors.verticalCenter: parent.verticalCenter
          }
          Item {
            width: parent.width - 34 - 10 - 10 - 14
            height: 8
            anchors.verticalCenter: parent.verticalCenter
            Rectangle {
              anchors.fill: parent
              radius: 4
              color: Colors.bg2
            }
            Rectangle {
              width: parent.width * (root.volValue / 100)
              height: parent.height
              radius: 4
              color: root.volValue === 0 ? "#f28779" : Colors.accent
              Behavior on width { NumberAnimation { duration: 80 } }
              Behavior on color { ColorAnimation { duration: 150 } }
            }
            Rectangle {
              x: parent.width * (root.volValue / 100) - 7
              y: -3
              width: 14; height: 14; radius: 7
              color: root.volValue === 0 ? "#f28779" : Colors.accent
              Behavior on x { NumberAnimation { duration: 80 } }
              Behavior on color { ColorAnimation { duration: 150 } }
            }
            MouseArea {
              anchors { fill: parent; margins: -10 }
              cursorShape: Qt.PointingHandCursor
              onClicked: function(m) { applyVol(m.x) }
              onPositionChanged: function(m) { if (pressed) applyVol(m.x) }
              function applyVol(mx) {
                var v = Math.round(Math.max(0, Math.min(100, (mx / width) * 100)))
                root.volValue = v
                volSetProc.command = ["/run/current-system/sw/bin/wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (v/100).toFixed(2)]
                volSetProc.running = true
              }
            }
          }
          Text {
            text: root.volValue === 0 ? "󰝟" : "󰕾"
            font { pixelSize: 12; family: "JetBrainsMono Nerd Font" }
            color: root.volValue === 0 ? "#f28779" : Colors.text3
            width: 14
            anchors.verticalCenter: parent.verticalCenter
            Behavior on color { ColorAnimation { duration: 150 } }
          }
        }
      }

      // ── Audio sink ────────────────────────────────────────
      Rectangle {
        width: parent.width
        height: 44
        radius: 12
        color: Colors.bg2
        RowLayout {
          anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
          Text {
            text: "󰋋"
            font { pixelSize: 14; family: "JetBrainsMono Nerd Font" }
            color: Colors.accent
          }
          Column {
            Layout.fillWidth: true
            spacing: 1
            Text {
              text: root.sinkName
              font { pixelSize: 11; family: "Roboto"; weight: Font.Medium }
              color: Colors.text1
              elide: Text.ElideRight
              width: parent.width
            }
            Text {
              text: "saída de áudio"
              font { pixelSize: 9; family: "Roboto" }
              color: Colors.text3
            }
          }
          Text {
            text: "›"
            font { pixelSize: 14; family: "Roboto" }
            color: Colors.text3
          }
        }
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: { root.close(); audioProc.running = true }
        }
      }

      Rectangle {
        visible: DeviceState.isDesktop
        width: parent.width
        height: actionsGrid.implicitHeight + 16
        radius: 14
        color: Colors.bg2

        GridLayout {
          id: actionsGrid
          anchors.fill: parent
          anchors.margins: 10
          columns: 2
          rowSpacing: 8
          columnSpacing: 8

          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 46
            radius: 10
            color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.12)

            Row {
              anchors.centerIn: parent
              spacing: 8
              Text {
                text: "󰒓"
                font { pixelSize: 13; family: "JetBrainsMono Nerd Font" }
                color: Colors.accent
              }
              Text {
                text: "Configurações"
                font { pixelSize: 10; family: "Roboto"; weight: Font.Medium }
                color: Colors.text1
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: { root.close(); settingsCenterProc.running = true }
            }
          }

          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 46
            radius: 10
            color: Colors.bg1

            Row {
              anchors.centerIn: parent
              spacing: 8
              Text {
                text: "󰏗"
                font { pixelSize: 13; family: "JetBrainsMono Nerd Font" }
                color: Colors.accent
              }
              Text {
                text: "Atualizações"
                font { pixelSize: 10; family: "Roboto"; weight: Font.Medium }
                color: Colors.text1
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: { root.close(); updateCenterProc.running = true }
            }
          }

          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 46
            radius: 10
            color: Colors.bg1

            Row {
              anchors.centerIn: parent
              spacing: 8
              Text {
                text: "󰀻"
                font { pixelSize: 13; family: "JetBrainsMono Nerd Font" }
                color: Colors.accent
              }
              Text {
                text: "Central de Apps"
                font { pixelSize: 10; family: "Roboto"; weight: Font.Medium }
                color: Colors.text1
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: { root.close(); appCenterProc.running = true }
            }
          }

          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 46
            radius: 10
            color: Colors.bg1

            Row {
              anchors.centerIn: parent
              spacing: 8
              Text {
                text: "󰕧"
                font { pixelSize: 13; family: "JetBrainsMono Nerd Font" }
                color: Colors.accent
              }
              Text {
                text: "OBS Studio"
                font { pixelSize: 10; family: "Roboto"; weight: Font.Medium }
                color: Colors.text1
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: { root.close(); obsProc.running = true }
            }
          }
        }
      }

      // divider
      Rectangle { width: parent.width; height: 1; color: Qt.rgba(1,1,1,0.04) }


      // ── WiFi + BT como lista ──────────────────────────────
      Column {
        visible: root.showConnectivity
        width: parent.width
        spacing: 10

        RowLayout {
          visible: DeviceState.hasWifi
          width: parent.width
          spacing: 0
          Text {
            text: "󰤨"
            font { pixelSize: 14; family: "JetBrainsMono Nerd Font" }
            color: root.wifiActive ? Colors.accent : Colors.text3
            Behavior on color { ColorAnimation { duration: 150 } }
          }
          Item { Layout.preferredWidth: 10 }
          Text {
            text: root.wifiActive ? (root.wifiName !== "—" ? root.wifiName : "WiFi") : "WiFi"
            font { pixelSize: 13; family: "Roboto"; weight: Font.Medium }
            color: root.wifiActive ? Colors.text1 : Colors.text3
            Layout.fillWidth: true
            elide: Text.ElideRight
            Behavior on color { ColorAnimation { duration: 150 } }
          }
          Rectangle {
            height: 20
            width: statusWifi.implicitWidth + 16
            radius: 6
            color: root.wifiActive ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.12) : Colors.bg2
            Behavior on color { ColorAnimation { duration: 150 } }
            Text {
              id: statusWifi
              anchors.centerIn: parent
              text: root.wifiActive ? "conectado" : "desligado"
              font { pixelSize: 9; family: "Roboto" }
              color: root.wifiActive ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.9) : Colors.text3
              Behavior on color { ColorAnimation { duration: 150 } }
            }
            MouseArea {
              z: 10
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                root.wifiActive = !root.wifiActive
                wifiToggleProc.command = ["sh", "-c", root.wifiActive ? "rfkill unblock wifi" : "rfkill block wifi"]
                wifiToggleProc.running = true
              }
            }
          }
          Item { Layout.preferredWidth: 6 }
          Item {
            implicitWidth: arrowWifi.implicitWidth + 8
            implicitHeight: 20
            Text {
              id: arrowWifi
              anchors.centerIn: parent
              text: "›"
              font { pixelSize: 13; family: "Roboto" }
              color: Colors.text3
            }
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: { root.close(); wifiAppProc.running = true }
            }
          }
        }

        RowLayout {
          visible: DeviceState.hasBluetooth
          width: parent.width
          spacing: 0
          Text {
            text: root.btConnected ? "󰂱" : "󰂯"
            font { pixelSize: 14; family: "JetBrainsMono Nerd Font" }
            color: root.btActive ? Colors.accent : Colors.text3
            Behavior on color { ColorAnimation { duration: 150 } }
          }
          Item { Layout.preferredWidth: 10 }
          Text {
            text: "Bluetooth"
            font { pixelSize: 13; family: "Roboto"; weight: Font.Medium }
            color: root.btActive ? Colors.text1 : Colors.text3
            Layout.fillWidth: true
            elide: Text.ElideRight
            Behavior on color { ColorAnimation { duration: 150 } }
          }
          Rectangle {
            height: 20
            width: statusBt.implicitWidth + 16
            radius: 6
            color: root.btActive ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.12) : Colors.bg2
            Behavior on color { ColorAnimation { duration: 150 } }
            Text {
              id: statusBt
              anchors.centerIn: parent
              text: root.btConnected ? "conectado" : root.btActive ? "ativado" : "desligado"
              font { pixelSize: 9; family: "Roboto" }
              color: root.btActive ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.9) : Colors.text3
              Behavior on color { ColorAnimation { duration: 150 } }
            }
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                console.log("BT toggle click", "bus:", root.sessionBus, "runtime:", root.runtimeDir)
                btToggleProc.command = [
                  "/run/current-system/sw/bin/env",
                  "DBUS_SESSION_BUS_ADDRESS=" + root.sessionBus,
                  "XDG_RUNTIME_DIR=" + root.runtimeDir,
                  "/run/current-system/sw/bin/bash",
                  Paths.scripts + "/bluetooth-helper.sh",
                  "toggle"
                ]
                btToggleProc.running = true
              }
            }
          }
          Item { Layout.preferredWidth: 6 }
          Item {
            implicitWidth: arrowBt.implicitWidth + 8
            implicitHeight: 20
            Text {
              id: arrowBt
              anchors.centerIn: parent
              text: "›"
              font { pixelSize: 13; family: "Roboto" }
              color: Colors.text3
            }
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: { root.close(); btAppProc.running = true }
            }
          }
        }
      }

      // divider
      Rectangle {
        visible: root.showConnectivity
        width: parent.width
        height: 1
        color: Qt.rgba(1,1,1,0.04)
      }

      // ── Toggles inferiores ────────────────────────────────
      Row {
        width: parent.width
        spacing: 6

        Rectangle {
          width: (parent.width - ((root.toggleCount - 1) * 6)) / root.toggleCount
          height: 56
          radius: 10
          color: SystemState.dnd ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.15) : Colors.bg2
          Behavior on color { ColorAnimation { duration: 150 } }
          Column {
            anchors.centerIn: parent
            spacing: 4
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: SystemState.dnd ? "󰂛" : "󰂚"
              font { pixelSize: 16; family: "JetBrainsMono Nerd Font" }
              color: SystemState.dnd ? Colors.accent : Colors.text3
              Behavior on color { ColorAnimation { duration: 150 } }
            }
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "silêncio"
              font { pixelSize: 8; family: "Roboto" }
              color: SystemState.dnd ? Colors.accent : Colors.text3
              Behavior on color { ColorAnimation { duration: 150 } }
            }
          }
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              SystemState.dnd = !SystemState.dnd
              NotificationService.dnd = SystemState.dnd
            }
          }
        }

        Rectangle {
          width: (parent.width - ((root.toggleCount - 1) * 6)) / root.toggleCount
          height: 56
          radius: 10
          color: SystemState.caffeine ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.15) : Colors.bg2
          Behavior on color { ColorAnimation { duration: 150 } }
          Column {
            anchors.centerIn: parent
            spacing: 4
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: SystemState.caffeine ? "󰅶" : "󰄰"
              font { pixelSize: 16; family: "JetBrainsMono Nerd Font" }
              color: SystemState.caffeine ? Colors.accent : Colors.text3
              Behavior on color { ColorAnimation { duration: 150 } }
            }
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "cafeína"
              font { pixelSize: 8; family: "Roboto" }
              color: SystemState.caffeine ? Colors.accent : Colors.text3
              Behavior on color { ColorAnimation { duration: 150 } }
            }
          }
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              SystemState.caffeine = !SystemState.caffeine
              caffeineProc.command = SystemState.caffeine
                ? ["sh", "-c", "pkill hypridle || true"]
                : ["sh", "-c", "pkill hypridle || true; hypridle >/dev/null 2>&1 & disown"]
              caffeineProc.running = true
            }
          }
        }

        Rectangle {
          visible: DeviceState.hasPowerProfiles
          width: (parent.width - ((root.toggleCount - 1) * 6)) / root.toggleCount
          height: 56
          radius: 10
          color: Colors.bg2
          Behavior on color { ColorAnimation { duration: 150 } }
          readonly property var modes:  ["󰾅", "󰓅", "󰌪"]
          readonly property var labels: ["economia", "balanceado", "performance"]
          readonly property var cols:   ["#69c880", Colors.accent, "#ffb347"]
          Column {
            anchors.centerIn: parent
            spacing: 4
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: parent.parent.modes[root.powerMode]
              font { pixelSize: 16; family: "JetBrainsMono Nerd Font" }
              color: parent.parent.cols[root.powerMode]
              Behavior on color { ColorAnimation { duration: 150 } }
            }
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: parent.parent.labels[root.powerMode]
              font { pixelSize: 8; family: "Roboto" }
              color: parent.parent.cols[root.powerMode]
              Behavior on color { ColorAnimation { duration: 150 } }
            }
          }
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              root.powerMode = (root.powerMode + 1) % 3
              powerSetProc.command = ["/run/current-system/sw/bin/powerprofilesctl", "set", ["power-saver", "balanced", "performance"][root.powerMode]]
              powerSetProc.running = true
            }
          }
        }
      }

      // ── Notificações ──────────────────────────────────────
      Column {
        width: parent.width
        spacing: 8
        visible: NotificationService.notifications.length > 0

        Rectangle { width: parent.width; height: 1; color: Qt.rgba(1,1,1,0.04) }

        RowLayout {
          width: parent.width
          Text {
            text: "notificações"
            color: Colors.text3
            font { pixelSize: 10; family: "Roboto" }
            Layout.fillWidth: true
          }
          Row {
            spacing: 6
            Rectangle {
              height: 20
              width: 54
              radius: 10
              color: SystemState.dnd ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.15) : Colors.bg2
              Text {
                anchors.centerIn: parent
                text: "silenciar"
                font { pixelSize: 9; family: "Roboto" }
                color: SystemState.dnd ? Colors.accent : Colors.text3
              }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: { SystemState.dnd = !SystemState.dnd; NotificationService.dnd = SystemState.dnd }
              }
            }
            Rectangle {
              height: 20
              width: 40
              radius: 10
              color: Colors.bg2
              Text {
                anchors.centerIn: parent
                text: "limpar"
                font { pixelSize: 9; family: "Roboto" }
                color: Colors.text3
              }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: NotificationService.dismissAll()
              }
            }
          }
        }

        Column {
          width: parent.width
          spacing: 6
          bottomPadding: 4
          Repeater {
            model: NotificationService.notifications
            delegate: Rectangle {
              required property Notification modelData
              width: parent.width
              height: nc.implicitHeight + 16
              radius: 12
              color: Colors.bg2
              Rectangle {
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom; topMargin: 8; bottomMargin: 8 }
                width: 3
                radius: 2
                color: Colors.accent
                opacity: 0.6
              }
              Column {
                id: nc
                anchors { left: parent.left; right: parent.right; top: parent.top; leftMargin: 16; rightMargin: 12; topMargin: 8 }
                spacing: 2
                RowLayout {
                  width: parent.width
                  Text {
                    text: modelData.appName
                    color: Colors.accent
                    font { pixelSize: 9; family: "Roboto" }
                    Layout.fillWidth: true
                  }
                  Text {
                    text: "✕"
                    color: Colors.text3
                    font.pixelSize: 10
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
                  font { pixelSize: 11; family: "Roboto"; weight: Font.Medium }
                  width: parent.width
                  wrapMode: Text.WordWrap
                  maximumLineCount: 1
                  elide: Text.ElideRight
                }
                Text {
                  visible: modelData.body !== ""
                  text: modelData.body
                  color: Colors.text3
                  font { pixelSize: 10; family: "Roboto" }
                  width: parent.width
                  wrapMode: Text.WordWrap
                  maximumLineCount: 2
                  elide: Text.ElideRight
                }
              }
            }
          }
        }
      }
    }
  }

  Process { id: wifiToggleProc; command: [] }
  Process {
    id: btToggleProc
    command: []
    stdout: SplitParser {
      onRead: data => {
        console.log("BT toggle stdout:", data.trim())
        var s = data.trim()
        root.btActive = s !== "off"
        root.btConnected = s === "connected"
      }
    }
    stderr: SplitParser {
      onRead: data => console.log("BT toggle stderr:", data.trim())
    }
    onRunningChanged: {
      console.log("BT toggle running:", running)
    }
    onExited: btCheck.running = true
  }
  Process { id: volSetProc;     command: [] }
  Process { id: brightSetProc;  command: [] }
  Process { id: caffeineProc;   command: [] }
  Process { id: powerSetProc;   command: [] }
  Process { id: audioProc;      command: ["/run/current-system/sw/bin/pwvucontrol"] }
  Process { id: wifiAppProc;    command: ["hyprctl", "dispatch", "exec", "kitty --title impala sudo impala"] }
  Process { id: btAppProc;      command: ["hyprctl", "dispatch", "exec", "kitty --title bluetui bluetui"] }
  Process { id: settingsCenterProc; command: ["quickshell", "ipc", "call", "settingscenter", "toggle"] }
  Process { id: updateCenterProc;   command: ["quickshell", "ipc", "call", "updatecenter", "toggle"] }
  Process { id: appCenterProc;      command: ["quickshell", "ipc", "call", "appcenter", "toggle"] }
  Process { id: obsProc;            command: ["hyprctl", "dispatch", "exec", "obs-studio"] }

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
    command: ["bash", Paths.scripts + "/battery-status.sh"]
    stdout: SplitParser {
      onRead: data => {
        var p = data.trim().split("\t")
        root.batValue    = parseInt(p[0]) || 100
        root.batCharging = (p[1] || "").trim() === "Charging"
      }
    }
  }
  Process {
    id: sinkNameProc
    command: [Paths.scripts + "/get-sink.sh"]
    stdout: SplitParser { onRead: data => { if (data.trim() !== "") root.sinkName = data.trim() } }
  }
  Process {
    id: wifiNameProc
    command: ["bash", Paths.scripts + "/wifi-name.sh"]
    stdout: SplitParser { onRead: data => { if (data.trim() !== "") root.wifiName = data.trim() } }
  }
  Process {
    id: wifiCheck
    command: ["sh", "-c", "rfkill list wifi 2>/dev/null | grep -c 'Soft blocked: no'"]
    stdout: SplitParser { onRead: data => root.wifiActive = parseInt(data.trim()) > 0 }
  }
  Process {
    id: btCheck
    command: [
      "/run/current-system/sw/bin/env",
      "DBUS_SESSION_BUS_ADDRESS=" + root.sessionBus,
      "XDG_RUNTIME_DIR=" + root.runtimeDir,
      "/run/current-system/sw/bin/bash",
      Paths.scripts + "/bluetooth-helper.sh",
      "status"
    ]
    stdout: SplitParser {
      onRead: data => {
        console.log("BT status:", data.trim())
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

  Timer {
    interval: 500; running: root.visible; repeat: true
    onTriggered: {
      volProc.running = true
      if (DeviceState.hasBrightness) {
        brightProc.running = true
      }
    }
  }
  Timer {
    interval: 5000; running: root.visible; repeat: true; triggeredOnStart: true
    onTriggered: {
      uptimeProc.running = true
      sinkNameProc.running = true
      if (DeviceState.hasWifi) {
        wifiCheck.running = true
        wifiNameProc.running = true
      }
      if (DeviceState.hasBluetooth) {
        btCheck.running = true
      }
      if (DeviceState.hasBattery) {
        ccBatProc.running = true
      }
    }
  }
}
