import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
  id: root
  required property var store

  radius: 18
  color: Colors.darkMode
    ? Qt.rgba(0, 0, 0, 0.14)
    : Qt.rgba(1, 1, 1, 0.44)
  border.width: 1
  border.color: Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, Colors.darkMode ? 0.08 : 0.12)
  clip: true

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: 18
    spacing: 14

    GridLayout {
      Layout.fillWidth: true
      columns: 2
      columnSpacing: 22
      rowSpacing: 12

      Repeater {
        model: [
          { label: "Host alvo", value: root.store.host },
          { label: "Canal", value: root.store.channel },
          { label: "Modo", value: root.store.mode },
          { label: "Último sucesso", value: root.store.formatDate(root.store.lastUpdateAt) },
          { label: "Estado", value: root.store.statusLabel() },
          { label: "Fila App Center", value: root.store.pendingApps > 0 ? (root.store.pendingApps + " apps") : "vazia" },
          { label: "Branch", value: root.store.currentBranch },
          { label: "Worktree", value: root.store.gitDirty ? "alterada" : "limpa" },
          { label: "Upstream", value: root.store.upstreamUpdateAvailable ? "disponivel" : "em dia" },
          { label: "Estado local", value: root.store.localChangesAvailable ? "rebuild pendente" : "limpo" },
          { label: "Reboot", value: root.store.rebootRecommended ? "recomendado" : "nao" },
          { label: "Passo atual", value: root.store.currentStep === "idle" ? "aguardando" : root.store.currentStep }
        ]

        delegate: ColumnLayout {
          required property var modelData
          Layout.fillWidth: true
          spacing: 4

          Text {
            text: modelData.label
            color: Colors.text3
            font { pixelSize: 10; family: "JetBrains Mono"; weight: Font.DemiBold }
          }

          Text {
            text: modelData.value
            color: Colors.text1
            font { pixelSize: 13; family: "Inter"; weight: Font.Medium }
          }
        }
      }
    }

    Rectangle {
      Layout.fillWidth: true
      implicitHeight: 1
      color: Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, Colors.darkMode ? 0.08 : 0.12)
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 8

      Text {
        text: "Log resumido"
        color: Colors.text1
        font { pixelSize: 12; family: "JetBrains Mono"; weight: Font.DemiBold }
      }

      Repeater {
        model: root.store.logPreview
        delegate: RowLayout {
          required property string modelData
          Layout.fillWidth: true
          spacing: 10

          Rectangle {
            Layout.alignment: Qt.AlignTop
            width: 5
            height: 5
            radius: 3
            color: Colors.accent
          }

          Text {
            Layout.fillWidth: true
            text: modelData
            wrapMode: Text.Wrap
            color: Colors.text2
            font { pixelSize: 12; family: "Inter" }
          }
        }
      }

      Text {
        visible: root.store.upstreamSummary !== "" || root.store.blockedReason !== "" || root.store.rebootReason !== ""
        Layout.fillWidth: true
        text: root.store.blockedReason !== ""
          ? root.store.blockedReason
          : (root.store.rebootReason !== "" ? root.store.rebootReason : root.store.upstreamSummary)
        wrapMode: Text.Wrap
        color: Colors.text2
        font { pixelSize: 12; family: "Inter" }
      }
    }
  }
}
