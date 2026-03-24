import QtQuick

Text {
  id: clock
  color: "#e0e0e0"
  font { pixelSize: 12; family: "JetBrainsMono Nerd Font" }

  function update() {
    var dias = ["Dom","Seg","Ter","Qua","Qui","Sex","Sáb"]
    var d = new Date()
    var h = ("0" + d.getHours()).slice(-2)
    var m = ("0" + d.getMinutes()).slice(-2)
    var dia = dias[d.getDay()]
    var dd = ("0" + d.getDate()).slice(-2)
    var mm = ("0" + (d.getMonth() + 1)).slice(-2)
    clock.text = h + ":" + m + "  •  " + dia + ", " + dd + "/" + mm
  }

  Timer {
    interval: 1000; running: true; repeat: true; triggeredOnStart: true
    onTriggered: clock.update()
  }
}
