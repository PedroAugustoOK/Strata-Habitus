import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import Quickshell.Io
import ".."
PanelWindow {
  id: barRoot
  anchors { top: true; left: true; right: true }
  implicitHeight: 34
  exclusiveZone:  34
  color: Colors.bg1
  property bool screenRecording: false
  property string screenRecordingElapsed: "--:--"
  property bool protonVpnConnected: false
  property string protonVpnLabel: "Proton"
  property int pillAnimFast: 140
  property int pillAnimMedium: 180
  Item {
    id: leftZone
    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
    width:  wsPill.x - 6
    height: 34
    Rectangle {
      id: titlePill
      anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
      height: 28; radius: 14
      color:  Colors.bg2
      width:  winText.text !== "" ? winText.implicitWidth + 24 : 0
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
    SpotifyPlayer {
      id: spotify
      anchors.centerIn: parent
    }
  }
  Rectangle {
    id: wsPill
    anchors.centerIn: parent
    height: 28; radius: 14
    color:  Colors.bg2
    width:  ws.width + 20
    Behavior on width { NumberAnimation { duration: barRoot.pillAnimMedium; easing.type: Easing.OutCubic } }
    Workspaces {
      id: ws
      anchors.centerIn: parent
    }
  }
  Item {
    id: rightZone
    anchors {
      left:           wsPill.right
      leftMargin:     6
      right:          parent.right
      verticalCenter: parent.verticalCenter
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
        color:  Colors.bg2
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
        color:  Colors.bg2
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
      Rectangle {
        id: recordPill
        height: 28; radius: 14
        color: Qt.rgba(228 / 255, 104 / 255, 118 / 255, 0.16)
        border.width: 1
        border.color: Qt.rgba(228 / 255, 104 / 255, 118 / 255, 0.42)
        width: barRoot.screenRecording ? recordLabel.implicitWidth + 24 : 0
        opacity: barRoot.screenRecording ? 1 : 0
        scale: barRoot.screenRecording ? 1 : 0.92
        visible: width > 0 || opacity > 0.01
        clip: true
        Behavior on width { NumberAnimation { duration: barRoot.pillAnimMedium; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: barRoot.pillAnimFast; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: barRoot.pillAnimMedium; easing.type: Easing.OutCubic } }

        Text {
          id: recordLabel
          anchors.centerIn: parent
          text: "󰻃 " + barRoot.screenRecordingElapsed
          color: "#e46876"
          font { family: "JetBrainsMono Nerd Font"; pixelSize: 13 }
          verticalAlignment: Text.AlignVCenter
        }
      }
      Rectangle {
        id: protonVpnPill
        height: 28; radius: 14
        color: Colors.bg2
        border.width: 1
        border.color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.22)
        width: barRoot.protonVpnConnected ? vpnLabel.implicitWidth + 24 : 0
        opacity: barRoot.protonVpnConnected ? 1 : 0
        scale: barRoot.protonVpnConnected ? 1 : 0.92
        visible: width > 0 || opacity > 0.01
        clip: true
        Behavior on width { NumberAnimation { duration: barRoot.pillAnimMedium; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: barRoot.pillAnimFast; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: barRoot.pillAnimMedium; easing.type: Easing.OutCubic } }

        Text {
          id: vpnLabel
          anchors.centerIn: parent
          text: "󰌾 " + barRoot.protonVpnLabel
          color: Colors.accent
          font { family: "JetBrainsMono Nerd Font"; pixelSize: 13 }
          verticalAlignment: Text.AlignVCenter
        }
      }
      Tray {
        id: trayPill
        Behavior on width { NumberAnimation { duration: barRoot.pillAnimMedium; easing.type: Easing.OutCubic } }
      }
      Rectangle {
        id: statusPill
        height: 28; radius: 14
        color:  Colors.bg2
        width:  sr.implicitWidth + 24
        Behavior on width { NumberAnimation { duration: barRoot.pillAnimMedium; easing.type: Easing.OutCubic } }
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: ccToggle.running = true
        }
        StatusRight {
          id: sr
          anchors.centerIn: parent
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
