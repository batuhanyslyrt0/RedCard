// Summarises the stored reports and lists the bet messages the filter missed.
//
//   node tools/report-stats.js              summary of all months
//   node tools/report-stats.js --missed     also print missed bet messages
//   node tools/report-stats.js --wrong      also print normal messages that were filtered
//
// Missed messages are the best input for new rules: add them to
// ClassifierTests.swift, adjust DefaultRules.swift and publish new rules.

"use strict";

const fs = require("node:fs");
const path = require("node:path");

const dataDir = process.env.DATA_DIR || path.join(__dirname, "..", "data");
const showMissed = process.argv.includes("--missed");
const showWrong = process.argv.includes("--wrong");

const files = fs.existsSync(dataDir)
  ? fs.readdirSync(dataDir).filter((f) => /^reports-\d{4}-\d{2}\.jsonl$/.test(f)).sort()
  : [];

let total = 0;
const missed = [];
const wronglyFiltered = [];
const byMonth = {};

for (const file of files) {
  const lines = fs.readFileSync(path.join(dataDir, file), "utf8").split("\n").filter(Boolean);
  const month = file.slice(8, 15);
  byMonth[month] = { junk: 0, notJunk: 0 };

  for (const line of lines) {
    let record;
    try { record = JSON.parse(line); } catch { continue; }
    total += 1;
    byMonth[month][record.report] = (byMonth[month][record.report] || 0) + 1;

    for (const message of record.messages || []) {
      if (record.report === "junk" && message.localDecision !== "junk") missed.push(message);
      if (record.report === "notJunk" && message.localDecision === "junk") wronglyFiltered.push(message);
    }
  }
}

console.log(`Reports: ${total}`);
for (const [month, counts] of Object.entries(byMonth)) {
  console.log(`  ${month}: ${counts.junk || 0} bet reports, ${counts.notJunk || 0} "not junk" reports`);
}
console.log(`Missed bet messages: ${missed.length}`);
console.log(`Normal messages filtered by mistake: ${wronglyFiltered.length}`);

function print(title, list) {
  console.log(`\n${title}`);
  for (const m of list) {
    console.log(`- [score ${m.localScore}/${m.localThreshold}, ${m.senderType}] ${m.body.replace(/\s+/g, " ")}`);
  }
}
if (showMissed) print("Missed bet messages:", missed);
if (showWrong) print("Normal messages filtered by mistake:", wronglyFiltered);
