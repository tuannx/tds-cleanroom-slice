// Minimal static server for the web build: correct MIME for .wasm, no deps.
//   node serve.mjs            -> http://localhost:8080
//   PORT=9000 node serve.mjs  -> another port
import { createServer } from "node:http";
import { createReadStream } from "node:fs";
import { stat } from "node:fs/promises";
import { extname, join, resolve, sep } from "node:path";
import { fileURLToPath } from "node:url";
import { networkInterfaces } from "node:os";

const root = resolve(fileURLToPath(new URL(".", import.meta.url)));
const port = Number(process.env.PORT || 8080);

const TYPES = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".mjs": "text/javascript; charset=utf-8",
  ".wasm": "application/wasm",
  ".css": "text/css; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".png": "image/png",
  ".svg": "image/svg+xml",
  ".ico": "image/x-icon",
};

const server = createServer(async (req, res) => {
  try {
    const url = new URL(req.url ?? "/", "http://localhost");
    let rel = decodeURIComponent(url.pathname);
    if (rel.endsWith("/")) rel += "index.html";
    const file = resolve(join(root, rel));
    if (file !== root && !file.startsWith(root + sep)) {
      res.writeHead(403).end("forbidden");
      return;
    }
    const info = await stat(file);
    if (!info.isFile()) {
      res.writeHead(404).end("not found");
      return;
    }
    res.writeHead(200, {
      "content-type": TYPES[extname(file).toLowerCase()] ?? "application/octet-stream",
      "content-length": info.size,
      "cache-control": "no-cache",
    });
    createReadStream(file).pipe(res);
  } catch {
    res.writeHead(404).end("not found");
  }
});

server.listen(port, "0.0.0.0", () => {
  console.log(`clean-room slice  ->  http://localhost:${port}/`);
  for (const list of Object.values(networkInterfaces())) {
    for (const net of list ?? []) {
      if (net.family === "IPv4" && !net.internal) {
        console.log(`                   ->  http://${net.address}:${port}/`);
      }
    }
  }
});
