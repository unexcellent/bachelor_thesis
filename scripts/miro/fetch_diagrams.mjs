// Download every frame on the Miro board as an SVG.
//
// Each frame's Miro title is used as the file name (<title>.svg), so the
// titles on the board must match the file names referenced from the thesis.
//
// Usage: node fetch_diagrams.mjs <output-dir>

import { MiroBoard } from "miro-export";
import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";

// https://miro.com/app/board/uXjVHvpaC3o=/?share_link_id=995986789489
const BOARD_ID = "uXjVHvpaC3o=";

const outDir = process.argv[2];
if (!outDir) {
  console.error("usage: node fetch_diagrams.mjs <output-dir>");
  process.exit(1);
}

// The board is public, so the content endpoint works without authentication.
const res = await fetch(
  `https://miro.com/api/v1/boards/${encodeURIComponent(BOARD_ID)}/content/`
);
if (!res.ok) {
  throw new Error(`Fetching board content failed: HTTP ${res.status}`);
}
const { content } = await res.json();

const frames = content.widgets
  .filter((w) => w.canvasedObjectData?.type === "frame")
  .map((w) => ({ id: w.id, title: JSON.parse(w.canvasedObjectData.json).name }));

if (frames.length === 0) {
  throw new Error("No frames found on the Miro board.");
}

await mkdir(outDir, { recursive: true });

const board = new MiroBoard({ boardId: BOARD_ID });
try {
  // miro-export waits only 3s (hardcoded) for the Miro SDK, which now takes
  // ~8s to load. Wait for it here so the library's check passes instantly.
  const page = await board.page;
  await page.waitForFunction(
    () => window.miro && window.cmd?.board?.api?.isAllWidgetsLoaded(),
    { timeout: 60_000 }
  );

  for (const { id, title } of frames) {
    const name = path.basename(title.trim());
    const file = path.join(outDir, `${name}.svg`);
    console.log(`Exporting "${title}" -> ${file}`);
    const svg = await board.getSvg([id]);
    await writeFile(file, svg);
  }
} finally {
  await board.dispose();
}

console.log(`Downloaded ${frames.length} frames to ${outDir}/`);
