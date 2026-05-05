import QtQuick
import QtQuick.Layouts
import ".."
import "../appcenter"

Item {
  id: root

  property bool open: false
  property int selected: 0
  property real progressValue: 0

  readonly property var filters: [
    { key: "discover", label: "Destaques" },
    { key: "available", label: "Disponiveis" },
    { key: "installed", label: "Instalados" },
    { key: "managed", label: "Gerenciados" },
    { key: "base", label: "Base" }
  ]
  readonly property var currentItem: store.filtered.length > 0 ? store.filtered[Math.max(0, Math.min(selected, store.filtered.length - 1))] : null
  readonly property bool busy: store.loading || store.applying || store.rebuilding
  readonly property real progressTarget: store.loading ? 0.34 : store.applying ? 0.68 : store.rebuilding ? 0.94 : 0
  readonly property color progressTone: store.loading ? Colors.info : store.rebuilding ? Colors.warning : Colors.success
  readonly property string queueHeadline: store.pendingCount === 0 ? "Fila vazia" : store.pendingCount === 1 ? "1 app na fila" : (store.pendingCount + " apps na fila")
  readonly property color panelFill: Colors.darkMode
    ? Qt.rgba(Colors.bg2.r, Colors.bg2.g, Colors.bg2.b, 0.58)
    : Qt.rgba(Colors.bg2.r, Colors.bg2.g, Colors.bg2.b, 0.86)
  readonly property color panelBorder: Colors.darkMode
    ? Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, 0.08)
    : Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, 0.14)
  readonly property color softFill: Colors.darkMode ? Qt.rgba(1, 1, 1, 0.04) : Qt.rgba(0, 0, 0, 0.035)

  function toggle() {
    if (open) {
      close()
      return
    }

    open = true
    selected = 0
    searchInput.text = ""
    store.setMode("discover")
    store.reload()
    OverlayState.setActive("appcenter")
    focusTimer.restart()
  }

  function close() {
    open = false
    selected = 0
    OverlayState.clear("appcenter")
  }

  function clampSelection() {
    if (store.filtered.length === 0) {
      selected = 0
      return
    }
    selected = Math.max(0, Math.min(selected, store.filtered.length - 1))
    results.positionViewAtIndex(selected, ListView.Contain)
  }

  function moveSelection(delta) {
    if (store.filtered.length === 0) return
    selected = Math.max(0, Math.min(store.filtered.length - 1, selected + delta))
    results.positionViewAtIndex(selected, ListView.Contain)
  }

  function runSelected() {
    if (!currentItem) return
    store.runAction(currentItem)
  }

  function isActionEnabled(item) {
    if (!item || item.action === "none") return false
    if (store.pendingCount > 0) return !store.applying && !store.rebuilding
    return !store.applying
  }

  function formatSource(item) {
    if (!item) return "-"
    return item.source === "flatpak" ? "Flatpak" : "Nix"
  }

  function formatState(item) {
    if (!item) return "-"
    if (item.source === "flatpak" && item.installed) return item.installedScope === "system" ? "Flatpak system" : "Flatpak user"
    if (item.source === "nix" && item.managed && !item.installed) return "Pendente de rebuild"
    if (item.managed) return "Gerenciado"
    if (item.installed) return "Instalado"
    return "Disponivel"
  }

  function stateTone(item) {
    if (!item) return Colors.text3
    if (item.source === "nix" && item.managed && !item.installed) return Colors.warning
    if (item.managed) return Colors.primary
    if (item.installed) return Colors.success
    return Colors.text3
  }

  function keyboardHint() {
    if (store.pendingCount > 0) return "Enter age no item atual. Ctrl+R confirma a fila."
    if (currentItem && currentItem.source === "flatpak") return "Enter aplica imediatamente via Flatpak."
    if (currentItem && currentItem.source === "nix" && currentItem.action !== "none") return "Enter adiciona ou remove este app da fila."
    if (currentItem && currentItem.source === "nix" && currentItem.installed) return "Apps da base mostram um aviso. Para remover, ajuste modules/packages.nix."
    return "Use setas para navegar e Enter para agir."
  }

  function handleKeyEvent(event) {
    if ((event.key === Qt.Key_R || event.key === Qt.Key_B) && (event.modifiers & Qt.ControlModifier)) {
      store.applyPendingAndRebuild()
      event.accepted = true
    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
      root.runSelected()
      event.accepted = true
    } else if (event.key === Qt.Key_PageDown) {
      root.moveSelection(7)
      event.accepted = true
    } else if (event.key === Qt.Key_PageUp) {
      root.moveSelection(-7)
      event.accepted = true
    } else if (event.key === Qt.Key_Home) {
      root.selected = 0
      event.accepted = true
    } else if (event.key === Qt.Key_End) {
      root.selected = Math.max(0, store.filtered.length - 1)
      event.accepted = true
    }
  }

  onBusyChanged: {
    if (!busy) progressValue = 0
    else if (progressValue === 0) progressValue = 0.08
  }

  anchors.fill: parent

  Timer {
    interval: 80
    repeat: true
    running: root.busy
    onTriggered: {
      if (root.progressValue < root.progressTarget) {
        root.progressValue = Math.min(root.progressTarget, root.progressValue + Math.max(0.01, (root.progressTarget - root.progressValue) * 0.18))
      }
    }
  }

  RightDrawer {
    id: drawer
    width: Math.min(920, Math.max(760, Math.round(parent.width * 0.54)))
    height: parent.height - 56
    gutter: 10
    open: root.open

    FrameSurface {
      anchors.fill: parent
      radius: 18
      attachedEdge: "right"
      fillColor: Colors.panelBackground
      borderColor: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.22)
      topToneOpacity: Colors.darkMode ? 0.98 : 0.94
      bottomToneOpacity: Colors.darkMode ? 0.98 : 0.96

      Item {
        id: keyGrabber
        anchors.fill: parent
        focus: root.open
        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Escape) {
            root.close()
            event.accepted = true
            return
          }
          root.handleKeyEvent(event)
        }
      }

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 14

        RowLayout {
          Layout.fillWidth: true
          spacing: 12

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            Text {
              Layout.fillWidth: true
              text: "Central de Apps"
              color: Colors.text1
              font { pixelSize: 24; family: "Inter"; weight: Font.DemiBold }
              elide: Text.ElideRight
            }

            Text {
              Layout.fillWidth: true
              text: store.filtered.length + " apps  •  Nix + Flatpak"
              color: Colors.text3
              font { pixelSize: 10; family: "JetBrains Mono" }
              elide: Text.ElideRight
            }
          }

          Rectangle {
            radius: 12
            implicitWidth: queueText.implicitWidth + 18
            implicitHeight: 30
            color: store.pendingCount > 0 ? Qt.rgba(Colors.warning.r, Colors.warning.g, Colors.warning.b, 0.16) : root.softFill
            border.width: 1
            border.color: store.pendingCount > 0 ? Qt.rgba(Colors.warning.r, Colors.warning.g, Colors.warning.b, 0.24) : root.panelBorder

            Text {
              id: queueText
              anchors.centerIn: parent
              text: root.queueHeadline
              color: store.pendingCount > 0 ? Colors.warning : Colors.text2
              font { pixelSize: 10; family: "JetBrains Mono"; weight: Font.DemiBold }
            }
          }
        }

        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: root.busy ? 22 : 0
          radius: 8
          color: Qt.rgba(root.progressTone.r, root.progressTone.g, root.progressTone.b, 0.10)
          visible: height > 0
          clip: true

          Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * root.progressValue
            radius: parent.radius
            color: root.progressTone
            opacity: 0.75
            Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
          }

          Text {
            anchors.centerIn: parent
            text: store.loading ? "Atualizando catalogo" : store.rebuilding ? "Abrindo rebuild" : store.applying ? "Aplicando alteracoes" : ""
            color: Colors.text0
            font { pixelSize: 10; family: "JetBrains Mono"; weight: Font.DemiBold }
          }
        }

        RowLayout {
          Layout.fillWidth: true
          Layout.fillHeight: true
          spacing: 14

          ColumnLayout {
            Layout.preferredWidth: 180
            Layout.fillHeight: true
            spacing: 10

            Rectangle {
              Layout.fillWidth: true
              Layout.preferredHeight: 42
              radius: 13
              color: Colors.darkMode ? Qt.rgba(0, 0, 0, 0.18) : Qt.rgba(1, 1, 1, 0.55)
              border.width: 1
              border.color: searchInput.activeFocus ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.30) : root.panelBorder

              TextInput {
                id: searchInput
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                color: Colors.text1
                font { pixelSize: 13; family: "JetBrains Mono" }
                verticalAlignment: TextInput.AlignVCenter
                selectByMouse: true
                onTextChanged: {
                  root.selected = 0
                  store.search(text)
                }
                Keys.onEscapePressed: root.close()
                Keys.onUpPressed: root.moveSelection(-1)
                Keys.onDownPressed: root.moveSelection(1)
                Keys.onPressed: function(event) { root.handleKeyEvent(event) }

                Text {
                  anchors.fill: parent
                  text: "Buscar..."
                  color: Colors.text3
                  font { pixelSize: 13; family: "JetBrains Mono" }
                  verticalAlignment: Text.AlignVCenter
                  visible: searchInput.text.length === 0
                }
              }
            }

            Repeater {
              model: root.filters
              delegate: Rectangle {
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                radius: 12
                color: store.mode === modelData.key ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.18) : root.softFill
                border.width: 1
                border.color: store.mode === modelData.key ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.26) : root.panelBorder

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  x: 12
                  text: modelData.label
                  color: store.mode === modelData.key ? Colors.primary : Colors.text2
                  font { pixelSize: 11; family: "JetBrains Mono" }
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    root.selected = 0
                    store.setMode(modelData.key)
                    searchInput.forceActiveFocus()
                  }
                }
              }
            }

            Item { Layout.fillHeight: true }
          }

          Rectangle {
            Layout.preferredWidth: 330
            Layout.fillHeight: true
            radius: 16
            color: root.panelFill
            border.width: 1
            border.color: root.panelBorder
            clip: true

            ListView {
              id: results
              anchors.fill: parent
              anchors.margins: 8
              clip: true
              spacing: 6
              model: store.filtered.length
              currentIndex: root.selected
              boundsBehavior: Flickable.StopAtBounds

              delegate: Rectangle {
                required property int index
                readonly property var item: store.filtered[index] || ({})
                readonly property bool selected: root.selected === index
                width: results.width
                height: 58
                radius: 12
                color: selected ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.16) : root.softFill
                border.width: 1
                border.color: selected ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.28) : "transparent"

                Column {
                  anchors.fill: parent
                  anchors.margins: 10
                  spacing: 4

                  Text {
                    width: parent.width
                    text: item.name || item.packageId || "-"
                    color: selected ? Colors.text0 : Colors.text1
                    font { pixelSize: 13; family: "Inter"; weight: Font.DemiBold }
                    elide: Text.ElideRight
                  }

                  Text {
                    width: parent.width
                    text: (item.packageId || "-") + "  •  " + root.formatSource(item)
                    color: Colors.text3
                    font { pixelSize: 9; family: "JetBrains Mono" }
                    elide: Text.ElideRight
                  }
                }

                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onEntered: root.selected = index
                  onClicked: {
                    root.selected = index
                    root.runSelected()
                  }
                }
              }
            }
          }

          Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 16
            color: root.panelFill
            border.width: 1
            border.color: root.panelBorder
            clip: true

            ColumnLayout {
              anchors.fill: parent
              anchors.margins: 16
              spacing: 12

              Text {
                Layout.fillWidth: true
                text: root.currentItem ? root.currentItem.name : "Selecione um app"
                color: Colors.text0
                font { pixelSize: 22; family: "Inter"; weight: Font.DemiBold }
                elide: Text.ElideRight
              }

              Text {
                Layout.fillWidth: true
                Layout.preferredHeight: 54
                text: root.currentItem ? (root.currentItem.description || root.currentItem.packageId || "") : "Use a busca ou os filtros para navegar pelo catalogo."
                color: Colors.text2
                wrapMode: Text.Wrap
                font { pixelSize: 12; family: "Inter" }
                elide: Text.ElideRight
              }

              RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                  model: [
                    { label: "Origem", value: root.formatSource(root.currentItem), tone: Colors.info },
                    { label: "Estado", value: root.formatState(root.currentItem), tone: root.stateTone(root.currentItem) }
                  ]

                  delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 58
                    radius: 12
                    color: root.softFill
                    border.width: 1
                    border.color: root.panelBorder

                    Column {
                      anchors.fill: parent
                      anchors.margins: 10
                      spacing: 4

                      Text {
                        text: modelData.label
                        color: Colors.text3
                        font { pixelSize: 9; family: "JetBrains Mono"; weight: Font.DemiBold }
                      }

                      Text {
                        width: parent.width
                        text: modelData.value
                        color: modelData.tone
                        font { pixelSize: 12; family: "Inter"; weight: Font.Medium }
                        elide: Text.ElideRight
                      }
                    }
                  }
                }
              }

              Text {
                Layout.fillWidth: true
                text: root.currentItem ? store.actionDescription(root.currentItem) : ""
                color: Colors.text3
                wrapMode: Text.Wrap
                font { pixelSize: 11; family: "Inter" }
              }

              Item { Layout.fillHeight: true }

              Text {
                Layout.fillWidth: true
                text: store.errorMessage || store.warningMessage || store.infoMessage || root.keyboardHint()
                color: store.errorMessage ? Colors.danger : store.warningMessage ? Colors.warning : store.infoMessage ? Colors.success : Colors.text3
                wrapMode: Text.Wrap
                font { pixelSize: 10; family: "JetBrains Mono" }
              }

              RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                  Layout.fillWidth: true
                  Layout.preferredHeight: 46
                  radius: 14
                  color: root.isActionEnabled(root.currentItem) ? Colors.primary : Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, 0.12)
                  border.width: 1
                  border.color: root.isActionEnabled(root.currentItem) ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.34) : root.panelBorder

                  Text {
                    anchors.centerIn: parent
                    text: store.actionLabel(root.currentItem)
                    color: root.isActionEnabled(root.currentItem) ? Colors.bg0 : Colors.text3
                    font { pixelSize: 13; family: "Inter"; weight: Font.DemiBold }
                  }

                  MouseArea {
                    anchors.fill: parent
                    enabled: root.isActionEnabled(root.currentItem)
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.runSelected()
                  }
                }

                Rectangle {
                  Layout.preferredWidth: 132
                  Layout.preferredHeight: 46
                  radius: 14
                  color: store.pendingCount > 0 ? Qt.rgba(Colors.warning.r, Colors.warning.g, Colors.warning.b, 0.16) : root.softFill
                  border.width: 1
                  border.color: store.pendingCount > 0 ? Qt.rgba(Colors.warning.r, Colors.warning.g, Colors.warning.b, 0.26) : root.panelBorder

                  Text {
                    anchors.centerIn: parent
                    text: "Rebuild"
                    color: store.pendingCount > 0 ? Colors.warning : Colors.text3
                    font { pixelSize: 12; family: "Inter"; weight: Font.DemiBold }
                  }

                  MouseArea {
                    anchors.fill: parent
                    enabled: store.pendingCount > 0 && !store.applying && !store.rebuilding
                    cursorShape: Qt.PointingHandCursor
                    onClicked: store.applyPendingAndRebuild()
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  AppCenterStore {
    id: store
  }

  Connections {
    target: store
    function onFilteredChanged() { root.clampSelection() }
    function onRebuildOpened() { root.close() }
  }

  Timer {
    id: focusTimer
    interval: 20
    repeat: false
    onTriggered: searchInput.forceActiveFocus()
  }
}
