import Quickshell.Io
import QtQuick
import ".."

Item {
  id: root

  property bool screenRecording: false
  property string screenRecordingElapsed: "--:--"
  property bool protonVpnConnected: false
  property string protonVpnLabel: "Proton"

  property string mediaStatus: "Stopped"
  property string mediaTitle: ""
  property string mediaArtist: ""
  property real mediaProgress: 0
  property string mediaArtPath: ""
  property string mediaPositionText: "--:--"
  property string mediaDurationText: "--:--"

  property int lastNotificationId: 0
  property string lastNotificationKey: ""
  property string notificationApp: ""
  property string notificationSummary: ""
  property string notificationBody: ""
  property string notificationIconPath: ""
  property string notificationUrgency: "normal"
  property bool notificationFresh: false
  property bool hovered: false

  readonly property bool mediaActive: mediaStatus !== "Stopped" && mediaTitle !== ""
  readonly property string notificationIconSource: notificationIconPath === ""
    ? ""
    : notificationIconPath.indexOf("file://") === 0 ? notificationIconPath : "file://" + notificationIconPath
  readonly property string mediaArtSource: mediaArtPath === ""
    ? ""
    : mediaArtPath.indexOf("file://") === 0 ? mediaArtPath : "file://" + mediaArtPath
  readonly property string mode: OverlayState.activeOverlay !== "" ? "overlay"
    : notificationFresh ? "notification"
    : screenRecording ? "recording"
    : mediaActive ? "media"
    : "idle"
  readonly property string overlayTitle: {
    if (OverlayState.activeOverlay === "launcher") return "Launcher"
    if (OverlayState.activeOverlay === "clipboard") return "Clipboard"
    if (OverlayState.activeOverlay === "controlcenter") return "Central de Controle"
    if (OverlayState.activeOverlay === "settingscenter") return "Configurações"
    if (OverlayState.activeOverlay === "appcenter") return "Central de Apps"
    if (OverlayState.activeOverlay === "updatecenter") return "Atualizações"
    if (OverlayState.activeOverlay === "themepicker") return "Tema"
    if (OverlayState.activeOverlay === "wallpickr") return "Wallpapers"
    return OverlayState.activeOverlay
  }
  readonly property color modeColor: {
    if (mode === "recording") return Colors.danger
    if (mode === "notification") return notificationUrgency === "high" ? Colors.danger : Colors.warning
    if (mode === "media") return Colors.primary
    if (mode === "overlay") return Colors.secondary
    return Colors.barActive
  }
  readonly property int targetWidth: {
    if (mode === "overlay") return Math.min(330, Math.max(168, overlayLabel.implicitWidth + 58))
    if (mode === "notification") return Math.min(470, Math.max(250, notificationTextCol.implicitWidth + 74))
    if (mode === "recording") return Math.max(170, recordLabel.implicitWidth + 44)
    if (mode === "media") return Math.min(430, Math.max(286, mediaTitleLabel.implicitWidth + 116))
    return idleLabel.implicitWidth + 66
  }

  width: targetWidth
  height: 30

  Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

  function publishGeometry() {
    const point = root.mapToItem(null, 0, 0)
    OverlayState.setIslandGeometry(point.x, point.y, root.width, root.height)
  }

  function publishIslandState() {
    DynamicIslandState.mediaStatus = mediaStatus
    DynamicIslandState.mediaTitle = mediaTitle
    DynamicIslandState.mediaArtist = mediaArtist
    DynamicIslandState.mediaProgress = mediaProgress
    DynamicIslandState.mediaArtPath = mediaArtPath
    DynamicIslandState.mediaPositionText = mediaPositionText
    DynamicIslandState.mediaDurationText = mediaDurationText
    DynamicIslandState.recording = screenRecording
    DynamicIslandState.recordingElapsed = screenRecordingElapsed
    DynamicIslandState.notificationId = lastNotificationId
    DynamicIslandState.notificationApp = notificationApp
    DynamicIslandState.notificationSummary = notificationSummary
    DynamicIslandState.notificationBody = notificationBody
    DynamicIslandState.notificationIconPath = notificationIconPath
    DynamicIslandState.notificationUrgency = notificationUrgency
  }

  function activeOverlayIpcTarget() {
    if (OverlayState.activeOverlay === "wallpickr") return "wallPickr"
    return OverlayState.activeOverlay
  }

  function toggleActiveOverlay() {
    const target = activeOverlayIpcTarget()
    if (target === "") return
    overlayToggleProc.command = ["quickshell", "ipc", "call", target, "toggle"]
    overlayToggleProc.running = true
  }

  onXChanged: publishGeometry()
  onYChanged: publishGeometry()
  onWidthChanged: publishGeometry()
  onHeightChanged: publishGeometry()
  onMediaStatusChanged: publishIslandState()
  onMediaTitleChanged: publishIslandState()
  onMediaArtistChanged: publishIslandState()
  onMediaProgressChanged: publishIslandState()
  onMediaArtPathChanged: publishIslandState()
  onMediaPositionTextChanged: publishIslandState()
  onMediaDurationTextChanged: publishIslandState()
  onScreenRecordingChanged: publishIslandState()
  onScreenRecordingElapsedChanged: publishIslandState()
  onNotificationAppChanged: publishIslandState()
  onNotificationSummaryChanged: publishIslandState()
  onNotificationBodyChanged: publishIslandState()
  onNotificationIconPathChanged: publishIslandState()
  onNotificationUrgencyChanged: publishIslandState()
  onModeChanged: {
    publishIslandState()
    if (DynamicIslandState.visible && DynamicIslandState.mode !== mode && mode !== "overlay")
      DynamicIslandState.close()
  }
  Component.onCompleted: {
    publishGeometry()
    publishIslandState()
  }

  Rectangle {
    id: surface
    anchors.fill: parent
    radius: 15
    color: mode === "idle"
      ? (root.hovered ? Qt.rgba(Colors.barActive.r, Colors.barActive.g, Colors.barActive.b, Colors.darkMode ? 0.12 : 0.10) : Colors.barPill)
      : Qt.rgba(root.modeColor.r, root.modeColor.g, root.modeColor.b, root.hovered ? (Colors.darkMode ? 0.22 : 0.18) : (Colors.darkMode ? 0.16 : 0.13))
    border.width: mode === "idle" ? 0 : 1
    border.color: Qt.rgba(root.modeColor.r, root.modeColor.g, root.modeColor.b, Colors.darkMode ? 0.34 : 0.28)
    clip: true

    Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }
    Behavior on border.color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }

    Row {
      anchors.centerIn: parent
      spacing: 8
      opacity: root.mode === "idle" ? 1 : 0
      visible: opacity > 0.01
      Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "󰣇"
        color: Colors.barActive
        font { family: "JetBrainsMono Nerd Font"; pixelSize: 13 }
      }
      Text {
        id: idleLabel
        anchors.verticalCenter: parent.verticalCenter
        text: "Strata"
        color: Colors.text0
        font { family: "Inter"; pixelSize: 12; weight: Font.DemiBold }
      }
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "󰅀"
        color: Colors.text3
        font { family: "JetBrainsMono Nerd Font"; pixelSize: 10 }
      }
    }

    Row {
      anchors.centerIn: parent
      spacing: 8
      opacity: root.mode === "overlay" ? 1 : 0
      visible: opacity > 0.01
      Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "󰕮"
        color: root.modeColor
        font { family: "JetBrainsMono Nerd Font"; pixelSize: 13 }
      }
      Text {
        id: overlayLabel
        anchors.verticalCenter: parent.verticalCenter
        text: root.overlayTitle
        color: Colors.text0
        font { family: "Inter"; pixelSize: 12; weight: Font.DemiBold }
        elide: Text.ElideRight
        width: Math.min(280, implicitWidth)
      }
    }

    Row {
      anchors.centerIn: parent
      spacing: 8
      opacity: root.mode === "recording" ? 1 : 0
      visible: opacity > 0.01
      Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

      Rectangle {
        width: 7
        height: 7
        radius: 4
        color: Colors.danger
        anchors.verticalCenter: parent.verticalCenter
        SequentialAnimation on opacity {
          running: root.screenRecording
          loops: Animation.Infinite
          NumberAnimation { to: 0.25; duration: 620; easing.type: Easing.InOutSine }
          NumberAnimation { to: 1.0; duration: 620; easing.type: Easing.InOutSine }
        }
      }
      Text {
        id: recordLabel
        anchors.verticalCenter: parent.verticalCenter
        text: "Gravando " + root.screenRecordingElapsed
        color: Colors.text0
        font { family: "Inter"; pixelSize: 12; weight: Font.DemiBold }
      }
    }

    Row {
      anchors.centerIn: parent
      spacing: 8
      opacity: root.mode === "notification" ? 1 : 0
      visible: opacity > 0.01
      Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

      Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 22
        height: 22
        radius: 11
        color: Qt.rgba(root.modeColor.r, root.modeColor.g, root.modeColor.b, 0.18)
        clip: true

        Image {
          id: notificationIcon
          anchors.fill: parent
          anchors.margins: 3
          source: root.notificationIconSource
          fillMode: Image.PreserveAspectFit
          smooth: true
          visible: status === Image.Ready
        }
        Text {
          anchors.centerIn: parent
          visible: root.notificationIconPath === "" || notificationIcon.status !== Image.Ready
          text: root.notificationUrgency === "high" ? "󰀪" : "󰂚"
          color: root.modeColor
          font { family: "JetBrainsMono Nerd Font"; pixelSize: 12 }
        }
      }

      Column {
        id: notificationTextCol
        anchors.verticalCenter: parent.verticalCenter
        spacing: -1

        Text {
          id: notificationAppLabel
          text: root.notificationApp || "Sistema"
          color: root.modeColor
          font { family: "Inter"; pixelSize: 10; weight: Font.DemiBold }
          elide: Text.ElideRight
          width: Math.min(120, implicitWidth)
        }
        Text {
          id: notificationLabel
          text: root.notificationSummary || root.notificationBody
          color: Colors.text0
          font { family: "Inter"; pixelSize: 11; weight: Font.DemiBold }
          elide: Text.ElideRight
          width: Math.min(315, implicitWidth)
        }
      }
    }

    Row {
      anchors.centerIn: parent
      spacing: 9
      opacity: root.mode === "media" ? 1 : 0
      visible: opacity > 0.01
      Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

      Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 22
        height: 22
        radius: 7
        color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.16)
        clip: true

        Image {
          id: mediaArt
          anchors.fill: parent
          source: root.mediaArtSource
          fillMode: Image.PreserveAspectCrop
          smooth: true
          visible: status === Image.Ready
        }

        Text {
          anchors.centerIn: parent
          visible: mediaArt.status !== Image.Ready
          text: "󰓇"
          color: Colors.primary
          font { family: "JetBrainsMono Nerd Font"; pixelSize: 12 }
        }
      }

      Column {
        anchors.verticalCenter: parent.verticalCenter
        spacing: -1
        Text {
          id: mediaTitleLabel
          text: root.mediaTitle
          width: Math.min(300, implicitWidth)
          elide: Text.ElideRight
          color: Colors.text0
          font { family: "Inter"; pixelSize: 11; weight: Font.DemiBold }
        }
        Text {
          text: root.mediaArtist
          visible: root.mediaArtist !== ""
          width: Math.min(300, implicitWidth)
          elide: Text.ElideRight
          color: Colors.text2
          font { family: "Inter"; pixelSize: 9 }
        }
      }

      Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 22
        height: 22
        radius: 11
        color: root.hovered ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.22) : Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, 0.08)
        Text {
          anchors.centerIn: parent
          text: root.mediaStatus === "Playing" ? "󰏤" : "󰐊"
          color: Colors.text0
          font { family: "JetBrainsMono Nerd Font"; pixelSize: 11 }
        }
      }
    }

    Rectangle {
      anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: 16; rightMargin: 16 }
      height: 2
      radius: 1
      visible: root.mode === "media"
      color: Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, 0.10)
      Rectangle {
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        width: parent.width * root.mediaProgress
        radius: 1
        color: Colors.primary
        Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.Linear } }
      }
    }

    Rectangle {
      anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
      width: 18
      height: 18
      radius: 9
      visible: root.protonVpnConnected && root.mode !== "recording"
      color: Qt.rgba(Colors.info.r, Colors.info.g, Colors.info.b, 0.14)
      Text {
        anchors.centerIn: parent
        text: "󰌾"
        color: Colors.info
        font { family: "JetBrainsMono Nerd Font"; pixelSize: 10 }
      }
    }

    MouseArea {
      id: islandMouse
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      hoverEnabled: true
      acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
      onEntered: root.hovered = true
      onExited: root.hovered = false
      onClicked: function(mouse) {
        if (mouse.button === Qt.MiddleButton) {
          settingsCenterProc.running = true
          return
        }
        if (root.mode === "overlay" && mouse.button === Qt.LeftButton) {
          toggleActiveOverlay()
          return
        }
        if (root.mode === "media" && mouse.button === Qt.RightButton) {
          mediaPauseProc.running = true
          return
        }
        if (root.mode === "notification" && mouse.button === Qt.RightButton) {
          root.notificationFresh = false
          if (root.lastNotificationId > 0) {
            notificationDismissProc.command = ["makoctl", "dismiss", "-n", String(root.lastNotificationId), "--no-history"]
            notificationDismissProc.running = true
          }
          return
        }
        if (mouse.button === Qt.RightButton) {
          controlCenterProc.running = true
          return
        }
        if (root.mode === "media") {
          publishIslandState()
          DynamicIslandState.open("media")
          return
        }
        if (root.mode === "notification") {
          publishIslandState()
          DynamicIslandState.open("notification")
          return
        }
        if (root.mode === "recording") {
          publishIslandState()
          DynamicIslandState.open("recording")
          return
        }
        launcherProc.running = true
      }
      onWheel: function(wheel) {
        if (root.mode !== "media") return
        if (wheel.angleDelta.y > 0) mediaNextProc.running = true
        else mediaPrevProc.running = true
      }
    }
  }

  Process {
    id: mediaProc
    command: ["bash", "-c", "status=\"$(playerctl -p spotify status 2>/dev/null || true)\"; title=\"$(playerctl -p spotify metadata xesam:title 2>/dev/null || true)\"; artist=\"$(playerctl -p spotify metadata xesam:artist 2>/dev/null || true)\"; pos=\"$(playerctl -p spotify position 2>/dev/null || true)\"; len=\"$(playerctl -p spotify metadata mpris:length 2>/dev/null || true)\"; art=\"$(playerctl -p spotify metadata mpris:artUrl 2>/dev/null || true)\"; art_path=\"\"; if [[ \"$art\" == file://* && -f \"${art#file://}\" ]]; then art_path=\"${art#file://}\"; elif [[ \"$art\" =~ ^https?:// ]]; then ext=\"$(printf '%s' \"$art\" | sed -E 's/[?#].*$//' | sed -En 's/.*(\\.(jpg|jpeg|png|webp))$/\\1/p' | tr '[:upper:]' '[:lower:]')\"; [ -n \"$ext\" ] || ext=.jpg; candidate=\"${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/strata/spotify-art/$(printf '%s' \"$art\" | sha1sum | cut -d' ' -f1)$ext\"; [ -f \"$candidate\" ] && art_path=\"$candidate\"; fi; printf '%s\\t%s\\t%s\\t%s\\t%s\\t%s\\n' \"$status\" \"$title\" \"$artist\" \"$pos\" \"$len\" \"$art_path\""]
    stdout: StdioCollector {
      onStreamFinished: {
        const parts = this.text.trim().split("\t")
        root.mediaStatus = parts[0] || "Stopped"
        root.mediaTitle = parts[1] || ""
        root.mediaArtist = parts[2] || ""
        const pos = Number(parts[3] || 0)
        const len = Number(parts[4] || 0) / 1000000
        root.mediaProgress = len > 0 ? Math.max(0, Math.min(1, pos / len)) : 0
        root.mediaArtPath = parts[5] || ""
        root.mediaPositionText = root.formatSeconds(pos)
        root.mediaDurationText = root.formatSeconds(len)
      }
    }
  }

  function formatSeconds(value) {
    const total = Math.max(0, Math.floor(Number(value || 0)))
    const minutes = Math.floor(total / 60)
    const seconds = total % 60
    return minutes + ":" + ("0" + seconds).slice(-2)
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
          const key = item.key || `${item.appName || ""}\u0000${item.summary || ""}\u0000${item.body || ""}`
          if ((id > 0 && id !== root.lastNotificationId) || (key !== "" && key !== root.lastNotificationKey)) {
            root.lastNotificationId = id
            root.lastNotificationKey = key
            root.notificationApp = item.appName || "Sistema"
            root.notificationSummary = item.summary || item.body || ""
            root.notificationBody = item.body || ""
            root.notificationIconPath = item.iconPath || ""
            root.notificationUrgency = item.urgency || "normal"
            publishIslandState()
            if (root.notificationSummary !== "") {
              root.notificationFresh = true
              notificationFreshTimer.restart()
            }
          }
        } catch(error) {
        }
      }
    }
  }

  Process { id: controlCenterProc; command: ["quickshell", "ipc", "call", "controlcenter", "toggle"] }
  Process { id: launcherProc; command: ["quickshell", "ipc", "call", "launcher", "toggle"] }
  Process { id: settingsCenterProc; command: ["quickshell", "ipc", "call", "settingscenter", "toggle"] }
  Process { id: overlayToggleProc; command: [] }
  Process { id: mediaPauseProc; command: ["playerctl", "-p", "spotify", "play-pause"] }
  Process { id: mediaNextProc; command: ["playerctl", "-p", "spotify", "next"] }
  Process { id: mediaPrevProc; command: ["playerctl", "-p", "spotify", "previous"] }
  Process { id: notificationDismissProc; command: [] }

  Timer {
    interval: 1200
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: mediaProc.running = true
  }

  Timer {
    interval: 900
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: notificationProc.running = true
  }

  Timer {
    id: notificationFreshTimer
    interval: root.notificationUrgency === "high" ? 9000 : 6500
    onTriggered: root.notificationFresh = false
  }
}
