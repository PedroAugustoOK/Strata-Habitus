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
  property string mediaDiscPath: ""
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
  property bool compactProgressVisible: mediaActive && mediaProgress > 0
  readonly property int childGap: 6
  readonly property int childSize: 24
  readonly property int childRailWidth: protonVpnConnected ? childSize + childGap : 0

  readonly property bool mediaActive: mediaStatus !== "Stopped" && mediaTitle !== ""
  readonly property string notificationIconSource: notificationIconPath === ""
    ? ""
    : notificationIconPath.indexOf("file://") === 0 ? notificationIconPath : "file://" + notificationIconPath
  readonly property string mediaArtSource: mediaArtPath === ""
    ? ""
    : mediaArtPath.indexOf("file://") === 0 ? mediaArtPath : "file://" + mediaArtPath
  readonly property string mediaDiscSource: mediaDiscPath === ""
    ? ""
    : mediaDiscPath.indexOf("file://") === 0 ? mediaDiscPath : "file://" + mediaDiscPath
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
    if (mode === "recording") return Math.max(118, recordLabel.implicitWidth + 42)
    if (mode === "media") return Math.min(398, Math.max(196, Math.min(246, Math.max(mediaTitleLabel.implicitWidth, mediaArtistLabel.implicitWidth)) + 112))
    return idleLabel.implicitWidth + 66
  }

  width: targetWidth + childRailWidth * 2
  height: 30

  Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

  function publishGeometry() {
    const point = surface.mapToItem(null, 0, 0)
    OverlayState.setIslandGeometry(point.x, point.y, surface.width, surface.height)
  }

  function publishIslandState() {
    DynamicIslandState.mediaStatus = mediaStatus
    DynamicIslandState.mediaTitle = mediaTitle
    DynamicIslandState.mediaArtist = mediaArtist
    DynamicIslandState.mediaProgress = mediaProgress
    DynamicIslandState.mediaArtPath = mediaArtPath
    DynamicIslandState.mediaDiscPath = mediaDiscPath
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

  function requestMediaPlayPause() {
    if (mediaStatus === "Playing") mediaStatus = "Paused"
    else if (mediaStatus === "Paused") mediaStatus = "Playing"
    publishIslandState()
    mediaPauseProc.running = true
    mediaRefreshAfterAction.restart()
  }

  function containsPoint(item, x, y) {
    const point = item.mapToItem(surface, 0, 0)
    return x >= point.x && x <= point.x + item.width && y >= point.y && y <= point.y + item.height
  }

  onXChanged: publishGeometry()
  onYChanged: publishGeometry()
  onWidthChanged: publishGeometry()
  onHeightChanged: publishGeometry()
  onMediaStatusChanged: publishIslandState()
  onMediaTitleChanged: {
    publishIslandState()
    if (mode === "media")
      mediaNudgeAnim.restart()
  }
  onMediaArtistChanged: publishIslandState()
  onMediaProgressChanged: publishIslandState()
  onMediaArtPathChanged: publishIslandState()
  onMediaDiscPathChanged: publishIslandState()
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
    modeMorphAnim.restart()
    if (DynamicIslandState.visible && DynamicIslandState.mode !== mode && mode !== "overlay")
      DynamicIslandState.close()
  }
  Component.onCompleted: {
    publishGeometry()
    publishIslandState()
  }

  Rectangle {
    id: surface
    anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter }
    width: root.targetWidth
    height: parent.height
    opacity: DynamicIslandState.visible ? 0 : 1
    radius: 15
    color: mode === "media"
      ? (root.hovered ? Qt.rgba(Colors.bg0.r, Colors.bg0.g, Colors.bg0.b, Colors.darkMode ? 0.96 : 0.90) : Qt.rgba(Colors.bg0.r, Colors.bg0.g, Colors.bg0.b, Colors.darkMode ? 0.88 : 0.82))
      : mode === "idle"
        ? (root.hovered ? Qt.rgba(Colors.barActive.r, Colors.barActive.g, Colors.barActive.b, Colors.darkMode ? 0.12 : 0.10) : Colors.barPill)
        : Qt.rgba(root.modeColor.r, root.modeColor.g, root.modeColor.b, root.hovered ? (Colors.darkMode ? 0.22 : 0.18) : (Colors.darkMode ? 0.16 : 0.13))
    border.width: mode === "idle" ? 0 : 1
    border.color: mode === "media"
      ? Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, Colors.darkMode ? 0.14 : 0.18)
      : Qt.rgba(root.modeColor.r, root.modeColor.g, root.modeColor.b, Colors.darkMode ? 0.34 : 0.28)
    clip: true
    transform: Scale {
      id: surfaceScale
      origin.x: surface.width / 2
      origin.y: surface.height / 2
      xScale: 1
      yScale: 1
    }

    Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }
    Behavior on border.color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 70; easing.type: Easing.OutQuad } }

    ParallelAnimation {
      id: modeMorphAnim
      NumberAnimation {
        target: surfaceScale
        property: "xScale"
        from: 0.78
        to: 1
        duration: 360
        easing.type: Easing.BezierSpline
        easing.bezierCurve: [0.23, 1, 0.61, 1, 1, 1]
      }
      NumberAnimation {
        target: surfaceScale
        property: "yScale"
        from: 1.22
        to: 1
        duration: 360
        easing.type: Easing.BezierSpline
        easing.bezierCurve: [0.23, 1, 0.61, 1, 1, 1]
      }
    }

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
        text: "REC " + root.screenRecordingElapsed
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
      spacing: 8
      opacity: root.mode === "media" ? 1 : 0
      visible: opacity > 0.01
      Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

      Item {
        anchors.verticalCenter: parent.verticalCenter
        width: 28
        height: 28
        rotation: 0

        Rectangle {
          anchors.fill: parent
          radius: width / 2
          color: Qt.rgba(0, 0, 0, Colors.darkMode ? 0.58 : 0.42)
        }

        Image {
          id: mediaDiscArt
          anchors.fill: parent
          source: root.mediaDiscSource
          fillMode: Image.PreserveAspectFit
          smooth: true
          visible: mediaDiscArt.status === Image.Ready
        }

        Rectangle {
          anchors.fill: parent
          radius: width / 2
          color: "transparent"
          border.width: 1
          border.color: Qt.rgba(Colors.text0.r, Colors.text0.g, Colors.text0.b, 0.14)
        }

        Rectangle {
          anchors.centerIn: parent
          width: 24
          height: 24
          radius: 12
          color: "transparent"
          border.width: 1
          border.color: Qt.rgba(Colors.text0.r, Colors.text0.g, Colors.text0.b, 0.10)
        }
        Rectangle {
          anchors.centerIn: parent
          width: 18
          height: 18
          radius: 9
          color: "transparent"
          border.width: 1
          border.color: Qt.rgba(Colors.text0.r, Colors.text0.g, Colors.text0.b, 0.07)
        }
        Rectangle {
          x: 8
          y: 5
          width: 4
          height: 4
          radius: 2
          color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.75)
        }
        Rectangle {
          anchors.centerIn: parent
          width: 9
          height: 9
          radius: 5
          color: Colors.bg0
          border.width: 1
          border.color: Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, 0.30)
        }

        NumberAnimation on rotation {
          running: root.mode === "media" && root.mediaStatus === "Playing"
          from: 0
          to: 360
          duration: 3200
          loops: Animation.Infinite
        }
      }

      Column {
        id: mediaTextCol
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1
        transform: Translate {
          id: mediaTextNudge
          x: 0
        }
        Text {
          id: mediaTitleLabel
          text: root.mediaTitle
          width: Math.min(246, implicitWidth)
          elide: Text.ElideRight
          color: Colors.text0
          font { family: "Inter"; pixelSize: 11; weight: Font.DemiBold }
        }
        Text {
          id: mediaArtistLabel
          text: root.mediaArtist
          visible: root.mediaArtist !== ""
          width: Math.min(246, implicitWidth)
          elide: Text.ElideRight
          color: Colors.text2
          font { family: "Inter"; pixelSize: 9 }
        }
        Rectangle {
          width: mediaTitleLabel.width
          height: 1
          radius: 1
          visible: root.compactProgressVisible
          color: Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, 0.08)
          Rectangle {
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            width: parent.width * root.mediaProgress
            radius: 1
            color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.42)
            Behavior on width { NumberAnimation { duration: 700; easing.type: Easing.Linear } }
          }
        }
      }

      Row {
        anchors.verticalCenter: parent.verticalCenter
        height: 18
        spacing: 2

        Repeater {
          model: [7, 12, 9, 15]
          delegate: Rectangle {
            required property int modelData
            required property int index
            anchors.verticalCenter: parent.verticalCenter
            width: 2
            height: root.mediaStatus === "Playing" ? Math.max(5, modelData - 2) : 5
            radius: 2
            color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, root.mediaStatus === "Playing" ? 0.78 : 0.36)
            opacity: root.mediaStatus === "Playing" ? 1 : 0.58

            SequentialAnimation on height {
              running: root.mode === "media" && root.mediaStatus === "Playing"
              loops: Animation.Infinite
              NumberAnimation { to: Math.max(5, modelData - 5); duration: 360 + index * 55; easing.type: Easing.InOutSine }
              NumberAnimation { to: modelData; duration: 420 + index * 45; easing.type: Easing.InOutSine }
            }
          }
        }
      }

      Rectangle {
        id: compactPlayButton
        anchors.verticalCenter: parent.verticalCenter
        width: 24
        height: 24
        radius: 12
        color: compactPlayMouse.containsMouse ? Qt.rgba(Colors.text0.r, Colors.text0.g, Colors.text0.b, 0.17) : Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, 0.08)
        Behavior on color { ColorAnimation { duration: 120; easing.type: Easing.OutCubic } }
        Text {
          anchors.centerIn: parent
          text: root.mediaStatus === "Playing" ? "󰏤" : "󰐊"
          color: Colors.text0
          font { family: "JetBrainsMono Nerd Font"; pixelSize: 11 }
        }
        MouseArea {
          id: compactPlayMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          acceptedButtons: Qt.LeftButton
          onClicked: function(mouse) {
            requestMediaPlayPause()
            mouse.accepted = true
          }
        }
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
          requestMediaPlayPause()
          return
        }
        if (root.mode === "media" && mouse.button === Qt.LeftButton && containsPoint(compactPlayButton, mouse.x, mouse.y)) {
          requestMediaPlayPause()
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
    }
  }

  Rectangle {
    id: vpnChildPill
    anchors { left: surface.right; leftMargin: root.childGap; verticalCenter: surface.verticalCenter }
    width: root.protonVpnConnected ? root.childSize : 0
    height: root.childSize
    radius: height / 2
    visible: width > 0 || opacity > 0.01
    opacity: root.protonVpnConnected ? 1 : 0
    scale: root.protonVpnConnected ? 1 : 0.78
    color: Qt.rgba(Colors.info.r, Colors.info.g, Colors.info.b, Colors.darkMode ? 0.18 : 0.14)
    border.width: 1
    border.color: Qt.rgba(Colors.info.r, Colors.info.g, Colors.info.b, Colors.darkMode ? 0.30 : 0.24)
    clip: true

    Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }

    Text {
      anchors.centerIn: parent
      text: "󰌾"
      color: Colors.info
      font { family: "JetBrainsMono Nerd Font"; pixelSize: 11 }
    }
  }

  SequentialAnimation {
    id: mediaNudgeAnim
    NumberAnimation {
      target: mediaTextNudge
      property: "x"
      from: 6
      to: 0
      duration: 260
      easing.type: Easing.BezierSpline
      easing.bezierCurve: [0.23, 1, 0.61, 1, 1, 1]
    }
  }

  Process {
    id: mediaProc
    command: ["bash", "-c", "status=\"$(playerctl -p spotify status 2>/dev/null || true)\"; title=\"$(playerctl -p spotify metadata xesam:title 2>/dev/null || true)\"; artist=\"$(playerctl -p spotify metadata xesam:artist 2>/dev/null || true)\"; pos=\"$(playerctl -p spotify position 2>/dev/null || true)\"; len=\"$(playerctl -p spotify metadata mpris:length 2>/dev/null || true)\"; art=\"$(playerctl -p spotify metadata mpris:artUrl 2>/dev/null || true)\"; art_path=\"\"; disc_path=\"\"; art_dir=\"${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/strata/spotify-art\"; if [[ \"$art\" == file://* && -f \"${art#file://}\" ]]; then art_path=\"${art#file://}\"; elif [[ \"$art\" =~ ^https?:// ]]; then ext=\"$(printf '%s' \"$art\" | sed -E 's/[?#].*$//' | sed -En 's/.*(\\.(jpg|jpeg|png|webp))$/\\1/p' | tr '[:upper:]' '[:lower:]')\"; [ -n \"$ext\" ] || ext=.jpg; candidate=\"$art_dir/$(printf '%s' \"$art\" | sha1sum | cut -d' ' -f1)$ext\"; [ -f \"$candidate\" ] && art_path=\"$candidate\"; fi; if [ -n \"$art_path\" ] && [ -f \"$art_path\" ]; then mkdir -p \"$art_dir\"; stamp=\"$(stat -c %Y \"$art_path\" 2>/dev/null || echo 0)\"; disc_path=\"$art_dir/$(printf '%s:%s' \"$art_path\" \"$stamp\" | sha1sum | cut -d' ' -f1).disc.png\"; if [ ! -f \"$disc_path\" ]; then if command -v magick >/dev/null 2>&1; then magick \"$art_path\" -resize 96x96^ -gravity center -extent 96x96 \\( -size 96x96 xc:none -fill white -draw 'circle 48,48 48,0' \\) -alpha off -compose CopyOpacity -composite \"$disc_path\" 2>/dev/null || disc_path=\"\"; elif command -v convert >/dev/null 2>&1; then convert \"$art_path\" -resize 96x96^ -gravity center -extent 96x96 \\( -size 96x96 xc:none -fill white -draw 'circle 48,48 48,0' \\) -alpha off -compose CopyOpacity -composite \"$disc_path\" 2>/dev/null || disc_path=\"\"; else disc_path=\"\"; fi; fi; fi; printf '%s\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\n' \"$status\" \"$title\" \"$artist\" \"$pos\" \"$len\" \"$art_path\" \"$disc_path\""]
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
        root.mediaDiscPath = parts[6] || ""
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
              publishIslandState()
              if (OverlayState.activeOverlay === "")
                DynamicIslandState.open("notification")
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
    id: mediaRefreshAfterAction
    interval: 120
    repeat: false
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
