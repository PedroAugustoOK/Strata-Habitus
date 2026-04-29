import Quickshell
import Quickshell.Io
import QtQuick

Item {
  id: store
  width: 0
  height: 0
  visible: false

  readonly property string nodeBin: "/run/current-system/sw/bin/node"
  readonly property string indexScript: Qt.resolvedUrl("../scripts/webapps-index.js").toString().replace("file://", "")
  readonly property string applyScript: Qt.resolvedUrl("../scripts/webapps-apply.js").toString().replace("file://", "")
  readonly property string catalogPath: Quickshell.env("HOME") + "/.cache/strata/webapps/catalog.json"

  property var items: []
  property string query: ""
  property bool loading: false
  property bool applying: false
  property string errorMessage: ""
  property string infoMessage: ""

  readonly property var filtered: {
    const q = query.trim().toLowerCase()
    const source = items.slice()
    if (q === "") return source
    return source.filter(item => {
      return (item.name || "").toLowerCase().includes(q)
        || (item.description || "").toLowerCase().includes(q)
        || (item.url || "").toLowerCase().includes(q)
        || (item.packageId || "").toLowerCase().includes(q)
    })
  }

  function reload() {
    if (indexProc.running) return
    loading = true
    errorMessage = ""
    indexProc.command = [nodeBin, indexScript]
    indexProc.running = true
  }

  function applyInstall(name, url, iconUrl) {
    if (applying) return
    applying = true
    errorMessage = ""
    infoMessage = ""
    const payload = JSON.stringify({
      name: name,
      url: url,
      iconUrl: iconUrl
    })
    applyProc.command = [nodeBin, applyScript, "install", payload]
    applyProc.running = true
  }

  function remove(packageId) {
    if (applying) return
    applying = true
    errorMessage = ""
    infoMessage = ""
    const payload = JSON.stringify({ packageId: packageId })
    applyProc.command = [nodeBin, applyScript, "remove", payload]
    applyProc.running = true
  }

  FileView {
    id: catalogFile
    path: store.catalogPath
    watchChanges: true
    onFileChanged: reload()
    onLoaded: {
      try {
        store.items = JSON.parse(text())
      } catch (e) {
        store.items = []
      }
    }
  }

  Process {
    id: indexProc
    command: []
    stdout: SplitParser {
      onRead: data => {
        const line = data.trim()
        if (line === "") return
        try {
          const payload = JSON.parse(line)
          if (!payload.ok) {
            store.errorMessage = payload.error || "falha ao carregar web apps"
            return
          }
          catalogFile.reload()
        } catch (e) {
          store.errorMessage = "falha ao carregar web apps"
        }
      }
    }
    onRunningChanged: {
      if (!running) store.loading = false
    }
  }

  Process {
    id: applyProc
    command: []
    stdout: SplitParser {
      onRead: data => {
        const line = data.trim()
        if (line === "") return
        try {
          const payload = JSON.parse(line)
          if (!payload.ok) {
            store.errorMessage = payload.error || "falha ao aplicar web app"
            return
          }
          store.infoMessage = payload.mode === "remove"
            ? "Web app removido."
            : "Web app instalado e indexado."
          store.reload()
        } catch (e) {
          store.errorMessage = "falha ao aplicar web app"
        }
      }
    }
    onRunningChanged: {
      if (!running) store.applying = false
    }
  }
}
