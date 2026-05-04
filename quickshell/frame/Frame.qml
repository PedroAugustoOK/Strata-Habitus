import Quickshell
import Quickshell.Wayland
import QtQuick
import ".."

Item {
  PanelWindow {
    anchors { top: true; left: true; bottom: true }
    implicitWidth: 12
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    Rectangle {
      x: 0
      y: 34
      width: 4
      height: parent.height - y
      color: Qt.rgba(Colors.barBackground.r, Colors.barBackground.g, Colors.barBackground.b, Colors.darkMode ? 0.70 : 0.62)
    }
    Rectangle {
      x: 4
      y: 34
      width: 1
      height: parent.height - y
      color: Qt.rgba(Colors.panelBorder.r, Colors.panelBorder.g, Colors.panelBorder.b, Colors.darkMode ? 0.65 : 0.80)
    }
    Rectangle {
      x: 5
      y: 34
      width: 7
      height: parent.height - y
      gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, Colors.darkMode ? 0.20 : 0.08) }
        GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.0) }
      }
    }
  }

  PanelWindow {
    anchors { top: true; right: true; bottom: true }
    implicitWidth: 12
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    Rectangle {
      x: parent.width - 4
      y: 34
      width: 4
      height: parent.height - y
      color: Qt.rgba(Colors.barBackground.r, Colors.barBackground.g, Colors.barBackground.b, Colors.darkMode ? 0.70 : 0.62)
    }
    Rectangle {
      x: parent.width - 5
      y: 34
      width: 1
      height: parent.height - y
      color: Qt.rgba(Colors.panelBorder.r, Colors.panelBorder.g, Colors.panelBorder.b, Colors.darkMode ? 0.65 : 0.80)
    }
    Rectangle {
      x: 0
      y: 34
      width: 7
      height: parent.height - y
      gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.0) }
        GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, Colors.darkMode ? 0.20 : 0.08) }
      }
    }
  }

  PanelWindow {
    anchors { left: true; right: true; bottom: true }
    implicitHeight: 12
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    Rectangle {
      anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
      height: 4
      color: Qt.rgba(Colors.barBackground.r, Colors.barBackground.g, Colors.barBackground.b, Colors.darkMode ? 0.70 : 0.62)
    }
    Rectangle {
      anchors { left: parent.left; right: parent.right; bottom: parent.bottom; bottomMargin: 4 }
      height: 1
      color: Qt.rgba(Colors.panelBorder.r, Colors.panelBorder.g, Colors.panelBorder.b, Colors.darkMode ? 0.65 : 0.80)
    }
    Rectangle {
      anchors { left: parent.left; right: parent.right; bottom: parent.bottom; bottomMargin: 5 }
      height: 7
      gradient: Gradient {
        orientation: Gradient.Vertical
        GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.0) }
        GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, Colors.darkMode ? 0.20 : 0.08) }
      }
    }
  }
}
