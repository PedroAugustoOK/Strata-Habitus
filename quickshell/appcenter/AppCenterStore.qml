import Quickshell
import Quickshell.Io
import QtQuick

Item {
  id: store
  width: 0
  height: 0
  visible: false

  readonly property string indexScript: Qt.resolvedUrl("../scripts/appcenter-index.js").toString().replace("file://", "")
  readonly property string applyScript: Qt.resolvedUrl("../scripts/appcenter-apply.js").toString().replace("file://", "")
  readonly property string queueApplyScript: Qt.resolvedUrl("../scripts/appcenter-queue-apply.js").toString().replace("file://", "")
  readonly property string rebuildScript: Qt.resolvedUrl("../scripts/appcenter-rebuild.js").toString().replace("file://", "")
  readonly property string nodeBin: "/run/current-system/sw/bin/node"
  readonly property string catalogPath: Quickshell.env("HOME") + "/.cache/strata/appcenter/catalog.json"
  readonly property string rebuildStatusPath: Quickshell.env("HOME") + "/.cache/strata/appcenter/rebuild-status.txt"
  readonly property string rebuildLogPath: Quickshell.env("HOME") + "/.cache/strata/appcenter/rebuild.log"

  property var items: []
  property var filtered: []
  property var availableItems: []
  property var installedItems: []
  property var managedItems: []
  property var baseItems: []
  property var discoverItems: []
  property var suggestions: []
  property string query: ""
  property string mode: "discover"
  property bool loading: false
  property bool applying: false
  property bool rebuilding: false
  property string rebuildState: "idle"
  property string errorMessage: ""
  property string infoMessage: ""
  property string warningMessage: ""
  property var pendingChanges: []
  readonly property int pendingCount: pendingChanges.length

  signal applied(bool ok)
  signal rebuildOpened()

  function reload() {
    if (indexProc.running) return
    loading = true
    errorMessage = ""
    infoMessage = ""
    warningMessage = ""
    indexProc.command = [nodeBin, indexScript]
    indexProc.running = true
  }

  function search(text) {
    query = text
    const q = text.trim().toLowerCase()
    const source = sourceItems()
    suggestions = availableItems.slice(0, 6)
    filtered = source
      .filter(item => {
        if (q === "") return true
        return (item.name || "").toLowerCase().includes(q) ||
          (item.packageId || "").toLowerCase().includes(q) ||
          (item.description || "").toLowerCase().includes(q) ||
          (item.source || "").toLowerCase().includes(q)
      })
      .sort(sortItems(q))
      .slice(0, q === "" ? 120 : 300)
  }

  function setMode(nextMode) {
    mode = nextMode
    search(query)
  }

  function rebuildViews() {
    const sorted = items.slice().sort(sortItems(""))
    availableItems = sorted.filter(item => !item.installed && item.discoverable)
    installedItems = sorted.filter(item => !!item.installed)
    managedItems = sorted.filter(item => !!item.managed && !!item.installed)
    baseItems = sorted.filter(item => item.installed && !item.managed)
    discoverItems = sorted.filter(item => item.discoverable)
    suggestions = availableItems.slice(0, 6)
  }

  function sourceItems() {
    if (mode === "managed") return managedItems
    if (mode === "installed") return installedItems
    if (mode === "available") return availableItems
    if (mode === "base") return baseItems
    return discoverItems
  }

  function actionLabel(item) {
    if (!item) return "Sem selecao"
    if (item.action === "none") return "Ja vem com o sistema"
    if (isQueued(item)) return "Remover da lista"
    if (item.source === "nix" && item.managed && !item.installed) return "Cancelar do estado"
    if (item.source === "nix") return item.installed ? "Marcar remocao" : "Adicionar a lista"
    return item.installed ? "Remover do App Center" : "Instalar agora"
  }

  function actionDescription(item) {
    if (!item) return "Selecione um app para ver detalhes e agir sobre ele."
    if (item.action === "none") return "Esse app ja faz parte da base atual do sistema."
    if (item.source === "nix" && isQueued(item)) return "Essa mudanca esta na lista e entra no proximo rebuild."
    if (item.source === "nix" && item.managed && !item.installed) return "O app ja foi adicionado ao estado, mas ainda depende de rebuild para entrar no sistema."
    if (item.installed) return "Remove do conjunto gerenciado pelo App Center."
    return item.source === "flatpak"
      ? "Instala imediatamente via Flatpak."
      : "Entra na lista de compras do Strata para aplicar no rebuild."
  }

  function requiresRebuild(item) {
    return !!item && item.source === "nix" && item.action !== "none"
  }

  function isQueued(item) {
    if (!item || item.source !== "nix") return false
    return pendingChanges.some(change => change.packageId === item.packageId)
  }

  function queueModeFor(item) {
    if (!item || item.source !== "nix" || item.action === "none") return ""
    return item.installed ? "remove" : "install"
  }

  function togglePending(item) {
    if (!item || item.source !== "nix" || item.action === "none") return
    const existing = pendingChanges.findIndex(change => change.packageId === item.packageId)
    if (existing >= 0) {
      pendingChanges = pendingChanges.filter((_, index) => index !== existing)
      infoMessage = "Mudanca removida da lista."
      return
    }

    pendingChanges = pendingChanges.concat([{
      packageId: item.packageId,
      mode: queueModeFor(item),
      name: item.name
    }])
    infoMessage = "Mudanca adicionada a lista."
  }

  function removePending(packageId) {
    const next = pendingChanges.filter(change => change.packageId !== packageId)
    if (next.length === pendingChanges.length) return
    pendingChanges = next
    infoMessage = "Mudanca removida da lista."
  }

  function sortItems(q) {
    return function(a, b) {
      const aExact = q !== "" && (a.name || "").toLowerCase().startsWith(q) ? 1 : 0
      const bExact = q !== "" && (b.name || "").toLowerCase().startsWith(q) ? 1 : 0
      if (aExact !== bExact) return bExact - aExact
      if ((b.relevance || 0) !== (a.relevance || 0)) return (b.relevance || 0) - (a.relevance || 0)
      if (a.installed !== b.installed) return a.installed ? -1 : 1
      if (!!a.managed !== !!b.managed) return a.managed ? -1 : 1
      return (a.name || "").localeCompare(b.name || "")
    }
  }

  function runAction(item) {
    if (!item || applying) return
    if (item.action === "none") {
      errorMessage = ""
      infoMessage = ""
      warningMessage = item.source === "nix" && item.installed
        ? "Esse app faz parte da base do sistema. Para remover, tire-o de modules/packages.nix."
        : "Esse app ja faz parte da base atual do sistema."
      return
    }
    if (item.source === "nix") {
      errorMessage = ""
      warningMessage = ""
      togglePending(item)
      return
    }
    applying = true
    errorMessage = ""
    infoMessage = ""
    warningMessage = ""
    applyProc.command = [nodeBin, applyScript, item.action, item.source, item.packageId, item.installedScope || ""]
    applyProc.running = true
  }

  function applyPendingAndRebuild() {
    if (applying || rebuilding || pendingChanges.length === 0) return
    applying = true
    errorMessage = ""
    infoMessage = ""
    queueApplyProc.command = [nodeBin, queueApplyScript, JSON.stringify(pendingChanges)]
    queueApplyProc.running = true
  }

  function runRebuild() {
    if (rebuilding) return
    rebuilding = true
    rebuildState = "opening"
    errorMessage = ""
    infoMessage = ""
    rebuildProc.command = [nodeBin, rebuildScript]
    rebuildProc.running = true
  }

  function applyRebuildStatus(rawText) {
    const lines = rawText.split(/\r?\n/).map(line => line.trim()).filter(Boolean)
    if (lines.length === 0) return

    const nextState = lines[0]
    const code = lines.length >= 5 ? lines[4] : ""
    rebuildState = nextState

    if (nextState === "opening" || nextState === "running") {
      rebuilding = true
      errorMessage = ""
      infoMessage = nextState === "opening"
        ? "Abrindo terminal de rebuild..."
        : "Rebuild em andamento no terminal."
      return
    }

    rebuilding = false
    if (nextState === "success") {
      errorMessage = ""
      infoMessage = "Rebuild concluido com sucesso."
      reload()
      return
    }

    if (nextState === "failed") {
      errorMessage = code !== ""
        ? `Rebuild falhou (codigo ${code}). Veja ${rebuildLogPath}.`
        : `Rebuild falhou. Veja ${rebuildLogPath}.`
    }
  }

  function indexOfPackage(packageId, source) {
    for (let i = 0; i < filtered.length; i += 1) {
      const item = filtered[i]
      if (item.packageId === packageId && item.source === source) return i
    }
    return -1
  }

  FileView {
    id: catalogFile
    path: store.catalogPath
    watchChanges: true
    onFileChanged: reload()
    onLoaded: {
        try {
          store.items = JSON.parse(text())
          store.rebuildViews()
          store.search(store.query)
        } catch (e) {
          store.items = []
          store.availableItems = []
          store.installedItems = []
          store.managedItems = []
          store.baseItems = []
          store.discoverItems = []
          store.suggestions = []
          store.filtered = []
        }
      }
  }

  FileView {
    id: rebuildStatusFile
    path: store.rebuildStatusPath
    watchChanges: true
    onFileChanged: reload()
    onLoaded: store.applyRebuildStatus(text())
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
            store.errorMessage = payload.error || "falha ao carregar catalogo"
            return
          }
          if (payload.flatpakWarning) {
            store.warningMessage = payload.flatpakWarning
          }
          catalogFile.reload()
        } catch (e) {
          store.errorMessage = "falha ao carregar catalogo"
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
          if (!payload.ok && payload.error) {
            store.errorMessage = payload.error
            store.applied(false)
            return
          }
          store.infoMessage = payload.source === "nix"
            ? "Estado Nix atualizado. Use o rebuild para aplicar."
            : "Alteracao aplicada."
          store.reload()
          store.applied(true)
        } catch (e) {
          store.errorMessage = "falha ao aplicar alteracao"
          store.applied(false)
        }
      }
    }
    onRunningChanged: {
      if (!running) store.applying = false
    }
  }

  Process {
    id: queueApplyProc
    command: []
    stdout: SplitParser {
      onRead: data => {
        const line = data.trim()
        if (line === "") return
        try {
          const payload = JSON.parse(line)
          if (!payload.ok) {
            store.errorMessage = payload.error || "falha ao aplicar lista"
            store.applied(false)
            return
          }
          store.pendingChanges = []
          store.infoMessage = "Lista aplicada. Abrindo rebuild."
          store.reload()
          store.applied(true)
          store.runRebuild()
        } catch (e) {
          store.errorMessage = "falha ao aplicar lista"
          store.applied(false)
        }
      }
    }
    onRunningChanged: {
      if (!running) store.applying = false
    }
  }

  Process {
    id: rebuildProc
    command: []
    stdout: SplitParser {
      onRead: data => {
        const line = data.trim()
        if (line === "") return
        try {
          const payload = JSON.parse(line)
          if (!payload.ok) {
            store.errorMessage = payload.error || "falha ao abrir rebuild"
            store.rebuilding = false
            store.rebuildState = "idle"
            return
          }
          store.infoMessage = payload.message || "Terminal de rebuild aberto."
          store.rebuildOpened()
        } catch (e) {
          store.errorMessage = "falha ao abrir rebuild"
          store.rebuilding = false
          store.rebuildState = "idle"
        }
      }
    }
  }
}
