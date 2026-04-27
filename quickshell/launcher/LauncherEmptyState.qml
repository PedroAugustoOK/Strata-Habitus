import QtQuick
import QtQuick.Layouts
import ".."

Item {
  id: root

  property bool isIndexing: false
  property bool ready: false
  property bool hasQuery: false
  property bool showAll: false
  property string indexError: ""

  ColumnLayout {
    anchors.centerIn: parent
    spacing: 10

    Text {
      text: root.isIndexing
        ? "Indexando aplicativos..."
        : root.indexError !== ""
          ? "Falha ao montar o indice"
          : root.hasQuery
            ? "Nenhum aplicativo encontrado"
            : root.showAll
              ? "Nenhum aplicativo instalado encontrado"
              : root.ready
              ? "Nenhum app recente ainda"
              : "Preparando launcher"
      color: Colors.text1
      font { pixelSize: 15; family: "JetBrainsMono Nerd Font" }
      Layout.alignment: Qt.AlignHCenter
    }

    Text {
      text: root.indexError !== ""
        ? root.indexError
        : root.hasQuery
          ? "Tente outro nome, palavra-chave ou categoria."
          : root.showAll
            ? "Use Ctrl+A para voltar ao modo rapido ou digite para filtrar a lista."
            : "Fixe alguns apps ou abra alguns para popular os resultados."
      color: Colors.text3
      font { pixelSize: 11; family: "JetBrainsMono Nerd Font" }
      horizontalAlignment: Text.AlignHCenter
      Layout.maximumWidth: 420
      wrapMode: Text.WordWrap
      Layout.alignment: Qt.AlignHCenter
    }

    RowLayout {
      spacing: 8
      visible: root.indexError === "" && !root.isIndexing
      Layout.alignment: Qt.AlignHCenter

      Repeater {
        model: root.hasQuery
          ? ["nome", "palavra-chave", "categoria"]
          : root.showAll
            ? ["Ctrl+A volta", "digite para filtrar", "Enter abre"]
            : ["Enter abre", "Tab mostra acoes", "Ctrl+K fixa"]

        delegate: Rectangle {
          required property var modelData
          radius: 8
          color: Qt.rgba(1, 1, 1, 0.04)
          Layout.preferredHeight: 24
          Layout.preferredWidth: hintText.implicitWidth + 16

          Text {
            id: hintText
            anchors.centerIn: parent
            text: modelData
            color: Colors.text3
            font { pixelSize: 10; family: "JetBrainsMono Nerd Font" }
          }
        }
      }
    }
  }
}
