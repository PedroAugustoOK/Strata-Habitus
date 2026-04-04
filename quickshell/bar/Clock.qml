import QtQuick
import ".."

Text {
  id: clock
  color: Colors.text1
  font { pixelSize: 11; family: "JetBrainsMono Nerd Font" }
  verticalAlignment: Text.AlignVCenter

  function update() {
    var dias = ["Dom","Seg","Ter","Qua","Qui","Sex","Sáb"]
    var d  = new Date()
    var h  = ("0" + d.getHours()).slice(-2)
    var m  = ("0" + d.getMinutes()).slice(-2)
    var dia = dias[d.getDay()]
    var dd  = ("0" + d.getDate()).slice(-2)
    var mm  = ("0" + (d.getMonth() + 1)).slice(-2)
    clock.text = h + ":" + m + "  •  " + dia + " " + dd + "/" + mm
  }

  Timer {
    interval: 1000; running: true; repeat: true; triggeredOnStart: true
    onTriggered: clock.update()
  }
}
