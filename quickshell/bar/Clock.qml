import QtQuick
import ".."

Row {
  id: root
  spacing: 5
  height: parent.height

  property string h: "00"
  property string m: "00"
  property string daydate: "Seg 13"

  Text {
    anchors.verticalCenter: parent.verticalCenter
    text: root.h
    color: Colors.secondary
    font { pixelSize: 13; family: "Roboto"; weight: Font.Bold }
  }

  Text {
    anchors.verticalCenter: parent.verticalCenter
    text: ":"
    color: Qt.rgba(Colors.secondary.r, Colors.secondary.g, Colors.secondary.b, 0.45)
    font { pixelSize: 11; family: "Roboto" }
  }

  Text {
    anchors.verticalCenter: parent.verticalCenter
    text: root.m
    color: Colors.secondary
    font { pixelSize: 13; family: "Roboto"; weight: Font.Bold }
  }

  Rectangle {
    width: 1; height: 14
    color: Colors.panelBorder
    anchors.verticalCenter: parent.verticalCenter
  }

  Text {
    anchors.verticalCenter: parent.verticalCenter
    text: root.daydate
    color: Colors.text3
    font { pixelSize: 10; family: "Roboto" }
  }

  Timer {
    interval: 1000; running: true; repeat: true; triggeredOnStart: true
    onTriggered: {
      var d = new Date()
      var dias = ["Dom","Seg","Ter","Qua","Qui","Sex","Sáb"]
      root.h       = ("0" + d.getHours()).slice(-2)
      root.m       = ("0" + d.getMinutes()).slice(-2)
      root.daydate = dias[d.getDay()] + " " + ("0" + d.getDate()).slice(-2)
    }
  }
}
