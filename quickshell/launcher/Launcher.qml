import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import ".."

PanelWindow {
  id: launcher
  anchors { bottom: true; left: true; right: true }
  implicitHeight: visible ? mainCol.implicitHeight + brd : 0
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  focusable: true
  visible: false

  readonly property int brd: 10
  property var results: []
  property var execs: []
  property var icons: []
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
    execs = []
    icons = []
    if (q.length === 0) return
    searchProc.command = ["sh", "-c", `~/.config/quickshell/scripts/search-apps.sh '${q}'`]
    searchProc.running = true
  }

  function launch() {
    if (results.length === 0) return
    runProc.command = ["sh", "-c", execs[selected] + " &"]
    runProc.running = true
    close()
  }

  function close() {
    visible = false
    searchInput.text = ""
    results = []
    execs = []
    icons = []
    selected = 0
  }

  MouseArea {
    anchors.fill: parent
    onClicked: launcher.close()
  }

  Item {
    id: mainCol
    anchors {
      bottom: parent.bottom
      bottomMargin: brd
      horizontalCenter: parent.horizontalCenter
    }
    width: 520
    implicitHeight: resultsList.implicitHeight + (results.length > 0 ? 8 : 0) + searchBox.height + 8

    MouseArea { anchors.fill: parent }

    Shape {
      anchors.fill: parent
      layer.enabled: true
      layer.smooth: true
      preferredRendererType: Shape.CurveRenderer
      ShapePath {
        strokeWidth: 0
        fillColor: Colors.bg1
        readonly property real r: 14
        startX: 0; startY: mainCol.implicitHeight
        PathLine { x: 0; y: r }
        PathArc { x: r; y: 0; radiusX: r; radiusY: r }
        PathLine { x: mainCol.width - r; y: 0 }
        PathArc { x: mainCol.width; y: r; radiusX: r; radiusY: r }
        PathLine { x: mainCol.width; y: mainCol.implicitHeight }
        PathLine { x: 0; y: mainCol.implicitHeight }
      }
    }

    Column {
      id: resultsList
      anchors { bottom: searchBox.top; left: parent.left; right: parent.right }
      anchors.bottomMargin: 8
      anchors.leftMargin: 8
      anchors.rightMargin: 8
      anchors.topMargin: 8
      spacing: 2
      visible: launcher.results.length > 0

      Repeater {
        model: launcher.results
        delegate: Rectangle {
          required property string modelData
          required property int index
          width: parent.width
          height: 40
          radius: 8
          color: launcher.selected === index ? Colors.accentDim : "transparent"
          border.color: launcher.selected === index
            ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.25)
            : "transparent"
          border.width: 1

          RowLayout {
            anchors { fill: parent; leftMargin: 10; rightMargin: 12 }
            spacing: 10

            // Ícone
            Image {
              source: launcher.icons[index] || ""
              width: 22
              height: 26
              fillMode: Image.PreserveAspectFit
              Layout.preferredWidth: 26
              Layout.preferredHeight: 26
              smooth: true
              visible: source !== ""
            }

            Text {
              text: modelData
              color: launcher.selected === index ? Colors.text0 : Colors.text2
              font.pixelSize: 13
              font.family: "JetBrainsMono Nerd Font"
              Layout.fillWidth: true
            }
          }
          MouseArea {
            anchors.fill: parent
            onClicked: { launcher.selected = index; launcher.launch() }
          }
        }
      }
    }

    Rectangle {
      id: searchBox
      anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
      height: 48
      color: "transparent"

      RowLayout {
        anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
        spacing: 10
        Text {
          text: "󰍉"
          color: Colors.text3
          font.pixelSize: 16
          font.family: "JetBrainsMono Nerd Font"
        }
        TextInput {
          id: searchInput
          Layout.fillWidth: true
          color: Colors.text1
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
  }

  Process {
    id: searchProc
    command: []
    stdout: SplitParser {
      onRead: data => {
        if (data.trim() !== "") {
          const parts = data.trim().split("|")
          launcher.results = [...launcher.results, parts[0]]
          launcher.execs  = [...launcher.execs,   parts[1] || parts[0]]
          launcher.icons  = [...launcher.icons,   parts[2] || ""]
        }
      }
    }
  }

  Process { id: runProc; command: [] }
}
