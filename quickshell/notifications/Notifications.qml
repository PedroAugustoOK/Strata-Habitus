import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts

PanelWindow {
  anchors { top: true; right: true }
  implicitWidth: server.trackedNotifications.length > 0 ? 340 : 0
  implicitHeight: server.trackedNotifications.length > 0 ? 500 : 0
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

  NotificationServer {
    id: server
    keepOnReload: true
    onNotification: notif => {
      notif.tracked = true
    }
  }

  Column {
    anchors { top: parent.top; right: parent.right }
    anchors.topMargin: 42
    anchors.rightMargin: 10
    spacing: 6

    Repeater {
      model: server.trackedNotifications
      delegate: Rectangle {
        required property Notification modelData
        width: 320
        height: notifContent.implicitHeight + 20
        radius: 10
        color: "#111113"
        border.color: "#cf9fff33"
        border.width: 1

        Timer {
          interval: modelData.expireTimeout > 0 ? modelData.expireTimeout : 5000
          running: true
          onTriggered: modelData.dismiss()
        }

        Column {
          id: notifContent
          anchors { left: parent.left; right: parent.right; top: parent.top }
          anchors.margins: 12
          spacing: 4

          RowLayout {
            width: parent.width
            Text {
              text: modelData.appName
              color: "#cf9fff"
              font.pixelSize: 10
              font.family: "JetBrainsMono Nerd Font"
              Layout.fillWidth: true
            }
            Text {
              text: "✕"
              color: "#555"
              font.pixelSize: 11
              MouseArea {
                anchors.fill: parent
                onClicked: modelData.dismiss()
              }
            }
          }

          Text {
            text: modelData.summary
            color: "#e0e0e0"
            font.pixelSize: 12
            font.family: "JetBrainsMono Nerd Font"
            width: parent.width
            wrapMode: Text.WordWrap
          }

          Text {
            visible: modelData.body !== ""
            text: modelData.body
            color: "#888"
            font.pixelSize: 11
            font.family: "JetBrainsMono Nerd Font"
            width: parent.width
            wrapMode: Text.WordWrap
          }
        }
      }
    }
  }
}
