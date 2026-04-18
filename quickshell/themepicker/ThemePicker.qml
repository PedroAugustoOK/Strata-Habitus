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

  property string currentTheme: "gruvbox"
  property int    selectedIdx:  0

  readonly property var themes: [
    { name: "gruvbox",  label: "Gruvbox",   mode: "Escuro",
      bg0: "#0d0d0f", bg1: "#111113", bg2: "#1a1a1c", bg3: "#252527", mid: "#504945", accent: "#d79921" },
    { name: "rosepine", label: "Rose Pine", mode: "Claro",
      bg0: "#f0ece4", bg1: "#e8e4dc", bg2: "#dedad2", bg3: "#d5d0c8", mid: "#9893a5", accent: "#b4637a" },
    { name: "nord",     label: "Nord",      mode: "Escuro",
      bg0: "#0d0d0f", bg1: "#111113", bg2: "#1e2228", bg3: "#2a3140", mid: "#4c566a", accent: "#88c0d0" }
  ]

  function toggle() {
    if (visible) {
      closeAnim.start()
    } else {
      selectedIdx = 0
      for (var i = 0; i < themes.length; i++) {
        if (themes[i].name === currentTheme) { selectedIdx = i; break }
      }
      visible = true
      picker.scale   = 0.88
      picker.opacity = 0
      openAnim.start()
    }
  }

  function close() { closeAnim.start() }

  SequentialAnimation {
    id: openAnim
    NumberAnimation { target: picker; property: "opacity"; to: 1; duration: 60 }
    NumberAnimation { target: picker; property: "scale"; to: 1.02; duration: 180; easing.type: Easing.OutCubic }
    NumberAnimation { target: picker; property: "scale"; to: 1.0; duration: 60; easing.type: Easing.InOutQuad }
  }

  SequentialAnimation {
    id: closeAnim
    NumberAnimation { target: picker; property: "scale"; to: 0.88; duration: 140; easing.type: Easing.InCubic }
    NumberAnimation { target: picker; property: "opacity"; to: 0; duration: 50 }
    ScriptAction { script: root.visible = false }
  }

  MouseArea {
    anchors.fill: parent
    onClicked: root.close()
  }

  Rectangle {
    id: picker
    anchors.centerIn: parent
    width:   660
    height:  220
    radius:  16
    color:   Colors.bg1
    border.color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.12)
    border.width: 1
    scale:   0.88
    opacity: 0
    transformOrigin: Item.Center

    MouseArea { anchors.fill: parent }

    Item {
      id: keyItem
      anchors.fill: parent
      focus: true
      Keys.onPressed: function(e) {
        if (e.key === Qt.Key_Escape) {
          root.close()
        } else if (e.key === Qt.Key_Left) {
          root.selectedIdx = Math.max(0, root.selectedIdx - 1)
        } else if (e.key === Qt.Key_Right) {
          root.selectedIdx = Math.min(root.themes.length - 1, root.selectedIdx + 1)
        } else if (e.key === Qt.Key_Return) {
          var t = root.themes[root.selectedIdx]
          themeProc.command = ["bash", Paths.scripts + "/set-theme.sh", t.name]
          themeProc.running = true
          root.close()
        }
      }
    }

    Row {
      anchors.centerIn: parent
      spacing: 12

      Repeater {
        model: root.themes
        delegate: Item {
          required property var modelData
          required property int index

          readonly property bool selected: root.selectedIdx === index

          width:  196
          height: 180

          // card com clip
          Rectangle {
            id: card
            anchors.fill: parent
            radius: 12
            color:  modelData.bg1
            clip:   true

            Column {
              anchors { top: parent.top; left: parent.left; right: parent.right }
              spacing: 0
              Rectangle { width: parent.width; height: 29; color: modelData.bg0 }
              Rectangle { width: parent.width; height: 29; color: modelData.bg2 }
              Rectangle { width: parent.width; height: 29; color: modelData.bg3 }
              Rectangle { width: parent.width; height: 16; color: modelData.mid }
              Rectangle { width: parent.width; height: 13; color: modelData.accent }
            }

            Rectangle {
              anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
              height: 64
              color:  modelData.bg1

              Rectangle {
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: 1
                color:  Qt.rgba(1,1,1,0.06)
              }

              Text {
                anchors { left: parent.left; leftMargin: 12; top: parent.top; topMargin: 12 }
                text:  modelData.label
                color: selected ? modelData.accent : (modelData.name === "rosepine" ? "#555" : "#ccc")
                font { pixelSize: 13; family: "Roboto"; weight: Font.DemiBold }
                Behavior on color { ColorAnimation { duration: 150 } }
              }

              Text {
                anchors { left: parent.left; leftMargin: 12; bottom: parent.bottom; bottomMargin: 12 }
                text:  modelData.mode.toUpperCase()
                color: "#666"
                font { pixelSize: 9; family: "JetBrainsMono Nerd Font" }
              }

              Row {
                anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                spacing: 5
                Repeater {
                  model: [modelData.bg0, modelData.mid, modelData.accent]
                  delegate: Rectangle {
                    required property var modelData
                    width: 10; height: 10; radius: 5
                    color: modelData
                    border.color: Qt.rgba(1,1,1,0.1)
                    border.width: 1
                  }
                }
              }
            }
          }

          // borda FORA do clip, filho direto do Item delegate
          Rectangle {
            anchors.fill: card
            radius: 0
            color:  "transparent"
            border.color: selected ? modelData.accent : Qt.rgba(1,1,1,0.05)
            border.width: selected ? 2 : 1
            z: 10
            Behavior on border.color { ColorAnimation { duration: 150 } }
          }

          MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape:  Qt.PointingHandCursor
            z: 20
            onEntered: root.selectedIdx = index
            onClicked: {
              themeProc.command = ["bash", Paths.scripts + "/set-theme.sh", modelData.name]
              themeProc.running = true
              root.close()
            }
          }
        }
      }
    }
  }

  onVisibleChanged: {
    if (visible) keyItem.forceActiveFocus()
  }

  FileView {
    path: Paths.themes + "/current.json"
    watchChanges: true
    onLoaded: {
      try {
        var t = JSON.parse(text())
        root.currentTheme = t.name || "gruvbox"
      } catch(e) {}
    }
  }

  Process { id: themeProc; command: [] }
}
