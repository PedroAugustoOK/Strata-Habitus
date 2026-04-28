pragma Singleton
import Quickshell
import Quickshell.Services.Notifications
import QtQuick
QtObject {
  id: root
  property bool dnd: false
  property int nextHistoryId: 1
  property var history: []
  property NotificationServer server: NotificationServer {
    keepOnReload: true
    onNotification: notif => {
      if (!root.dnd) {
        notif.tracked = true
        root.pushHistory(notif)
      } else notif.dismiss()
    }
  }
  readonly property var notifications: server.trackedNotifications
  readonly property int historyCount: history.length

  function pushHistory(notif) {
    const entry = {
      id: root.nextHistoryId++,
      appName: notif.appName || "",
      summary: notif.summary || "",
      body: notif.body || "",
      expireTimeout: notif.expireTimeout || 0,
      actionsCount: notif.actions ? notif.actions.length : 0,
      notification: notif
    }

    root.history = [entry].concat(root.history)
  }

  function removeHistory(id) {
    root.history = root.history.filter(entry => entry.id !== id)
  }

  function dismissHistoryEntry(id) {
    const entry = root.history.find(item => item.id === id)
    if (entry && entry.notification && entry.notification.dismiss)
      entry.notification.dismiss()
    removeHistory(id)
  }

  function clearHistory() {
    root.history = []
  }

  function dismissAll() {
    for (var i = notifications.length - 1; i >= 0; i--)
      notifications[i].dismiss()
    clearHistory()
  }
}
