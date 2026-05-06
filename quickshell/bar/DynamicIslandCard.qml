import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import ".."

PanelWindow {
  id: root
  anchors { top: true }
  implicitWidth: cardWidth
  implicitHeight: cardY + cardHeight
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: DynamicIslandState.mode === "notification" ? WlrKeyboardFocus.None : WlrKeyboardFocus.OnDemand
  focusable: DynamicIslandState.mode !== "notification"
  visible: DynamicIslandState.visible || closing
  mask: Region { item: cardInputRegion }

  readonly property real cardWidth: DynamicIslandState.mode === "media" ? 416 : 380
  readonly property real cardHeight: DynamicIslandState.mode === "media" ? 200
    : DynamicIslandState.mode === "notification" ? 104
    : 100
  readonly property real cardRadius: DynamicIslandState.mode === "media" ? 28 : 22
  readonly property real windowX: Math.max(0, (Screen.width - cardWidth) / 2)
  readonly property real cardX: 0
  readonly property real cardY: Math.max(4, OverlayState.islandY)
  readonly property real startX: OverlayState.islandWidth > 0 ? OverlayState.islandX - windowX : cardX + cardWidth / 2 - 120
  readonly property real startY: OverlayState.islandHeight > 0 ? OverlayState.islandY : cardY - 39
  readonly property real startWidth: Math.max(80, OverlayState.islandWidth)
  readonly property real startHeight: Math.max(30, OverlayState.islandHeight)
  readonly property real startRadius: startHeight / 2
  property real morphProgress: 0
  property bool closing: false

  function mix(from, to) {
    return from + (to - from) * morphProgress
  }

  function requestMediaAction(action) {
    if (action === "play-pause") {
      if (DynamicIslandState.mediaStatus === "Playing") DynamicIslandState.mediaStatus = "Paused"
      else if (DynamicIslandState.mediaStatus === "Paused") DynamicIslandState.mediaStatus = "Playing"
    }
    mediaActionProc.command = ["playerctl", "-p", "spotify", action]
    mediaActionProc.running = true
  }

  function close() {
    if (closing)
      return
    closing = true
    closeAnim.restart()
  }

  onVisibleChanged: {
    if (visible && DynamicIslandState.visible && !closing) {
      morphProgress = 0
      if (DynamicIslandState.mode !== "notification")
        keyGrabber.forceActiveFocus()
      openAnim.restart()
    }
  }

  Item {
    id: keyGrabber
    focus: root.visible
    Keys.onPressed: function(e) {
      if (e.key === Qt.Key_Escape) {
        root.close()
        e.accepted = true
      }
    }
  }

  Item {
    id: cardInputRegion
    x: card.x
    y: card.y
    width: card.width
    height: card.height
  }

  MouseArea {
    anchors.fill: card
    enabled: DynamicIslandState.mode !== "notification"
    onClicked: root.close()
  }

  Rectangle {
    id: card
    x: root.mix(root.startX, root.cardX)
    y: root.mix(root.startY, root.cardY)
    width: root.mix(root.startWidth, root.cardWidth)
    height: root.mix(root.startHeight, root.cardHeight)
    radius: root.mix(root.startRadius, root.cardRadius)
    color: DynamicIslandState.mode === "media"
      ? Qt.rgba(Colors.bg0.r, Colors.bg0.g, Colors.bg0.b, Colors.darkMode ? 0.96 : 0.90)
      : Qt.rgba(Colors.panelBackground.r, Colors.panelBackground.g, Colors.panelBackground.b, Colors.darkMode ? 0.98 : 0.96)
    border.width: 1
    border.color: Qt.rgba(modeTone.r, modeTone.g, modeTone.b, Colors.darkMode ? 0.32 : 0.26)
    opacity: root.visible ? 1 : 0
    clip: true

    readonly property color modeTone: DynamicIslandState.mode === "notification"
      ? (DynamicIslandState.notificationUrgency === "high" ? Colors.danger : Colors.warning)
      : DynamicIslandState.mode === "recording"
        ? Colors.danger
        : Colors.primary
    readonly property real compactOpacity: Math.max(0, Math.min(1, 1 - root.morphProgress / 0.42))
    readonly property real expandedOpacity: Math.max(0, Math.min(1, (root.morphProgress - 0.32) / 0.68))

    NumberAnimation {
      id: openAnim
      target: root
      property: "morphProgress"
      from: 0
      to: 1
      duration: 430
      easing.type: Easing.BezierSpline
      easing.bezierCurve: [0.23, 1, 0.61, 1, 1, 1]
    }

    NumberAnimation {
      id: closeAnim
      target: root
      property: "morphProgress"
      from: 1
      to: 0
      duration: 300
      easing.type: Easing.BezierSpline
      easing.bezierCurve: [0.23, 1, 0.61, 1, 1, 1]
      onFinished: {
        closing = false
        DynamicIslandState.close()
      }
    }

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.LeftButton | Qt.RightButton
    }

    Rectangle {
      anchors.fill: parent
      anchors.margins: 1
      radius: parent.radius - 1
      color: "transparent"
      border.width: 1
      border.color: Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, (Colors.darkMode ? 0.06 : 0.10) * root.morphProgress)
    }

    Row {
      id: compactMedia
      x: root.mix((card.width - implicitWidth) / 2, 16)
      y: root.mix((card.height - implicitHeight) / 2, 16)
      spacing: 8
      opacity: DynamicIslandState.mode === "media" ? card.compactOpacity : 0
      visible: opacity > 0.01
      scale: root.mix(1, 0.94)

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
          id: compactDiscArt
          anchors.fill: parent
          source: DynamicIslandState.mediaDiscSource
          fillMode: Image.PreserveAspectFit
          smooth: true
          visible: compactDiscArt.status === Image.Ready
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
          running: DynamicIslandState.mode === "media" && DynamicIslandState.mediaStatus === "Playing" && card.compactOpacity > 0
          from: 0
          to: 360
          duration: 3200
          loops: Animation.Infinite
        }
      }

      Column {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1
        Text {
          text: DynamicIslandState.mediaTitle
          width: Math.min(246, implicitWidth)
          elide: Text.ElideRight
          color: Colors.text0
          font { family: "Inter"; pixelSize: 11; weight: Font.DemiBold }
        }
        Text {
          text: DynamicIslandState.mediaArtist
          visible: DynamicIslandState.mediaArtist !== ""
          width: Math.min(246, implicitWidth)
          elide: Text.ElideRight
          color: Colors.text2
          font { family: "Inter"; pixelSize: 9 }
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
            height: DynamicIslandState.mediaStatus === "Playing" ? Math.max(5, modelData - 2) : 5
            radius: 2
            color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, DynamicIslandState.mediaStatus === "Playing" ? 0.78 : 0.36)
            opacity: DynamicIslandState.mediaStatus === "Playing" ? 1 : 0.58
            SequentialAnimation on height {
              running: DynamicIslandState.mode === "media" && DynamicIslandState.mediaStatus === "Playing" && card.compactOpacity > 0
              loops: Animation.Infinite
              NumberAnimation { to: Math.max(5, modelData - 5); duration: 360 + index * 55; easing.type: Easing.InOutSine }
              NumberAnimation { to: modelData; duration: 420 + index * 45; easing.type: Easing.InOutSine }
            }
          }
        }
      }

      Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 24
        height: 24
        radius: 12
        color: Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, 0.08)
        Text {
          anchors.centerIn: parent
          text: DynamicIslandState.mediaStatus === "Playing" ? "󰏤" : "󰐊"
          color: Colors.text0
          font { family: "JetBrainsMono Nerd Font"; pixelSize: 11 }
        }
      }
    }

    Row {
      x: root.mix((card.width - implicitWidth) / 2, 16)
      y: root.mix((card.height - implicitHeight) / 2, 16)
      spacing: 8
      opacity: DynamicIslandState.mode === "notification" ? card.compactOpacity : 0
      visible: opacity > 0.01
      scale: root.mix(1, 0.94)

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: DynamicIslandState.notificationUrgency === "high" ? "󰀪" : "󰂚"
        color: card.modeTone
        font { family: "JetBrainsMono Nerd Font"; pixelSize: 13 }
      }
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: DynamicIslandState.notificationSummary || DynamicIslandState.notificationBody || "Notificação"
        width: Math.min(280, implicitWidth)
        elide: Text.ElideRight
        color: Colors.text0
        font { family: "Inter"; pixelSize: 12; weight: Font.DemiBold }
      }
    }

    Row {
      x: root.mix((card.width - implicitWidth) / 2, 16)
      y: root.mix((card.height - implicitHeight) / 2, 16)
      spacing: 8
      opacity: DynamicIslandState.mode === "recording" ? card.compactOpacity : 0
      visible: opacity > 0.01
      scale: root.mix(1, 0.94)

      Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 7
        height: 7
        radius: 4
        color: Colors.danger
      }
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "Gravando " + DynamicIslandState.recordingElapsed
        color: Colors.text0
        font { family: "Inter"; pixelSize: 12; weight: Font.DemiBold }
      }
    }

    Column {
      anchors.fill: parent
      anchors.margins: 16
      spacing: DynamicIslandState.mode === "media" ? 7 : 10
      opacity: card.expandedOpacity
      visible: DynamicIslandState.mode !== "notification"
      transform: Translate {
        y: (1 - card.expandedOpacity) * 10
      }

      Row {
        width: parent.width
        height: DynamicIslandState.mode === "media" ? 84 : 40
        spacing: DynamicIslandState.mode === "media" ? 12 : 14

        Rectangle {
          id: artBox
          width: DynamicIslandState.mode === "media" ? 84 : 40
          height: width
          radius: DynamicIslandState.mode === "media" ? 22 : 20
          color: Qt.rgba(card.modeTone.r, card.modeTone.g, card.modeTone.b, 0.16)
          clip: true

          Image {
            id: artworkImage
            anchors.fill: parent
            anchors.margins: DynamicIslandState.mode === "media" ? 0 : 6
            source: DynamicIslandState.mode === "media"
              ? DynamicIslandState.mediaArtSource
              : DynamicIslandState.mode === "notification"
                ? DynamicIslandState.notificationIconSource
                : ""
            fillMode: DynamicIslandState.mode === "media" ? Image.PreserveAspectCrop : Image.PreserveAspectFit
            smooth: true
            visible: status === Image.Ready
          }
          Rectangle {
            anchors.fill: parent
            visible: DynamicIslandState.mode === "media" && artworkImage.status === Image.Ready
            gradient: Gradient {
              orientation: Gradient.Vertical
              GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.0) }
              GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.38) }
            }
          }
          Text {
            anchors.centerIn: parent
            visible: DynamicIslandState.mode === "media"
              ? artworkImage.status !== Image.Ready
              : DynamicIslandState.mode !== "notification" || artworkImage.status !== Image.Ready
            text: DynamicIslandState.mode === "media"
              ? "󰓇"
              : DynamicIslandState.mode === "notification"
                ? (DynamicIslandState.notificationUrgency === "high" ? "󰀪" : "󰂚")
                : "󰻃"
            color: card.modeTone
            font { family: "JetBrainsMono Nerd Font"; pixelSize: DynamicIslandState.mode === "media" ? 28 : 18 }
          }
          MouseArea {
            anchors.fill: parent
            enabled: DynamicIslandState.mode === "media"
            cursorShape: Qt.PointingHandCursor
            onClicked: focusSpotifyProc.running = true
          }
        }

        Column {
          width: parent.width - artBox.width - parent.spacing
          height: parent.height
          spacing: DynamicIslandState.mode === "media" ? 4 : 2

          Text {
            width: parent.width
            text: DynamicIslandState.mode === "media"
              ? (DynamicIslandState.mediaTitle || "Mídia")
              : DynamicIslandState.mode === "notification"
                ? (DynamicIslandState.notificationSummary || "Notificação")
                : "Gravação de tela"
            color: Colors.text0
            elide: Text.ElideRight
            maximumLineCount: DynamicIslandState.mode === "media" ? 2 : 1
            wrapMode: DynamicIslandState.mode === "media" ? Text.WordWrap : Text.NoWrap
            font { family: "Inter"; pixelSize: DynamicIslandState.mode === "media" ? 16 : 14; weight: Font.DemiBold }
          }
          Text {
            width: parent.width
            text: DynamicIslandState.mode === "media"
              ? (DynamicIslandState.mediaArtist || DynamicIslandState.mediaStatus)
              : DynamicIslandState.mode === "notification"
                ? (DynamicIslandState.notificationBody || DynamicIslandState.notificationApp || "Sistema")
                : ("Tempo decorrido: " + DynamicIslandState.recordingElapsed)
            color: Colors.text2
            elide: Text.ElideRight
            font { family: "Inter"; pixelSize: DynamicIslandState.mode === "media" ? 12 : 11 }
          }
          Rectangle {
            visible: DynamicIslandState.mode === "media"
            width: statusRow.implicitWidth + 16
            height: 24
            radius: 12
            color: Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, 0.07)
            Row {
              id: statusRow
              anchors.centerIn: parent
              spacing: 6
              Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 6
                height: 6
                radius: 3
                color: DynamicIslandState.mediaStatus === "Playing" ? Colors.success : Colors.warning
              }
              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: DynamicIslandState.mediaStatus === "Playing" ? "Tocando" : "Pausado"
                color: Colors.text0
                font { family: "Inter"; pixelSize: 11; weight: Font.DemiBold }
              }
            }
          }
        }
      }

      Rectangle {
        width: parent.width
        height: 4
        radius: 2
        visible: DynamicIslandState.mode === "media"
        color: Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, 0.11)
        Rectangle {
          anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
          width: parent.width * DynamicIslandState.mediaProgress
          radius: 2
          color: Colors.primary
          Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.Linear } }
        }
      }

      Row {
        width: parent.width
        height: 12
        visible: DynamicIslandState.mode === "media"
        Text {
          width: parent.width / 2
          text: DynamicIslandState.mediaPositionText
          color: Colors.text3
          font { family: "Inter"; pixelSize: 9; weight: Font.DemiBold }
        }
        Text {
          width: parent.width / 2
          horizontalAlignment: Text.AlignRight
          text: DynamicIslandState.mediaDurationText
          color: Colors.text3
          font { family: "Inter"; pixelSize: 9; weight: Font.DemiBold }
        }
      }

      Row {
        width: 146
        anchors.horizontalCenter: parent.horizontalCenter
        height: 44
        spacing: 10
        visible: DynamicIslandState.mode === "media"

        Repeater {
          model: [
            { icon: "󰒮", action: "previous" },
            { icon: DynamicIslandState.mediaStatus === "Playing" ? "󰏤" : "󰐊", action: "play-pause" },
            { icon: "󰒭", action: "next" }
          ]
          delegate: Rectangle {
            required property var modelData
            readonly property bool primary: modelData.action === "play-pause"
            width: primary ? 50 : 38
            height: primary ? 44 : 38
            anchors.verticalCenter: parent.verticalCenter
            radius: height / 2
            color: primary
              ? (actionMouse.containsMouse ? Qt.rgba(Colors.text0.r, Colors.text0.g, Colors.text0.b, 0.22) : Qt.rgba(Colors.text0.r, Colors.text0.g, Colors.text0.b, 0.14))
              : (actionMouse.containsMouse ? Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, 0.13) : Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, 0.07))
            Behavior on color { ColorAnimation { duration: 120; easing.type: Easing.OutCubic } }
            Text {
              anchors.centerIn: parent
              text: modelData.icon
              color: Colors.text0
              font { family: "JetBrainsMono Nerd Font"; pixelSize: parent.primary ? 18 : 15 }
            }
            MouseArea {
              id: actionMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                root.requestMediaAction(modelData.action)
              }
            }
          }
        }
      }

      Row {
        width: parent.width
        height: 34
        spacing: 8
        visible: DynamicIslandState.mode !== "media" && DynamicIslandState.mode !== "notification"

        Rectangle {
          width: parent.width
          height: 32
          radius: 12
          color: openMouse.containsMouse ? Qt.rgba(card.modeTone.r, card.modeTone.g, card.modeTone.b, 0.16) : Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, 0.05)
          Text {
            anchors.centerIn: parent
            text: DynamicIslandState.mode === "notification" ? "Abrir histórico" : "Abrir Central de Controle"
            color: Colors.text0
            font { family: "Inter"; pixelSize: 11; weight: Font.DemiBold }
          }
          MouseArea {
            id: openMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              root.close()
              controlCenterProc.running = true
            }
          }
        }
      }
    }

    Row {
      id: notificationCard
      anchors.fill: parent
      anchors.margins: 16
      spacing: 12
      opacity: DynamicIslandState.mode === "notification" ? card.expandedOpacity : 0
      visible: opacity > 0.01
      transform: Translate {
        y: (1 - card.expandedOpacity) * 8
      }

      Rectangle {
        id: notificationArtBox
        anchors.verticalCenter: parent.verticalCenter
        width: 42
        height: 42
        radius: 21
        color: Qt.rgba(card.modeTone.r, card.modeTone.g, card.modeTone.b, 0.14)
        clip: true

        Image {
          id: notificationExpandedIcon
          anchors.fill: parent
          anchors.margins: 7
          source: DynamicIslandState.notificationIconSource
          fillMode: Image.PreserveAspectFit
          smooth: true
          visible: status === Image.Ready
        }

        Text {
          anchors.centerIn: parent
          visible: DynamicIslandState.notificationIconPath === "" || notificationExpandedIcon.status !== Image.Ready
          text: DynamicIslandState.notificationUrgency === "high" ? "󰀪" : "󰂚"
          color: card.modeTone
          font { family: "JetBrainsMono Nerd Font"; pixelSize: 18 }
        }
      }

      Column {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - notificationArtBox.width - parent.spacing
        spacing: 3

        Row {
          width: parent.width
          height: 16
          spacing: 6

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: DynamicIslandState.notificationApp || "Sistema"
            width: Math.min(parent.width - 44, implicitWidth)
            elide: Text.ElideRight
            color: card.modeTone
            font { family: "Inter"; pixelSize: 10; weight: Font.DemiBold }
          }

          Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: DynamicIslandState.notificationUrgency === "high" ? urgencyText.implicitWidth + 12 : 0
            height: 16
            radius: 8
            visible: DynamicIslandState.notificationUrgency === "high"
            color: Qt.rgba(Colors.danger.r, Colors.danger.g, Colors.danger.b, 0.14)
            Text {
              id: urgencyText
              anchors.centerIn: parent
              text: "urgente"
              color: Colors.danger
              font { family: "Inter"; pixelSize: 9; weight: Font.DemiBold }
            }
          }
        }

        Text {
          width: parent.width
          text: DynamicIslandState.notificationSummary || "Notificação"
          color: Colors.text0
          elide: Text.ElideRight
          font { family: "Inter"; pixelSize: 14; weight: Font.DemiBold }
        }

        Text {
          width: parent.width
          text: DynamicIslandState.notificationBody
          visible: text !== ""
          color: Colors.text2
          elide: Text.ElideRight
          maximumLineCount: 2
          wrapMode: Text.WordWrap
          font { family: "Inter"; pixelSize: 11 }
        }
      }
    }

    MouseArea {
      anchors.fill: notificationCard
      enabled: DynamicIslandState.mode === "notification" && notificationCard.visible
      cursorShape: Qt.PointingHandCursor
      onClicked: root.close()
    }
  }

  Process { id: mediaActionProc; command: [] }
  Process { id: focusSpotifyProc; command: ["hyprctl", "dispatch", "focuswindow", "spotify"] }
  Process { id: controlCenterProc; command: ["quickshell", "ipc", "call", "controlcenter", "toggle"] }
}
