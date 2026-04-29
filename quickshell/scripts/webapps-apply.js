#!/run/current-system/sw/bin/node

const webapps = require("./webapp-lib.js");

const mode = process.argv[2] || "";
const rawPayload = process.argv[3] || "{}";

let payload = {};
try {
  payload = JSON.parse(rawPayload);
} catch {
  write({ ok: false, error: "payload invalido" });
  process.exit(0);
}

try {
  if (mode === "install") {
    const result = webapps.installWebApp(payload);
    write({ ok: true, mode, ...result });
    process.exit(0);
  }

  if (mode === "remove") {
    const result = webapps.removeWebApp(payload.packageId);
    write({ ok: true, mode, ...result });
    process.exit(0);
  }

  write({ ok: false, error: "modo invalido" });
} catch (error) {
  write({
    ok: false,
    error: error && error.message ? error.message : "falha ao aplicar web app"
  });
}

function write(payload) {
  process.stdout.write(JSON.stringify(payload) + "\n");
}
