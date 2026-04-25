import Quickshell
import Quickshell.Io
import QtQuick
import ".."

Item {
  id: store
  width: 0
  height: 0
  visible: false

  readonly property string cacheDir: Paths.home + "/.cache/strata/launcher"
  readonly property string indexPath: cacheDir + "/index.json"
  readonly property string metaPath: cacheDir + "/index.meta.json"
  readonly property string historyPath: Paths.state + "/launcher-history.json"
  readonly property string pinsPath: Paths.state + "/launcher-pins.json"
  readonly property string nodeBin: "/run/current-system/sw/bin/node"
  readonly property string nodeLauncherIndex: Qt.resolvedUrl("../scripts/launcher-index.js").toString().replace("file://", "")
  readonly property string nodeLauncherSearch: Qt.resolvedUrl("../scripts/launcher-search.js").toString().replace("file://", "")
  readonly property string nodeLauncherLaunch: Qt.resolvedUrl("../scripts/launcher-launch.js").toString().replace("file://", "")
  readonly property string nodeLauncherState: Qt.resolvedUrl("../scripts/launcher-state.js").toString().replace("file://", "")

  property var results: []
  property var lastIndexMeta: ({})
  property string query: ""
  property bool ready: false
  property bool isIndexing: false
  property bool isSearching: false
  property bool isLaunching: false
  property string launchError: ""
  property string indexError: ""
  property int resultLimit: 8
  property bool _pendingRefreshAfterIndex: false
  property bool _pendingSearchAfterIndex: false

  signal launched(bool ok)

  function ensureIndex() {
    rebuildIndex(true)
  }

  function rebuildIndex(forceSearch) {
    _pendingRefreshAfterIndex = true
    _pendingSearchAfterIndex = forceSearch
    indexError = ""
    if (indexProc.running) return
    isIndexing = true
    indexProc.command = [nodeBin, nodeLauncherIndex]
    indexProc.running = true
  }

  function requestSearch(text) {
    query = text
    if (!ready && !isIndexing) rebuildIndex(true)
    searchDelay.restart()
  }

  function performSearch() {
    if (!ready && !isIndexing) return
    isSearching = true
    searchProc.command = [nodeBin, nodeLauncherSearch, indexPath, historyPath, pinsPath, query, String(resultLimit)]
    searchProc.running = true
  }

  function launchItem(item) {
    if (!item || !item.desktopFile || isLaunching) return false
    launchError = ""
    isLaunching = true
    launchProc.command = [
      nodeBin,
      nodeLauncherLaunch,
      "main",
      item.desktopFile,
      item.id,
      historyPath,
      item.exec || "",
      item.terminal ? "true" : "false"
    ]
    launchProc.running = true
    return true
  }

  function launchAction(item, action) {
    if (!item || !action || isLaunching) return false
    launchError = ""
    isLaunching = true
    launchProc.command = [
      nodeBin,
      nodeLauncherLaunch,
      "action",
      item.desktopFile,
      item.id,
      historyPath,
      "",
      "false",
      action.exec || "",
      action.name || ""
    ]
    launchProc.running = true
    return true
  }

  function togglePin(item) {
    if (!item || !item.id || pinProc.running) return
    pinProc.command = [nodeBin, nodeLauncherState, "toggle-pin", item.id, pinsPath]
    pinProc.running = true
  }

  Timer {
    id: searchDelay
    interval: 80
    repeat: false
    onTriggered: store.performSearch()
  }

  FileView {
    id: metaFile
    path: store.metaPath
    watchChanges: true
    onFileChanged: reload()
    onLoaded: {
      try {
        store.lastIndexMeta = JSON.parse(text())
        store.ready = !!store.lastIndexMeta.entryCount
        if (store.ready && !store.isIndexing) {
          if (store.query.trim().length > 0) store.performSearch()
          else if (store.results.length === 0) store.performSearch()
        }
      } catch (e) {
        store.lastIndexMeta = ({})
      }
    }
  }

  Process {
    id: indexProc
    command: []
    stdout: SplitParser {
      onRead: data => {
        var line = data.trim()
        if (line === "") return
        try {
          var payload = JSON.parse(line)
          if (!payload.ok) {
            store.indexError = payload.error || "falha ao indexar aplicativos"
          }
        } catch (e) {
          store.indexError = "saida invalida do indexador"
        }
      }
    }
    onRunningChanged: {
      if (running) return
      store.isIndexing = false
      metaFile.reload()
      store.ready = true
      if (store._pendingRefreshAfterIndex) {
        store._pendingRefreshAfterIndex = false
        if (store._pendingSearchAfterIndex) {
          store._pendingSearchAfterIndex = false
          store.performSearch()
        } else {
          store.requestSearch(store.query)
        }
      }
    }
  }

  Process {
    id: searchProc
    command: []
    stdout: SplitParser {
      onRead: data => {
        var line = data.trim()
        if (line === "") return
        try {
          var payload = JSON.parse(line)
          store.results = payload.results || []
        } catch (e) {
          store.results = []
        }
      }
    }
    onRunningChanged: {
      if (!running) store.isSearching = false
    }
  }

  Process {
    id: launchProc
    command: []
    stdout: SplitParser {
      onRead: data => {
        var line = data.trim()
        if (line === "") return
        try {
          var payload = JSON.parse(line)
          if (payload.ok) {
            store.launchError = ""
            store.requestSearch(store.query)
            store.launched(true)
          } else {
            store.launchError = payload.error || "falha ao abrir aplicativo"
            store.launched(false)
          }
        } catch (e) {
          store.launchError = "falha ao abrir aplicativo"
          store.launched(false)
        }
      }
    }
    onRunningChanged: {
      if (!running) store.isLaunching = false
    }
  }

  Process {
    id: pinProc
    command: []
    stdout: SplitParser {
      onRead: data => {
        var line = data.trim()
        if (line === "") return
        try {
          var payload = JSON.parse(line)
          if (!payload.ok) {
            store.launchError = payload.error || "falha ao alterar fixacao"
            return
          }
          store.requestSearch(store.query)
        } catch (e) {
          store.launchError = "falha ao alterar fixacao"
        }
      }
    }
  }
}
