import Quickshell
import Quickshell.Wayland
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

  // Borda esquerda
  PanelWindow {
    anchors { top: true; left: true; bottom: true }
    implicitWidth: 3
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    Rectangle {
      anchors { top: parent.top; bottom: parent.bottom; right: parent.right }
      anchors.topMargin: 34
      width: 1
      color: "#ffffff18"
    }
  }

  // Borda direita
  PanelWindow {
    anchors { top: true; right: true; bottom: true }
    implicitWidth: 3
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    Rectangle {
      anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
      anchors.topMargin: 34
      width: 1
      color: "#ffffff18"
    }
  }

  // Borda inferior
  PanelWindow {
    anchors { left: true; right: true; bottom: true }
    implicitHeight: 3
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    Rectangle {
      anchors { left: parent.left; right: parent.right; top: parent.top }
      height: 1
      color: "#ffffff18"
    }
  }

  IpcHandler {
    target: "launcher"
    function toggle(): void { launcher.toggle() }
  }
}
