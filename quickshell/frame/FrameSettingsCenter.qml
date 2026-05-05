import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import ".."

Item {
  id: root

  signal openControlCenter()
  signal openThemePicker()
  signal openWallPickr()
  signal openAppCenter()
  signal openUpdateCenter()

  property bool open: false
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
  readonly property color panelFill: Colors.darkMode
    ? Qt.rgba(Colors.bg1.r, Colors.bg1.g, Colors.bg1.b, 0.98)
    : Qt.rgba(Colors.bg1.r, Colors.bg1.g, Colors.bg1.b, 0.97)
  readonly property color rowFill: Colors.darkMode
    ? Qt.rgba(Colors.bg2.r, Colors.bg2.g, Colors.bg2.b, 0.34)
    : Qt.rgba(Colors.bg2.r, Colors.bg2.g, Colors.bg2.b, 0.78)
  readonly property color rowSelected: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, Colors.darkMode ? 0.16 : 0.12)

  function toggle() {
    if (open) {
      close()
      return
    }
    selectedActionIdx = 0
    open = true
    OverlayState.setActive("settingscenter")
    focusTimer.restart()
    ensureCurrentActionVisible()
  }

  function close() {
    open = false
    OverlayState.clear("settingscenter")
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

  onSelectedActionIdxChanged: ensureCurrentActionVisible()

  anchors.fill: parent

  RightDrawer {
    id: drawer
    width: Math.min(620, Math.max(500, Math.round(parent.width * 0.34)))
    height: parent.height - 56
    gutter: 10
    open: root.open

    FrameSurface {
      anchors.fill: parent
      radius: 18
      attachedEdge: "right"
      fillColor: root.panelFill
      borderColor: root.panelBorder
      topToneOpacity: Colors.darkMode ? 0.62 : 0.54
      bottomToneOpacity: 0.98

      Item {
        id: keyGrabber
        anchors.fill: parent
        focus: root.open

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
        anchors.margins: 22
        spacing: 16

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 4

          Text {
            text: "Centro de Configuração"
            color: Colors.text0
            font { pixelSize: 24; family: "Inter"; weight: Font.DemiBold }
          }

          Text {
            Layout.fillWidth: true
            text: "Acessos principais do sistema."
            color: Colors.text2
            font { pixelSize: 12; family: "Inter" }
            elide: Text.ElideRight
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
            height: (showSection ? 30 : 0) + 72

            Column {
              anchors.fill: parent
              spacing: 8

              Text {
                visible: actionDelegate.showSection
                text: modelData.section
                color: Colors.text3
                font { pixelSize: 10; family: "JetBrains Mono"; weight: Font.DemiBold }
              }

              Rectangle {
                width: parent.width
                height: 72
                radius: 14
                color: actionDelegate.selected ? root.rowSelected : root.rowFill
                border.width: 1
                border.color: actionDelegate.selected
                  ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.28)
                  : Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, Colors.darkMode ? 0.05 : 0.08)

                RowLayout {
                  anchors.fill: parent
                  anchors.margins: 12
                  spacing: 12

                  Rectangle {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    radius: 12
                    color: actionDelegate.selected
                      ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.22)
                      : Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, Colors.darkMode ? 0.08 : 0.06)
                    border.width: 1
                    border.color: Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, Colors.darkMode ? 0.05 : 0.08)

                    Text {
                      anchors.centerIn: parent
                      text: modelData.badge
                      color: actionDelegate.selected ? Colors.text0 : Colors.text1
                      font { pixelSize: 11; family: "JetBrains Mono"; weight: Font.DemiBold }
                    }
                  }

                  ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                      Layout.fillWidth: true
                      text: modelData.title
                      color: actionDelegate.selected ? Colors.text0 : Colors.text1
                      font { pixelSize: 14; family: "Inter"; weight: Font.DemiBold }
                      elide: Text.ElideRight
                    }

                    Text {
                      Layout.fillWidth: true
                      text: modelData.body
                      color: Colors.text2
                      font { pixelSize: 11; family: "Inter" }
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
          Layout.fillWidth: true
          text: "Esc fecha  •  Cima/Baixo navega  •  Enter abre"
          color: Colors.text3
          font { pixelSize: 10; family: "JetBrains Mono" }
          elide: Text.ElideRight
        }
      }
    }
  }

  Timer {
    id: focusTimer
    interval: 20
    repeat: false
    onTriggered: keyGrabber.forceActiveFocus()
  }

  Process {
    id: appProc
    command: []
  }
}
