#!/run/current-system/sw/bin/node

const fs = require("fs");
const path = require("path");
const os = require("os");
const webapps = require("./webapp-lib.js");

const HOME = process.env.HOME || os.homedir();
const CACHE_DIR = path.join(HOME, ".cache", "strata", "webapps");
const CATALOG_PATH = path.join(CACHE_DIR, "catalog.json");

fs.mkdirSync(CACHE_DIR, { recursive: true });

const installed = webapps.readInstalledSet();
const items = webapps.buildCatalog().map(item => ({
  ...item,
  id: `webapp:${item.packageId}`,
  source: "webapp",
  installed: installed.has(item.packageId)
}));

fs.writeFileSync(CATALOG_PATH, `${JSON.stringify(items, null, 2)}\n`, "utf8");
process.stdout.write(JSON.stringify({
  ok: true,
  count: items.length,
  cachePath: CATALOG_PATH
}) + "\n");
