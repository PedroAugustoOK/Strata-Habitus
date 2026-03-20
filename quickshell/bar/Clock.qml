import QtQuick

Text {
  id: clock
  color: "#e0e0e0"
  font.pixelSize: 12
  font.family: "JetBrainsMono Nerd Font"

  Timer {
    interval: 1000; running: true; repeat: true; triggeredOnStart: true
    onTriggered: clock.text = Qt.formatTime(new Date(), "hh:mm")
  }
}
