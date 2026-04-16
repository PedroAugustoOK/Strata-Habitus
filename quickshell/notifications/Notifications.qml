import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import ".."

PanelWindow {
  id: root
  anchors { top: true; right: true }
  implicitWidth: 360
  implicitHeight: Screen.height - 34
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

  Column {
    anchors { top: parent.top; right: parent.right }
    anchors.topMargin: 44
    anchors.rightMargin: 20
    spacing: 6

    Repeater {
      model: NotificationService.notifications
      delegate: Rectangle {
        required property Notification modelData

        width:   320
        height:  notifLayout.implicitHeight + 20
        radius:  14
        color:   Colors.bg1
        opacity: 1
        border.color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.15)
        border.width: 1

        Component.onCompleted: enterAnim.start()

        SequentialAnimation {
          id: enterAnim
          NumberAnimation { target: parent; property: "opacity"; from: 0; to: 1; duration: 200 }
        }

        SequentialAnimation {
          id: exitAnim
          NumberAnimation { target: parent; property: "opacity"; to: 0; duration: 160 }
          ScriptAction { script: modelData.dismiss() }
        }

        Timer {
          interval: modelData.expireTimeout > 0 ? modelData.expireTimeout : 5000
          running: true
          onTriggered: exitAnim.start()
        }

        // barra lateral accent
        Rectangle {
          anchors { left: parent.left; top: parent.top; bottom: parent.bottom; topMargin: 8; bottomMargin: 8 }
          width: 3; radius: 2; color: Colors.accent; opacity: 0.7
        }

        RowLayout {
          id: notifLayout
          anchors { left: parent.left; right: parent.right; top: parent.top }
          anchors.margins: 12
          anchors.leftMargin: 18
          spacing: 10

          // ícone
          Rectangle {
            width: 28; height: 28; radius: 7
            color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.1)
            Layout.alignment: Qt.AlignTop
            Text {
              anchors.centerIn: parent
              text: "󰇮"
              color: Colors.accent
              font { pixelSize: 14; family: "JetBrainsMono Nerd Font" }
            }
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
              text: modelData.appName
              color: Colors.accent
              font { pixelSize: 10; family: "Roboto"; weight: Font.Medium }
              Layout.fillWidth: true
              elide: Text.ElideRight
            }

            Text {
              text: modelData.summary
              color: Colors.text1
              font { pixelSize: 12; family: "Roboto"; weight: Font.DemiBold }
              Layout.fillWidth: true
              wrapMode: Text.WordWrap
            }

            Text {
              visible: modelData.body !== ""
              text: modelData.body
              color: Colors.text3
              font { pixelSize: 11; family: "Roboto" }
              Layout.fillWidth: true
              wrapMode: Text.WordWrap
              maximumLineCount: 2
              elide: Text.ElideRight
            }

            Row {
              visible: modelData.actions.length > 0
              spacing: 6
              Layout.topMargin: 4

              Repeater {
                model: modelData.actions
                delegate: Rectangle {
                  required property NotificationAction modelData
                  height: 22; radius: 6
                  width: actionText.implicitWidth + 16
                  color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.1)
                  Text {
                    id: actionText
                    anchors.centerIn: parent
                    text: modelData.identifier === "default" ? "Abrir" : modelData.text
                    color: Colors.accent
                    font { pixelSize: 10; family: "Roboto" }
                  }
                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { modelData.invoke(); exitAnim.start() }
                  }
                }
              }
            }
          }

          // fechar
          Text {
            text: "✕"
            color: Colors.text3
            font { pixelSize: 11 }
            Layout.alignment: Qt.AlignTop
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: exitAnim.start()
            }
          }
        }
      }
    }
  }
}
