import QtQuick
import QtQuick.Layouts
import ".."
import "../launcher"

Item {
  id: root

  property bool open: false
  property int selected: 0
  property bool actionMode: false
  property int actionSelected: 0
  property bool closingForLaunch: false
  property int panelWidth: FrameTokens.launcherWidth
  property int bottomInset: FrameTokens.bottomInset
  property alias drawerVisible: drawer.visible
  property alias drawerOffsetScale: drawer.offsetScale
  readonly property int itemH: 62
  readonly property int actionItemH: 42
  readonly property int rows: Math.max(1, Math.min(5, store.results.length > 0 ? store.results.length : 4))
  readonly property int listH: rows * itemH + 8
  readonly property var selectedItem: store.results.length > 0 ? store.results[selected] : null
  readonly property var currentActions: selectedItem && selectedItem.actions ? selectedItem.actions : []
  readonly property int actionRows: Math.max(1, Math.min(4, currentActions.length > 0 ? currentActions.length : 1))
  readonly property int actionsH: actionMode ? actionRows * actionItemH + 46 : 0
  readonly property int panelHeight: 62 + root.listH + root.actionsH + 36 + root.bottomInset + (store.launchError !== "" ? 26 : 0)

  function toggle() {
    if (open) {
      close()
      return
    }

    open = true
    selected = 0
    actionSelected = 0
    actionMode = false
    closingForLaunch = false
    searchInput.text = ""
    store.showAll = false
    store.launchError = ""
    store.ensureIndex()
    OverlayState.setActive("launcher")
    focusTimer.restart()
  }

  function close() {
    open = false
    actionMode = false
    actionSelected = 0
    closingForLaunch = false
    searchInput.text = ""
    OverlayState.clear("launcher")
  }

  function moveSelection(delta) {
    if (store.results.length === 0) return
    selected = Math.max(0, Math.min(store.results.length - 1, selected + delta))
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
    closingForLaunch = true
    if (store.launchItem(store.results[selected])) close()
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
    closingForLaunch = true
    if (store.launchAction(selectedItem, currentActions[actionSelected])) close()
  }

  function togglePinSelected() {
    if (store.results.length === 0) return
    store.togglePin(store.results[selected])
  }

  anchors.fill: parent

  BottomDrawer {
    id: drawer
    width: root.panelWidth
    height: root.panelHeight
    open: root.open

    Binding { target: FramePanelState; property: "launcherOpen"; value: root.open }
    Binding { target: FramePanelState; property: "launcherVisible"; value: drawer.visible }
    Binding { target: FramePanelState; property: "launcherOffsetScale"; value: drawer.offsetScale }
    Binding { target: FramePanelState; property: "launcherWidth"; value: root.panelWidth }
    Binding { target: FramePanelState; property: "launcherHeight"; value: root.panelHeight }

    FrameBlobSurface {
      anchors.fill: parent
      drawSurface: false
      radius: FrameTokens.compactSurfaceRadius
      attachedEdge: "bottom"
      fillColor: Colors.panelBackground
      borderColor: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.18)
      deformScale: 0.000028
      stiffness: 165
      damping: 20

      ColumnLayout {
        anchors { fill: parent; bottomMargin: root.bottomInset }
        spacing: 0

        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 62
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
              cursorVisible: root.open
              verticalAlignment: TextInput.AlignVCenter
              selectionColor: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.35)
              selectedTextColor: Colors.text0
              onTextChanged: {
                root.selected = 0
                root.actionSelected = 0
                root.actionMode = false
                store.requestSearch(text)
              }

              Keys.onReturnPressed: root.launchSelected()
              Keys.onEscapePressed: root.close()
              Keys.onUpPressed: root.actionMode ? root.moveActionSelection(-1) : root.moveSelection(-1)
              Keys.onDownPressed: root.actionMode ? root.moveActionSelection(1) : root.moveSelection(1)
              Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Tab) {
                  root.toggleActionMode()
                  event.accepted = true
                  return
                }

                if (event.key === Qt.Key_PageDown) {
                  root.actionMode ? root.moveActionSelection(4) : root.moveSelection(4)
                  event.accepted = true
                  return
                }

                if (event.key === Qt.Key_PageUp) {
                  root.actionMode ? root.moveActionSelection(-4) : root.moveSelection(-4)
                  event.accepted = true
                  return
                }

                if (event.key === Qt.Key_Home) {
                  root.selected = 0
                  resultList.positionViewAtIndex(root.selected, ListView.Contain)
                  event.accepted = true
                  return
                }

                if (event.key === Qt.Key_End) {
                  root.selected = Math.max(0, store.results.length - 1)
                  resultList.positionViewAtIndex(root.selected, ListView.Contain)
                  event.accepted = true
                  return
                }

                if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_A) {
                  store.toggleAllMode()
                  root.selected = 0
                  root.actionSelected = 0
                  root.actionMode = false
                  event.accepted = true
                } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_K) {
                  root.togglePinSelected()
                  event.accepted = true
                } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_R) {
                  store.rebuildIndex(true)
                  event.accepted = true
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
                  root.selected = 0
                  root.actionSelected = 0
                  root.actionMode = false
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
          Layout.preferredHeight: root.listH

          ListView {
            id: resultList
            anchors { fill: parent; margins: 8 }
            clip: true
            spacing: 4
            model: store.results.length
            currentIndex: root.selected
            boundsBehavior: Flickable.StopAtBounds
            interactive: store.results.length > 0

            delegate: LauncherListItem {
              width: resultList.width
              height: root.itemH
              item: store.results[index] || ({})
              itemIndex: index
              selected: root.selected === index
              onHovered: idx => root.selected = idx
              onTriggered: idx => {
                root.selected = idx
                root.actionSelected = 0
                root.actionMode = false
                root.launchSelected()
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
          Layout.preferredHeight: root.actionsH
          visible: root.actionMode

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
                    text: "Acoes de " + (root.selectedItem ? root.selectedItem.name : "")
                    color: Colors.text2
                    font { pixelSize: 11; family: "JetBrainsMono Nerd Font" }
                  }

                  Item { Layout.fillWidth: true }

                  Text {
                    text: String(root.currentActions.length)
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
                model: root.currentActions.length
                interactive: root.currentActions.length > 0

                delegate: LauncherActionItem {
                  width: actionList.width
                  height: root.actionItemH
                  action: root.currentActions[index] || ({})
                  actionIndex: index
                  selected: root.actionSelected === index
                  onHovered: idx => root.actionSelected = idx
                  onTriggered: idx => {
                    root.actionSelected = idx
                    root.launchSelectedAction()
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
          Layout.preferredHeight: 36
          Layout.leftMargin: 18
          Layout.rightMargin: 18
          selectedItem: store.results.length > 0 ? store.results[root.selected] : null
          showAll: store.showAll
        }
      }
    }
  }

  LauncherStore {
    id: store
    resultLimit: 5
    onLaunched: function(ok) {
      if (ok) return

      if (root.closingForLaunch) {
        root.open = true
        OverlayState.setActive("launcher")
        focusTimer.restart()
      }

      root.closingForLaunch = false
    }
  }

  Timer {
    id: focusTimer
    interval: 20
    repeat: false
    onTriggered: searchInput.forceActiveFocus()
  }
}
