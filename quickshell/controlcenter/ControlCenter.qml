import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import ".."
import "../frame"

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
  onVisibleChanged: {
    if (visible) OverlayState.setActive("controlcenter")
    else OverlayState.clear("controlcenter")
  }

  function toggle() {
    if (visible) {
      closeAnim.start()
    } else {
      visible = true
      refreshAll()
      keyGrabber.forceActiveFocus()
      panel.opacity = 0
      panelXOffset = 28
      panelScale.xScale = 0.965
      panelScale.yScale = 0.985
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
    notificationHistoryProc.running = true
    notificationDndStatusProc.running = true
  }

  SequentialAnimation {
    id: openAnim
    ParallelAnimation {
      NumberAnimation { target: panel; property: "opacity"; from: 0; to: 1; duration: 120; easing.type: Easing.OutQuad }
      NumberAnimation { target: root; property: "panelXOffset"; from: 28; to: 0; duration: 260; easing.type: Easing.OutCubic }
      NumberAnimation { target: panelScale; property: "xScale"; from: 0.965; to: 1; duration: 260; easing.type: Easing.OutCubic }
      NumberAnimation { target: panelScale; property: "yScale"; from: 0.985; to: 1; duration: 260; easing.type: Easing.OutCubic }
    }
  }
  SequentialAnimation {
    id: closeAnim
    ParallelAnimation {
      NumberAnimation { target: root; property: "panelXOffset"; to: 28; duration: 150; easing.type: Easing.InCubic }
      NumberAnimation { target: panelScale; property: "xScale"; to: 0.965; duration: 150; easing.type: Easing.InCubic }
      NumberAnimation { target: panelScale; property: "yScale"; to: 0.985; duration: 150; easing.type: Easing.InCubic }
      NumberAnimation { target: panel; property: "opacity"; to: 0; duration: 110; easing.type: Easing.InQuad }
    }
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
  property bool   screenRecording: false
  property bool   protonVpnConnected: false
  property var    notificationHistory: []
  property var    notificationIgnoredKeys: []
  property var    notificationExpandedKeys: []
  property real   panelXOffset: 0
  readonly property string sessionBus: Quickshell.env("DBUS_SESSION_BUS_ADDRESS")
  readonly property string runtimeDir: Quickshell.env("XDG_RUNTIME_DIR")
  readonly property bool showLaptopHeader: DeviceState.isLaptop && DeviceState.hasBattery
  readonly property bool showDesktopHeader: !showLaptopHeader
  readonly property bool showConnectivity: DeviceState.hasWifi || DeviceState.hasBluetooth
  readonly property int toggleCount: DeviceState.hasPowerProfiles ? 4 : 3

  function mergeNotificationHistory(items) {
    const incoming = Array.isArray(items) ? items : []
    const current = Array.isArray(root.notificationHistory) ? root.notificationHistory.slice() : []
    const ignored = new Set(Array.isArray(root.notificationIgnoredKeys) ? root.notificationIgnoredKeys : [])
    const byKey = new Map()

    for (const entry of current) {
      if (!ignored.has(entry.key || ""))
        byKey.set(entry.key, entry)
    }

    for (const entry of incoming) {
      const key = entry.key || `${entry.appName || ""}\u0000${entry.summary || ""}\u0000${entry.body || ""}`
      if (!key || ignored.has(key))
        continue
      if (!byKey.has(key)) {
        byKey.set(key, {
          id: Number(entry.id || 0),
          key,
          groupKey: entry.groupKey || "",
          appName: entry.appName || "",
          summary: entry.summary || "",
          body: entry.body || "",
          actionsCount: Number(entry.actionsCount || 0),
          iconPath: entry.iconPath || ""
        })
      } else {
        const existing = byKey.get(key)
        if (!existing)
          continue

        byKey.set(key, {
          id: Math.max(Number(existing.id || 0), Number(entry.id || 0)),
          key,
          groupKey: entry.groupKey || existing.groupKey || "",
          appName: entry.appName || existing.appName || "",
          summary: entry.summary || existing.summary || "",
          body: entry.body || existing.body || "",
          actionsCount: Math.max(Number(existing.actionsCount || 0), Number(entry.actionsCount || 0)),
          iconPath: entry.iconPath || existing.iconPath || ""
        })
      }
    }

    root.notificationHistory = Array.from(byKey.values()).sort((a, b) => (b.id || 0) - (a.id || 0))
  }

  function clearNotificationHistory() {
    const ignored = new Set(Array.isArray(root.notificationIgnoredKeys) ? root.notificationIgnoredKeys : [])
    for (const entry of root.notificationHistory) {
      if (entry.key)
        ignored.add(entry.key)
    }
    root.notificationIgnoredKeys = Array.from(ignored)
    root.notificationExpandedKeys = []
    root.notificationHistory = []
  }

  function removeNotificationByKey(key) {
    const ignored = new Set(Array.isArray(root.notificationIgnoredKeys) ? root.notificationIgnoredKeys : [])
    if (key)
      ignored.add(key)
    root.notificationIgnoredKeys = Array.from(ignored)
    root.notificationExpandedKeys = (Array.isArray(root.notificationExpandedKeys) ? root.notificationExpandedKeys : []).filter(item => item !== key)
    root.notificationHistory = root.notificationHistory.filter(entry => entry.key !== key)
  }

  function isNotificationExpanded(key) {
    return Array.isArray(root.notificationExpandedKeys) && root.notificationExpandedKeys.indexOf(key) >= 0
  }

  function toggleNotificationExpanded(key) {
    if (!key)
      return

    const current = Array.isArray(root.notificationExpandedKeys) ? root.notificationExpandedKeys.slice() : []
    const index = current.indexOf(key)
    if (index >= 0)
      current.splice(index, 1)
    else
      current.push(key)
    root.notificationExpandedKeys = current
  }

  function notificationTone(entry) {
    if (!entry) return Colors.info
    const urgency = String(entry.urgency || "").toLowerCase()
    const app = String(entry.appName || "").toLowerCase()
    if (urgency === "critical" || urgency === "high") return Colors.danger
    if (urgency === "low") return Colors.secondary
    if ((entry.actionsCount || 0) > 0) return Colors.primary
    if (app.indexOf("chrom") >= 0 || app.indexOf("firefox") >= 0 || app.indexOf("web") >= 0) return Colors.secondary
    return Colors.info
  }

  Item {
    id: keyGrabber
    focus: true
    Keys.onPressed: function(e) {
      if (e.key === Qt.Key_Escape) root.close()
    }
  }
  MouseArea { anchors.fill: parent; onClicked: root.close() }

  FrameSurface {
    id: panel
    anchors { top: parent.top; right: parent.right; topMargin: 44; rightMargin: 10 - root.panelXOffset }
    width: DeviceState.isDesktop ? 344 : 316
    height: col.implicitHeight + 28
    radius: 18
    attachedEdge: "right"
    fillColor: Colors.panelBackground
    borderColor: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, Colors.darkMode ? 0.18 : 0.16)
    topToneOpacity: Colors.darkMode ? 0.62 : 0.48
    bottomToneOpacity: 0.98
    opacity: 0
    transform: Scale {
      id: panelScale
      origin.x: panel.width
      origin.y: 0
      xScale: 1
      yScale: 1
    }

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
              color: Colors.primary
              anchors.baseline: parent.bottom
              anchors.baselineOffset: -6
            }
            Column {
              anchors.bottom: parent.bottom
              anchors.bottomMargin: 8
              Text {
                text: "%"
                font { pixelSize: 14; weight: Font.Medium; family: "Roboto" }
                color: Colors.primary
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
            color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.12)

            Text {
              id: uptimeDesktop
              anchors.centerIn: parent
              text: root.uptimeStr
              font { pixelSize: 10; family: "Roboto"; weight: Font.Medium }
              color: Colors.primary
            }
          }
        }
      }

      // divider accent
      Rectangle { width: parent.width; height: 1; color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.15) }

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
              color: Colors.primary
              Behavior on width { NumberAnimation { duration: 80 } }
            }
            Rectangle {
              x: parent.width * (root.brightValue / 100) - 7
              y: -3
              width: 14; height: 14; radius: 7
              color: Colors.primary
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
              color: root.volValue === 0 ? Colors.danger : Colors.primary
              Behavior on width { NumberAnimation { duration: 80 } }
              Behavior on color { ColorAnimation { duration: 150 } }
            }
            Rectangle {
              x: parent.width * (root.volValue / 100) - 7
              y: -3
              width: 14; height: 14; radius: 7
              color: root.volValue === 0 ? Colors.danger : Colors.primary
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
            color: root.volValue === 0 ? Colors.danger : Colors.text3
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
            color: Colors.primary
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
            color: Colors.bg1

            Row {
              anchors.centerIn: parent
              spacing: 8
              Text {
                text: "󰒓"
                font { pixelSize: 13; family: "JetBrainsMono Nerd Font" }
                color: Colors.primary
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
                color: Colors.primary
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
                color: Colors.primary
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
            color: root.protonVpnConnected
              ? Qt.rgba(Colors.success.r, Colors.success.g, Colors.success.b, 0.15)
              : Colors.bg1
            Behavior on color { ColorAnimation { duration: 150 } }

            Row {
              anchors.centerIn: parent
              spacing: 8
              Text {
                text: "󰌾"
                font { pixelSize: 13; family: "JetBrainsMono Nerd Font" }
                color: root.protonVpnConnected ? Colors.success : Colors.text3
                Behavior on color { ColorAnimation { duration: 150 } }
              }
              Text {
                text: root.protonVpnConnected ? "VPN conectada" : "Proton VPN"
                font { pixelSize: 10; family: "Roboto"; weight: Font.Medium }
                color: root.protonVpnConnected ? Colors.success : Colors.text1
                Behavior on color { ColorAnimation { duration: 150 } }
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: { root.close(); protonVpnProc.running = true }
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
            color: root.wifiActive ? Colors.info : Colors.text3
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
            color: root.wifiActive ? Qt.rgba(Colors.info.r, Colors.info.g, Colors.info.b, 0.12) : Colors.bg2
            Behavior on color { ColorAnimation { duration: 150 } }
            Text {
              id: statusWifi
              anchors.centerIn: parent
              text: root.wifiActive ? "conectado" : "desligado"
              font { pixelSize: 9; family: "Roboto" }
              color: root.wifiActive ? Qt.rgba(Colors.info.r, Colors.info.g, Colors.info.b, 0.9) : Colors.text3
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
            color: root.btActive ? Colors.secondary : Colors.text3
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
            color: root.btActive ? Qt.rgba(Colors.secondary.r, Colors.secondary.g, Colors.secondary.b, 0.12) : Colors.bg2
            Behavior on color { ColorAnimation { duration: 150 } }
            Text {
              id: statusBt
              anchors.centerIn: parent
              text: root.btConnected ? "conectado" : root.btActive ? "ativado" : "desligado"
              font { pixelSize: 9; family: "Roboto" }
              color: root.btActive ? Qt.rgba(Colors.secondary.r, Colors.secondary.g, Colors.secondary.b, 0.9) : Colors.text3
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
          color: SystemState.dnd ? Qt.rgba(Colors.secondary.r, Colors.secondary.g, Colors.secondary.b, 0.15) : Colors.bg2
          Behavior on color { ColorAnimation { duration: 150 } }
          Column {
            anchors.centerIn: parent
            spacing: 4
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: SystemState.dnd ? "󰂛" : "󰂚"
              font { pixelSize: 16; family: "JetBrainsMono Nerd Font" }
              color: SystemState.dnd ? Colors.secondary : Colors.text3
              Behavior on color { ColorAnimation { duration: 150 } }
            }
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "silêncio"
              font { pixelSize: 8; family: "Roboto" }
              color: SystemState.dnd ? Colors.secondary : Colors.text3
              Behavior on color { ColorAnimation { duration: 150 } }
            }
          }
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              notificationDndToggleProc.running = true
            }
          }
        }

        Rectangle {
          width: (parent.width - ((root.toggleCount - 1) * 6)) / root.toggleCount
          height: 56
          radius: 10
          color: SystemState.caffeine ? Qt.rgba(Colors.warning.r, Colors.warning.g, Colors.warning.b, 0.15) : Colors.bg2
          Behavior on color { ColorAnimation { duration: 150 } }
          Column {
            anchors.centerIn: parent
            spacing: 4
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: SystemState.caffeine ? "󰅶" : "󰄰"
              font { pixelSize: 16; family: "JetBrainsMono Nerd Font" }
              color: SystemState.caffeine ? Colors.warning : Colors.text3
              Behavior on color { ColorAnimation { duration: 150 } }
            }
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "cafeína"
              font { pixelSize: 8; family: "Roboto" }
              color: SystemState.caffeine ? Colors.warning : Colors.text3
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
          width: (parent.width - ((root.toggleCount - 1) * 6)) / root.toggleCount
          height: 56
          radius: 10
          color: root.screenRecording ? Qt.rgba(Colors.danger.r, Colors.danger.g, Colors.danger.b, 0.15) : Colors.bg2
          Behavior on color { ColorAnimation { duration: 150 } }
          Column {
            anchors.centerIn: parent
            spacing: 4
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: root.screenRecording ? "󰻃" : "󰕧"
              font { pixelSize: 16; family: "JetBrainsMono Nerd Font" }
              color: root.screenRecording ? Colors.danger : Colors.text3
              Behavior on color { ColorAnimation { duration: 150 } }
            }
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: root.screenRecording ? "gravando" : "gravar"
              font { pixelSize: 8; family: "Roboto" }
              color: root.screenRecording ? Colors.danger : Colors.text3
              Behavior on color { ColorAnimation { duration: 150 } }
            }
          }
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: obsProc.running = true
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
          readonly property var cols:   [Colors.success, Colors.info, Colors.warning]
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

        Rectangle { width: parent.width; height: 1; color: Qt.rgba(1,1,1,0.04) }

        RowLayout {
          width: parent.width
          Row {
            spacing: 8
            Layout.fillWidth: true

            Text {
              text: "notificações"
              color: Colors.text3
              font { pixelSize: 10; family: "Roboto" }
            }
            Rectangle {
              width: notifCountText.implicitWidth + 12
              height: 18
              radius: 9
              color: Colors.bg2

              Text {
                id: notifCountText
                anchors.centerIn: parent
                text: String(root.notificationHistory.length)
                color: Colors.text3
                font { pixelSize: 9; family: "Roboto"; weight: Font.Medium }
              }
            }
          }
          Row {
            spacing: 6
            Rectangle {
              height: 20
              width: 54
              radius: 10
              color: SystemState.dnd ? Qt.rgba(Colors.secondary.r, Colors.secondary.g, Colors.secondary.b, 0.15) : Colors.bg2
              Text {
                anchors.centerIn: parent
                text: "silenciar"
                font { pixelSize: 9; family: "Roboto" }
                color: SystemState.dnd ? Colors.secondary : Colors.text3
              }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: notificationDndToggleProc.running = true
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
                onClicked: {
                  root.clearNotificationHistory()
                  notificationDismissAllProc.running = true
                }
              }
            }
          }
        }

        Rectangle {
          width: parent.width
          height: root.notificationHistory.length > 0 ? 224 : 92
          radius: 18
          color: Qt.rgba(Colors.bg2.r, Colors.bg2.g, Colors.bg2.b, 0.92)

          Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: 15
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, Colors.darkMode ? 0.05 : 0.08)
          }

          Item {
            anchors.fill: parent
            anchors.margins: 10

            Column {
              anchors.centerIn: parent
              width: parent.width - 8
              spacing: 4
              visible: root.notificationHistory.length === 0

              Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: "sem notificações recentes"
                color: Colors.text2
                font { pixelSize: 11; family: "Roboto"; weight: Font.Medium }
              }
              Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: SystemState.dnd ? "silenciamento ativo" : "novos avisos aparecem aqui"
                color: Colors.text3
                font { pixelSize: 9; family: "Roboto" }
              }
            }

            Flickable {
              anchors.fill: parent
              visible: root.notificationHistory.length > 0
              clip: true
              contentWidth: width
              contentHeight: historyColumn.implicitHeight

              Column {
                id: historyColumn
                width: parent.width
                spacing: 6

                Repeater {
                  model: root.notificationHistory
                  delegate: Rectangle {
                    required property var modelData
                    readonly property bool expanded: root.isNotificationExpanded(modelData.key)
                    width: historyColumn.width
                    height: cardRow.implicitHeight + 18
                    radius: 16
                    color: Qt.rgba(Colors.bg1.r, Colors.bg1.g, Colors.bg1.b, 0.94)
                    border.width: 1
                    border.color: Qt.rgba(root.notificationTone(modelData).r, root.notificationTone(modelData).g, root.notificationTone(modelData).b, Colors.darkMode ? 0.20 : 0.26)

                    Behavior on height {
                      NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                    }

                    MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      onClicked: root.toggleNotificationExpanded(modelData.key)
                    }

                    RowLayout {
                      id: cardRow
                      anchors.fill: parent
                      anchors.margins: 9
                      spacing: 10

                      Rectangle {
                        width: 38
                        height: 38
                        radius: 19
                        color: Qt.rgba(root.notificationTone(modelData).r, root.notificationTone(modelData).g, root.notificationTone(modelData).b, 0.14)
                        Layout.alignment: Qt.AlignTop

                        Text {
                          anchors.centerIn: parent
                          visible: !iconImage.visible
                          text: "󰍡"
                          color: root.notificationTone(modelData)
                          font { pixelSize: 14; family: "JetBrainsMono Nerd Font" }
                        }

                        Image {
                          id: iconImage
                          anchors.centerIn: parent
                          width: 22
                          height: 22
                          source: modelData.iconPath || ""
                          visible: source !== ""
                          smooth: true
                          fillMode: Image.PreserveAspectFit
                        }
                      }

                      ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        RowLayout {
                          Layout.fillWidth: true
                          spacing: 6

                          Text {
                            text: modelData.appName || "Sistema"
                            color: Colors.text2
                            font { pixelSize: 9; family: "Roboto"; weight: Font.Medium }
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                          }

                          Rectangle {
                            width: 20
                            height: 20
                            radius: 10
                            color: closeMouse.containsMouse ? Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, 0.10) : "transparent"

                            Text {
                              anchors.centerIn: parent
                              text: "✕"
                              color: Colors.text3
                              font.pixelSize: 9
                            }

                            MouseArea {
                              id: closeMouse
                              anchors.fill: parent
                              hoverEnabled: true
                              cursorShape: Qt.PointingHandCursor
                              onClicked: root.removeNotificationByKey(modelData.key)
                            }
                          }
                        }

                        Text {
                          text: modelData.summary || "sem título"
                          color: Colors.text1
                          font { pixelSize: 12; family: "Roboto"; weight: Font.DemiBold }
                          Layout.fillWidth: true
                          wrapMode: Text.WordWrap
                          maximumLineCount: expanded ? 0 : 2
                          elide: expanded ? Text.ElideNone : Text.ElideRight
                        }

                        Text {
                          visible: (modelData.body || "") !== ""
                          text: modelData.body || ""
                          color: Colors.text3
                          font { pixelSize: 10; family: "Roboto" }
                          Layout.fillWidth: true
                          wrapMode: Text.WordWrap
                          maximumLineCount: expanded ? 0 : 3
                          elide: expanded ? Text.ElideNone : Text.ElideRight
                        }

                        Rectangle {
                          visible: modelData.actionsCount > 0
                          height: 20
                          radius: 10
                          color: Qt.rgba(root.notificationTone(modelData).r, root.notificationTone(modelData).g, root.notificationTone(modelData).b, 0.10)
                          Layout.topMargin: 4
                          width: actionMetaText.implicitWidth + 16

                          Text {
                            id: actionMetaText
                            anchors.centerIn: parent
                            text: modelData.actionsCount === 1 ? "1 ação" : modelData.actionsCount + " ações"
                            color: root.notificationTone(modelData)
                            font { pixelSize: 9; family: "Roboto"; weight: Font.Medium }
                          }
                        }
                      }
                    }
                  }
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
  Process {
    id: screenrecordStateProc
    command: ["bash", Paths.scripts + "/screenrecord-status.sh"]
    stdout: SplitParser {
      onRead: data => {
        const parts = data.trim().split("\t")
        root.screenRecording = (parts[0] || "") === "recording"
      }
    }
  }
  Process {
    id: protonVpnStateProc
    command: ["bash", Paths.scripts + "/protonvpn-status.sh"]
    stdout: SplitParser {
      onRead: data => {
        const parts = data.trim().split("\t")
        root.protonVpnConnected = (parts[0] || "") === "connected"
      }
    }
  }
  Process { id: audioProc;      command: ["/run/current-system/sw/bin/pwvucontrol"] }
  Process { id: wifiAppProc;    command: ["hyprctl", "dispatch", "exec", "kitty --title impala sudo impala"] }
  Process { id: btAppProc;      command: ["hyprctl", "dispatch", "exec", "kitty --title bluetui bluetui"] }
  Process { id: settingsCenterProc; command: ["quickshell", "ipc", "call", "settingscenter", "toggle"] }
  Process { id: updateCenterProc;   command: ["quickshell", "ipc", "call", "updatecenter", "toggle"] }
  Process { id: appCenterProc;      command: ["quickshell", "ipc", "call", "appcenter", "toggle"] }
  Process { id: obsProc;            command: ["hyprctl", "dispatch", "exec", "bash /home/ankh/.config/quickshell/scripts/screenrecord.sh"] }
  Process { id: protonVpnProc;      command: ["hyprctl", "dispatch", "exec", "bash /home/ankh/.config/quickshell/scripts/protonvpn-toggle-notify.sh"] }
  Process {
    id: notificationHistoryProc
    command: ["/run/current-system/sw/bin/node", Paths.scripts + "/notification-history.js"]
    stdout: SplitParser {
      onRead: data => {
        const text = data.trim()
        if (!text)
          return
        try {
          root.mergeNotificationHistory(JSON.parse(text))
        } catch (error) {
          console.log("Notification history parse failed:", text)
        }
      }
    }
  }
  Process {
    id: notificationDndStatusProc
    command: ["bash", Paths.scripts + "/notification-dnd.sh", "status"]
    stdout: SplitParser {
      onRead: data => {
        SystemState.dnd = data.trim() === "on"
      }
    }
  }
  Process {
    id: notificationDndToggleProc
    command: ["bash", Paths.scripts + "/notification-dnd.sh", "toggle"]
    stdout: SplitParser {
      onRead: data => {
        SystemState.dnd = data.trim() === "on"
      }
    }
  }
  Process {
    id: notificationDismissAllProc
    command: ["makoctl", "dismiss", "--all", "--no-history"]
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
    interval: 1000; running: root.visible; repeat: true; triggeredOnStart: true
    onTriggered: {
      screenrecordStateProc.running = true
      protonVpnStateProc.running = true
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
    interval: 1200; running: root.visible; repeat: true; triggeredOnStart: true
    onTriggered: {
      notificationHistoryProc.running = true
      notificationDndStatusProc.running = true
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
