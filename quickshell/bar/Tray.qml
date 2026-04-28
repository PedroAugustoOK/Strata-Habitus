import Quickshell
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
  id: trayPill
  height: 28
  radius: 14
  color:  Colors.bg2
  width:  trayRow.implicitWidth + 20
  visible: SystemTray.items.values.length > 0

  Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }

  RowLayout {
    id: trayRow
    anchors.centerIn: parent
    spacing: 8

    Repeater {
      model: SystemTray.items.values
      delegate: Item {
        required property SystemTrayItem modelData
        width: 16; height: 16
        readonly property string trayId: String(modelData.id || "").toLowerCase()
        readonly property string trayTitle: String(modelData.title || "").toLowerCase()
        readonly property string trayTooltip: String(modelData.tooltipTitle || "").toLowerCase()
        readonly property string trayIcon: String(modelData.icon || "")
        readonly property bool spotifyLike: trayId.includes("spotify")
                                         || trayTitle.includes("spotify")
                                         || trayTooltip.includes("spotify")
                                         || trayIcon.toLowerCase().includes("spotify")
        readonly property string resolvedIcon: spotifyLike
                                             ? "file:///run/current-system/sw/share/icons/hicolor/24x24/apps/spotify-client.png"
                                             : trayIcon

        Rectangle {
          anchors.centerIn: parent
          width: 20
          height: 20
          radius: 10
          color: Colors.darkMode ? "transparent" : Qt.rgba(0, 0, 0, 0.08)
          visible: !Colors.darkMode
        }

        Image {
          anchors.fill: parent
          source:       resolvedIcon
          smooth:       true
          fillMode:     Image.PreserveAspectFit
        }

        MouseArea {
          anchors.fill: parent
          cursorShape:  Qt.PointingHandCursor
          acceptedButtons: Qt.LeftButton | Qt.RightButton
          onClicked: function(m) {
            if (m.button === Qt.LeftButton) {
              TrayMenuState.close()
              modelData.activate()
            } else {
              const point = trayPill.mapToItem(null, trayRow.x + parent.x + width / 2, trayPill.height + 8)
              const label = modelData.tooltipTitle || modelData.title || modelData.id || "App"
              TrayMenuState.open(modelData, label, point.x, point.y)
            }
          }
        }
      }
    }
  }
}
