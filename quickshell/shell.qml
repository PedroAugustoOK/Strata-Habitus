import Quickshell
import Quickshell.Io
import QtQuick
import "bar"
import "launcher"
import "notifications"
import "osd"

ShellRoot {
  Bar {}
  Launcher { id: launcher }
  Notifications {}
  OSD { id: osd }

  IpcHandler {
    target: "launcher"
    function toggle(): void { launcher.toggle() }
  }
}
