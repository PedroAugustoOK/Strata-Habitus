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

  readonly property real cardWidth: 380
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
    height: DynamicIslandState.mode === "media" ? 164
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
        spacing: 12

        Rectangle {
          width: 40
          height: 40
          radius: 20
          color: Qt.rgba(card.modeTone.r, card.modeTone.g, card.modeTone.b, 0.16)
          clip: true

          Image {
            id: notifImage
            anchors.fill: parent
            anchors.margins: 6
            source: DynamicIslandState.mode === "notification" ? DynamicIslandState.notificationIconSource : ""
            fillMode: Image.PreserveAspectFit
            smooth: true
            visible: status === Image.Ready
          }
          Text {
            anchors.centerIn: parent
            visible: DynamicIslandState.mode !== "notification" || notifImage.status !== Image.Ready
            text: DynamicIslandState.mode === "media"
              ? (DynamicIslandState.mediaStatus === "Playing" ? "󰏤" : "󰐊")
              : DynamicIslandState.mode === "notification"
                ? (DynamicIslandState.notificationUrgency === "high" ? "󰀪" : "󰂚")
                : "󰻃"
            color: card.modeTone
            font { family: "JetBrainsMono Nerd Font"; pixelSize: 18 }
          }
        }

        Column {
          width: parent.width - 52
          spacing: 2

          Text {
            width: parent.width
            text: DynamicIslandState.mode === "media"
              ? (DynamicIslandState.mediaTitle || "Mídia")
              : DynamicIslandState.mode === "notification"
                ? (DynamicIslandState.notificationSummary || "Notificação")
                : "Gravação de tela"
            color: Colors.text0
            elide: Text.ElideRight
            font { family: "Inter"; pixelSize: 14; weight: Font.DemiBold }
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
            font { family: "Inter"; pixelSize: 11 }
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
        height: 36
        spacing: 8
        visible: DynamicIslandState.mode === "media"

        Repeater {
          model: [
            { icon: "󰒮", action: "previous" },
            { icon: DynamicIslandState.mediaStatus === "Playing" ? "󰏤" : "󰐊", action: "play-pause" },
            { icon: "󰒭", action: "next" }
          ]
          delegate: Rectangle {
            required property var modelData
            width: (parent.width - 16) / 3
            height: 36
            radius: 14
            color: actionMouse.containsMouse ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.18) : Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, 0.06)
            Text {
              anchors.centerIn: parent
              text: modelData.icon
              color: Colors.text0
              font { family: "JetBrainsMono Nerd Font"; pixelSize: 15 }
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
  Process { id: controlCenterProc; command: ["quickshell", "ipc", "call", "controlcenter", "toggle"] }
}
