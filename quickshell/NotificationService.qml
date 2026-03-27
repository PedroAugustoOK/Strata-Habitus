pragma Singleton
import Quickshell
import Quickshell.Services.Notifications
import QtQuick

QtObject {
  id: root

  property bool dnd: false

  property var server: NotificationServer {
    keepOnReload: true
    onNotification: notif => {
      if (!root.dnd) notif.tracked = true
      else notif.dismiss()
    }
  }

  readonly property var notifications: server.trackedNotifications

  function dismissAll() {
    for (var i = notifications.length - 1; i >= 0; i--)
      notifications[i].dismiss()
  }
}
