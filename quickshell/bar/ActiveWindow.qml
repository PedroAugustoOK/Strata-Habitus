import Quickshell.Io
import QtQuick
import ".."

Text {
  id: winTitle
  color: Colors.text3
  font { pixelSize: 11; family: "Roboto" }
  text: ""

  Process {
    id: titleProc
    command: [Paths.scripts + "/active-title.sh"]
    stdout: SplitParser {
      onRead: data => {
        var t = data.trim()
        winTitle.text = t.length > 40 ? t.substring(0, 37) + "…" : t
        winTitle.color = t === "" ? "transparent" : Colors.text3
      }
    }
  }

  Timer {
    interval: 500; running: true; repeat: true; triggeredOnStart: true
    onTriggered: titleProc.running = true
  }
}
