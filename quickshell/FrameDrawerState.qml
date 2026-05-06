pragma Singleton
import QtQuick

QtObject {
  property bool launcherOpen: false
  property bool launcherVisible: false
  property real launcherOffsetScale: 1
  readonly property real launcherProgress: 1 - launcherOffsetScale
  property real launcherX: 0
  property real launcherY: 0
  property real launcherWidth: 0
  property real launcherHeight: 0
}
