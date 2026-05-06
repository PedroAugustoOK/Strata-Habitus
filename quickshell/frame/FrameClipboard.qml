import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import ".."

Item {
  id: root

  property bool open: false
  property var items: []
  property var filtered: []
  property string query: ""
  property int selected: 0
  property string selectedId: ""
  property string errorMessage: ""
  property bool loading: false
  property bool acting: false
  property string imagePreviewPath: ""
  property string imagePreviewError: ""
  property int imagePreviewVersion: 0
  readonly property int panelWidth: FrameTokens.clipboardWidth
  readonly property int panelHeight: FrameTokens.clipboardHeight
  readonly property bool drawerVisible: drawer.visible

  readonly property var currentItem: {
    if (filtered.length === 0) return null
    if (selectedId !== "") {
      const byId = filtered.find(item => item.id === selectedId)
      if (byId) return byId
    }
    return filtered[Math.max(0, Math.min(selected, filtered.length - 1))]
  }
  readonly property string currentPreviewSource: imagePreviewPath ? ("file://" + imagePreviewPath) : ""
  readonly property string currentItemDescription: {
    if (!currentItem) return "Historico persistente do clipboard."
    if (currentItem.isImage) return "Preview da imagem selecionada."
    if (currentItem.kind === "link") return "Item textual classificado como link."
    if (currentItem.kind === "links") return "Item textual com multiplos links."
    return currentItem.preview || currentItem.raw || ""
  }
  readonly property string listScript: Qt.resolvedUrl("../scripts/clipboard-list.js").toString().replace("file://", "")
  readonly property string actionScript: Qt.resolvedUrl("../scripts/clipboard-action.js").toString().replace("file://", "")
  readonly property string previewScript: Qt.resolvedUrl("../scripts/clipboard-preview.js").toString().replace("file://", "")
  readonly property string daemonScript: Qt.resolvedUrl("../scripts/clipboard-daemon.sh").toString().replace("file://", "")
  readonly property color panelFill: Colors.darkMode ? Qt.rgba(1, 1, 1, 0.035) : Qt.rgba(0, 0, 0, 0.035)
  readonly property color panelBorder: Colors.darkMode ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(0, 0, 0, 0.08)

  function toggle() {
    if (open) {
      close()
      return
    }

    daemonProc.command = [daemonScript, "start"]
    daemonProc.running = true
    open = true
    selected = 0
    selectedId = ""
    errorMessage = ""
    query = ""
    searchInput.text = ""
    imagePreviewPath = ""
    imagePreviewError = ""
    reload()
    OverlayState.setActive("clipboard")
    focusTimer.restart()
  }

  function close() {
    open = false
    selected = 0
    OverlayState.clear("clipboard")
  }

  function reload() {
    if (listProc.running) return
    loading = true
    errorMessage = ""
    listProc.command = [listScript]
    listProc.running = true
  }

  function filterItems() {
    const q = query.trim().toLowerCase()
    filtered = items
      .filter(item => {
        if (q === "") return true
        return (item.preview || "").toLowerCase().includes(q) || (item.label || "").toLowerCase().includes(q)
      })
      .slice(0, 150)

    if (filtered.length === 0) selected = 0
    else {
      const currentIndex = selectedId !== "" ? filtered.findIndex(item => item.id === selectedId) : -1
      if (currentIndex >= 0) selected = currentIndex
      else {
        selected = Math.max(0, Math.min(selected, filtered.length - 1))
        selectedId = filtered[selected] ? filtered[selected].id : ""
      }
    }
  }

  function copySelected() {
    if (!currentItem || acting) return
    acting = true
    errorMessage = ""
    actionProc.command = [
      actionScript,
      "copy",
      currentItem.entry || currentItem.id,
      currentItem.isImage ? "image" : "text",
      currentItem.imageFormat || ""
    ]
    actionProc.running = true
  }

  function deleteSelected() {
    if (!currentItem || acting) return
    acting = true
    errorMessage = ""
    actionProc.command = [actionScript, "delete", currentItem.entry || currentItem.id]
    actionProc.running = true
  }

  function moveSelection(delta) {
    if (filtered.length === 0) return
    selected = Math.max(0, Math.min(filtered.length - 1, selected + delta))
    selectedId = filtered[selected] ? filtered[selected].id : ""
    list.positionViewAtIndex(selected, ListView.Contain)
  }

  onItemsChanged: filterItems()
  onQueryChanged: filterItems()
  onSelectedChanged: {
    if (filtered.length > 0 && filtered[selected]) selectedId = filtered[selected].id
    if (open && filtered.length > 0) list.positionViewAtIndex(selected, ListView.Contain)
  }

  onCurrentItemChanged: {
    imagePreviewPath = ""
    imagePreviewError = ""
    imagePreviewVersion = 0
    if (previewProc.running) previewProc.running = false
    if (currentItem && currentItem.isImage) {
      previewProc.command = [previewScript, currentItem.entry || currentItem.id, currentItem.imageFormat || ""]
      previewProc.running = true
    }
  }

  anchors.fill: parent

  BottomDrawer {
    id: drawer
    width: root.panelWidth
    height: root.panelHeight
    gutter: FrameTokens.rightPanelGutter
    open: root.open

    FrameSurface {
      anchors.fill: parent
      radius: FrameTokens.surfaceRadius
      attachedEdge: "bottom"
      borderColor: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.18)

      Item {
        id: keyGrabber
        anchors.fill: parent
        focus: root.open
        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Escape) {
            root.close()
            event.accepted = true
          }
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
              text: "Clipboard"
              color: Colors.text1
              font { pixelSize: 22; family: "Inter"; weight: Font.DemiBold }
              elide: Text.ElideRight
            }

            Text {
              Layout.fillWidth: true
              text: "Setas navegam, Enter copia, Ctrl+Delete apaga."
              color: Colors.text3
              font { pixelSize: 10; family: "JetBrains Mono" }
              elide: Text.ElideRight
            }
          }

          Rectangle {
            radius: 13
            implicitWidth: stateText.implicitWidth + 18
            implicitHeight: 30
            color: (root.loading || root.acting) ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.18) : root.panelFill
            border.width: 1
            border.color: (root.loading || root.acting) ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.26) : root.panelBorder

            Text {
              id: stateText
              anchors.centerIn: parent
              text: root.loading ? "carregando" : root.acting ? "aplicando" : (root.filtered.length + " itens")
              color: (root.loading || root.acting) ? Colors.accent : Colors.text2
              font { pixelSize: 10; family: "JetBrains Mono"; weight: Font.DemiBold }
            }
          }
        }

        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 42
          radius: 13
          color: Qt.rgba(1, 1, 1, Colors.darkMode ? 0.05 : 0.42)
          border.width: 1
          border.color: searchInput.activeFocus ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.32) : root.panelBorder

          TextInput {
            id: searchInput
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            color: Colors.text1
            font { pixelSize: 14; family: "JetBrains Mono" }
            verticalAlignment: TextInput.AlignVCenter
            onTextChanged: root.query = text
            Keys.onEscapePressed: root.close()
            Keys.onUpPressed: root.moveSelection(-1)
            Keys.onDownPressed: root.moveSelection(1)
            Keys.onPressed: function(event) {
              if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                root.copySelected()
                event.accepted = true
              } else if ((event.key === Qt.Key_Backspace || event.key === Qt.Key_Delete) && (event.modifiers & Qt.ControlModifier)) {
                root.deleteSelected()
                event.accepted = true
              } else if (event.key === Qt.Key_PageDown) {
                root.moveSelection(8)
                event.accepted = true
              } else if (event.key === Qt.Key_PageUp) {
                root.moveSelection(-8)
                event.accepted = true
              } else if (event.key === Qt.Key_Home) {
                root.selected = 0
                root.selectedId = root.filtered.length > 0 && root.filtered[0] ? root.filtered[0].id : ""
                event.accepted = true
              } else if (event.key === Qt.Key_End) {
                root.selected = Math.max(0, root.filtered.length - 1)
                root.selectedId = root.filtered.length > 0 && root.filtered[root.selected] ? root.filtered[root.selected].id : ""
                event.accepted = true
              }
            }

            Text {
              anchors.fill: parent
              text: "Pesquisar historico..."
              color: Colors.text3
              font { pixelSize: 14; family: "JetBrains Mono" }
              verticalAlignment: Text.AlignVCenter
              visible: searchInput.text.length === 0
            }
          }
        }

        RowLayout {
          Layout.fillWidth: true
          Layout.fillHeight: true
          spacing: 14

          Rectangle {
            Layout.preferredWidth: 420
            Layout.fillHeight: true
            radius: 16
            color: root.panelFill
            border.width: 1
            border.color: root.panelBorder
            clip: true

            ListView {
              id: list
              anchors.fill: parent
              anchors.margins: 10
              clip: true
              spacing: 6
              model: root.filtered.length

              delegate: Rectangle {
                required property int index
                property var item: root.filtered[index] || ({})
                width: list.width
                height: 70
                radius: 14
                color: root.selected === index ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.16) : rowMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.045) : "transparent"
                border.width: root.selected === index ? 1 : 0
                border.color: root.selected === index ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.30) : "transparent"

                Text {
                  x: 12
                  y: 11
                  text: item.isImage ? "Imagem" : item.kind === "link" || item.kind === "links" ? "Link" : (item.label || "Texto")
                  color: item.isImage ? Colors.accent : Colors.text2
                  font { pixelSize: 10; family: "JetBrains Mono" }
                }

                Text {
                  x: 12
                  y: 30
                  width: parent.width - 52
                  text: item.preview || ""
                  color: Colors.text1
                  font { pixelSize: 11; family: "JetBrains Mono" }
                  elide: Text.ElideRight
                  maximumLineCount: 2
                  wrapMode: Text.Wrap
                }

                MouseArea {
                  id: rowMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  preventStealing: true
                  cursorShape: Qt.PointingHandCursor
                  onEntered: {
                    root.selected = index
                    root.selectedId = item.id || ""
                  }
                  onClicked: {
                    root.selected = index
                    root.selectedId = item.id || ""
                    root.copySelected()
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
              anchors.margins: 14
              spacing: 12

              Text {
                Layout.fillWidth: true
                text: root.currentItem ? root.currentItem.label : "Nenhum item"
                color: Colors.text1
                font { pixelSize: 18; family: "Inter"; weight: Font.DemiBold }
                elide: Text.ElideRight
              }

              Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 230
                radius: 14
                color: Qt.rgba(1, 1, 1, Colors.darkMode ? 0.06 : 0.36)
                border.width: 1
                border.color: root.currentItem && root.currentItem.isImage ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.30) : root.panelBorder
                clip: true

                Image {
                  anchors.fill: parent
                  anchors.margins: 14
                  source: root.currentItem && root.currentItem.isImage && root.currentPreviewSource ? (root.currentPreviewSource + "?v=" + root.imagePreviewVersion) : ""
                  fillMode: Image.PreserveAspectFit
                  asynchronous: false
                  cache: false
                  smooth: true
                  visible: root.currentItem && root.currentItem.isImage && status === Image.Ready
                }

                Flickable {
                  anchors.fill: parent
                  anchors.margins: 16
                  visible: !!root.currentItem && !root.currentItem.isImage
                  contentWidth: width
                  contentHeight: textPreview.implicitHeight
                  clip: true

                  Text {
                    id: textPreview
                    width: parent.width
                    text: root.currentItem ? (root.currentItem.preview || root.currentItem.raw || "") : "Selecione um item."
                    color: Colors.text2
                    font { pixelSize: 12; family: "JetBrains Mono" }
                    wrapMode: Text.Wrap
                  }
                }

                Text {
                  anchors.centerIn: parent
                  width: parent.width - 32
                  visible: !!root.currentItem && root.currentItem.isImage && imagePreviewPath === ""
                  text: root.imagePreviewError !== "" ? root.imagePreviewError : "gerando preview..."
                  color: root.imagePreviewError !== "" ? Colors.danger : Colors.text3
                  font { pixelSize: 11; family: "JetBrains Mono" }
                  wrapMode: Text.WordWrap
                  horizontalAlignment: Text.AlignHCenter
                }
              }

              Text {
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: root.currentItemDescription
                color: Colors.text2
                wrapMode: Text.WordWrap
                font { pixelSize: 11; family: "JetBrains Mono" }
              }

              Text {
                Layout.fillWidth: true
                text: root.errorMessage
                color: Colors.danger
                visible: text !== ""
                font { pixelSize: 10; family: "JetBrains Mono" }
                elide: Text.ElideRight
              }

              RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                  Layout.fillWidth: true
                  Layout.preferredHeight: 44
                  radius: 14
                  color: root.currentItem ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.18) : root.panelFill
                  border.width: 1
                  border.color: root.currentItem ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.24) : root.panelBorder

                  Text {
                    anchors.centerIn: parent
                    text: root.currentItem ? "Copiar" : "Sem selecao"
                    color: root.currentItem ? Colors.accent : Colors.text3
                    font { pixelSize: 12; family: "Inter"; weight: Font.DemiBold }
                  }

                  MouseArea {
                    anchors.fill: parent
                    enabled: !!root.currentItem && !root.acting
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: root.copySelected()
                  }
                }

                Rectangle {
                  Layout.preferredWidth: 150
                  Layout.preferredHeight: 44
                  radius: 14
                  color: root.currentItem ? root.panelFill : Qt.rgba(1, 1, 1, 0.025)
                  border.width: 1
                  border.color: root.panelBorder

                  Text {
                    anchors.centerIn: parent
                    text: "Apagar"
                    color: root.currentItem ? Colors.text2 : Colors.text3
                    font { pixelSize: 12; family: "Inter"; weight: Font.DemiBold }
                  }

                  MouseArea {
                    anchors.fill: parent
                    enabled: !!root.currentItem && !root.acting
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: root.deleteSelected()
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  Process {
    id: listProc
    command: []
    stdout: SplitParser {
      onRead: data => {
        const line = data.trim()
        if (line === "") return
        try {
          const payload = JSON.parse(line)
          if (!payload.ok) {
            root.errorMessage = payload.error || "falha ao carregar historico"
            root.items = []
            return
          }
          root.items = payload.items || []
        } catch (error) {
          root.errorMessage = "falha ao carregar historico"
          root.items = []
        }
      }
    }
    onRunningChanged: {
      if (!running) root.loading = false
    }
  }

  Process {
    id: actionProc
    command: []
    stdout: SplitParser {
      onRead: data => {
        const line = data.trim()
        if (line === "") return
        try {
          const payload = JSON.parse(line)
          if (!payload.ok) {
            root.errorMessage = payload.error || "falha ao aplicar acao"
            return
          }

          if (actionProc.command.length > 1 && actionProc.command[1] === "delete") {
            root.reload()
          } else {
            searchInput.text = ""
            root.query = ""
            root.close()
          }
        } catch (error) {
          root.errorMessage = "falha ao aplicar acao"
        }
      }
    }
    onRunningChanged: {
      if (!running) root.acting = false
    }
  }

  Process {
    id: previewProc
    command: []
    stdout: SplitParser {
      onRead: data => {
        const line = data.trim()
        if (line === "") return
        try {
          const payload = JSON.parse(line)
          if (!payload.ok) {
            root.imagePreviewError = payload.error || "falha ao gerar preview"
            root.imagePreviewPath = ""
            return
          }
          root.imagePreviewError = ""
          root.imagePreviewPath = payload.path || ""
          root.imagePreviewVersion += 1
        } catch (error) {}
      }
    }
  }

  Process {
    id: daemonProc
    command: []
  }

  Timer {
    id: focusTimer
    interval: 20
    repeat: false
    onTriggered: searchInput.forceActiveFocus()
  }
}
