import Quickshell
import Quickshell.Wayland
import Quickshell.Io
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

  property var items: []
  property var filtered: []
  property string query: ""
  property int selected: 0
  property string selectedId: ""
  property real cardYOffset: 18
  property string errorMessage: ""
  property bool loading: false
  property bool acting: false
  property string imagePreviewPath: ""
  property string imagePreviewError: ""
  property int imagePreviewVersion: 0
  property string imagePreviewToken: ""

  readonly property var currentItem: {
    if (filtered.length === 0) return null
    if (selectedId !== "") {
      const byId = filtered.find(item => item.id === selectedId)
      if (byId) return byId
    }
    return filtered[Math.max(0, Math.min(selected, filtered.length - 1))]
  }
  readonly property string currentPreviewSource: root.imagePreviewPath ? ("file://" + root.imagePreviewPath) : ""
  readonly property string currentItemDescription: {
    if (!currentItem) return "O historico agora e persistente e continua disponivel mesmo depois de fechar o app de origem."
    if (currentItem.isImage) {
      const format = (currentItem.imageFormat || "imagem").toUpperCase()
      return "Preview da imagem selecionada. Formato " + format + "."
    }
    if (currentItem.kind === "link") return "Item textual classificado como link. Enter copia o conteudo normalizado."
    if (currentItem.kind === "links") return "Item textual com multiplos links. Enter copia o conteudo normalizado."
    return currentItem.preview || currentItem.raw || ""
  }
  readonly property string listScript: Qt.resolvedUrl("../scripts/clipboard-list.js").toString().replace("file://", "")
  readonly property string actionScript: Qt.resolvedUrl("../scripts/clipboard-action.js").toString().replace("file://", "")
  readonly property string previewScript: Qt.resolvedUrl("../scripts/clipboard-preview.js").toString().replace("file://", "")
  readonly property string daemonScript: Qt.resolvedUrl("../scripts/clipboard-daemon.sh").toString().replace("file://", "")

  function toggle() {
    if (visible) {
      closeAnim.start()
      return
    }

    daemonProc.command = [daemonScript, "start"]
    daemonProc.running = true
    visible = true
    selected = 0
    selectedId = ""
    errorMessage = ""
    query = ""
    searchInput.text = ""
    imagePreviewPath = ""
    imagePreviewError = ""
    card.opacity = 0
    card.scale = 0.985
    cardYOffset = 16
    reload()
    openAnim.start()
  }

  function close() {
    closeAnim.start()
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
        return (item.preview || "").toLowerCase().includes(q) ||
          (item.label || "").toLowerCase().includes(q)
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
    if (filtered.length > 0 && filtered[selected]) {
      selectedId = filtered[selected].id
    }
    if (visible && filtered.length > 0) {
      list.positionViewAtIndex(selected, ListView.Contain)
    }
  }

  onCurrentItemChanged: {
    if (detailFlick) detailFlick.contentY = 0
    imagePreviewPath = ""
    imagePreviewError = ""
    imagePreviewVersion = 0
    imagePreviewToken = ""
    if (previewProc.running) previewProc.running = false
    if (currentItem && currentItem.isImage) {
      previewProc.command = [previewScript, currentItem.entry || currentItem.id, currentItem.imageFormat || ""]
      previewProc.running = true
    }
  }

  SequentialAnimation {
    id: openAnim
    ParallelAnimation {
      NumberAnimation { target: root; property: "cardYOffset"; from: 16; to: 0; duration: 190; easing.type: Easing.OutCubic }
      NumberAnimation { target: card; property: "opacity"; from: 0; to: 1; duration: 140; easing.type: Easing.OutQuad }
      NumberAnimation { target: card; property: "scale"; from: 0.985; to: 1; duration: 190; easing.type: Easing.OutCubic }
    }
    ScriptAction { script: searchInput.forceActiveFocus() }
  }

  SequentialAnimation {
    id: closeAnim
    ParallelAnimation {
      NumberAnimation { target: root; property: "cardYOffset"; to: 10; duration: 120; easing.type: Easing.InCubic }
      NumberAnimation { target: card; property: "scale"; to: 0.992; duration: 120; easing.type: Easing.InCubic }
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
        } catch (e) {
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
        } catch (e) {
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
          root.imagePreviewToken = `${payload.path || ""}#${root.imagePreviewVersion}`
        } catch (e) {}
      }
    }
  }

  Process {
    id: daemonProc
    command: []
  }

  Rectangle {
    id: card
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    anchors.verticalCenterOffset: cardYOffset
    width: 900
    height: 620
    radius: 22
    color: Colors.bg1
    border.width: 1
    border.color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.18)
    opacity: 0
    scale: 1
    clip: true

    Rectangle {
      anchors.fill: parent
      color: "transparent"

      Rectangle {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 84
        color: "transparent"

        Text {
          x: 24
          y: 18
          text: "Clipboard"
          color: Colors.text1
          font { pixelSize: 22; family: "JetBrainsMono Nerd Font" }
        }

        Text {
          x: 24
          y: 48
          text: "Setas navegam, Enter copia, mouse seleciona e clique aplica."
          color: Colors.text3
          font { pixelSize: 10; family: "JetBrainsMono Nerd Font" }
        }

        Rectangle {
          id: searchBox
          x: 24
          y: 104 - 44
          width: 430
          height: 44
          radius: 14
          color: Qt.rgba(1, 1, 1, 0.05)
          border.width: 1
          border.color: searchInput.activeFocus
            ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.32)
            : Qt.rgba(1, 1, 1, 0.08)

          Text {
            x: 14
            anchors.verticalCenter: parent.verticalCenter
            text: "󰍉"
            color: Colors.accent
            font { pixelSize: 15; family: "JetBrainsMono Nerd Font" }
          }

          TextInput {
            id: searchInput
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 42
            anchors.rightMargin: 14
            color: Colors.text1
            font { pixelSize: 14; family: "JetBrainsMono Nerd Font" }
            Keys.priority: Keys.BeforeItem
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
          }

          Text {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 42
            anchors.rightMargin: 14
            text: "Pesquisar historico..."
            color: Colors.text3
            font { pixelSize: 14; family: "JetBrainsMono Nerd Font" }
            visible: searchInput.text.length === 0
          }
        }

        Rectangle {
          id: statePill
          anchors.right: parent.right
          anchors.rightMargin: 24
          anchors.verticalCenter: searchBox.verticalCenter
          width: 150
          height: 34
          radius: 17
          color: (root.loading || root.acting)
            ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.18)
            : Qt.rgba(1, 1, 1, 0.05)
          border.width: 1
          border.color: (root.loading || root.acting)
            ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.26)
            : Qt.rgba(1, 1, 1, 0.08)

          Text {
            anchors.centerIn: parent
            text: root.loading ? "carregando historico" : root.acting ? "aplicando" : (root.filtered.length + " itens")
            color: (root.loading || root.acting) ? Colors.accent : Colors.text2
            font { pixelSize: 11; family: "JetBrainsMono Nerd Font" }
          }
        }
      }

      Rectangle {
        id: leftPanel
        x: 24
        y: 106
        width: 430
        height: 460
        radius: 18
        color: Qt.rgba(1, 1, 1, 0.035)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.07)
        clip: true

        ListView {
          id: list
          anchors.fill: parent
          anchors.margins: 10
          clip: true
          spacing: 6
          model: root.filtered.length

          delegate: Rectangle {
            property var item: root.filtered[index] || ({})
            width: list.width
            height: 76
            radius: 16
            color: root.selected === index
              ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.16)
              : rowMouse.containsMouse
                ? Qt.rgba(1, 1, 1, 0.045)
                : "transparent"
            border.width: root.selected === index ? 1 : 0
            border.color: root.selected === index
              ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.30)
              : "transparent"

            Rectangle {
              x: 12
              y: 14
              width: 40
              height: 40
              radius: 12
              color: item.isImage
                ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.16)
                : Qt.rgba(1, 1, 1, 0.05)

              Text {
                anchors.centerIn: parent
                text: item.isImage ? "󰋩" : item.isBinary ? "󰈔" : item.kind === "link" || item.kind === "links" ? "󰌹" : "󰆍"
                color: item.isImage ? Colors.accent : Colors.text2
                font { pixelSize: 13; family: "JetBrainsMono Nerd Font" }
              }
            }

            Text {
              x: 66
              y: 12
              text: item.label || ""
              color: item.isImage ? Colors.accent : Colors.text2
              font { pixelSize: 10; family: "JetBrainsMono Nerd Font" }
            }

            Text {
              x: 66
              y: 30
              width: parent.width - 118
              text: item.preview || ""
              color: Colors.text1
              font { pixelSize: 11; family: "JetBrainsMono Nerd Font" }
              elide: Text.ElideRight
              maximumLineCount: 2
              wrapMode: Text.Wrap
            }

            Rectangle {
              anchors.right: parent.right
              anchors.rightMargin: 12
              anchors.verticalCenter: parent.verticalCenter
              width: 30
              height: 24
              radius: 12
              color: root.selected === index
                ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.18)
                : "transparent"
              visible: root.selected === index

              Text {
                anchors.centerIn: parent
                text: "↵"
                color: Colors.accent
                font { pixelSize: 11; family: "JetBrainsMono Nerd Font" }
              }
            }

            MouseArea {
              id: rowMouse
              anchors.fill: parent
              hoverEnabled: true
              preventStealing: true
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
        id: rightPanel
        anchors.top: leftPanel.top
        anchors.left: leftPanel.right
        anchors.leftMargin: 16
        anchors.right: parent.right
        anchors.rightMargin: 24
        anchors.bottom: leftPanel.bottom
        radius: 18
        color: Qt.rgba(1, 1, 1, 0.035)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.07)
        clip: true

        Rectangle {
          id: summaryCard
          anchors.top: parent.top
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.margins: 16
          height: 82
          radius: 16
          color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.09)
          border.width: 1
          border.color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.16)

          Rectangle {
            x: 16
            y: 15
            width: 50
            height: 50
            radius: 16
            color: Qt.rgba(1, 1, 1, 0.08)

            Text {
              anchors.centerIn: parent
              text: root.currentItem ? (root.currentItem.isImage ? "󰋩" : root.currentItem.isBinary ? "󰈔" : root.currentItem.kind === "link" || root.currentItem.kind === "links" ? "󰌹" : "󰆍") : "?"
              color: root.currentItem && root.currentItem.isImage ? Colors.accent : Colors.text2
              font { pixelSize: 18; family: "JetBrainsMono Nerd Font" }
            }
          }

          Text {
            x: 82
            y: 16
            width: parent.width - 98
            text: root.currentItem ? root.currentItem.label : "Nenhum item"
            color: Colors.text1
            font { pixelSize: 18; family: "JetBrainsMono Nerd Font" }
            elide: Text.ElideRight
          }

          Text {
            x: 82
            y: 42
            width: parent.width - 98
            text: root.currentItem ? ("ID " + root.currentItem.id) : "Selecione um item a esquerda."
            color: Colors.text3
            font { pixelSize: 10; family: "JetBrainsMono Nerd Font" }
            elide: Text.ElideRight
          }
        }

        Rectangle {
          id: previewSurface
          anchors.top: summaryCard.bottom
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.topMargin: 16
          anchors.leftMargin: 16
          anchors.rightMargin: 16
          height: 250
          radius: 18
          color: Qt.rgba(1, 1, 1, 0.06)
          border.width: 1
          border.color: root.currentItem && root.currentItem.isImage
            ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.30)
            : Qt.rgba(1, 1, 1, 0.08)
          clip: true

          Rectangle {
            anchors.fill: parent
            anchors.margins: 10
            radius: 14
            color: Qt.rgba(1, 1, 1, 0.08)
          }

          Image {
            id: previewImage
            anchors.fill: parent
            anchors.margins: 14
            source: root.currentItem && root.currentItem.isImage && root.currentPreviewSource
              ? (root.currentPreviewSource + "?v=" + root.imagePreviewVersion)
              : ""
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
              text: root.currentItem ? (root.currentItem.preview || root.currentItem.raw || "") : "Selecione um item para ver o conteudo aqui."
              color: Colors.text2
              font { pixelSize: 12; family: "JetBrainsMono Nerd Font" }
              wrapMode: Text.Wrap
            }
          }

          Text {
            anchors.centerIn: parent
            width: parent.width - 32
            visible: !!root.currentItem && root.currentItem.isImage && previewImage.status !== Image.Ready
            text: root.imagePreviewError !== ""
              ? root.imagePreviewError
              : previewImage.status === Image.Error
                ? "falha ao renderizar preview"
                : "gerando preview..."
            color: root.imagePreviewError !== "" || previewImage.status === Image.Error ? "#ff8e8e" : Colors.text3
            font { pixelSize: 11; family: "JetBrainsMono Nerd Font" }
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
          }

          Text {
            anchors.centerIn: parent
            width: parent.width - 32
            visible: !root.currentItem
            text: "Passe o mouse ou use as setas para focar um item."
            color: Colors.text3
            font { pixelSize: 11; family: "JetBrainsMono Nerd Font" }
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
          }
        }

        Flickable {
          id: detailFlick
          anchors.top: previewSurface.bottom
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.bottom: actionRow.top
          anchors.topMargin: 16
          anchors.leftMargin: 16
          anchors.rightMargin: 16
          anchors.bottomMargin: 12
          contentWidth: width
          contentHeight: detailColumn.implicitHeight
          boundsBehavior: Flickable.StopAtBounds
          clip: true

          Column {
            id: detailColumn
            width: detailFlick.width
            spacing: 12

            Text {
              width: parent.width
              text: root.currentItem && root.currentItem.isImage
                ? "Preview pronto. Clique para copiar imediatamente ou use Enter."
                : root.currentItemDescription
              color: Colors.text2
              font { pixelSize: 11; family: "JetBrainsMono Nerd Font" }
              wrapMode: Text.WordWrap
            }

            Rectangle {
              width: parent.width
              height: 1
              color: Qt.rgba(1, 1, 1, 0.06)
            }

            Text {
              width: parent.width
              text: "Teclado: Up/Down, PageUp/PageDown, Home/End, Enter, Ctrl+Delete, Esc."
              color: Colors.text3
              font { pixelSize: 10; family: "JetBrainsMono Nerd Font" }
              wrapMode: Text.WordWrap
            }

            Text {
              width: parent.width
              text: "Mouse: passar por cima seleciona, clique aplica, clique fora fecha."
              color: Colors.text3
              font { pixelSize: 10; family: "JetBrainsMono Nerd Font" }
              wrapMode: Text.WordWrap
            }
          }
        }

        Row {
          id: actionRow
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          anchors.leftMargin: 16
          anchors.rightMargin: 16
          anchors.bottomMargin: 16
          spacing: 10

          Rectangle {
            width: (actionRow.width - 10) / 2
            height: 46
            radius: 14
            color: root.currentItem
              ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.18)
              : Qt.rgba(1, 1, 1, 0.04)
            border.width: 1
            border.color: root.currentItem
              ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.24)
              : Qt.rgba(1, 1, 1, 0.06)

            Text {
              anchors.centerIn: parent
              text: root.currentItem ? "Copiar Selecionado" : "Sem selecao"
              color: root.currentItem ? Colors.accent : Colors.text3
              font { pixelSize: 11; family: "JetBrainsMono Nerd Font" }
            }

            MouseArea {
              anchors.fill: parent
              enabled: !!root.currentItem && !root.acting
              cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
              onClicked: root.copySelected()
            }
          }

          Rectangle {
            width: (actionRow.width - 10) / 2
            height: 46
            radius: 14
            color: root.currentItem
              ? Qt.rgba(1, 1, 1, 0.05)
              : Qt.rgba(1, 1, 1, 0.03)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.06)

            Text {
              anchors.centerIn: parent
              text: root.currentItem ? "Apagar do Historico" : "Nada para apagar"
              color: root.currentItem ? Colors.text2 : Colors.text3
              font { pixelSize: 10; family: "JetBrainsMono Nerd Font" }
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

      Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: root.errorMessage !== "" ? 30 : 0
        color: "transparent"

        Text {
          anchors.centerIn: parent
          text: root.errorMessage
          color: "#ff8e8e"
          font { pixelSize: 10; family: "JetBrainsMono Nerd Font" }
          visible: text !== ""
        }
      }
    }
  }
}
