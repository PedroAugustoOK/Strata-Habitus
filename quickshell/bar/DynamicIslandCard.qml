import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import ".."

PanelWindow {
  id: root
  anchors { top: true; left: true; right: true; bottom: true }
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
  focusable: true
  visible: DynamicIslandState.visible

  readonly property real cardWidth: DynamicIslandState.mode === "media" ? 430 : 380
  readonly property real cardX: Math.max(12, Math.min(width - cardWidth - 12, OverlayState.islandCenterX - cardWidth / 2))
  readonly property real cardY: Math.max(44, OverlayState.islandY + OverlayState.islandHeight + 9)
  property bool opening: false

  function close() {
    DynamicIslandState.close()
  }

  onVisibleChanged: {
    if (visible) {
      opening = true
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

  MouseArea {
    anchors.fill: parent
    onClicked: root.close()
  }

  Rectangle {
    id: card
    x: root.cardX
    y: root.cardY
    width: root.cardWidth
    height: DynamicIslandState.mode === "media" ? 232
      : DynamicIslandState.mode === "notification" ? 154
      : 124
    radius: 22
    color: Qt.rgba(Colors.panelBackground.r, Colors.panelBackground.g, Colors.panelBackground.b, Colors.darkMode ? 0.98 : 0.96)
    border.width: 1
    border.color: Qt.rgba(modeTone.r, modeTone.g, modeTone.b, Colors.darkMode ? 0.32 : 0.26)
    opacity: root.opening ? 0 : 1
    clip: true
    transform: Scale {
      id: cardScale
      origin.x: Math.max(0, Math.min(card.width, OverlayState.islandCenterX - card.x))
      origin.y: 0
      xScale: root.opening ? 0.94 : 1
      yScale: root.opening ? 0.88 : 1
    }

    readonly property color modeTone: DynamicIslandState.mode === "notification"
      ? (DynamicIslandState.notificationUrgency === "high" ? Colors.danger : Colors.warning)
      : DynamicIslandState.mode === "recording"
        ? Colors.danger
        : Colors.primary

    Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

    ParallelAnimation {
      id: openAnim
      NumberAnimation { target: card; property: "opacity"; from: 0; to: 1; duration: 120; easing.type: Easing.OutQuad }
      NumberAnimation { target: cardScale; property: "xScale"; from: 0.94; to: 1; duration: 210; easing.type: Easing.OutCubic }
      NumberAnimation { target: cardScale; property: "yScale"; from: 0.88; to: 1; duration: 210; easing.type: Easing.OutCubic }
      onFinished: root.opening = false
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
      border.color: Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, Colors.darkMode ? 0.06 : 0.10)
    }

    Column {
      anchors.fill: parent
      anchors.margins: 16
      spacing: 14

      Row {
        width: parent.width
        height: DynamicIslandState.mode === "media" ? 96 : 40
        spacing: 14

        Rectangle {
          id: artBox
          width: DynamicIslandState.mode === "media" ? 96 : 40
          height: width
          radius: DynamicIslandState.mode === "media" ? 20 : 20
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
              GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.30) }
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
          width: parent.width - artBox.width - 14
          height: parent.height
          spacing: DynamicIslandState.mode === "media" ? 6 : 2

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
            font { family: "Inter"; pixelSize: DynamicIslandState.mode === "media" ? 18 : 14; weight: Font.DemiBold }
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
            width: statusRow.implicitWidth + 18
            height: 26
            radius: 13
            color: Qt.rgba(card.modeTone.r, card.modeTone.g, card.modeTone.b, 0.14)
            Row {
              id: statusRow
              anchors.centerIn: parent
              spacing: 7
              Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 7
                height: 7
                radius: 4
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
        color: Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, 0.10)
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
        height: 14
        visible: DynamicIslandState.mode === "media"
        Text {
          width: parent.width / 2
          text: DynamicIslandState.mediaPositionText
          color: Colors.text3
          font { family: "Inter"; pixelSize: 10; weight: Font.DemiBold }
        }
        Text {
          width: parent.width / 2
          horizontalAlignment: Text.AlignRight
          text: DynamicIslandState.mediaDurationText
          color: Colors.text3
          font { family: "Inter"; pixelSize: 10; weight: Font.DemiBold }
        }
      }

      Row {
        width: parent.width
        height: 42
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
            width: (parent.width - 20) / 3
            height: 42
            radius: 16
            color: primary
              ? (actionMouse.containsMouse ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.34) : Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.24))
              : (actionMouse.containsMouse ? Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, 0.12) : Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, 0.06))
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
                mediaActionProc.command = ["playerctl", "-p", "spotify", modelData.action]
                mediaActionProc.running = true
              }
            }
          }
        }
      }

      Row {
        width: parent.width
        height: 34
        spacing: 8
        visible: DynamicIslandState.mode !== "media"

        Rectangle {
          width: parent.width
          height: 34
          radius: 13
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
  }

  Process { id: mediaActionProc; command: [] }
  Process { id: focusSpotifyProc; command: ["hyprctl", "dispatch", "focuswindow", "spotify"] }
  Process { id: controlCenterProc; command: ["quickshell", "ipc", "call", "controlcenter", "toggle"] }
}
