import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import ".."

PanelWindow {
  id: launcher
  anchors { top: true; left: true; right: true; bottom: true }
  implicitHeight: 0
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  focusable: true
  visible: false

  readonly property int pillW: 480
  readonly property int pillH: 48
  readonly property int itemH: 44
  readonly property int maxResults: 7

  property var allApps: []
  property var filtered: []
  property int selected: 0

  function toggle() {
    if (visible) {
      closeAnim.start()
    } else {
      visible = true
      searchInput.text = ""
      selected = 0
      filtered = []
      allApps = []; indexProc.running = true
      pill.width = pillH
      pill.opacity = 0
      openAnim.start()
    }
  }

  function filterApps(q) {
    selected = 0
    if (q.length === 0) { filtered = []; return }
    const ql = q.toLowerCase()
    filtered = allApps.filter(a => a.name.toLowerCase().startsWith(ql)).slice(0, maxResults)
  }

  function launch() {
    if (filtered.length === 0) return
    runProc.command = ["sh", "-c", filtered[selected].exec + " &"]
    runProc.running = true
    closeAnim.start()
  }

  function close() {
    closeAnim.start()
  }

  SequentialAnimation {
    id: openAnim
    NumberAnimation { target: pill; property: "opacity"; from: 0; to: 1; duration: 20 }
    NumberAnimation { target: pill; property: "width"; from: pillH; to: pillW * 1.04; duration: 260; easing.type: Easing.OutCubic }
    NumberAnimation { target: pill; property: "width"; to: pillW; duration: 80; easing.type: Easing.InOutQuad }
    ScriptAction { script: searchInput.forceActiveFocus() }
  }

  SequentialAnimation {
    id: closeAnim
    NumberAnimation { target: pill; property: "width"; to: pillH; duration: 140; easing.type: Easing.InCubic }
    NumberAnimation { target: pill; property: "opacity"; to: 0; duration: 60 }
    ScriptAction { script: {
      launcher.visible = false
      searchInput.text = ""
      launcher.selected = 0
      launcher.filtered = []
    }}
  }

  MouseArea {
    anchors.fill: parent
    onClicked: launcher.close()
  }

  Rectangle {
    id: pill
    anchors.verticalCenter: parent.verticalCenter
    x: (parent.width - pillW) / 2 + (pillW - width) / 2
    width: pillH
    height: pillH + (filtered.length > 0 ? filtered.length * itemH + 14 : 0)
    radius: 14
    color: Colors.bg1
    border.color: filtered.length > 0
      ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.12)
      : Qt.rgba(1,1,1,0.06)
    border.width: 1
    clip: true
    opacity: 0

    Behavior on height {
      NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
    }

    MouseArea { anchors.fill: parent }

    RowLayout {
      anchors {
        top: parent.top
        left: parent.left; leftMargin: 18
        right: parent.right; rightMargin: 18
      }
      height: pillH
      spacing: 12

      Text {
        text: "󰍉"
        color: filtered.length > 0 ? Colors.accent : Colors.text3
        font { pixelSize: 16; family: "JetBrainsMono Nerd Font" }
        verticalAlignment: Text.AlignVCenter
        Behavior on color { ColorAnimation { duration: 150 } }
      }

      TextInput {
        id: searchInput
        Layout.fillWidth: true
        color: Colors.text1
        font { pixelSize: 14; family: "JetBrainsMono Nerd Font" }
        cursorVisible: true
        verticalAlignment: TextInput.AlignVCenter
        selectionColor: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.4)
        selectedTextColor: Colors.text0

        Text {
          anchors.fill: parent
          text: "Buscar aplicativo..."
          color: Colors.text3
          font { pixelSize: 14; family: "JetBrainsMono Nerd Font" }
          verticalAlignment: Text.AlignVCenter
          visible: searchInput.text.length === 0
        }

        Keys.onReturnPressed: launcher.launch()
        Keys.onEscapePressed: launcher.close()
        Keys.onUpPressed:     launcher.selected = Math.max(0, launcher.selected - 1)
        Keys.onDownPressed:   launcher.selected = Math.min(launcher.filtered.length - 1, launcher.selected + 1)
        onTextChanged:        launcher.filterApps(text)
      }
    }

    Rectangle {
      anchors {
        top: parent.top; topMargin: pillH
        left: parent.left; leftMargin: 12
        right: parent.right; rightMargin: 12
      }
      height: 1
      color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.25)
      opacity: filtered.length > 0 ? 1 : 0
      Behavior on opacity { NumberAnimation { duration: 120 } }
    }

    Column {
      anchors {
        top: parent.top; topMargin: pillH + 4
        left: parent.left; leftMargin: 6
        right: parent.right; rightMargin: 6
        bottom: parent.bottom; bottomMargin: 6
      }
      spacing: 2

      Repeater {
        model: launcher.filtered
        delegate: Rectangle {
          required property var modelData
          required property int index
          width: parent.width
          height: itemH
          radius: 10
          color: launcher.selected === index
            ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.12)
            : "transparent"
          Behavior on color { ColorAnimation { duration: 80 } }

          RowLayout {
            anchors { fill: parent; leftMargin: 12; rightMargin: 14 }
            spacing: 12
            Image {
              source: modelData.icon || ""
              Layout.preferredWidth: 22
              Layout.preferredHeight: 22
              fillMode: Image.PreserveAspectFit
              smooth: true
              visible: source !== ""
            }
            Text {
              text: modelData.name
              color: launcher.selected === index ? Colors.text0 : Colors.text2
              font { pixelSize: 13; family: "JetBrainsMono Nerd Font" }
              Layout.fillWidth: true
              Behavior on color { ColorAnimation { duration: 80 } }
            }
            Text {
              text: "↵"
              color: Colors.accent
              font { pixelSize: 11; family: "JetBrainsMono Nerd Font" }
              opacity: launcher.selected === index ? 1 : 0
              Behavior on opacity { NumberAnimation { duration: 80 } }
            }
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: launcher.selected = index
            onClicked: { launcher.selected = index; launcher.launch() }
          }
        }
      }
    }
  }

  Process {
    id: indexProc
    command: ["/home/ankh/.config/quickshell/scripts/index-apps.sh"]
    stdout: SplitParser {
      onRead: data => {
        if (data.trim() === "") return
        const parts = data.trim().split("|")
        if (parts.length < 2) return
        launcher.allApps = [...launcher.allApps, {
          name: parts[0],
          exec: parts[1],
          icon: parts[2] || ""
        }]
      }
    }
  }

  Process { id: runProc; command: [] }
}
