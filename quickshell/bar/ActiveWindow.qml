import Quickshell.Io
import QtQuick

Text {
  id: winTitle
  color: "#888888"
  font { pixelSize: 11; family: "JetBrainsMono Nerd Font" }
  text: ""

  Process {
    id: titleProc
    command: ["/home/ankh/.config/quickshell/scripts/active-title.sh"]
    stdout: SplitParser {
      onRead: data => {
        var t = data.trim()
        winTitle.text = t.length > 40 ? t.substring(0, 37) + "…" : t
        winTitle.color = t === "" ? "transparent" : "#888888"
      }
    }
  }

  Timer {
    interval: 500; running: true; repeat: true; triggeredOnStart: true
    onTriggered: titleProc.running = true
  }
}
