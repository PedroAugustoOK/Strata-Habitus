import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import ".."

PanelWindow {
  id: root
  anchors { top: true; left: true; right: true; bottom: true }
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
  focusable: true
  visible: TrayMenuState.visible

  readonly property real menuWidth: 196
  readonly property real menuX: Math.max(12, Math.min(width - menuWidth - 12, TrayMenuState.anchorX - menuWidth / 2))
  readonly property real menuY: Math.max(44, TrayMenuState.anchorY)

  function close() {
    TrayMenuState.close()
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

  onVisibleChanged: {
    if (visible)
      keyGrabber.forceActiveFocus()
  }

  MouseArea {
    anchors.fill: parent
    onClicked: root.close()
  }

  Rectangle {
    id: panel
    x: root.menuX
    y: root.menuY
    width: root.menuWidth
    height: menuColumn.implicitHeight + 16
    radius: 16
    color: Colors.bg1
    border.width: 1
    border.color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.18)

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
      border.color: Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, Colors.darkMode ? 0.07 : 0.10)
    }

    Column {
      id: menuColumn
      anchors.fill: parent
      anchors.margins: 8
      spacing: 4

      Text {
        width: parent.width
        text: TrayMenuState.label
        color: Colors.text3
        font { family: "JetBrains Mono"; pixelSize: 10 }
        elide: Text.ElideRight
      }

      Rectangle {
        width: parent.width
        height: 1
        color: Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, Colors.darkMode ? 0.08 : 0.12)
      }

      Rectangle {
        width: parent.width
        height: 34
        radius: 12
        color: nativeMouse.containsMouse ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.14) : "transparent"
        opacity: TrayMenuState.item && TrayMenuState.item.hasMenu ? 1 : 0.55

        Text {
          anchors.verticalCenter: parent.verticalCenter
          anchors.left: parent.left
          anchors.leftMargin: 12
          text: "Menu nativo"
          color: Colors.text1
          font { family: "JetBrains Mono"; pixelSize: 11 }
        }

        MouseArea {
          id: nativeMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: TrayMenuState.item && TrayMenuState.item.hasMenu ? Qt.PointingHandCursor : Qt.ArrowCursor
          onClicked: {
            if (TrayMenuState.item && TrayMenuState.item.hasMenu) {
              TrayMenuState.item.display(root, Math.round(TrayMenuState.anchorX), Math.round(TrayMenuState.anchorY))
              root.close()
            }
          }
        }
      }

      Rectangle {
        width: parent.width
        height: 34
        radius: 12
        color: killMouse.containsMouse ? Qt.rgba(0.86, 0.33, 0.33, 0.16) : "transparent"

        Text {
          anchors.verticalCenter: parent.verticalCenter
          anchors.left: parent.left
          anchors.leftMargin: 12
          text: "Encerrar app"
          color: "#e07a7a"
          font { family: "JetBrains Mono"; pixelSize: 11 }
        }

        MouseArea {
          id: killMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            if (TrayMenuState.item) {
              killProc.command = [
                "/run/current-system/sw/bin/bash",
                Paths.scripts + "/tray-kill.sh",
                TrayMenuState.item.id || "",
                TrayMenuState.item.title || "",
                TrayMenuState.item.tooltipTitle || ""
              ]
              killProc.running = true
            }
            root.close()
          }
        }
      }
    }
  }

  Process { id: killProc; command: [] }
}
