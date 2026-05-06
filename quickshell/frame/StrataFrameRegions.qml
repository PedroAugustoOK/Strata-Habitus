import Quickshell
import QtQuick
import ".."

Region {
  id: root

  property int barHeight: 34
  property int thickness: 12
  property var win

  Region {
    x: 0
    y: root.barHeight
    width: root.thickness
    height: Math.max(0, root.win ? root.win.height - root.barHeight : 0)
  }

  Region {
    x: Math.max(0, root.win ? root.win.width - root.thickness : 0)
    y: root.barHeight
    width: root.thickness
    height: Math.max(0, root.win ? root.win.height - root.barHeight : 0)
  }

  Region {
    x: 0
    y: Math.max(0, root.win ? root.win.height - root.thickness : 0)
    width: root.win ? root.win.width : 0
    height: root.thickness
  }

}
