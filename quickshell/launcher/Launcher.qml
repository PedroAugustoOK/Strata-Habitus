import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

PanelWindow {
  id: launcher
  visible: false
  anchors { top: true; bottom: true; left: true; right: true }
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  color: "transparent"

  property var results: []
  property int selected: 0

  function toggle() {
    visible = !visible
    if (visible) {
      searchInput.text = ""
      searchInput.forceActiveFocus()
    }
  }

  function search(q) {
    results = []
    if (q.length === 0) return
    searchProc.command = ["sh", "-c", `compgen -c | sort -u | grep -i '${q}' | head -8`]
    searchProc.running = true
  }

  function launch() {
    if (results.length === 0) return
    runProc.command = ["sh", "-c", results[selected] + " &"]
    runProc.running = true
    close()
  }

  function close() {
    visible = false
    searchInput.text = ""
    results = []
    selected = 0
  }

  MouseArea {
    anchors.fill: parent
    onClicked: launcher.close()
  }

  Rectangle {
    id: box
    width: 480
    height: contentCol.implicitHeight + 24
    anchors.centerIn: parent
    anchors.verticalCenterOffset: -80
    radius: 12
    color: "#111113"
    border.color: "#ffffff10"
    border.width: 1

    MouseArea { anchors.fill: parent }

    Column {
      id: contentCol
      anchors { left: parent.left; right: parent.right; top: parent.top }
      anchors.margins: 12
      spacing: 6

      Rectangle {
        width: parent.width
        height: 40
        radius: 8
        color: "#0d0d0f"
        border.color: "#cf9fff33"
        border.width: 1

        RowLayout {
          anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
          spacing: 8

          Text {
            text: "󰍉"
            color: "#555"
            font.pixelSize: 14
            font.family: "JetBrainsMono Nerd Font"
          }

          TextInput {
            id: searchInput
            Layout.fillWidth: true
            color: "#e0e0e0"
            font.pixelSize: 13
            font.family: "JetBrainsMono Nerd Font"
            cursorVisible: true

            Keys.onReturnPressed: launcher.launch()
            Keys.onEscapePressed: launcher.close()
            Keys.onUpPressed:   launcher.selected = Math.max(0, launcher.selected - 1)
            Keys.onDownPressed: launcher.selected = Math.min(launcher.results.length - 1, launcher.selected + 1)
            onTextChanged: launcher.search(text)
          }
        }
      }

      Column {
        width: parent.width
        spacing: 2
        visible: launcher.results.length > 0

        Repeater {
          model: launcher.results
          delegate: Rectangle {
            required property string modelData
            required property int index
            width: parent.width
            height: 36
            radius: 6
            color: launcher.selected === index ? "#1e1a2e" : "transparent"
            border.color: launcher.selected === index ? "#cf9fff33" : "transparent"
            border.width: 1

            RowLayout {
              anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
              spacing: 10
              Text {
                text: "󰘔"
                color: launcher.selected === index ? "#cf9fff" : "#444"
                font.pixelSize: 12
                font.family: "JetBrainsMono Nerd Font"
              }
              Text {
                text: modelData
                color: launcher.selected === index ? "#e0e0e0" : "#888"
                font.pixelSize: 12
                font.family: "JetBrainsMono Nerd Font"
              }
            }
            MouseArea {
              anchors.fill: parent
              onClicked: { launcher.selected = index; launcher.launch() }
            }
          }
        }
      }
    }
  }

  Process {
    id: searchProc
    command: []
    stdout: SplitParser {
      onRead: data => {
        if (data.trim() !== "") launcher.results = [...launcher.results, data.trim()]
      }
    }
    onRunningChanged: if (!running) launcher.selected = 0
  }

  Process { id: runProc; command: [] }
}
