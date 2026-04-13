import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import ".."

PanelWindow {
  id: root
  anchors { top: true; bottom: true; left: true; right: true }
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  focusable: true
  visible: false
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

  property var    items:    []
  property var    filtered: []
  property string query:    ""

  function toggle() {
    if (visible) {
      closeAnim.start()
    } else {
      items = []
      query = ""
      searchField.text = ""
      visible = true
      panel.height = 52
      panel.opacity = 0
      openAnim.start()
      loadProc.running = false
      loadProc.running = true
    }
  }

  function close() { closeAnim.start() }

  function filterItems() {
    if (query === "")
      filtered = items.slice(0, 50)
    else
      filtered = items.filter(function(i) {
        return i.display.toLowerCase().indexOf(query.toLowerCase()) !== -1
      }).slice(0, 50)
  }

  onItemsChanged: filterItems()

  SequentialAnimation {
    id: openAnim
    NumberAnimation { target: panel; property: "opacity"; to: 1; duration: 20 }
    NumberAnimation { target: panel; property: "height"; to: 510; duration: 260; easing.type: Easing.OutCubic }
    NumberAnimation { target: panel; property: "height"; to: 500; duration: 80; easing.type: Easing.InOutQuad }
    ScriptAction { script: searchField.forceActiveFocus() }
  }

  SequentialAnimation {
    id: closeAnim
    NumberAnimation { target: panel; property: "height"; to: 52; duration: 160; easing.type: Easing.InCubic }
    NumberAnimation { target: panel; property: "opacity"; to: 0; duration: 60 }
    ScriptAction { script: root.visible = false }
  }

  MouseArea {
    anchors.fill: parent
    onClicked: root.close()
  }

  Process {
    id: loadProc
    command: ["sh", "-c", "cliphist list 2>/dev/null | head -100"]
    stdout: SplitParser {
      onRead: data => {
        var line = data.trim()
        if (line === "") return
        var tab  = line.indexOf("\t")
        var id   = tab >= 0 ? line.substring(0, tab) : line
        var text = tab >= 0 ? line.substring(tab + 1) : line
        var isImg = text.indexOf("[[ binary") === 0
        root.items = [...root.items, {
          id:      id,
          display: isImg ? "🖼 " + text : text,
          isImg:   isImg
        }]
      }
    }
  }

  Process {
    id: pasteProc
    command: []
    onRunningChanged: {
      if (!running) root.close()
    }
  }
  Process { id: deleteProc; command: [] }

  Rectangle {
    id: panel
    anchors.centerIn: parent
    width:   500
    height:  52
    radius:  16
    color:   Colors.bg1
    border.color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.15)
    border.width: 1
    opacity: 0
    clip:    true

    MouseArea { anchors.fill: parent }

    Column {
      anchors { fill: parent; margins: 10 }
      spacing: 8

      // busca
      Rectangle {
        width: parent.width
        height: 32
        radius: 10
        color: Colors.bg2
        border.color: searchField.activeFocus
          ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.4)
          : Qt.rgba(1,1,1,0.06)
        border.width: 1
        Behavior on border.color { ColorAnimation { duration: 150 } }

        Text {
          anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
          text: "󰍉"
          color: Colors.text3
          font { pixelSize: 13; family: "JetBrainsMono Nerd Font" }
          visible: searchField.text === ""
        }

        TextInput {
          id: searchField
          anchors { fill: parent; leftMargin: 32; rightMargin: 40 }
          verticalAlignment: Text.AlignVCenter
          color: Colors.text1
          font { pixelSize: 12; family: "Roboto" }
          onTextChanged: { root.query = text; root.filterItems() }
          Keys.onEscapePressed: root.close()
          Keys.onReturnPressed: {
            if (root.filtered.length > 0) pasteItem(root.filtered[0])
          }
        }

        Text {
          anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
          text: root.filtered.length + ""
          color: Colors.text3
          font { pixelSize: 10; family: "Roboto" }
        }
      }

      // lista
      ListView {
        id: list
        width:  parent.width
        height: 440
        spacing: 2
        clip:    true
        model:   root.filtered

        delegate: Rectangle {
          required property var modelData
          required property int index
          width:  list.width
          height: 38
          radius: 8
          color:  itemMa.containsMouse ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.08) : "transparent"
          Behavior on color { ColorAnimation { duration: 100 } }

          Text {
            anchors { left: parent.left; right: delBtn.left; leftMargin: 10; rightMargin: 6; verticalCenter: parent.verticalCenter }
            text: modelData.display.replace(/\n/g, " ").substring(0, 90) + (modelData.display.length > 90 ? "…" : "")
            color: modelData.isImg ? Colors.accent : Colors.text1
            font { pixelSize: 12; family: "Roboto" }
            elide: Text.ElideRight
          }

          Rectangle {
            id: delBtn
            anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
            width: 22; height: 22; radius: 6
            color: delMa.containsMouse ? "#cc4444" : Qt.rgba(1,1,1,0.05)
            visible: itemMa.containsMouse || delMa.containsMouse
            Behavior on color { ColorAnimation { duration: 100 } }

            Text {
              anchors.centerIn: parent
              text: "✕"
              color: Colors.text3
              font { pixelSize: 9; family: "Roboto" }
            }

            MouseArea {
              id: delMa
              anchors.fill: parent
              hoverEnabled: true
              onClicked: {
                deleteProc.command = ["sh", "-c", "printf '%s' '" + modelData.id + "' | cliphist delete-query"]
                deleteProc.running = true
                root.items = root.items.filter(function(i) { return i.id !== modelData.id })
                root.filterItems()
              }
            }
          }

          MouseArea {
            id: itemMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: pasteItem(modelData)
          }
        }
      }
    }
  }

  function pasteItem(item) {
    pasteProc.command = ["sh", "-c", "printf '%s' " + item.id + " | cliphist decode | nohup wl-copy &"]
    pasteProc.running = true

  }
}
