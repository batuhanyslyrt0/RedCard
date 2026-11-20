// Red Card report receiver.
//
// iOS posts the JSON that the RedCardReport extension builds (see
// ReportPayload.swift) to /api/report when someone reports a message.
// Reports are appended to one JSON Lines file per month in ./data.
//
// No IP address, device identifier or phone number is ever stored.
// Static files (rules.json, privacy page, apple-app-site-association) are
// served by nginx straight from ./public, not by this process.
//
// No dependencies: Node.js 18+ only.  Start:  PORT=3200 node server.js

"use strict";

const http = require("node:http");
const fs = require("node:fs");
const path = require("node:path");

const PORT = Number(process.env.PORT || 3200);
const HOST = process.env.HOST || "127.0.0.1";
const DATA_DIR = process.env.DATA_DIR || path.join(__dirname, "data");
const MAX_BODY_BYTES = 64 * 1024;
const MAX_MESSAGES = 5;
const MAX_BODY_CHARS = 2000;

// Simple in-memory rate limit per client, never written to disk.
const RATE_LIMIT = { windowMs: 60 * 60 * 1000, max: 60 };
const hits = new Map();

fs.mkdirSync(DATA_DIR, { recursive: true });

function tooManyRequests(clientKey) {
  const now = Date.now();
  const entry = hits.get(clientKey);
  if (!entry || now - entry.start > RATE_LIMIT.windowMs) {
    hits.set(clientKey, { start: now, count: 1 });
    return false;
  }
  entry.count += 1;
  return entry.count > RATE_LIMIT.max;
}

// Forget old rate-limit entries every hour.
setInterval(() => {
  const now = Date.now();
  for (const [key, entry] of hits) {
    if (now - entry.start > RATE_LIMIT.windowMs) hits.delete(key);
  }
}, RATE_LIMIT.windowMs).unref();

function send(res, status, body) {
  const json = JSON.stringify(body);
  res.writeHead(status, {
    "Content-Type": "application/json; charset=utf-8",
    "Content-Length": Buffer.byteLength(json),
    "Cache-Control": "no-store",
  });
  res.end(json);
}

/// Finds our payload whether iOS sends it as-is or wraps it in another object.
function findPayload(value, depth = 0) {
  if (!value || typeof value !== "object" || depth > 4) return null;
  if (value.app === "RedCard" && Array.isArray(value.messages)) return value;
  for (const child of Object.values(value)) {
    const found = findPayload(child, depth + 1);
    if (found) return found;
  }
  return null;
}

function cleanReport(payload) {
  const report = payload.report === "notJunk" ? "notJunk" : "junk";
  const messages = payload.messages
    .slice(0, MAX_MESSAGES)
    .filter((m) => m && typeof m.body === "string" && m.body.trim() !== "")
    .map((m) => ({
      body: m.body.slice(0, MAX_BODY_CHARS),
      senderType: typeof m.senderType === "string" ? m.senderType.slice(0, 32) : "unknown",
      receivedDay: typeof m.receivedDay === "string" ? m.receivedDay.slice(0, 10) : null,
      localScore: Number.isFinite(m.localScore) ? m.localScore : null,
      localThreshold: Number.isFinite(m.localThreshold) ? m.localThreshold : null,
      localDecision: m.localDecision === "junk" ? "junk" : "allow",
    }));

  if (messages.length === 0) return null;
  return {
    receivedAt: new Date().toISOString(),
    report,
    appVersion: String(payload.appVersion || "").slice(0, 16),
    rulesVersion: Number.isFinite(payload.rulesVersion) ? payload.rulesVersion : null,
    messages,
  };
}

function storeReport(record) {
  const month = record.receivedAt.slice(0, 7); // YYYY-MM
  const file = path.join(DATA_DIR, `reports-${month}.jsonl`);
  fs.appendFileSync(file, JSON.stringify(record) + "\n", { mode: 0o600 });
}

const server = http.createServer((req, res) => {
  const url = new URL(req.url, "http://localhost");

  if (req.method === "GET" && url.pathname === "/api/health") {
    return send(res, 200, { ok: true });
  }

  if (url.pathname !== "/api/report") {
    return send(res, 404, { ok: false });
  }
  if (req.method !== "POST") {
    return send(res, 405, { ok: false });
  }

  const clientKey = req.headers["x-real-ip"] || req.socket.remoteAddress || "unknown";
  if (tooManyRequests(clientKey)) {
    return send(res, 429, { ok: false });
  }

  let size = 0;
  const chunks = [];
  req.on("data", (chunk) => {
    size += chunk.length;
    if (size > MAX_BODY_BYTES) {
      send(res, 413, { ok: false });
      req.destroy();
      return;
    }
    chunks.push(chunk);
  });

  req.on("end", () => {
    if (res.writableEnded) return;
    let body;
    try {
      body = JSON.parse(Buffer.concat(chunks).toString("utf8"));
    } catch {
      return send(res, 400, { ok: false });
    }

    const payload = findPayload(body);
    const record = payload && cleanReport(payload);
    if (!record) return send(res, 422, { ok: false });

    try {
      storeReport(record);
    } catch (error) {
      console.error("Could not store report:", error.message);
      return send(res, 500, { ok: false });
    }
    return send(res, 200, { ok: true });
  });
});

server.listen(PORT, HOST, () => {
  console.log(`Red Card report receiver on http://${HOST}:${PORT}`);
});
