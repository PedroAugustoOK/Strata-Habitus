import Quickshell
import Quickshell.Wayland
import QtQuick
import ".."

PanelWindow {
  id: root
  anchors { top: true; left: true; right: true; bottom: true }
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  focusable: true
  visible: false
  onVisibleChanged: {
    if (visible) OverlayState.setActive("appcenter")
    else OverlayState.clear("appcenter")
  }

  property int selected: 0
  property real cardYOffset: 20
  property real progressValue: 0
  readonly property color cardBase: Colors.panelBackground
  readonly property color cardAccentWash: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, Colors.darkMode ? 0.10 : 0.06)
  readonly property color cardTop: Colors.darkMode
    ? Qt.rgba(Colors.bg2.r, Colors.bg2.g, Colors.bg2.b, 0.98)
    : Qt.rgba(Colors.bg2.r, Colors.bg2.g, Colors.bg2.b, 0.94)
  readonly property color cardBottom: Colors.darkMode
    ? Qt.rgba(Colors.bg0.r, Colors.bg0.g, Colors.bg0.b, 0.98)
    : Qt.rgba(Colors.bg1.r, Colors.bg1.g, Colors.bg1.b, 0.96)
  readonly property color panelFill: Colors.darkMode
    ? Qt.rgba(Colors.bg2.r, Colors.bg2.g, Colors.bg2.b, 0.58)
    : Qt.rgba(Colors.bg2.r, Colors.bg2.g, Colors.bg2.b, 0.86)
  readonly property color panelBorder: Colors.darkMode
    ? Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, 0.08)
    : Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, 0.14)
  readonly property color softFill: Colors.darkMode
    ? Qt.rgba(1, 1, 1, 0.04)
    : Qt.rgba(0, 0, 0, 0.035)
  readonly property color softerFill: Colors.darkMode
    ? Qt.rgba(1, 1, 1, 0.025)
    : Qt.rgba(0, 0, 0, 0.024)
  readonly property color searchFill: Colors.darkMode
    ? Qt.rgba(0, 0, 0, 0.18)
    : Qt.rgba(1, 1, 1, 0.55)
  property var filters: [
    { key: "discover", label: "Destaques" },
    { key: "available", label: "Disponiveis" },
    { key: "installed", label: "Instalados" },
    { key: "managed", label: "Gerenciados" },
    { key: "base", label: "Base" }
  ]
  readonly property var currentItem: store.filtered.length > 0 ? store.filtered[Math.max(0, Math.min(selected, store.filtered.length - 1))] : null
  readonly property var currentQueueMode: store.queueModeFor(currentItem)
  readonly property bool busy: store.loading || store.applying || store.rebuilding
  readonly property real progressTarget: store.loading
    ? 0.34
    : store.applying
      ? 0.68
      : store.rebuilding
        ? 0.94
        : 0
  readonly property int progressStepIndex: store.loading ? 1 : store.applying ? 2 : store.rebuilding ? 3 : 0
  readonly property color progressTone: store.loading
      ? Colors.info
    : store.rebuilding
      ? Colors.warning
      : Colors.success
  readonly property string progressLabel: store.loading
    ? "Atualizando catalogo"
    : store.rebuilding
      ? "Abrindo rebuild"
      : store.applying
        ? "Aplicando alteracoes"
        : ""
  readonly property string progressStepOne: "Catalogo"
  readonly property string progressStepTwo: "Aplicar"
  readonly property string progressStepThree: "Rebuild"
  readonly property string queueHeadline: store.pendingCount === 0
    ? "Fila vazia"
    : store.pendingCount === 1
      ? "1 app na fila"
      : (store.pendingCount + " apps na fila")

  function toggle() {
    if (visible) {
      closeAnim.start()
      return
    }

    visible = true
    selected = 0
    searchInput.text = ""
    store.setMode("discover")
    store.reload()
    card.opacity = 0
    cardScale.xScale = 0.985
    cardScale.yScale = 0.985
    cardYOffset = 16
    openAnim.start()
  }

  function close() {
    closeAnim.start()
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
  }

  function runSelected() {
    if (!currentItem) return
    store.runAction(currentItem)
  }

  function primaryAction() {
    runSelected()
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
    if (item.source === "flatpak" && item.installed) {
      return item.installedScope === "system" ? "Flatpak system" : "Flatpak user"
    }
    if (item.source === "nix" && item.managed && !item.installed) {
      return "Pendente de rebuild"
    }
    if (item.managed) return "Gerenciado"
    if (item.installed) return "Instalado"
    return "Disponivel"
  }

  function keyboardHint() {
    if (store.pendingCount > 0) return "Enter age no item atual. Ctrl+R confirma a fila."
    if (currentItem && currentItem.source === "flatpak") return "Enter aplica imediatamente via Flatpak."
    if (currentItem && currentItem.source === "nix" && currentItem.action !== "none") return "Enter adiciona ou remove este app da fila."
    if (currentItem && currentItem.source === "nix" && currentItem.installed) return "Apps da base mostram um aviso. Para remover, ajuste modules/packages.nix."
    return "Use setas para navegar e Enter para agir."
  }

  function stateFillColor(item) {
    if (!item) return root.softFill
    if (item.source === "nix" && item.managed && !item.installed) {
      return Qt.rgba(Colors.warning.r, Colors.warning.g, Colors.warning.b, Colors.darkMode ? 0.18 : 0.14)
    }
    if (item.managed) {
      return Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.14)
    }
    if (item.installed) {
      return Qt.rgba(Colors.success.r, Colors.success.g, Colors.success.b, Colors.darkMode ? 0.18 : 0.14)
    }
    return root.softFill
  }

  function stateTextColor(item) {
    if (!item) return Colors.text3
    if (item.source === "nix" && item.managed && !item.installed) return Colors.warning
    if (item.managed) return Colors.primary
    if (item.installed) return Colors.success
    return Colors.text3
  }

  function handleKeyEvent(event) {
    if ((event.key === Qt.Key_R || event.key === Qt.Key_B) && (event.modifiers & Qt.ControlModifier)) {
      store.applyPendingAndRebuild()
      event.accepted = true
    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
      root.primaryAction()
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

  Keys.priority: Keys.BeforeItem
  Keys.onPressed: function(event) {
    root.handleKeyEvent(event)
  }

  Timer {
    interval: 80
    repeat: true
    running: root.busy
    onTriggered: {
      if (root.progressValue < root.progressTarget) {
        root.progressValue = Math.min(
          root.progressTarget,
          root.progressValue + Math.max(0.01, (root.progressTarget - root.progressValue) * 0.18)
        )
      }
    }
  }

  onBusyChanged: {
    if (!busy) {
      progressValue = 0
    } else if (progressValue === 0) {
      progressValue = 0.08
    }
  }

  SequentialAnimation {
    id: openAnim
    ParallelAnimation {
      NumberAnimation { target: root; property: "cardYOffset"; from: 16; to: 0; duration: 190; easing.type: Easing.OutCubic }
      NumberAnimation { target: card; property: "opacity"; from: 0; to: 1; duration: 140; easing.type: Easing.OutQuad }
      NumberAnimation { target: cardScale; property: "xScale"; from: 0.985; to: 1; duration: 190; easing.type: Easing.OutCubic }
      NumberAnimation { target: cardScale; property: "yScale"; from: 0.985; to: 1; duration: 190; easing.type: Easing.OutCubic }
    }
    ScriptAction { script: searchInput.forceActiveFocus() }
  }

  SequentialAnimation {
    id: closeAnim
    ParallelAnimation {
      NumberAnimation { target: root; property: "cardYOffset"; to: 10; duration: 120; easing.type: Easing.InCubic }
      NumberAnimation { target: cardScale; property: "xScale"; to: 0.992; duration: 120; easing.type: Easing.InCubic }
      NumberAnimation { target: cardScale; property: "yScale"; to: 0.992; duration: 120; easing.type: Easing.InCubic }
      NumberAnimation { target: card; property: "opacity"; to: 0; duration: 95; easing.type: Easing.InQuad }
    }
    ScriptAction { script: {
      root.visible = false
      root.selected = 0
    }}
  }

  MouseArea {
    anchors.fill: parent
    onClicked: root.close()
  }

  AppCenterStore {
    id: store
  }

  Connections {
    target: store
    function onFilteredChanged() { root.clampSelection() }
    function onRebuildOpened() { root.close() }
  }

  onSelectedChanged: {
    if (visible && store.filtered.length > 0) {
      results.positionViewAtIndex(selected, ListView.Contain)
    }
  }

  Rectangle {
    id: card
    anchors.centerIn: parent
    anchors.verticalCenterOffset: cardYOffset
    width: 980
    height: 612
    radius: 28
    antialiasing: true
    color: root.cardBase
    border.width: 1
    border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.22)
    opacity: 0
    clip: true
    transform: Scale {
      id: cardScale
      origin.x: Math.max(0, Math.min(card.width, OverlayState.islandCenterX - card.x))
      origin.y: Math.max(0, Math.min(card.height, OverlayState.islandCenterY - card.y))
      xScale: 1
      yScale: 1
    }

    Rectangle {
      anchors.fill: parent
      radius: parent.radius
      antialiasing: true
      gradient: Gradient {
        GradientStop { position: 0.0; color: root.cardTop }
        GradientStop { position: 0.38; color: root.cardBase }
        GradientStop { position: 1.0; color: root.cardBottom }
      }
    }

    Rectangle {
      anchors.fill: parent
      radius: parent.radius
      antialiasing: true
      color: "transparent"
      gradient: Gradient {
        GradientStop { position: 0.0; color: root.cardAccentWash }
        GradientStop { position: 1.0; color: "transparent" }
      }
    }

    Item {
      anchors.fill: parent

      Rectangle {
        id: hero
        x: 20
        y: 18
        width: parent.width - 40
        height: 92
        radius: 20
        antialiasing: true
        color: root.softFill
        border.width: 1
        border.color: root.panelBorder

        Text {
          x: 18
          y: 14
          text: "Central de Apps"
          color: Colors.text1
          font { pixelSize: 22; family: "JetBrainsMono Nerd Font" }
        }

        Text {
          x: 18
          y: 42
          text: store.filtered.length + " apps"
          color: Colors.text3
          font { pixelSize: 10; family: "JetBrainsMono Nerd Font" }
        }

        Rectangle {
          anchors.horizontalCenter: parent.horizontalCenter
          y: 16
          width: 98
          height: 20
          radius: 10
          color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.14)

          Text {
            anchors.centerIn: parent
            text: "Nix + Flatpak"
            color: Colors.primary
            font { pixelSize: 9; family: "JetBrainsMono Nerd Font" }
          }
        }

        Rectangle {
          x: parent.width - 194
          y: 14
          width: 176
          height: 46
          radius: 14
          color: store.pendingCount > 0
            ? Qt.rgba(Colors.warning.r, Colors.warning.g, Colors.warning.b, 0.16)
            : Qt.rgba(1, 1, 1, 0.035)
          border.width: 1
          border.color: store.pendingCount > 0
            ? Qt.rgba(Colors.warning.r, Colors.warning.g, Colors.warning.b, 0.24)
            : Qt.rgba(1, 1, 1, 0.06)

          Text {
            anchors.centerIn: parent
            text: queueHeadline
            color: store.pendingCount > 0 ? Colors.warning : Colors.text2
            font { pixelSize: 10; family: "JetBrainsMono Nerd Font" }
          }
        }

        Item {
          x: 18
          y: 66
          width: parent.width - 36
          height: 18
          visible: root.busy
          opacity: root.busy ? 1 : 0

          Behavior on opacity { NumberAnimation { duration: 140 } }

          Text {
            anchors.left: parent.left
            y: -1
            text: root.progressLabel
            color: root.progressTone
            font { pixelSize: 9; family: "JetBrainsMono Nerd Font" }
          }

          Text {
            anchors.right: parent.right
            y: -1
            text: Math.round(root.progressValue * 100) + "%"
            color: Colors.text2
            font { pixelSize: 9; family: "JetBrainsMono Nerd Font" }
          }

          Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 6
            radius: 3
            color: Qt.rgba(1, 1, 1, 0.08)
            clip: true

            Rectangle {
              width: parent.width * root.progressValue
              height: parent.height
              radius: 3
              color: root.progressTone
              Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            }
          }

          Row {
            anchors.horizontalCenter: parent.horizontalCenter
            y: -1
            spacing: 6

            Rectangle {
              width: 10
              height: 10
              radius: 5
              color: root.progressStepIndex >= 1 ? root.progressTone : Qt.rgba(1, 1, 1, 0.10)
            }

            Text {
              text: root.progressStepOne
              color: root.progressStepIndex >= 1 ? Colors.text2 : Colors.text3
              font { pixelSize: 8; family: "JetBrainsMono Nerd Font" }
            }

            Rectangle {
              width: 10
              height: 10
              radius: 5
              color: root.progressStepIndex >= 2 ? root.progressTone : Qt.rgba(1, 1, 1, 0.10)
            }

            Text {
              text: root.progressStepTwo
              color: root.progressStepIndex >= 2 ? Colors.text2 : Colors.text3
              font { pixelSize: 8; family: "JetBrainsMono Nerd Font" }
            }

            Rectangle {
              width: 10
              height: 10
              radius: 5
              color: root.progressStepIndex >= 3 ? root.progressTone : Qt.rgba(1, 1, 1, 0.10)
            }

            Text {
              text: root.progressStepThree
              color: root.progressStepIndex >= 3 ? Colors.text2 : Colors.text3
              font { pixelSize: 8; family: "JetBrainsMono Nerd Font" }
            }
          }
        }
      }

      Rectangle {
        id: rail
        x: 20
        y: 124
        width: 152
        height: 436
        radius: 20
        antialiasing: true
        color: root.panelFill
        border.width: 1
        border.color: root.panelBorder

        Column {
          x: 12
          y: 12
          width: parent.width - 28
          spacing: 6

          Repeater {
            model: root.filters
            delegate: Rectangle {
              required property var modelData
              width: parent.width
              height: 42
              radius: 12
              antialiasing: true
              color: store.mode === modelData.key
                ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.18)
                : root.softFill
              border.width: 1
              border.color: store.mode === modelData.key
                ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.26)
                : root.panelBorder

              Text {
                x: 12
                anchors.verticalCenter: parent.verticalCenter
                text: modelData.label
                color: store.mode === modelData.key ? Colors.primary : Colors.text2
                font { pixelSize: 11; family: "JetBrainsMono Nerd Font" }
              }

              MouseArea {
                anchors.fill: parent
                onClicked: {
                  root.selected = 0
                  store.setMode(modelData.key)
                  searchInput.forceActiveFocus()
                }
              }
            }
          }
        }
      }

      Rectangle {
        id: centerPane
        x: 186
        y: 124
        width: 418
        height: 436
        radius: 20
        antialiasing: true
        color: root.panelFill
        border.width: 1
        border.color: root.panelBorder
        clip: true

        Rectangle {
          x: 16
          y: 16
          width: parent.width - 32
          height: 42
          radius: 13
          antialiasing: true
          color: root.searchFill
          border.width: 1
          border.color: searchInput.activeFocus
            ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.30)
            : root.panelBorder

          Text {
            x: 16
            anchors.verticalCenter: parent.verticalCenter
            text: "󰍉"
            color: Colors.primary
            font { pixelSize: 15; family: "JetBrainsMono Nerd Font" }
          }

          TextInput {
            id: searchInput
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 42
            anchors.rightMargin: 16
            color: Colors.text1
            font { pixelSize: 14; family: "JetBrainsMono Nerd Font" }
            selectByMouse: true
            Keys.priority: Keys.BeforeItem
            onTextChanged: {
              root.selected = 0
              store.search(text)
            }
            Keys.onEscapePressed: root.close()
            Keys.onUpPressed: {
              root.moveSelection(-1)
            }
            Keys.onDownPressed: {
              root.moveSelection(1)
            }
            Keys.onPressed: function(event) {
              root.handleKeyEvent(event)
            }
          }

          Text {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 42
            anchors.rightMargin: 16
            text: "Buscar por nome, pacote ou descricao..."
            color: Colors.text3
            font { pixelSize: 13; family: "JetBrainsMono Nerd Font" }
            visible: searchInput.text.length === 0
          }
        }

        Rectangle {
          x: 16
          y: 64
          width: parent.width - 32
          height: 34
          radius: 11
          antialiasing: true
          color: (store.loading || store.applying || store.rebuilding)
            ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.16)
            : root.softFill
          border.width: 1
          border.color: (store.loading || store.applying || store.rebuilding)
            ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.24)
            : root.panelBorder

          Text {
            x: 14
            anchors.verticalCenter: parent.verticalCenter
            text: store.loading
              ? "Carregando catalogo..."
              : store.applying
                ? "Aplicando alteracoes..."
                : store.rebuilding
                  ? "Abrindo rebuild..."
                  : store.mode
            color: (store.loading || store.applying || store.rebuilding) ? Colors.primary : Colors.text2
            font { pixelSize: 10; family: "JetBrainsMono Nerd Font" }
          }
        }

        ListView {
          id: results
          x: 12
          y: 108
          width: parent.width - 24
          height: parent.height - 120
          clip: true
          spacing: 8
          model: store.filtered.length

          delegate: Rectangle {
            property var item: store.filtered[index] || ({})
            width: results.width
            height: 76
            radius: 14
            antialiasing: true
            color: root.selected === index
              ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.18)
              : mouse.containsMouse
                ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, Colors.darkMode ? 0.08 : 0.06)
                : root.softerFill
            border.width: 1
            border.color: root.selected === index
              ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.28)
              : root.panelBorder
            Behavior on color { ColorAnimation { duration: 110 } }
            Behavior on border.color { ColorAnimation { duration: 110 } }

            Rectangle {
              x: 14
              y: 16
              width: 36
              height: 36
              radius: 10
              antialiasing: true
              color: item.source === "flatpak"
                ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.16)
                : root.softFill

              Text {
                anchors.centerIn: parent
                text: item.source === "flatpak" ? "F" : "N"
                color: item.source === "flatpak" ? Colors.primary : Colors.text2
                font { pixelSize: 13; family: "JetBrainsMono Nerd Font" }
              }
            }

            Text {
              x: 74
              y: 12
              width: parent.width - 186
              text: item.name || ""
              color: Colors.text1
              font { pixelSize: 13; family: "JetBrainsMono Nerd Font" }
              elide: Text.ElideRight
            }

            Text {
              x: 74
              y: 30
              width: parent.width - 186
              height: 24
              text: item.description || item.packageId || ""
              color: Colors.text3
              font { pixelSize: 10; family: "JetBrainsMono Nerd Font" }
              wrapMode: Text.WordWrap
              maximumLineCount: 2
              elide: Text.ElideRight
              clip: true
            }

            Row {
              x: 74
              y: 50
              spacing: 6

              Rectangle {
                width: sourceLabel.implicitWidth + 16
                height: 22
                radius: 8
                antialiasing: true
                color: item.source === "flatpak"
                  ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.12)
                  : root.softFill

                Text {
                  id: sourceLabel
                  anchors.centerIn: parent
                  text: item.source === "flatpak" ? "Flatpak" : "Nix"
                  color: item.source === "flatpak" ? Colors.primary : Colors.text2
                  font { pixelSize: 10; family: "JetBrainsMono Nerd Font" }
                }
              }

              Rectangle {
                width: stateLabel.implicitWidth + 16
                height: 22
                radius: 8
                antialiasing: true
                color: root.stateFillColor(item)
                border.width: 1
                border.color: Qt.rgba(root.stateTextColor(item).r, root.stateTextColor(item).g, root.stateTextColor(item).b, 0.24)

                Text {
                  id: stateLabel
                  anchors.centerIn: parent
                  text: formatState(item)
                  color: root.stateTextColor(item)
                  font { pixelSize: 10; family: "JetBrainsMono Nerd Font" }
                }
              }

              Rectangle {
                visible: item.source === "nix" && item.action !== "none"
                width: queueLabel.implicitWidth + 16
                height: 22
                radius: 8
                antialiasing: true
                color: store.isQueued(item) ? Qt.rgba(Colors.warning.r, Colors.warning.g, Colors.warning.b, 0.14)
                  : root.softerFill

                Text {
                  id: queueLabel
                  anchors.centerIn: parent
                  text: store.isQueued(item) ? "Na fila" : "Fila"
                  color: store.isQueued(item) ? Colors.warning : Colors.text3
                  font { pixelSize: 10; family: "JetBrainsMono Nerd Font" }
                }
              }
            }

            Rectangle {
              id: rowAction
              x: parent.width - 92
              y: 18
              width: 72
              height: 34
              radius: 11
              antialiasing: true
              visible: item.action !== "none"
              color: item.source === "flatpak"
                ? (item.installed
                    ? root.softFill
                    : Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.16))
                : (store.isQueued(item) ? Qt.rgba(Colors.warning.r, Colors.warning.g, Colors.warning.b, 0.16)
                    : root.softFill)
              border.width: 1
              border.color: root.panelBorder

              Text {
                anchors.centerIn: parent
                text: item.source === "nix"
                  ? (store.isQueued(item) ? "Tirar" : "+")
                  : (item.installed ? "Tirar" : "+")
                color: item.source === "flatpak"
                  ? (item.installed ? Colors.text2 : Colors.primary)
                  : (store.isQueued(item) ? Colors.warning : Colors.text2)
                font { pixelSize: 10; family: "JetBrainsMono Nerd Font" }
              }

              MouseArea {
                anchors.fill: parent
                enabled: !store.applying
                onClicked: {
                  root.selected = index
                  store.runAction(item)
                  searchInput.forceActiveFocus()
                }
              }
            }

            MouseArea {
              id: mouse
              anchors.fill: parent
              hoverEnabled: true
              onEntered: root.selected = index
              onClicked: {
                root.selected = index
                searchInput.forceActiveFocus()
              }
            }
          }
        }
      }

      Rectangle {
        id: detailPane
        x: 618
        y: 124
        width: 342
        height: 436
        radius: 20
        antialiasing: true
        color: root.panelFill
        border.width: 1
        border.color: root.panelBorder

        Rectangle {
          x: 16
          y: 16
          width: parent.width - 32
          height: 126
          radius: 16
          antialiasing: true
          color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.10)
          border.width: 1
          border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.16)
          clip: true

          Rectangle {
            x: 18
            y: 18
            width: 56
            height: 56
            radius: 18
            antialiasing: true
            color: root.softFill

            Text {
              anchors.centerIn: parent
              text: currentItem ? (currentItem.source === "flatpak" ? "F" : "N") : "?"
              color: currentItem && currentItem.source === "flatpak" ? Colors.primary : Colors.text2
              font { pixelSize: 20; family: "JetBrainsMono Nerd Font" }
            }
          }

          Text {
            x: 88
            y: 18
            width: parent.width - 106
            text: currentItem ? currentItem.name : "Nenhum app selecionado"
            color: Colors.text1
            font { pixelSize: 18; family: "JetBrainsMono Nerd Font" }
            elide: Text.ElideRight
          }

          Text {
            x: 88
            y: 48
            width: parent.width - 106
            text: currentItem ? (currentItem.packageId || "") : "Passe o mouse ou use as setas para explorar."
            color: Colors.text3
            font { pixelSize: 10; family: "JetBrainsMono Nerd Font" }
            elide: Text.ElideRight
          }

          Row {
            x: 18
            y: 84
            spacing: 6

            Rectangle {
              width: sourceTag.implicitWidth + 16
              height: 24
              radius: 8
              color: currentItem && currentItem.source === "flatpak"
                ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.12)
                : Qt.rgba(1, 1, 1, 0.05)

              Text {
                id: sourceTag
                anchors.centerIn: parent
                text: formatSource(currentItem)
                color: currentItem && currentItem.source === "flatpak" ? Colors.primary : Colors.text2
                font { pixelSize: 10; family: "JetBrainsMono Nerd Font" }
              }
            }

            Rectangle {
              width: stateTag.implicitWidth + 16
              height: 24
              radius: 8
              color: root.stateFillColor(currentItem)
              border.width: 1
              border.color: currentItem
                ? Qt.rgba(root.stateTextColor(currentItem).r, root.stateTextColor(currentItem).g, root.stateTextColor(currentItem).b, 0.24)
                : root.panelBorder

              Text {
                id: stateTag
                anchors.centerIn: parent
                text: formatState(currentItem)
                color: root.stateTextColor(currentItem)
                font { pixelSize: 10; family: "JetBrainsMono Nerd Font" }
              }
            }

            Rectangle {
              visible: !!currentItem && currentItem.source === "nix" && currentItem.action !== "none"
              width: queueTag.implicitWidth + 16
              height: 24
              radius: 8
              color: store.isQueued(currentItem) ? Qt.rgba(Colors.warning.r, Colors.warning.g, Colors.warning.b, 0.14)
                : Qt.rgba(1, 1, 1, 0.04)

              Text {
                id: queueTag
                anchors.centerIn: parent
                text: store.isQueued(currentItem)
                  ? (currentQueueMode === "remove" ? "Remocao na fila" : "Instalacao na fila")
                  : "Nao esta na fila"
                color: store.isQueued(currentItem) ? Colors.warning : Colors.text3
                font { pixelSize: 10; family: "JetBrainsMono Nerd Font" }
              }
            }
          }

          Text {
            x: 18
            y: 110
            width: parent.width - 36
            height: 14
            text: currentItem
              ? (currentItem.description || currentItem.packageId || "")
              : "Selecione um app para ver detalhes, origem e o tipo de acao."
            color: Colors.text2
            font { pixelSize: 11; family: "JetBrainsMono Nerd Font" }
            wrapMode: Text.WordWrap
            maximumLineCount: 1
            elide: Text.ElideRight
            clip: true
          }
        }

        Rectangle {
          x: 16
          y: 156
          width: parent.width - 32
          height: 166
          radius: 16
          antialiasing: true
          color: store.pendingCount > 0
            ? Qt.rgba(Colors.warning.r, Colors.warning.g, Colors.warning.b, 0.10)
            : root.softFill
          border.width: 1
          border.color: store.pendingCount > 0
            ? Qt.rgba(Colors.warning.r, Colors.warning.g, Colors.warning.b, 0.16)
            : root.panelBorder
          clip: true

          Text {
            x: 16
            y: 14
            text: "Lista de compras"
            color: store.pendingCount > 0 ? Colors.warning : Colors.text2
            font { pixelSize: 11; family: "JetBrainsMono Nerd Font" }
          }

          Text {
            x: 16
            y: 34
            width: parent.width - 32
            text: store.pendingCount > 0
              ? queueHeadline
              : "Apps Nix marcados aparecem aqui."
            color: Colors.text3
            font { pixelSize: 10; family: "JetBrainsMono Nerd Font" }
          }

          ListView {
            x: 12
            y: 58
            width: parent.width - 24
            height: 96
            clip: true
            spacing: 6
            model: store.pendingChanges

            delegate: Rectangle {
              required property var modelData
              width: parent ? parent.width : 0
              height: 24
              radius: 8
              antialiasing: true
              color: root.softFill

              Text {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 58
                text: (modelData.mode === "remove" ? "Remover " : "Instalar ") + (modelData.name || modelData.packageId)
                color: Colors.text2
                font { pixelSize: 9; family: "JetBrainsMono Nerd Font" }
                elide: Text.ElideRight
              }

              Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                width: 34
                height: 18
                radius: 7
                antialiasing: true
                color: root.softerFill

                Text {
                  anchors.centerIn: parent
                  text: "x"
                  color: Colors.text3
                  font { pixelSize: 9; family: "JetBrainsMono Nerd Font" }
                }

                MouseArea {
                  anchors.fill: parent
                  onClicked: store.removePending(modelData.packageId)
                }
              }
            }
          }
        }

        Rectangle {
          x: 16
          y: 338
          width: parent.width - 32
          height: 40
          radius: 13
          antialiasing: true
          color: store.pendingCount > 0
            ? Qt.rgba(Colors.warning.r, Colors.warning.g, Colors.warning.b, 0.18)
            : root.softFill
          border.width: 1
          border.color: store.pendingCount > 0
            ? Qt.rgba(Colors.warning.r, Colors.warning.g, Colors.warning.b, 0.24)
            : root.panelBorder

          Text {
            anchors.centerIn: parent
            text: store.pendingCount > 0
              ? (store.rebuilding
                  ? "Abrindo rebuild..."
                  : store.applying
                    ? "Aplicando lista..."
                    : "Confirmar lista e rebuild")
              : "Fila vazia"
            color: store.pendingCount > 0 ? Colors.warning : Colors.text3
            font { pixelSize: 11; family: "JetBrainsMono Nerd Font" }
          }

          MouseArea {
            anchors.fill: parent
            enabled: store.pendingCount > 0 && !store.applying && !store.rebuilding
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: store.applyPendingAndRebuild()
          }
        }
      }

      Rectangle {
        x: 20
        y: 572
        width: parent.width - 40
        height: 20
        radius: 12
        color: "transparent"

        Text {
          anchors.centerIn: parent
          text: store.errorMessage !== ""
            ? store.errorMessage
            : (store.infoMessage !== ""
                ? store.infoMessage
                : (store.warningMessage !== ""
                    ? store.warningMessage
                    : keyboardHint()))
          color: store.errorMessage !== ""
            ? Colors.danger
            : (store.infoMessage !== ""
                ? Colors.primary
                : (store.warningMessage !== "" ? Colors.warning : Colors.text3))
          font { pixelSize: 9; family: "JetBrainsMono Nerd Font" }
        }
      }
    }
  }
}
