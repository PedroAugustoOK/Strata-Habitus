import QtQuick
import QtQuick.Layouts
import ".."
import "../updatecenter"

Item {
  id: root

  property bool open: false

  readonly property color panelBorder: Colors.darkMode
    ? Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, 0.10)
    : Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, 0.16)
  readonly property color detailFill: Colors.darkMode
    ? Qt.rgba(Colors.bg2.r, Colors.bg2.g, Colors.bg2.b, 0.50)
    : Qt.rgba(Colors.bg2.r, Colors.bg2.g, Colors.bg2.b, 0.74)
  readonly property color statusTone: store.status === "error"
    ? Colors.danger
    : store.status === "success" || store.status === "clean"
      ? Colors.success
      : store.blockedReason !== ""
        ? Colors.warning
        : store.running
          ? Colors.info
          : Colors.primary

  function toggle() {
    if (open) {
      close()
      return
    }

    store.resetViewState()
    store.reload()
    open = true
    OverlayState.setActive("updatecenter")
    focusTimer.restart()
  }

  function close() {
    open = false
    OverlayState.clear("updatecenter")
  }

  function handlePrimaryAction() {
    if (store.status === "success" || store.status === "clean") {
      close()
      return
    }
    store.primaryAction()
  }

  anchors.fill: parent

  RightDrawer {
    id: drawer
    width: Math.min(720, Math.max(560, Math.round(parent.width * 0.40)))
    height: parent.height - 56
    gutter: 10
    open: root.open

    FrameSurface {
      anchors.fill: parent
      radius: 18
      attachedEdge: "right"
      borderColor: root.panelBorder
      topToneOpacity: Colors.darkMode ? 0.96 : 0.91
      bottomToneOpacity: 0.98

      Item {
        id: keyGrabber
        anchors.fill: parent
        focus: root.open
        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Escape) {
            root.close()
            event.accepted = true
          } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.handlePrimaryAction()
            event.accepted = true
          } else if (event.key === Qt.Key_D) {
            store.toggleDetails()
            event.accepted = true
          } else if (event.key === Qt.Key_R && !store.running) {
            store.reload()
            event.accepted = true
          }
        }
      }

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 22
        spacing: 18

        RowLayout {
          Layout.fillWidth: true
          spacing: 12

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
              Layout.fillWidth: true
              text: "Central de Atualizações"
              color: Colors.text1
              font { pixelSize: 24; family: "Inter"; weight: Font.DemiBold }
              elide: Text.ElideRight
            }

            Text {
              Layout.fillWidth: true
              text: "Estado do sistema e fluxo de rebuild."
              color: Colors.text3
              font { pixelSize: 11; family: "JetBrains Mono" }
              elide: Text.ElideRight
            }
          }

          Rectangle {
            radius: 12
            implicitWidth: badgeLabel.implicitWidth + 16
            implicitHeight: 28
            color: Qt.rgba(root.statusTone.r, root.statusTone.g, root.statusTone.b, Colors.darkMode ? 0.14 : 0.11)
            border.width: 1
            border.color: Qt.rgba(root.statusTone.r, root.statusTone.g, root.statusTone.b, 0.22)

            Text {
              id: badgeLabel
              anchors.centerIn: parent
              text: store.host + " • " + store.channel
              color: root.statusTone
              font { pixelSize: 10; family: "JetBrains Mono"; weight: Font.DemiBold }
            }
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 8

          Text {
            Layout.fillWidth: true
            text: store.heroTitle()
            color: Colors.text0
            wrapMode: Text.Wrap
            font { pixelSize: 30; family: "Inter"; weight: Font.DemiBold }
          }

          Text {
            Layout.fillWidth: true
            text: store.heroBody()
            wrapMode: Text.Wrap
            color: Colors.text2
            font { pixelSize: 13; family: "Inter" }
          }
        }

        GridLayout {
          Layout.fillWidth: true
          columns: 2
          rowSpacing: 10
          columnSpacing: 10

          Repeater {
            model: [
              { label: "Último update", value: store.formatDate(store.lastUpdateAt) },
              { label: "Último lock", value: store.formatDate(store.lastLockAt) },
              { label: "Estado atual", value: store.statusLabel() },
              { label: "Fila pendente", value: store.pendingApps > 0 ? (store.pendingApps + " apps") : "vazia" }
            ]

            delegate: Rectangle {
              required property var modelData
              Layout.fillWidth: true
              implicitHeight: 58
              radius: 14
              color: root.detailFill
              border.width: 1
              border.color: Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, Colors.darkMode ? 0.06 : 0.10)

              Column {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 4

                Text {
                  text: modelData.label
                  color: Colors.text3
                  font { pixelSize: 9; family: "JetBrains Mono"; weight: Font.DemiBold }
                }

                Text {
                  width: parent.width
                  text: modelData.value
                  color: Colors.text1
                  font { pixelSize: 12; family: "Inter"; weight: Font.Medium }
                  elide: Text.ElideRight
                }
              }
            }
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 10

          RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Repeater {
              model: store.steps
              delegate: ColumnLayout {
                required property var modelData
                required property int index
                readonly property string state: store.stepState(index)
                Layout.fillWidth: true
                spacing: 7

                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 4
                  radius: 3
                  color: state === "done"
                    ? Colors.success
                    : state === "active"
                      ? Qt.rgba(Colors.info.r, Colors.info.g, Colors.info.b, 0.70)
                      : state === "error"
                        ? Colors.danger
                        : Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, 0.10)
                }

                Text {
                  Layout.fillWidth: true
                  text: modelData.label
                  color: state === "idle" ? Colors.text3 : Colors.text1
                  font { pixelSize: 10; family: "JetBrains Mono"; weight: Font.DemiBold }
                  elide: Text.ElideRight
                }
              }
            }
          }

          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 8
            radius: 4
            color: Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, 0.08)

            Rectangle {
              width: Math.max(8, parent.width * store.progressValue)
              height: parent.height
              radius: parent.radius
              color: root.statusTone
            }
          }
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: 12

          Rectangle {
            Layout.preferredWidth: 210
            implicitHeight: 48
            radius: 15
            color: store.running
                ? Qt.rgba(root.statusTone.r, root.statusTone.g, root.statusTone.b, 0.16)
              : store.primaryEnabled()
                ? root.statusTone
                : Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, 0.12)
            border.width: 1
            border.color: store.primaryEnabled()
              ? Qt.rgba(root.statusTone.r, root.statusTone.g, root.statusTone.b, store.running ? 0.24 : 0.36)
              : Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, 0.12)

            Text {
              anchors.centerIn: parent
              text: store.primaryLabel()
              color: store.running
                ? root.statusTone
                : store.primaryEnabled()
                  ? Colors.bg0
                  : Colors.text3
              font { pixelSize: 13; family: "Inter"; weight: Font.DemiBold }
            }

            MouseArea {
              anchors.fill: parent
              enabled: store.primaryEnabled()
              cursorShape: Qt.PointingHandCursor
              onClicked: root.handlePrimaryAction()
            }
          }

          Text {
            text: store.detailsLabel()
            color: Colors.text2
            font { pixelSize: 11; family: "JetBrains Mono" }
            font.underline: detailsMouse.containsMouse

            MouseArea {
              id: detailsMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: store.toggleDetails()
            }
          }
        }

        Text {
          Layout.fillWidth: true
          text: store.running ? store.currentStepLabel : "R recarrega o estado  •  D abre detalhes"
          color: Colors.text3
          font { pixelSize: 10; family: "JetBrains Mono" }
          elide: Text.ElideRight
        }

        UpdateCenterDetails {
          Layout.fillWidth: true
          Layout.fillHeight: true
          Layout.minimumHeight: store.detailsOpen ? 180 : 0
          Layout.maximumHeight: store.detailsOpen ? 260 : 0
          opacity: store.detailsOpen ? 1 : 0
          visible: opacity > 0
          store: store

          Behavior on opacity {
            NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
          }
        }
      }
    }
  }

  UpdateCenterStore {
    id: store
    onCloseRequested: root.close()
  }

  Timer {
    id: focusTimer
    interval: 20
    repeat: false
    onTriggered: keyGrabber.forceActiveFocus()
  }
}
