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
  Keys.priority: Keys.BeforeItem
  Keys.onPressed: function(event) {
    if (event.key === Qt.Key_Escape) {
      root.close()
      event.accepted = true
    }
  }

  property real cardYOffset: 18

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
    if (visible) {
      closeAnim.start()
      return
    }

    store.resetViewState()
    visible = true
    card.opacity = 0
    cardScale.xScale = 0.985
    cardScale.yScale = 0.985
    cardYOffset = 16
    store.reload()
    openAnim.start()
  }

  function close() {
    closeAnim.start()
  }

  function handlePrimaryAction() {
    if (store.status === "success" || store.status === "clean") {
      close()
      return
    }
    store.primaryAction()
  }

  MouseArea {
    anchors.fill: parent
    onClicked: root.close()
  }

  onVisibleChanged: {
    if (visible) OverlayState.setActive("updatecenter")
    else OverlayState.clear("updatecenter")
    if (visible) {
      root.forceActiveFocus()
    }
  }

  UpdateCenterStore {
    id: store
    onCloseRequested: root.close()
  }

  SequentialAnimation {
    id: openAnim
    ParallelAnimation {
      NumberAnimation { target: root; property: "cardYOffset"; from: OverlayState.morphStartYOffset(root.height); to: 0; duration: 260; easing.type: Easing.OutCubic }
      NumberAnimation { target: card; property: "opacity"; from: 0; to: 1; duration: 140; easing.type: Easing.OutQuad }
      NumberAnimation { target: cardScale; property: "xScale"; from: OverlayState.morphStartXScale(card.width); to: 1; duration: 260; easing.type: Easing.OutCubic }
      NumberAnimation { target: cardScale; property: "yScale"; from: OverlayState.morphStartYScale(card.height); to: 1; duration: 260; easing.type: Easing.OutCubic }
    }
    ScriptAction { script: root.forceActiveFocus() }
  }

  SequentialAnimation {
    id: closeAnim
    ParallelAnimation {
      NumberAnimation { target: root; property: "cardYOffset"; to: OverlayState.morphStartYOffset(root.height); duration: 150; easing.type: Easing.InCubic }
      NumberAnimation { target: cardScale; property: "xScale"; to: OverlayState.morphStartXScale(card.width); duration: 150; easing.type: Easing.InCubic }
      NumberAnimation { target: cardScale; property: "yScale"; to: OverlayState.morphStartYScale(card.height); duration: 150; easing.type: Easing.InCubic }
      NumberAnimation { target: card; property: "opacity"; to: 0; duration: 95; easing.type: Easing.InQuad }
    }
    ScriptAction { script: root.visible = false }
  }

  Rectangle {
    id: card
    anchors.centerIn: parent
    anchors.verticalCenterOffset: root.cardYOffset
    width: 760
    height: 420 + (store.detailsOpen ? 220 : 0)
    radius: 28
    antialiasing: true
    color: Colors.bg1
    border.width: 1
    border.color: root.panelBorder
    transform: Scale {
      id: cardScale
      origin.x: Math.max(0, Math.min(card.width, OverlayState.islandCenterX - card.x))
      origin.y: Math.max(0, Math.min(card.height, OverlayState.islandCenterY - card.y))
      xScale: 1
      yScale: 1
    }
    clip: true
    opacity: 0

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
      onPressed: function(mouse) { mouse.accepted = true }
      onClicked: function(mouse) { mouse.accepted = true }
      onDoubleClicked: function(mouse) { mouse.accepted = true }
      onWheel: function(wheel) { wheel.accepted = true }
    }

    Behavior on height {
      NumberAnimation { duration: 170; easing.type: Easing.OutCubic }
    }

    Rectangle {
      anchors.fill: parent
      radius: parent.radius
      antialiasing: true
      gradient: Gradient {
        GradientStop { position: 0.0; color: Qt.rgba(Colors.bg2.r, Colors.bg2.g, Colors.bg2.b, Colors.darkMode ? 0.96 : 0.91) }
        GradientStop { position: 1.0; color: Qt.rgba(Colors.bg1.r, Colors.bg1.g, Colors.bg1.b, 0.98) }
      }
    }

    Rectangle {
      anchors.fill: parent
      anchors.margins: 1
      radius: parent.radius - 1
      color: "transparent"
      border.width: 1
      border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.10)
    }

    Item {
      anchors.fill: parent
      focus: root.visible
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
      anchors.margins: 24
      spacing: 22

      RowLayout {
        Layout.fillWidth: true
        spacing: 12

        ColumnLayout {
          spacing: 5

          Text {
            text: "Central de Atualizações"
            color: Colors.text1
            font { pixelSize: 28; family: "Inter"; weight: Font.DemiBold }
          }

          Text {
            text: "Uma visão clara do estado do sistema."
            color: Colors.text3
            font { pixelSize: 11; family: "JetBrains Mono" }
          }
        }

        Item { Layout.fillWidth: true }

        Rectangle {
          radius: 13
          implicitWidth: badgeLabel.implicitWidth + 18
          implicitHeight: 30
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
          text: store.heroTitle()
          color: Colors.text0
          font { pixelSize: 36; family: "Inter"; weight: Font.DemiBold }
        }

        Text {
          Layout.fillWidth: true
          text: store.heroBody()
          wrapMode: Text.Wrap
          color: Colors.text2
          font { pixelSize: 14; family: "Inter" }
        }
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: 12

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
            implicitHeight: 62
            radius: 16
            color: root.detailFill
            border.width: 1
            border.color: Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, Colors.darkMode ? 0.06 : 0.10)

            Column {
              anchors.fill: parent
              anchors.margins: 14
              spacing: 5

              Text {
                text: modelData.label
                color: Colors.text3
                font { pixelSize: 9; family: "JetBrains Mono"; weight: Font.DemiBold }
              }

              Text {
                text: modelData.value
                color: Colors.text1
                font { pixelSize: 13; family: "Inter"; weight: Font.Medium }
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
              readonly property int idx: index
              readonly property string state: store.stepState(idx)
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
                text: modelData.label
                color: state === "idle" ? Colors.text3 : Colors.text1
                font { pixelSize: 11; family: "JetBrains Mono"; weight: Font.DemiBold }
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
          id: actionButton
          Layout.preferredWidth: 224
          implicitHeight: 50
          radius: 17
          color: store.running
              ? Qt.rgba(root.statusTone.r, root.statusTone.g, root.statusTone.b, 0.16)
            : store.primaryEnabled()
              ? root.statusTone
              : Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, 0.12)
          border.width: 1
          border.color: store.primaryEnabled()
            ? Qt.rgba(root.statusTone.r, root.statusTone.g, root.statusTone.b, store.running ? 0.24 : 0.36)
            : Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, 0.12)
          focus: true

          Text {
            anchors.centerIn: parent
            text: store.primaryLabel()
            color: store.running
              ? root.statusTone
              : store.primaryEnabled()
                ? Colors.bg0
                : Colors.text3
            font { pixelSize: 14; family: "Inter"; weight: Font.DemiBold }
          }

          Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
              root.handlePrimaryAction()
              event.accepted = true
            }
          }

          MouseArea {
            anchors.fill: parent
            enabled: store.primaryEnabled()
            cursorShape: Qt.PointingHandCursor
            onClicked: root.handlePrimaryAction()
          }
        }

        Item {
          Layout.preferredWidth: detailsLabel.implicitWidth
          Layout.preferredHeight: detailsLabel.implicitHeight

          Text {
            id: detailsLabel
            anchors.centerIn: parent
            text: store.detailsLabel()
            color: Colors.text2
            font { pixelSize: 12; family: "JetBrains Mono" }
            font.underline: detailsMouse.containsMouse
          }

          MouseArea {
            id: detailsMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: store.toggleDetails()
          }
        }

        Item { Layout.fillWidth: true }

        Text {
          text: store.running
            ? store.currentStepLabel
            : "R recarrega o estado  •  D abre detalhes"
          color: Colors.text3
          horizontalAlignment: Text.AlignRight
          font { pixelSize: 10; family: "JetBrains Mono" }
        }
      }

      UpdateCenterDetails {
        Layout.fillWidth: true
        Layout.preferredHeight: store.detailsOpen ? 220 : 0
        Layout.maximumHeight: store.detailsOpen ? 220 : 0
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
