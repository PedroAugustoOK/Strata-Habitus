import Quickshell
import Quickshell.Io
import QtQuick
import "bar"
import "launcher"

ShellRoot {
  Bar {}

  Launcher { id: launcher }

  IpcHandler {
    target: "launcher"
    function toggle(): void { launcher.toggle() }
  }
}
