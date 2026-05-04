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
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

  signal openControlCenter()
  signal openThemePicker()
  signal openWallPickr()
  signal openAppCenter()
  signal openUpdateCenter()

  property real cardYOffset: 18
  property int selectedActionIdx: 0

  readonly property var actions: [
    { key: "themepicker", section: "Aparência", title: "Tema", body: "Cores e identidade visual.", badge: "TM" },
    { key: "wallpickr", section: "Aparência", title: "Papéis de Parede", body: "Escolha e troque o plano de fundo.", badge: "WP" },
    { key: "controlcenter", section: "Aparência", title: "Central de Controle", body: "Brilho, áudio e ajustes rápidos.", badge: "CC" },
    { key: "updatecenter", section: "Sistema", title: "Central de Atualizações", body: "Rebuild, release e status.", badge: "UP" },
    { key: "settings", section: "Sistema", title: "Configurações do Sistema", body: "Preferências gerais do desktop.", badge: "GS" },
    { key: "protonvpn", section: "Sistema", title: "Proton VPN", body: "Conecte ou desconecte o túnel WireGuard manual.", badge: "PV" },
    { key: "recorder", section: "Sistema", title: "Gravador de Tela", body: "Inicie ou pare uma gravação rápida sem abrir janelas.", badge: "RC" },
    { key: "bluetooth", section: "Dispositivos", title: "Bluetooth", body: "Pareamento e dispositivos sem fio.", badge: "BT" },
    { key: "printer", section: "Dispositivos", title: "Impressoras", body: "Filas e administração.", badge: "PR" },
    { key: "scanner", section: "Dispositivos", title: "Scanner", body: "Digitalização simples.", badge: "SC" },
    { key: "appcenter", section: "Apps e Arquivos", title: "Central de Apps", body: "Instalação e fila declarativa.", badge: "AP" },
    { key: "archive", section: "Apps e Arquivos", title: "Arquivos Compactados", body: "Abrir, extrair e criar.", badge: "AR" },
    { key: "mail", section: "Apps e Arquivos", title: "E-mail", body: "Thunderbird e contas locais.", badge: "ML" }
  ]

  readonly property var selectedAction: actions[Math.max(0, Math.min(selectedActionIdx, actions.length - 1))]
  readonly property color panelBorder: Colors.darkMode
    ? Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, 0.08)
    : Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, 0.14)
  readonly property color cardFill: Colors.darkMode
    ? Qt.rgba(Colors.bg1.r, Colors.bg1.g, Colors.bg1.b, 0.98)
    : Qt.rgba(Colors.bg1.r, Colors.bg1.g, Colors.bg1.b, 0.97)
  readonly property color rowFill: Colors.darkMode
    ? Qt.rgba(Colors.bg2.r, Colors.bg2.g, Colors.bg2.b, 0.34)
    : Qt.rgba(Colors.bg2.r, Colors.bg2.g, Colors.bg2.b, 0.78)
  readonly property color rowSelected: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, Colors.darkMode ? 0.16 : 0.12)

  function toggle() {
    if (visible) {
      closeAnim.start()
      return
    }
    selectedActionIdx = 0
    visible = true
    card.opacity = 0
    cardScale.xScale = OverlayState.morphStartXScale(card.width)
    cardScale.yScale = OverlayState.morphStartYScale(card.height)
    cardYOffset = OverlayState.morphStartYOffset(root.height)
    openAnim.start()
  }

  function close() {
    closeAnim.start()
  }

  function moveAction(delta) {
    selectedActionIdx = Math.max(0, Math.min(actions.length - 1, selectedActionIdx + delta))
  }

  function ensureCurrentActionVisible() {
    if (actionsList) actionsList.positionViewAtIndex(selectedActionIdx, ListView.Contain)
  }

  function launch(command) {
    if (!command || command.length === 0) return
    appProc.command = command
    appProc.running = true
    close()
  }

  function runAction(action) {
    if (!action) return
    if (action === "controlcenter") { root.openControlCenter(); close(); return }
    if (action === "themepicker") { root.openThemePicker(); close(); return }
    if (action === "wallpickr") { root.openWallPickr(); close(); return }
    if (action === "appcenter") { root.openAppCenter(); close(); return }
    if (action === "updatecenter") { root.openUpdateCenter(); close(); return }
    if (action === "settings") return launch(["gnome-control-center"])
    if (action === "protonvpn") return launch(["bash", "/home/ankh/.config/quickshell/scripts/protonvpn-toggle-notify.sh"])
    if (action === "recorder") return launch(["bash", "/home/ankh/.config/quickshell/scripts/screenrecord.sh"])
    if (action === "bluetooth") return launch(["gnome-control-center", "bluetooth"])
    if (action === "printer") return launch(["system-config-printer"])
    if (action === "scanner") return launch(["simple-scan"])
    if (action === "archive") return launch(["file-roller"])
    if (action === "mail") return launch(["thunderbird"])
  }

  Keys.priority: Keys.BeforeItem
  Keys.onPressed: function(event) {
    if (event.key === Qt.Key_Escape) {
      root.close()
      event.accepted = true
    }
  }

  onVisibleChanged: {
    if (visible) OverlayState.setActive("settingscenter")
    else OverlayState.clear("settingscenter")
    if (visible) {
      keyGrabber.forceActiveFocus()
      ensureCurrentActionVisible()
    }
  }

  onSelectedActionIdxChanged: ensureCurrentActionVisible()

  MouseArea {
    anchors.fill: parent
    onClicked: root.close()
  }

  SequentialAnimation {
    id: openAnim
    ParallelAnimation {
      NumberAnimation { target: root; property: "cardYOffset"; from: OverlayState.morphStartYOffset(root.height); to: 0; duration: 260; easing.type: Easing.OutCubic }
      NumberAnimation { target: card; property: "opacity"; from: 0; to: 1; duration: 120; easing.type: Easing.OutQuad }
      NumberAnimation { target: cardScale; property: "xScale"; from: OverlayState.morphStartXScale(card.width); to: 1; duration: 260; easing.type: Easing.OutCubic }
      NumberAnimation { target: cardScale; property: "yScale"; from: OverlayState.morphStartYScale(card.height); to: 1; duration: 260; easing.type: Easing.OutCubic }
    }
    ScriptAction {
      script: {
        keyGrabber.forceActiveFocus()
        ensureCurrentActionVisible()
      }
    }
  }

  SequentialAnimation {
    id: closeAnim
    ParallelAnimation {
      NumberAnimation { target: root; property: "cardYOffset"; to: OverlayState.morphStartYOffset(root.height); duration: 150; easing.type: Easing.InCubic }
      NumberAnimation { target: cardScale; property: "xScale"; to: OverlayState.morphStartXScale(card.width); duration: 150; easing.type: Easing.InCubic }
      NumberAnimation { target: cardScale; property: "yScale"; to: OverlayState.morphStartYScale(card.height); duration: 150; easing.type: Easing.InCubic }
      NumberAnimation { target: card; property: "opacity"; to: 0; duration: 110; easing.type: Easing.InQuad }
    }
    ScriptAction { script: root.visible = false }
  }

  Rectangle {
    id: card
    anchors.centerIn: parent
    anchors.verticalCenterOffset: root.cardYOffset
    width: 700
    height: 760
    radius: 24
    antialiasing: true
    color: root.cardFill
    border.width: 1
    border.color: root.panelBorder
    clip: true
    opacity: 0
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
        GradientStop { position: 0.0; color: Qt.rgba(Colors.bg2.r, Colors.bg2.g, Colors.bg2.b, Colors.darkMode ? 0.62 : 0.54) }
        GradientStop { position: 1.0; color: Qt.rgba(Colors.bg1.r, Colors.bg1.g, Colors.bg1.b, 0.98) }
      }
    }

    Item {
      id: keyGrabber
      anchors.fill: parent
      focus: root.visible

      Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
          root.close()
          event.accepted = true
        } else if (event.key === Qt.Key_Up) {
          root.moveAction(-1)
          event.accepted = true
        } else if (event.key === Qt.Key_Down) {
          root.moveAction(1)
          event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
          root.runAction(root.selectedAction.key)
          event.accepted = true
        }
      }
    }

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 24
      spacing: 18

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 4

        Text {
          text: "Centro de Configuração"
          color: Colors.text0
          font { pixelSize: 30; family: "Inter"; weight: Font.DemiBold }
        }

        Text {
          text: "Acessos principais do sistema em uma lista simples."
          color: Colors.text2
          font { pixelSize: 13; family: "Inter" }
        }
      }

      ListView {
        id: actionsList
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 10
        boundsBehavior: Flickable.StopAtBounds
        model: root.actions

        delegate: Item {
          id: actionDelegate
          required property var modelData
          required property int index
          readonly property bool selected: index === root.selectedActionIdx
          readonly property bool showSection: index === 0 || root.actions[index - 1].section !== modelData.section

          width: ListView.view.width
          height: (showSection ? 34 : 0) + 76

          Column {
            anchors.fill: parent
            spacing: 10

            Text {
              visible: actionDelegate.showSection
              text: modelData.section
              color: Colors.text3
              font { pixelSize: 11; family: "JetBrains Mono"; weight: Font.DemiBold }
            }

            Rectangle {
              width: parent.width
              height: 76
              radius: 18
              color: selected ? root.rowSelected : root.rowFill
              border.width: 1
              border.color: selected
                ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.28)
                : Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, Colors.darkMode ? 0.05 : 0.08)

              RowLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 14

                Rectangle {
                  Layout.preferredWidth: 44
                  Layout.preferredHeight: 44
                  radius: 14
                  color: selected
                    ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.22)
                    : Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, Colors.darkMode ? 0.08 : 0.06)
                  border.width: 1
                  border.color: Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, Colors.darkMode ? 0.05 : 0.08)

                  Text {
                    anchors.centerIn: parent
                    text: modelData.badge
                    color: selected ? Colors.text0 : Colors.text1
                    font { pixelSize: 12; family: "JetBrains Mono"; weight: Font.DemiBold }
                  }
                }

                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: 2

                  Text {
                    Layout.fillWidth: true
                    text: modelData.title
                    color: selected ? Colors.text0 : Colors.text1
                    font { pixelSize: 16; family: "Inter"; weight: Font.DemiBold }
                    elide: Text.ElideRight
                  }

                  Text {
                    Layout.fillWidth: true
                    text: modelData.body
                    color: Colors.text2
                    font { pixelSize: 12; family: "Inter" }
                    elide: Text.ElideRight
                  }
                }
              }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: root.selectedActionIdx = index
                onClicked: {
                  root.selectedActionIdx = index
                  root.runAction(modelData.key)
                }
              }
            }
          }
        }
      }

      Text {
        text: "Esc fecha  •  Cima/Baixo navega  •  Enter abre"
        color: Colors.text3
        font { pixelSize: 10; family: "JetBrains Mono" }
      }
    }
  }

  Process {
    id: appProc
    command: []
  }
}
