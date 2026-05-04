import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import ".."

PanelWindow {
  id: root

  anchors { top: true; left: true; right: true }
  implicitHeight: expanded ? 210 : 86
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  focusable: expanded
  mask: Region { item: hitRegion }
  WlrLayershell.namespace: "strata-island"
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

  property bool expanded: false
  property bool hovered: false
  property string timeText: "--:--"
  property string dateText: ""

  property string mediaStatus: "Stopped"
  property string mediaTitle: ""
  property string mediaArtist: ""
  property real mediaProgress: 0
  property bool mediaActive: mediaStatus !== "Stopped" && mediaTitle !== ""

  property bool recording: false
  property string recordingElapsed: "--:--"
  property bool vpnConnected: false
  property string vpnLabel: "VPN"

  property int lastNotificationId: 0
  property string notificationApp: ""
  property string notificationSummary: ""
  property bool notificationFresh: false

  readonly property string mode: notificationFresh ? "notification"
    : recording ? "recording"
    : mediaActive ? "media"
    : "clock"

  readonly property int collapsedWidth: {
    if (mode === "notification") return Math.min(520, Math.max(220, notificationSummaryText.implicitWidth + notificationAppText.implicitWidth + 64))
    if (mode === "recording") return 180
    if (mode === "media") return Math.min(440, Math.max(250, mediaTitleText.implicitWidth + 96))
    return vpnConnected ? 170 : 126
  }
  readonly property int expandedWidth: Math.min(620, Screen.width - 40)
  readonly property int islandWidth: expanded ? expandedWidth : collapsedWidth
  readonly property int islandHeight: expanded ? 150 : 42
  readonly property int islandY: 40

  Item {
    id: hitRegion
    x: island.x - 10
    y: island.y - 8
    width: island.width + 20
    height: island.height + 16
  }

  Rectangle {
    id: island
    x: Math.round((parent.width - width) / 2)
    y: root.islandY
    width: root.islandWidth
    height: root.islandHeight
    radius: expanded ? 22 : height / 2
    color: Qt.rgba(Colors.panelBackground.r, Colors.panelBackground.g, Colors.panelBackground.b, expanded ? 0.97 : 0.90)
    border.width: root.recording ? 2 : 1
    border.color: {
      if (root.recording) return Qt.rgba(Colors.danger.r, Colors.danger.g, Colors.danger.b, 0.65)
      if (root.notificationFresh) return Qt.rgba(Colors.warning.r, Colors.warning.g, Colors.warning.b, 0.48)
      if (root.mediaActive) return Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.36)
      return Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, Colors.darkMode ? 0.10 : 0.16)
    }
    scale: root.hovered && !root.expanded ? 1.025 : 1
    clip: true

    Behavior on width { NumberAnimation { duration: 360; easing.type: Easing.OutCubic } }
    Behavior on height { NumberAnimation { duration: 360; easing.type: Easing.OutCubic } }
    Behavior on radius { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    Behavior on color { ColorAnimation { duration: Colors.themeTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on border.color { ColorAnimation { duration: 220; easing.type: Easing.OutCubic } }

    Rectangle {
      anchors.fill: parent
      radius: parent.radius
      opacity: root.recording ? recordPulse.opacity * 0.14 : root.notificationFresh ? 0.10 : 0
      color: root.recording ? Colors.danger : Colors.warning
      Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    }

    Rectangle {
      id: shadowHint
      anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
      height: 1
      color: Qt.rgba(1, 1, 1, Colors.darkMode ? 0.035 : 0.22)
    }

    Item {
      id: collapsedLayer
      anchors.fill: parent
      opacity: root.expanded ? 0 : 1
      visible: opacity > 0.01
      Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

      Row {
        anchors.centerIn: parent
        spacing: 10

        Rectangle {
          id: recordPulse
          width: 8
          height: 8
          radius: 4
          visible: root.recording
          anchors.verticalCenter: parent.verticalCenter
          color: Colors.danger
          opacity: 1
          SequentialAnimation on opacity {
            running: root.recording
            loops: Animation.Infinite
            NumberAnimation { to: 0.22; duration: 620; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.0; duration: 620; easing.type: Easing.InOutSine }
          }
        }

        Text {
          id: modeIcon
          anchors.verticalCenter: parent.verticalCenter
          text: root.mode === "notification" ? "󰂚"
            : root.recording ? "󰻃"
            : root.mediaActive ? (root.mediaStatus === "Playing" ? "󰏤" : "󰐊")
            : "󰥔"
          color: root.recording ? Colors.danger : root.notificationFresh ? Colors.warning : root.mediaActive ? Colors.primary : Colors.text1
          font { family: "JetBrainsMono Nerd Font"; pixelSize: 14 }
        }

        Column {
          anchors.verticalCenter: parent.verticalCenter
          spacing: -1
          width: Math.min(330, island.width - (root.vpnConnected ? 78 : 44))

          Text {
            id: mediaTitleText
            visible: root.mode === "media"
            text: root.mediaTitle
            width: parent.width
            elide: Text.ElideRight
            color: Colors.text0
            font { family: "Inter"; pixelSize: 12; weight: Font.DemiBold }
          }
          Text {
            visible: root.mode === "recording"
            text: "Gravando " + root.recordingElapsed
            width: parent.width
            elide: Text.ElideRight
            color: Colors.text0
            font { family: "Inter"; pixelSize: 12; weight: Font.DemiBold }
          }
          Text {
            id: notificationAppText
            visible: root.mode === "notification"
            text: root.notificationApp
            width: parent.width
            elide: Text.ElideRight
            color: Colors.warning
            font { family: "Inter"; pixelSize: 11; weight: Font.DemiBold }
          }
          Text {
            visible: root.mode === "clock"
            text: root.timeText
            width: parent.width
            color: Colors.text0
            font { family: "JetBrainsMono Nerd Font"; pixelSize: 13; weight: Font.DemiBold }
          }
          Text {
            id: notificationSummaryText
            visible: root.mode === "notification"
            text: root.notificationSummary
            width: parent.width
            elide: Text.ElideRight
            color: Colors.text0
            font { family: "Inter"; pixelSize: 12; weight: Font.DemiBold }
          }
          Text {
            visible: root.mode === "media" && root.mediaArtist !== ""
            text: root.mediaArtist
            width: parent.width
            elide: Text.ElideRight
            color: Colors.text2
            font { family: "Inter"; pixelSize: 10 }
          }
        }

        Rectangle {
          visible: root.vpnConnected && root.mode !== "recording"
          anchors.verticalCenter: parent.verticalCenter
          width: 26
          height: 22
          radius: 11
          color: Qt.rgba(Colors.info.r, Colors.info.g, Colors.info.b, 0.14)
          Text {
            anchors.centerIn: parent
            text: "󰌾"
            color: Colors.info
            font { family: "JetBrainsMono Nerd Font"; pixelSize: 12 }
          }
        }
      }

      Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: 16; rightMargin: 16 }
        height: 2
        radius: 1
        visible: root.mediaActive
        color: Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, 0.10)
        Rectangle {
          anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
          width: parent.width * root.mediaProgress
          radius: 1
          color: Colors.primary
          Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.Linear } }
        }
      }
    }

    Column {
      id: expandedLayer
      anchors { fill: parent; margins: 18 }
      spacing: 12
      opacity: root.expanded ? 1 : 0
      visible: opacity > 0.01
      Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

      Row {
        width: parent.width
        height: 28
        spacing: 10
        Text {
          text: root.mode === "media" ? "Mídia" : root.mode === "recording" ? "Gravação" : root.mode === "notification" ? "Notificação" : "Strata"
          color: Colors.text0
          font { family: "Inter"; pixelSize: 15; weight: Font.DemiBold }
          width: parent.width - closeButton.width - 10
          elide: Text.ElideRight
          anchors.verticalCenter: parent.verticalCenter
        }
        Rectangle {
          id: closeButton
          width: 28
          height: 28
          radius: 14
          color: closeMouse.containsMouse ? Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, 0.10) : "transparent"
          Text {
            anchors.centerIn: parent
            text: "󰅖"
            color: Colors.text2
            font { family: "JetBrainsMono Nerd Font"; pixelSize: 13 }
          }
          MouseArea {
            id: closeMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expanded = false
          }
        }
      }

      Rectangle {
        width: parent.width
        height: 1
        color: Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, Colors.darkMode ? 0.07 : 0.12)
      }

      Column {
        width: parent.width
        spacing: 6
        Text {
          text: root.mode === "media" ? root.mediaTitle
            : root.mode === "recording" ? "Gravação de tela em andamento"
            : root.mode === "notification" ? root.notificationSummary
            : root.dateText
          width: parent.width
          elide: Text.ElideRight
          color: Colors.text0
          font { family: "Inter"; pixelSize: 14; weight: Font.DemiBold }
        }
        Text {
          text: root.mode === "media" ? root.mediaArtist
            : root.mode === "recording" ? ("Tempo decorrido: " + root.recordingElapsed)
            : root.mode === "notification" ? root.notificationApp
            : (root.vpnConnected ? root.vpnLabel : "Sem atividade prioritária")
          width: parent.width
          elide: Text.ElideRight
          color: Colors.text2
          font { family: "Inter"; pixelSize: 12 }
        }
      }

      Rectangle {
        width: parent.width
        height: 4
        radius: 2
        visible: root.mediaActive
        color: Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, 0.10)
        Rectangle {
          anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
          width: parent.width * root.mediaProgress
          radius: 2
          color: Colors.primary
        }
      }
    }

    MouseArea {
      anchors.fill: parent
      enabled: !root.expanded
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onEntered: root.hovered = true
      onExited: root.hovered = false
      onClicked: root.expanded = !root.expanded
    }
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      const now = new Date()
      root.timeText = Qt.formatDateTime(now, "hh:mm")
      root.dateText = Qt.formatDateTime(now, "dddd, dd 'de' MMMM")
    }
  }

  Process {
    id: mediaProc
    command: ["bash", "-c", "status=\"$(playerctl status 2>/dev/null || true)\"; title=\"$(playerctl metadata xesam:title 2>/dev/null || true)\"; artist=\"$(playerctl metadata xesam:artist 2>/dev/null || true)\"; pos=\"$(playerctl position 2>/dev/null || true)\"; len=\"$(playerctl metadata mpris:length 2>/dev/null || true)\"; printf '%s\\t%s\\t%s\\t%s\\t%s\\n' \"$status\" \"$title\" \"$artist\" \"$pos\" \"$len\""]
    stdout: StdioCollector {
      onStreamFinished: {
        const parts = this.text.trim().split("\t")
        root.mediaStatus = parts[0] || "Stopped"
        root.mediaTitle = parts[1] || ""
        root.mediaArtist = parts[2] || ""
        const pos = Number(parts[3] || 0)
        const len = Number(parts[4] || 0) / 1000000
        root.mediaProgress = len > 0 ? Math.max(0, Math.min(1, pos / len)) : 0
      }
    }
  }

  Process {
    id: recordingProc
    command: ["bash", Paths.scripts + "/screenrecord-status.sh"]
    stdout: StdioCollector {
      onStreamFinished: {
        const parts = this.text.trim().split("\t")
        root.recording = (parts[0] || "") === "recording"
        root.recordingElapsed = parts[1] || "--:--"
      }
    }
  }

  Process {
    id: vpnProc
    command: ["bash", Paths.scripts + "/protonvpn-status.sh"]
    stdout: StdioCollector {
      onStreamFinished: {
        const parts = this.text.trim().split("\t")
        root.vpnConnected = (parts[0] || "") === "connected"
        root.vpnLabel = parts[1] || "Proton VPN"
      }
    }
  }

  Process {
    id: notificationProc
    command: ["node", Paths.scripts + "/notification-history.js"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const items = JSON.parse(this.text.trim() || "[]")
          if (!items || items.length === 0) return
          const item = items[0]
          const id = Number(item.id || 0)
          if (id > 0 && id !== root.lastNotificationId) {
            root.lastNotificationId = id
            root.notificationApp = item.appName || "Sistema"
            root.notificationSummary = item.summary || item.body || ""
            if (root.notificationSummary !== "") {
              root.notificationFresh = true
              notificationFreshTimer.restart()
            }
          }
        } catch(e) {
        }
      }
    }
  }

  Timer {
    interval: 1200
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      mediaProc.running = true
      recordingProc.running = true
      vpnProc.running = true
    }
  }

  Timer {
    interval: 4000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: notificationProc.running = true
  }

  Timer {
    id: notificationFreshTimer
    interval: 4500
    onTriggered: root.notificationFresh = false
  }
}
