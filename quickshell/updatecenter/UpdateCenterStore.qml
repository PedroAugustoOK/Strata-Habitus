import Quickshell
import Quickshell.Io
import QtQuick

Item {
  id: store
  width: 0
  height: 0
  visible: false

  readonly property string nodeBin: "/run/current-system/sw/bin/node"
  readonly property string statusScript: Qt.resolvedUrl("../scripts/update-center-status.js").toString().replace("file://", "")
  readonly property string runScript: Qt.resolvedUrl("../scripts/update-center-run.js").toString().replace("file://", "")
  readonly property string cacheDir: Quickshell.env("HOME") + "/.cache/strata/update-center"
  readonly property string statusPath: cacheDir + "/status.json"
  readonly property string logPath: cacheDir + "/update.log"

  property string host: (Quickshell.env("HOSTNAME") || "desktop").trim()
  property string channel: host === "desktop" ? "main" : "stable"
  property string mode: host === "desktop" ? "local" : "release"
  property string status: "updates"
  property int summaryCount: 0
  property string currentStep: "idle"
  property bool detailsOpen: false
  property bool running: false
  property bool rebuildRequired: false
  property int pendingApps: 0
  property string lastError: ""
  property string currentStepLabel: "Pronto para verificar o estado do sistema."
  property string currentBranch: "-"
  property bool gitDirty: false
  property bool flakeLockChanged: false
  property bool releaseUpdateAvailable: false
  property var lastUpdateAt: null
  property var lastLockAt: null
  property var lastFinishedAt: null
  property real progressValue: 0
  property var steps: [
    { key: "inputs", label: "Inputs" },
    { key: "build", label: "Build" },
    { key: "switch", label: "Switch" },
    { key: "refresh", label: "Refresh" }
  ]
  property var logPreview: []

  readonly property int stepIndex: {
    if (currentStep === "inputs") return 0
    if (currentStep === "build") return 1
    if (currentStep === "switch") return 2
    if (currentStep === "refresh") return 3
    return -1
  }

  function resetViewState() {
    detailsOpen = false
  }

  function reload() {
    if (statusProc.running) return
    statusProc.command = [nodeBin, statusScript]
    statusProc.running = true
  }

  function toggleDetails() {
    detailsOpen = !detailsOpen
  }

  function heroTitle() {
    if (status === "clean") return "Sistema em dia"
    if (status === "running") return "Atualizando o sistema com segurança"
    if (status === "success") return "Atualização aplicada"
    if (status === "error") return "A atualização não foi concluída"
    return summaryCount <= 1 ? "1 mudança pronta para aplicar" : (summaryCount + " mudanças prontas para aplicar")
  }

  function heroBody() {
    if (status === "clean") return "Nenhuma ação necessária no momento."
    if (status === "running") return currentStepLabel
    if (status === "success") return "O sistema foi atualizado com sucesso."
    if (status === "error") return lastError !== "" ? lastError : "Revise os detalhes e tente novamente."
    if (mode === "release") return "O host atual usa o fluxo de release do Strata e pode aplicar a atualização diretamente daqui."
    return "Atualizações locais detectadas e prontas para uso."
  }

  function statusLabel() {
    if (status === "clean") return "Atualizado"
    if (status === "running") return "Em progresso"
    if (status === "success") return "Concluído"
    if (status === "error") return "Erro"
    if (mode === "release" && releaseUpdateAvailable) return "Release disponível"
    return rebuildRequired ? "Rebuild necessário" : "Mudanças detectadas"
  }

  function primaryLabel() {
    if (status === "running") return "Executando atualização"
    if (status === "success") return "Concluir"
    if (status === "error") return "Tentar novamente"
    if (status === "clean") return "Fechar"
    return "Atualizar agora"
  }

  function detailsLabel() {
    return detailsOpen ? "Ocultar detalhes" : "Ver detalhes"
  }

  function formatDate(value) {
    if (!value) return "-"
    return Qt.formatDateTime(value, "dd/MM  HH:mm")
  }

  function stepState(index) {
    if (status === "error" && index === stepIndex) return "error"
    if (status === "success") return "done"
    if (stepIndex < 0 || currentStep === "idle") return "idle"
    if (index < stepIndex) return "done"
    if (index === stepIndex) return status === "running" ? "active" : "done"
    return "idle"
  }

  function primaryAction() {
    if (status === "running" || runProc.running) return
    if (status === "success" || status === "clean") {
      closeRequested()
      return
    }

    runProc.command = [nodeBin, runScript]
    runProc.running = true
  }

  function progressForStep(stepKey) {
    if (stepKey === "inputs") return 0.16
    if (stepKey === "build") return 0.46
    if (stepKey === "switch") return 0.77
    if (stepKey === "refresh") return 0.94
    return 0
  }

  function applyStatus(payload) {
    if (!payload || typeof payload !== "object") return

    host = payload.host || host
    channel = payload.channel || channel
    mode = payload.mode || mode
    status = payload.status || "updates"
    summaryCount = Number(payload.summaryCount || 0)
    currentStep = payload.currentStep || "idle"
    running = status === "running" || payload.running === true
    rebuildRequired = payload.rebuildRequired === true
    pendingApps = Number(payload.pendingApps || 0)
    lastError = payload.lastError || ""
    currentStepLabel = payload.currentStepLabel || "Pronto para verificar o estado do sistema."
    currentBranch = payload.currentBranch || "-"
    gitDirty = payload.gitDirty === true
    flakeLockChanged = payload.flakeLockChanged === true
    releaseUpdateAvailable = payload.releaseUpdateAvailable === true
    lastUpdateAt = payload.lastSuccessAt ? new Date(payload.lastSuccessAt) : null
    lastLockAt = payload.lastLockAt ? new Date(payload.lastLockAt) : null
    lastFinishedAt = payload.finishedAt ? new Date(payload.finishedAt) : lastUpdateAt
    progressValue = payload.progressValue !== undefined ? Number(payload.progressValue) : progressForStep(currentStep)
    logPreview = Array.isArray(payload.logPreview) ? payload.logPreview : []
  }

  signal closeRequested()

  FileView {
    id: statusFile
    path: store.statusPath
    watchChanges: true
    onFileChanged: store.reload()
    onLoaded: {
      try {
        store.applyStatus(JSON.parse(text()))
      } catch (error) {
        console.log("update-center status parse error:", error.message)
      }
    }
  }

  Process {
    id: statusProc
    command: []
    stdout: SplitParser {
      onRead: data => {
        const line = data.trim()
        if (line === "") return
        try {
          store.applyStatus(JSON.parse(line))
        } catch (error) {
          console.log("update-center stdout parse error:", error.message)
        }
      }
    }
  }

  Process {
    id: runProc
    command: []
    stdout: SplitParser {
      onRead: data => {
        const line = data.trim()
        if (line === "") return
        try {
          const payload = JSON.parse(line)
          if (payload.ok) {
            store.reload()
            return
          }
          store.status = "error"
          store.running = false
          store.lastError = payload.error || "Falha ao iniciar a atualização."
          store.logPreview = [store.lastError]
        } catch (error) {
          console.log("update-center run parse error:", error.message)
        }
      }
    }
    onRunningChanged: {
      if (!running) store.reload()
    }
  }
}
