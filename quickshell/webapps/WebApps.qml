import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import ".."

PanelWindow {
  id: root
  anchors { top: true; left: true; right: true; bottom: true }
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  focusable: true
  visible: false
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

  property int selected: 0
  property real cardYOffset: 18
  property string formName: ""
  property string formUrl: ""
  property string formIconUrl: ""

  readonly property string previewImageSource: {
    const value = formIconUrl.trim()
    if (value === "") return ""
    if (value.startsWith("http://") || value.startsWith("https://") || value.startsWith("file://")) return value
    if (value.startsWith("/")) return "file://" + value
    return ""
  }
  readonly property bool canSubmit: formName.trim() !== "" && formUrl.trim() !== ""
  readonly property color cardFill: Colors.darkMode
    ? Qt.rgba(Colors.bg1.r, Colors.bg1.g, Colors.bg1.b, 0.985)
    : Qt.rgba(Colors.bg1.r, Colors.bg1.g, Colors.bg1.b, 0.975)
  readonly property color cardEdge: Colors.darkMode
    ? Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, 0.08)
    : Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, 0.12)
  readonly property color surfaceFill: Colors.darkMode
    ? Qt.rgba(Colors.bg2.r, Colors.bg2.g, Colors.bg2.b, 0.40)
    : Qt.rgba(Colors.bg2.r, Colors.bg2.g, Colors.bg2.b, 0.88)
  readonly property color fieldFill: Colors.darkMode
    ? Qt.rgba(0, 0, 0, 0.16)
    : Qt.rgba(1, 1, 1, 0.58)
  readonly property color fieldEdge: Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, Colors.darkMode ? 0.08 : 0.12)
  readonly property color rowSelected: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, Colors.darkMode ? 0.16 : 0.12)

  function toggle() {
    if (visible) {
      closeAnim.start()
      return
    }

    visible = true
    selected = 0
    store.query = ""
    store.reload()
    card.opacity = 0
    card.scale = 0.988
    cardYOffset = 16
    openAnim.start()
  }

  function close() {
    closeAnim.start()
  }

  function submit() {
    if (!canSubmit || store.applying) return
    store.applyInstall(formName, formUrl, formIconUrl)
    formName = ""
    formUrl = ""
    formIconUrl = ""
  }

  function moveSelection(delta) {
    if (store.filtered.length === 0) return
    selected = Math.max(0, Math.min(store.filtered.length - 1, selected + delta))
    results.positionViewAtIndex(selected, ListView.Contain)
  }

  function loadItem(item) {
    if (!item) return
    formName = item.name || ""
    formUrl = item.url || ""
    formIconUrl = item.iconUrl || ""
  }

  Keys.priority: Keys.BeforeItem
  Keys.onPressed: function(event) {
    if (event.key === Qt.Key_Escape) {
      close()
      event.accepted = true
    } else if (event.key === Qt.Key_Down) {
      moveSelection(1)
      event.accepted = true
    } else if (event.key === Qt.Key_Up) {
      moveSelection(-1)
      event.accepted = true
    } else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && !(event.modifiers & Qt.ShiftModifier)) {
      submit()
      event.accepted = true
    }
  }

  onVisibleChanged: {
    if (visible) {
      focusGrabber.forceActiveFocus()
      nameInput.forceActiveFocus()
    }
  }

  SequentialAnimation {
    id: openAnim
    ParallelAnimation {
      NumberAnimation { target: root; property: "cardYOffset"; from: 16; to: 0; duration: 170; easing.type: Easing.OutCubic }
      NumberAnimation { target: card; property: "opacity"; from: 0; to: 1; duration: 130; easing.type: Easing.OutQuad }
      NumberAnimation { target: card; property: "scale"; from: 0.988; to: 1; duration: 170; easing.type: Easing.OutCubic }
    }
  }

  SequentialAnimation {
    id: closeAnim
    ParallelAnimation {
      NumberAnimation { target: root; property: "cardYOffset"; to: 10; duration: 110; easing.type: Easing.InCubic }
      NumberAnimation { target: card; property: "scale"; to: 0.992; duration: 110; easing.type: Easing.InCubic }
      NumberAnimation { target: card; property: "opacity"; to: 0; duration: 90; easing.type: Easing.InQuad }
    }
    ScriptAction { script: root.visible = false }
  }

  WebAppsStore {
    id: store
  }

  MouseArea {
    anchors.fill: parent
    onClicked: root.close()
  }

  Rectangle {
    id: card
    anchors.centerIn: parent
    anchors.verticalCenterOffset: root.cardYOffset
    width: 1040
    height: 628
    radius: 32
    antialiasing: true
    color: root.cardFill
    border.width: 1
    border.color: root.cardEdge
    clip: true
    opacity: 0

    MouseArea {
      anchors.fill: parent
    }

    Rectangle {
      anchors.fill: parent
      radius: parent.radius
      gradient: Gradient {
        GradientStop { position: 0.0; color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, Colors.darkMode ? 0.08 : 0.05) }
        GradientStop { position: 0.18; color: "transparent" }
        GradientStop { position: 1.0; color: "transparent" }
      }
    }

    Item {
      id: focusGrabber
      focus: root.visible
      width: 0
      height: 0

      Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
          root.close()
          event.accepted = true
        }
      }
    }

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 22
      spacing: 16

      RowLayout {
        Layout.fillWidth: true

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 2

          Text {
            text: "Apps Web"
            color: Colors.text0
            font { pixelSize: 30; family: "Inter"; weight: Font.DemiBold }
          }

          Text {
            text: "Nome, link e imagem"
            color: Colors.text3
            font { pixelSize: 12; family: "Inter" }
          }
        }

      }

      RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 16

        Rectangle {
          Layout.preferredWidth: 390
          Layout.fillHeight: true
          radius: 28
          color: root.surfaceFill
          border.width: 1
          border.color: root.cardEdge

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            Rectangle {
              Layout.alignment: Qt.AlignHCenter
              Layout.preferredWidth: 112
              Layout.preferredHeight: 112
              radius: 30
              color: Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, Colors.darkMode ? 0.08 : 0.06)
              border.width: 1
              border.color: Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, 0.08)
              clip: true

              Image {
                anchors.fill: parent
                anchors.margins: 10
                visible: root.previewImageSource !== ""
                source: root.previewImageSource
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                cache: false
              }

              Text {
                anchors.centerIn: parent
                visible: root.previewImageSource === ""
                text: formName.trim() !== "" ? formName.trim().slice(0, 2).toUpperCase() : "WA"
                color: Colors.text2
                font { pixelSize: 28; family: "JetBrains Mono"; weight: Font.DemiBold }
              }
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 6

              Text {
                text: "Nome"
                color: Colors.text3
                font { pixelSize: 10; family: "JetBrainsMono Nerd Font" }
              }

              Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 46
                radius: 18
                color: root.fieldFill
                border.width: 1
                border.color: root.fieldEdge

                TextInput {
                  id: nameInput
                  anchors.fill: parent
                  anchors.leftMargin: 14
                  anchors.rightMargin: 14
                  anchors.topMargin: 12
                  anchors.bottomMargin: 12
                  color: Colors.text0
                  selectionColor: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.30)
                  selectedTextColor: Colors.text0
                  font.pixelSize: 14
                  font.family: "Inter"
                  clip: true
                  text: root.formName
                  onTextChanged: root.formName = text
                  Keys.onEscapePressed: function(event) { root.close(); event.accepted = true }
                }
              }
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 6

              Text {
                text: "Link"
                color: Colors.text3
                font { pixelSize: 10; family: "JetBrainsMono Nerd Font" }
              }

              Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 46
                radius: 18
                color: root.fieldFill
                border.width: 1
                border.color: root.fieldEdge

                TextInput {
                  anchors.fill: parent
                  anchors.leftMargin: 14
                  anchors.rightMargin: 14
                  anchors.topMargin: 12
                  anchors.bottomMargin: 12
                  color: Colors.text0
                  selectionColor: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.30)
                  selectedTextColor: Colors.text0
                  font.pixelSize: 13
                  font.family: "JetBrains Mono"
                  clip: true
                  text: root.formUrl
                  onTextChanged: root.formUrl = text
                  Keys.onEscapePressed: function(event) { root.close(); event.accepted = true }
                }
              }
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 6

              Text {
                text: "Imagem"
                color: Colors.text3
                font { pixelSize: 10; family: "JetBrainsMono Nerd Font" }
              }

              Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 46
                radius: 18
                color: root.fieldFill
                border.width: 1
                border.color: root.fieldEdge

                TextInput {
                  anchors.fill: parent
                  anchors.leftMargin: 14
                  anchors.rightMargin: 14
                  anchors.topMargin: 12
                  anchors.bottomMargin: 12
                  color: Colors.text0
                  selectionColor: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.30)
                  selectedTextColor: Colors.text0
                  font.pixelSize: 13
                  font.family: "JetBrains Mono"
                  clip: true
                  text: root.formIconUrl
                  onTextChanged: root.formIconUrl = text
                  Keys.onEscapePressed: function(event) { root.close(); event.accepted = true }
                }
              }
            }

            Item { Layout.fillHeight: true }

            RowLayout {
              Layout.fillWidth: true
              spacing: 10

              Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                radius: 20
                color: root.canSubmit
                  ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.18)
                  : Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, 0.06)
                border.width: 1
                border.color: root.canSubmit
                  ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.28)
                  : Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, 0.08)

                Text {
                  anchors.centerIn: parent
                  text: store.applying ? "Adicionando" : "Adicionar"
                  color: root.canSubmit ? Colors.accent : Colors.text3
                  font { pixelSize: 13; family: "Inter"; weight: Font.DemiBold }
                }

                MouseArea {
                  anchors.fill: parent
                  enabled: root.canSubmit && !store.applying
                  onClicked: root.submit()
                }
              }

            }

            Text {
              visible: store.errorMessage !== ""
              text: store.errorMessage
              color: Qt.color("#e57474")
              wrapMode: Text.WordWrap
              font { pixelSize: 11; family: "Inter" }
            }

            Text {
              visible: store.infoMessage !== ""
              text: store.infoMessage
              color: Colors.accent
              wrapMode: Text.WordWrap
              font { pixelSize: 11; family: "Inter" }
            }
          }
        }

        Rectangle {
          Layout.fillWidth: true
          Layout.fillHeight: true
          radius: 28
          color: root.surfaceFill
          border.width: 1
          border.color: root.cardEdge

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            ListView {
              id: results
              Layout.fillWidth: true
              Layout.fillHeight: true
              clip: true
              spacing: 10
              boundsBehavior: Flickable.StopAtBounds
              model: store.filtered.length

              WheelHandler {
                target: results
                onWheel: function(event) {
                  results.contentY = Math.max(
                    0,
                    Math.min(results.contentHeight - results.height, results.contentY - event.angleDelta.y)
                  )
                }
              }

              delegate: Rectangle {
                property var item: store.filtered[index] || ({})
                width: results.width
                height: 84
                radius: 22
                color: root.selected === index
                  ? root.rowSelected
                  : Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, Colors.darkMode ? 0.04 : 0.03)
                border.width: 1
                border.color: root.selected === index
                  ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.24)
                  : Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, 0.08)

                Rectangle {
                  x: 14
                  y: 14
                  width: 56
                  height: 56
                  radius: 18
                  color: item.installed
                    ? Qt.rgba(0.38, 0.82, 0.58, 0.14)
                    : Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.14)

                  Text {
                    anchors.centerIn: parent
                    text: (item.name || "WA").slice(0, 2).toUpperCase()
                    color: item.installed ? Qt.color("#74d38e") : Colors.accent
                    font { pixelSize: 13; family: "JetBrains Mono"; weight: Font.DemiBold }
                  }
                }

                Text {
                  x: 84
                  y: 16
                  width: parent.width - 180
                  text: item.name || ""
                  color: Colors.text1
                  elide: Text.ElideRight
                  font { pixelSize: 15; family: "Inter"; weight: Font.DemiBold }
                }

                Text {
                  x: 84
                  y: 40
                  width: parent.width - 180
                  text: item.url || ""
                  color: Colors.text3
                  elide: Text.ElideRight
                  font { pixelSize: 10; family: "JetBrains Mono" }
                }

                Rectangle {
                  x: parent.width - 92
                  y: 22
                  width: 68
                  height: 38
                  radius: 16
                  color: item.installed
                    ? Qt.rgba(0.88, 0.34, 0.34, 0.12)
                    : Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.14)
                  border.width: 1
                  border.color: Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, 0.08)

                  Text {
                    anchors.centerIn: parent
                    text: item.installed ? "Remover" : "Usar"
                    color: item.installed ? Qt.color("#e57474") : Colors.accent
                    font { pixelSize: 11; family: "Inter"; weight: Font.DemiBold }
                  }

                  MouseArea {
                    anchors.fill: parent
                    enabled: !store.applying
                    onClicked: {
                      root.selected = index
                      if (item.installed) {
                        root.loadItem(item)
                      } else {
                        root.loadItem(item)
                        nameInput.forceActiveFocus()
                      }
                    }
                  }
                }

                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  onEntered: root.selected = index
                  onClicked: {
                    root.selected = index
                    root.loadItem(item)
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
