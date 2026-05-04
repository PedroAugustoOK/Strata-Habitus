pragma Singleton
import QtQuick

QtObject {
  property bool visible: false
  property string mode: "media"

  property string mediaStatus: "Stopped"
  property string mediaTitle: ""
  property string mediaArtist: ""
  property real mediaProgress: 0

  property int notificationId: 0
  property string notificationApp: ""
  property string notificationSummary: ""
  property string notificationBody: ""
  property string notificationIconPath: ""
  property string notificationUrgency: "normal"

  property bool recording: false
  property string recordingElapsed: "--:--"

  readonly property string notificationIconSource: notificationIconPath === ""
    ? ""
    : notificationIconPath.indexOf("file://") === 0 ? notificationIconPath : "file://" + notificationIconPath

  function open(nextMode) {
    mode = nextMode || mode
    visible = true
  }

  function close() {
    visible = false
  }
}
