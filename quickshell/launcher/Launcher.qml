import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import ".."

PanelWindow {
  id: launcher
  anchors { top: true; left: true; right: true; bottom: true }
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  focusable: true
  visible: false
  onVisibleChanged: {
    if (visible) OverlayState.setActive("launcher")
    else OverlayState.clear("launcher")
  }

  readonly property int cardW: 720
  readonly property int cardHeaderH: 62
  readonly property int cardFooterH: 36
  readonly property int itemH: 62
  readonly property int actionItemH: 42
  readonly property int maxVisibleItems: 10
  readonly property int visibleRows: Math.max(1, Math.min(maxVisibleItems, store.results.length > 0 ? store.results.length : 4))
  readonly property int listH: visibleRows * itemH + 8
  readonly property var selectedItem: store.results.length > 0 ? store.results[selected] : null
  readonly property var currentActions: selectedItem && selectedItem.actions ? selectedItem.actions : []
  readonly property int actionRows: Math.max(1, Math.min(4, currentActions.length > 0 ? currentActions.length : 1))
  readonly property int actionsH: actionMode ? actionRows * actionItemH + 46 : 0

  property int selected: 0
  property bool actionMode: false
  property int actionSelected: 0
  property real cardYOffset: 18
  property bool closingForLaunch: false

  function toggle() {
    if (visible) {
      closeAnim.start()
      return
    }

    visible = true
    selected = 0
    actionSelected = 0
    actionMode = false
    searchInput.text = ""
    store.showAll = false
    store.launchError = ""
    card.opacity = 0
    cardScale.xScale = 0.985
    cardScale.yScale = 0.985
    cardYOffset = 16
    closingForLaunch = false
    store.ensureIndex()
    openAnim.start()
  }

  function close() {
    if (actionMode) {
      actionMode = false
      actionSelected = 0
      return
    }
    closeAnim.start()
  }

  function moveSelection(delta) {
    if (store.results.length === 0) return
    selected = Math.max(0, Math.min(store.results.length - 1, selected + delta))
    actionSelected = 0
    actionMode = false
    resultList.positionViewAtIndex(selected, ListView.Contain)
  }

  function jumpSelection(target) {
    if (store.results.length === 0) return
    selected = Math.max(0, Math.min(store.results.length - 1, target))
    actionSelected = 0
    actionMode = false
    resultList.positionViewAtIndex(selected, ListView.Contain)
  }

  function launchSelected() {
    if (store.results.length === 0) return
    if (actionMode) {
      launchSelectedAction()
      return
    }
    if (store.launchItem(store.results[selected])) {
      closingForLaunch = true
      closeAnim.start()
    }
  }

  function toggleActionMode() {
    if (currentActions.length === 0) return
    actionMode = !actionMode
    if (!actionMode) actionSelected = 0
  }

  function moveActionSelection(delta) {
    if (currentActions.length === 0) return
    actionSelected = Math.max(0, Math.min(currentActions.length - 1, actionSelected + delta))
    actionList.positionViewAtIndex(actionSelected, ListView.Contain)
  }

  function launchSelectedAction() {
    if (currentActions.length === 0) return
    if (store.launchAction(selectedItem, currentActions[actionSelected])) {
      closingForLaunch = true
      closeAnim.start()
    }
  }

  function togglePinSelected() {
    if (store.results.length === 0) return
    store.togglePin(store.results[selected])
  }

  SequentialAnimation {
    id: openAnim
    ParallelAnimation {
      NumberAnimation { target: launcher; property: "cardYOffset"; from: OverlayState.morphStartYOffset(launcher.height); to: 0; duration: 260; easing.type: Easing.OutCubic }
      NumberAnimation { target: card; property: "opacity"; from: 0; to: 1; duration: 120; easing.type: Easing.OutQuad }
      NumberAnimation { target: cardScale; property: "xScale"; from: OverlayState.morphStartXScale(card.width); to: 1; duration: 260; easing.type: Easing.OutCubic }
      NumberAnimation { target: cardScale; property: "yScale"; from: OverlayState.morphStartYScale(card.height); to: 1; duration: 260; easing.type: Easing.OutCubic }
    }
    ScriptAction { script: searchInput.forceActiveFocus() }
  }

  SequentialAnimation {
    id: closeAnim
    ParallelAnimation {
      NumberAnimation { target: launcher; property: "cardYOffset"; to: OverlayState.morphStartYOffset(launcher.height); duration: 150; easing.type: Easing.InCubic }
      NumberAnimation { target: cardScale; property: "xScale"; to: OverlayState.morphStartXScale(card.width); duration: 150; easing.type: Easing.InCubic }
      NumberAnimation { target: cardScale; property: "yScale"; to: OverlayState.morphStartYScale(card.height); duration: 150; easing.type: Easing.InCubic }
      NumberAnimation { target: card; property: "opacity"; to: 0; duration: 110; easing.type: Easing.InQuad }
    }
    ScriptAction { script: {
      launcher.visible = false
      launcher.selected = 0
      launcher.actionSelected = 0
      launcher.actionMode = false
      launcher.closingForLaunch = false
      searchInput.text = ""
    }}
  }

  MouseArea {
    anchors.fill: parent
    onClicked: launcher.close()
  }

  LauncherStore {
    id: store
    resultLimit: launcher.maxVisibleItems
    onLaunched: function(ok) {
      if (ok) return

      if (launcher.closingForLaunch) {
        closeAnim.stop()
        launcher.visible = true
        card.opacity = 1
        cardScale.xScale = 1
        cardScale.yScale = 1
        launcher.cardYOffset = 0
      }

      launcher.closingForLaunch = false
    }
  }

  Rectangle {
    id: card
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    anchors.verticalCenterOffset: cardYOffset
    width: cardW
    height: cardHeaderH + listH + actionsH + cardFooterH + (store.launchError !== "" ? 26 : 0)
    radius: 18
    color: Colors.bg1
    border.width: 1
    border.color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.16)
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
      color: "transparent"
      border.width: 1
      border.color: Qt.rgba(1, 1, 1, 0.035)
    }

    Behavior on height {
      NumberAnimation { duration: 130; easing.type: Easing.OutCubic }
    }

    ColumnLayout {
      anchors.fill: parent
      spacing: 0

      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: cardHeaderH
        color: "transparent"

        RowLayout {
          anchors { fill: parent; leftMargin: 18; rightMargin: 18 }
          spacing: 12

          Rectangle {
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28
            radius: 10
            color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.14)

            Text {
              anchors.centerIn: parent
              text: "󰍉"
              color: Colors.accent
              font { pixelSize: 14; family: "JetBrainsMono Nerd Font" }
            }
          }

          TextInput {
            id: searchInput
            Layout.fillWidth: true
            color: Colors.text1
            font { pixelSize: 15; family: "JetBrainsMono Nerd Font" }
            cursorVisible: true
            verticalAlignment: TextInput.AlignVCenter
            selectionColor: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.35)
            selectedTextColor: Colors.text0
            onTextChanged: {
              launcher.selected = 0
              launcher.actionSelected = 0
              launcher.actionMode = false
              store.requestSearch(text)
            }

            Keys.onReturnPressed: launcher.launchSelected()
            Keys.onEscapePressed: launcher.close()
            Keys.onUpPressed: actionMode ? launcher.moveActionSelection(-1) : launcher.moveSelection(-1)
            Keys.onDownPressed: actionMode ? launcher.moveActionSelection(1) : launcher.moveSelection(1)
            Keys.onPressed: function(event) {
              if (event.key === Qt.Key_Tab) {
                launcher.toggleActionMode()
                event.accepted = true
                return
              }

              if (event.key === Qt.Key_PageDown) {
                actionMode ? launcher.moveActionSelection(4) : launcher.moveSelection(4)
                event.accepted = true
                return
              }

              if (event.key === Qt.Key_PageUp) {
                actionMode ? launcher.moveActionSelection(-4) : launcher.moveSelection(-4)
                event.accepted = true
                return
              }

              if (event.key === Qt.Key_Home) {
                launcher.jumpSelection(0)
                event.accepted = true
                return
              }

              if (event.key === Qt.Key_End) {
                launcher.jumpSelection(store.results.length - 1)
                event.accepted = true
                return
              }

              if (event.modifiers & Qt.ControlModifier) {
                if (event.key === Qt.Key_A) {
                  store.toggleAllMode()
                  launcher.selected = 0
                  launcher.actionSelected = 0
                  launcher.actionMode = false
                  event.accepted = true
                } else if (event.key === Qt.Key_K) {
                  launcher.togglePinSelected()
                  event.accepted = true
                } else if (event.key === Qt.Key_R) {
                  store.rebuildIndex(true)
                  event.accepted = true
                }
              }
            }

            Text {
              anchors.fill: parent
              text: "Buscar apps, categorias e palavras-chave..."
              color: Colors.text3
              font { pixelSize: 15; family: "JetBrainsMono Nerd Font" }
              verticalAlignment: Text.AlignVCenter
              visible: searchInput.text.length === 0
            }
          }

          ColumnLayout {
            spacing: 1

            Text {
              text: store.isIndexing ? "indexando" : store.isSearching ? "buscando" : store.showAll ? "todos" : "apps"
              color: Colors.text3
              font { pixelSize: 10; family: "JetBrainsMono Nerd Font" }
            }

            Text {
              text: String(store.results.length)
              color: Colors.text2
              font { pixelSize: 12; family: "JetBrainsMono Nerd Font" }
            }
          }

          Rectangle {
            radius: 10
            color: store.showAll
              ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.16)
              : Qt.rgba(1, 1, 1, 0.04)
            border.width: 1
            border.color: store.showAll
              ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.28)
              : Qt.rgba(1, 1, 1, 0.06)
            Layout.preferredHeight: 28
            Layout.preferredWidth: allAppsLabel.implicitWidth + 18

            Text {
              id: allAppsLabel
              anchors.centerIn: parent
              text: "Todos os Apps"
              color: store.showAll ? Colors.accent : Colors.text3
              font { pixelSize: 10; family: "JetBrainsMono Nerd Font" }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                store.toggleAllMode()
                launcher.selected = 0
                launcher.actionSelected = 0
                launcher.actionMode = false
                searchInput.forceActiveFocus()
              }
            }
          }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.18)
      }

      Item {
        Layout.fillWidth: true
        Layout.preferredHeight: listH

        ListView {
          id: resultList
          anchors { fill: parent; margins: 8 }
          clip: true
          spacing: 4
          model: store.results.length
          currentIndex: launcher.selected
          boundsBehavior: Flickable.StopAtBounds
          interactive: store.results.length > 0

          delegate: LauncherListItem {
            width: resultList.width
            height: itemH
            item: store.results[index] || ({})
            itemIndex: index
            selected: launcher.selected === index
            onHovered: idx => launcher.selected = idx
            onTriggered: idx => {
              launcher.selected = idx
              launcher.launchSelected()
            }
          }

          visible: store.results.length > 0
        }

        LauncherEmptyState {
          anchors.fill: parent
          visible: store.results.length === 0
          isIndexing: store.isIndexing
          ready: store.ready
          hasQuery: searchInput.text.trim().length > 0
          showAll: store.showAll
          indexError: store.indexError
        }
      }

      Item {
        Layout.fillWidth: true
        Layout.preferredHeight: actionsH
        visible: actionMode

        Rectangle {
          anchors { fill: parent; leftMargin: 8; rightMargin: 8; topMargin: 4; bottomMargin: 4 }
          radius: 14
          color: Qt.rgba(1, 1, 1, 0.03)
          border.width: 1
          border.color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.10)

          ColumnLayout {
            anchors.fill: parent
            spacing: 0

            Rectangle {
              Layout.fillWidth: true
              Layout.preferredHeight: 38
              color: "transparent"

              RowLayout {
                anchors { fill: parent; leftMargin: 14; rightMargin: 14 }

                Text {
                  text: "Acoes de " + (selectedItem ? selectedItem.name : "")
                  color: Colors.text2
                  font { pixelSize: 11; family: "JetBrainsMono Nerd Font" }
                }

                Item { Layout.fillWidth: true }

                Text {
                  text: String(currentActions.length)
                  color: Colors.text3
                  font { pixelSize: 10; family: "JetBrainsMono Nerd Font" }
                }
              }
            }

            Rectangle {
              Layout.fillWidth: true
              Layout.preferredHeight: 1
              color: Qt.rgba(1, 1, 1, 0.05)
            }

            ListView {
              id: actionList
              Layout.fillWidth: true
              Layout.fillHeight: true
              Layout.leftMargin: 6
              Layout.rightMargin: 6
              Layout.topMargin: 6
              Layout.bottomMargin: 6
              clip: true
              spacing: 4
              model: currentActions.length
              interactive: currentActions.length > 0

              delegate: LauncherActionItem {
                width: actionList.width
                height: actionItemH
                action: currentActions[index] || ({})
                actionIndex: index
                selected: launcher.actionSelected === index
                onHovered: idx => launcher.actionSelected = idx
                onTriggered: idx => {
                  launcher.actionSelected = idx
                  launcher.launchSelectedAction()
                }
              }
            }
          }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: store.launchError !== "" ? 26 : 0
        color: "transparent"
        clip: true

        Text {
          anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 18; rightMargin: 18 }
          text: store.launchError
          color: "#ff8e8e"
          font { pixelSize: 10; family: "JetBrainsMono Nerd Font" }
          elide: Text.ElideRight
          visible: text !== ""
        }
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: Qt.rgba(1, 1, 1, 0.04)
      }

      LauncherFooter {
        Layout.fillWidth: true
        Layout.preferredHeight: cardFooterH
        Layout.leftMargin: 18
        Layout.rightMargin: 18
        selectedItem: launcher.selectedItem
        showAll: store.showAll
      }
    }
  }
}
