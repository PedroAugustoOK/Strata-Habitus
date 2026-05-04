import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import Quickshell.Io
import ".."
PanelWindow {
  id: barRoot
  anchors { top: true; left: true; right: true }
  implicitHeight: 40
  exclusiveZone:  34
  color: "transparent"
  property bool screenRecording: false
  property string screenRecordingElapsed: "--:--"
  property bool protonVpnConnected: false
  property string protonVpnLabel: "Proton"
  property int pillAnimFast: 140
  property int pillAnimMedium: 180
  Rectangle {
    id: barSurface
    anchors { top: parent.top; left: parent.left; right: parent.right }
    height: 34
    color: Colors.barBackground
  }
  Rectangle {
    id: barHairline
    anchors { left: parent.left; right: parent.right; top: barSurface.bottom }
    height: 1
    color: Qt.rgba(0, 0, 0, Colors.darkMode ? 0.18 : 0.08)
  }
  Rectangle {
    id: barShadow
    anchors { left: parent.left; right: parent.right; top: barHairline.bottom }
    height: 4
    gradient: Gradient {
      orientation: Gradient.Vertical
      GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, Colors.darkMode ? 0.12 : 0.05) }
      GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.0) }
    }
  }
  Item {
    id: leftZone
    anchors { left: parent.left; verticalCenter: barSurface.verticalCenter }
    width:  dynamicPill.x - 6
    height: 34
    Rectangle {
      id: titlePill
      anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
      height: 28; radius: 14
      color: Colors.barPill
      width:  winText.text !== "" ? Math.min(winText.implicitWidth + 24, Math.max(0, wsPill.x - 20)) : 0
      opacity: winText.text !== "" ? 1 : 0
      scale: winText.text !== "" ? 1 : 0.96
      visible: width > 0 || opacity > 0.01
      clip: true
      Behavior on width { NumberAnimation { duration: barRoot.pillAnimMedium; easing.type: Easing.OutCubic } }
      Behavior on opacity { NumberAnimation { duration: barRoot.pillAnimFast; easing.type: Easing.OutCubic } }
      Behavior on scale { NumberAnimation { duration: barRoot.pillAnimMedium; easing.type: Easing.OutCubic } }
      ActiveWindow {
        id: winText
        anchors.centerIn: parent
      }
    }
    Rectangle {
      id: wsPill
      anchors { right: parent.right; rightMargin: 0; verticalCenter: parent.verticalCenter }
      height: 28
      radius: 14
      color: Colors.barPill
      width: workspaces.width + 20
      clip: true
      Behavior on width { NumberAnimation { duration: barRoot.pillAnimMedium; easing.type: Easing.OutCubic } }

      Workspaces {
        id: workspaces
        anchors.centerIn: parent
      }
    }
  }
  DynamicPill {
    id: dynamicPill
    anchors.centerIn: barSurface
    screenRecording: barRoot.screenRecording
    screenRecordingElapsed: barRoot.screenRecordingElapsed
    protonVpnConnected: barRoot.protonVpnConnected
    protonVpnLabel: barRoot.protonVpnLabel
  }
  Item {
    id: rightZone
    anchors {
      left:           dynamicPill.right
      leftMargin:     6
      right:          parent.right
      verticalCenter: barSurface.verticalCenter
    }
    height: 34
    Row {
      id: infoRow
      y: (parent.height - height) / 2
      x: {
        const ideal = (rightZone.width - infoRow.width) / 2
        const limit = edgeRow.x - infoRow.width - 6
        return Math.max(0, Math.min(ideal, limit))
      }
      spacing: 6
      Behavior on x { NumberAnimation { duration: barRoot.pillAnimMedium; easing.type: Easing.OutCubic } }
      Behavior on width { NumberAnimation { duration: barRoot.pillAnimMedium; easing.type: Easing.OutCubic } }
      Rectangle {
        id: statsPill
        height: 28; radius: 14
        color: Colors.barPill
        width:  stats.implicitWidth + 24
        Behavior on width { NumberAnimation { duration: barRoot.pillAnimMedium; easing.type: Easing.OutCubic } }
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: btopProc.running = true
        }
        Process {
          id: btopProc
          command: ["kitty", "--title", "btop", "--override", "window_padding_width=0", "btop"]
        }
        SysStats {
          id: stats
          anchors.centerIn: parent
        }
      }
      Rectangle {
        id: clockPill
        height: 28; radius: 14
        color: Colors.barPill
        width:  clk.implicitWidth + 24
        Behavior on width { NumberAnimation { duration: barRoot.pillAnimMedium; easing.type: Easing.OutCubic } }
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            const point = clockPill.mapToItem(null, clockPill.width / 2, clockPill.height + 8)
            CalendarMenuState.toggle(point.x, point.y)
          }
        }
        Clock {
          id: clk
          anchors.centerIn: parent
        }
      }
    }
    Row {
      id: edgeRow
      anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
      spacing: 6
      Behavior on x { NumberAnimation { duration: barRoot.pillAnimMedium; easing.type: Easing.OutCubic } }
      Behavior on width { NumberAnimation { duration: barRoot.pillAnimMedium; easing.type: Easing.OutCubic } }
      Tray {
        id: trayPill
        Behavior on width { NumberAnimation { duration: barRoot.pillAnimMedium; easing.type: Easing.OutCubic } }
      }
      Rectangle {
        id: statusPill
        height: 28; radius: 14
        color: Colors.barPill
        readonly property bool hasTransientIndicators: SystemState.dnd || SystemState.caffeine
        width:  sr.implicitWidth + 24 + (hasTransientIndicators ? transientRow.implicitWidth + 10 : 0)
        Behavior on width { NumberAnimation { duration: barRoot.pillAnimMedium; easing.type: Easing.OutCubic } }
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: ccToggle.running = true
        }
        Row {
          id: transientRow
          anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
          spacing: 6
          visible: statusPill.hasTransientIndicators

          Text {
            visible: SystemState.dnd
            text: "󰂛"
            color: Colors.secondary
            font { family: "JetBrainsMono Nerd Font"; pixelSize: 13 }
            verticalAlignment: Text.AlignVCenter
          }
          Item {
            visible: SystemState.caffeine
            width: 13
            height: 16

            Text {
              anchors.centerIn: parent
              anchors.verticalCenterOffset: 1
              text: "󰅶"
              color: Colors.warning
              font { family: "JetBrainsMono Nerd Font"; pixelSize: 13 }
            }
          }
        }
        StatusRight {
          id: sr
          anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
        }
      }
    }
  }
  Process {
    id: screenrecordProc
    command: ["bash", Paths.scripts + "/screenrecord-status.sh"]
    stdout: SplitParser {
      onRead: data => {
        const parts = data.trim().split("\t")
        barRoot.screenRecording = (parts[0] || "") === "recording"
        barRoot.screenRecordingElapsed = parts[1] || "--:--"
      }
    }
  }
  Process {
    id: protonVpnProc
    command: ["bash", Paths.scripts + "/protonvpn-status.sh"]
    stdout: SplitParser {
      onRead: data => {
        const parts = data.trim().split("\t")
        barRoot.protonVpnConnected = (parts[0] || "") === "connected"
        barRoot.protonVpnLabel = "Proton"
      }
    }
  }
  Timer {
    interval: 1000; running: true; repeat: true; triggeredOnStart: true
    onTriggered: {
      screenrecordProc.running = true
      protonVpnProc.running = true
    }
  }
  Process { id: ccToggle; command: ["quickshell", "ipc", "call", "controlcenter", "toggle"] }
}
