#!/usr/bin/env node
/**
 * Tack Visual UI Diff Engine (adapted from imuratalpay/ui-diff).
 *
 * Compares baseline vs current multi-device Android screenshots using:
 * - pixelmatch (threshold 0.1, anti-aliasing ignored)
 * - status-bar top mask (ignores live Android clock/battery noise)
 * - 8-connected coarse-grid bounding-box clustering + proximity merging
 * - 3-panel `Before | After | Diff` PNG composites with red bounding boxes
 * - animated Before <-> After blink GIFs via `gifenc`
 * - machine-readable `.ui-diff/report.json` + automatic `UI_change.md` sync
 *
 * Usage:
 *   node qa/ui-diff/diff_runner.mjs [--base .ui-diff/baseline] [--head .ui-diff/current] [--mask-top 0.042] [--update-md]
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import pixelmatch from 'pixelmatch';
import { PNG } from 'pngjs';
import gifenc from 'gifenc';

const { GIFEncoder, quantize, applyPalette } = gifenc;

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, '..', '..');

function parseArgs(argv) {
  const opts = {
    base: path.join(repoRoot, '.ui-diff', 'baseline'),
    head: path.join(repoRoot, '.ui-diff', 'current'),
    out: path.join(repoRoot, '.ui-diff', 'compare'),
    report: path.join(repoRoot, '.ui-diff', 'report.json'),
    maskTop: 0.042,
    threshold: 0.1,
    minChangedPixels: 25,
    updateMd: true,
  };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--base' && argv[i + 1]) opts.base = path.resolve(argv[++i]);
    else if (a === '--head' && argv[i + 1]) opts.head = path.resolve(argv[++i]);
    else if (a === '--out' && argv[i + 1]) opts.out = path.resolve(argv[++i]);
    else if (a === '--mask-top' && argv[i + 1]) opts.maskTop = parseFloat(argv[++i]);
    else if (a === '--no-md') opts.updateMd = false;
  }
  return opts;
}

function collectPngs(dir, rel = '') {
  const out = new Map();
  if (!fs.existsSync(dir)) return out;
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    const key = rel ? `${rel}/${entry.name}` : entry.name;
    if (entry.isDirectory()) {
      for (const [k, v] of collectPngs(full, key)) out.set(k, v);
    } else if (entry.name.endsWith('.png')) {
      out.set(key, full);
    }
  }
  return out;
}

function readPng(filePath) {
  return PNG.sync.read(fs.readFileSync(filePath));
}

function padPng(src, width, height) {
  if (src.width === width && src.height === height) return src;
  const dst = new PNG({ width, height });
  dst.data.fill(0);
  PNG.bitblt(src, dst, 0, 0, src.width, src.height, 0, 0);
  return dst;
}

function maskTopBand(png, maskRatio) {
  const clone = new PNG({ width: png.width, height: png.height });
  png.data.copy(clone.data);
  const rows = Math.round(png.height * maskRatio);
  for (let y = 0; y < rows; y++) {
    for (let x = 0; x < png.width; x++) {
      const idx = (y * png.width + x) * 4;
      clone.data[idx] = 0;
      clone.data[idx + 1] = 0;
      clone.data[idx + 2] = 0;
      clone.data[idx + 3] = 255;
    }
  }
  return clone;
}

function intersects(a, b, gap) {
  return !(
    a.x + a.width + gap < b.x ||
    b.x + b.width + gap < a.x ||
    a.y + a.height + gap < b.y ||
    b.y + b.height + gap < a.y
  );
}

function unionBox(a, b) {
  const x1 = Math.min(a.x, b.x);
  const y1 = Math.min(a.y, b.y);
  const x2 = Math.max(a.x + a.width, b.x + b.width);
  const y2 = Math.max(a.y + a.height, b.y + b.height);
  return { x: x1, y: y1, width: x2 - x1, height: y2 - y1 };
}

function mergeBoxes(input, gap = 28) {
  let boxes = input.slice();
  let merged = true;
  while (merged) {
    merged = false;
    const next = [];
    for (const box of boxes) {
      const hit = next.findIndex((o) => intersects(box, o, gap));
      if (hit >= 0) {
        next[hit] = unionBox(next[hit], box);
        merged = true;
      } else {
        next.push(box);
      }
    }
    boxes = next;
  }
  return boxes;
}

/** 8-connected coarse grid region clustering matching imuratalpay/ui-diff */
function findRegions(diffMask, width, height, cell = 10, gap = 28) {
  const cols = Math.ceil(width / cell);
  const rows = Math.ceil(height / cell);
  const hot = new Uint8Array(cols * rows);
  for (let y = 0; y < height; y++) {
    const rowOff = ((y / cell) | 0) * cols;
    const base = y * width;
    for (let x = 0; x < width; x++) {
      if (diffMask[base + x]) hot[rowOff + ((x / cell) | 0)] = 1;
    }
  }
  const seen = new Uint8Array(cols * rows);
  const boxes = [];
  const stack = [];
  for (let start = 0; start < hot.length; start++) {
    if (!hot[start] || seen[start]) continue;
    let minC = cols, maxC = -1, minR = rows, maxR = -1;
    stack.push(start);
    seen[start] = 1;
    while (stack.length) {
      const idx = stack.pop();
      const r = (idx / cols) | 0;
      const c = idx - r * cols;
      if (c < minC) minC = c;
      if (c > maxC) maxC = c;
      if (r < minR) minR = r;
      if (r > maxR) maxR = r;
      for (let dr = -1; dr <= 1; dr++) {
        const nr = r + dr;
        if (nr < 0 || nr >= rows) continue;
        for (let dc = -1; dc <= 1; dc++) {
          const nc = c + dc;
          if (nc < 0 || nc >= cols) continue;
          const n = nr * cols + nc;
          if (hot[n] && !seen[n]) {
            seen[n] = 1;
            stack.push(n);
          }
        }
      }
    }
    boxes.push({
      x: minC * cell,
      y: minR * cell,
      width: Math.min(width, (maxC + 1) * cell) - minC * cell,
      height: Math.min(height, (maxR + 1) * cell) - minR * cell,
    });
  }
  return mergeBoxes(boxes, gap);
}

function strokeBox(png, box, rgba = [239, 91, 91, 255], thickness = 4) {
  const { width, height, data } = png;
  const x1 = Math.max(0, box.x);
  const y1 = Math.max(0, box.y);
  const x2 = Math.min(width - 1, box.x + box.width);
  const y2 = Math.min(height - 1, box.y + box.height);
  const paint = (x, y) => {
    const idx = (y * width + x) * 4;
    data[idx] = rgba[0];
    data[idx + 1] = rgba[1];
    data[idx + 2] = rgba[2];
    data[idx + 3] = rgba[3];
  };
  for (let t = 0; t < thickness; t++) {
    for (let x = x1; x <= x2; x++) {
      if (y1 + t < height) paint(x, y1 + t);
      if (y2 - t >= 0) paint(x, y2 - t);
    }
    for (let y = y1; y <= y2; y++) {
      if (x1 + t < width) paint(x1 + t, y);
      if (x2 - t >= 0) paint(x2 - t, y);
    }
  }
}

function downscaleHalf(src) {
  const w = Math.max(1, Math.floor(src.width / 2));
  const h = Math.max(1, Math.floor(src.height / 2));
  const dst = new PNG({ width: w, height: h });
  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) {
      const si = (y * 2 * src.width + x * 2) * 4;
      const di = (y * w + x) * 4;
      dst.data[di] = src.data[si];
      dst.data[di + 1] = src.data[si + 1];
      dst.data[di + 2] = src.data[si + 2];
      dst.data[di + 3] = src.data[si + 3];
    }
  }
  return dst;
}

function buildThreeUpComposite(before, after, diffImg, regions) {
  const bCopy = new PNG({ width: before.width, height: before.height });
  before.data.copy(bCopy.data);
  const aCopy = new PNG({ width: after.width, height: after.height });
  after.data.copy(aCopy.data);

  for (const box of regions) {
    strokeBox(bCopy, box, [239, 91, 91, 255], 4);
    strokeBox(aCopy, box, [239, 91, 91, 255], 4);
  }

  const bSmall = downscaleHalf(bCopy);
  const aSmall = downscaleHalf(aCopy);
  const dSmall = downscaleHalf(diffImg);
  const gap = 12;
  const totalW = bSmall.width * 3 + gap * 2;
  const totalH = bSmall.height;
  const out = new PNG({ width: totalW, height: totalH });
  for (let i = 0; i < out.data.length; i += 4) {
    out.data[i] = 24;
    out.data[i + 1] = 25;
    out.data[i + 2] = 28;
    out.data[i + 3] = 255;
  }
  PNG.bitblt(bSmall, out, 0, 0, bSmall.width, bSmall.height, 0, 0);
  PNG.bitblt(aSmall, out, 0, 0, aSmall.width, aSmall.height, bSmall.width + gap, 0);
  PNG.bitblt(dSmall, out, 0, 0, dSmall.width, dSmall.height, (bSmall.width + gap) * 2, 0);
  return out;
}

function writeBlinkGif(before, after, outPath) {
  const bSmall = downscaleHalf(before);
  const aSmall = downscaleHalf(after);
  const gif = GIFEncoder();
  for (const frame of [bSmall, aSmall]) {
    const palette = quantize(frame.data, 256);
    const index = applyPalette(frame.data, palette);
    gif.writeFrame(index, frame.width, frame.height, { palette, delay: 750 });
  }
  gif.finish();
  fs.writeFileSync(outPath, Buffer.from(gif.bytes()));
}

function loadMeta(pngPath) {
  const metaPath = pngPath.replace(/\.png$/, '.meta.json');
  if (!fs.existsSync(metaPath)) return null;
  try {
    return JSON.parse(fs.readFileSync(metaPath, 'utf8'));
  } catch {
    return null;
  }
}

function updateUiChangeMd(report) {
  const mdPath = path.join(repoRoot, 'UI_change.md');
  if (!fs.existsSync(mdPath)) return;
  const startMarker = '<!-- ui-diff:begin -->';
  const endMarker = '<!-- ui-diff:end -->';
  const existing = fs.readFileSync(mdPath, 'utf8');
  if (!existing.includes(startMarker) || !existing.includes(endMarker)) return;

  const lines = [
    startMarker,
    `_Last run: ${report.timestamp} · Verdict: **${report.verdict}** (${report.changedCount} changed / ${report.totalScreens} screens)_`,
    '',
    '| Device Persona | Screen | Status | Changed Pixels | Regions | A11y Audit | Errors | Composite |',
    '|---|---|---|---:|---:|---|---:|---|',
  ];

  for (const row of report.screens) {
    const pct = row.ratio != null ? `${(row.ratio * 100).toFixed(2)}%` : '—';
    const compLink = row.compositePath
      ? `[Before/After/Diff](file:///${row.compositePath.replace(/\\/g, '/')})`
      : '—';
    lines.push(
      `| \`${row.persona}\` | \`${row.screen}\` | ${row.status} | ${pct} | ${row.regionCount} | ${row.a11ySummary || '—'} | ${row.errorCount} | ${compLink} |`,
    );
  }
  lines.push(endMarker);

  const re = new RegExp(`${startMarker}[\\s\\S]*?${endMarker}`, 'm');
  fs.writeFileSync(mdPath, existing.replace(re, lines.join('\n')), 'utf8');
}

function main() {
  const opts = parseArgs(process.argv.slice(2));
  fs.mkdirSync(opts.out, { recursive: true });

  const basePngs = collectPngs(opts.base);
  const headPngs = collectPngs(opts.head);
  const allKeys = Array.from(new Set([...basePngs.keys(), ...headPngs.keys()])).sort();

  const screens = [];
  let changedCount = 0;

  for (const key of allKeys) {
    const parts = key.split('/');
    const persona = parts.length > 1 ? parts[0] : 'default';
    const screen = parts[parts.length - 1].replace(/\.png$/, '');
    const bPath = basePngs.get(key);
    const hPath = headPngs.get(key);
    const headMeta = hPath ? loadMeta(hPath) : null;
    const a11ySummary = headMeta?.a11y_summary ?? '—';
    const errorCount = headMeta?.errors?.length ?? 0;

    if (!bPath && hPath) {
      screens.push({
        persona,
        screen,
        status: 'new',
        changedPixels: null,
        ratio: null,
        regionCount: 0,
        a11ySummary,
        errorCount,
        compositePath: null,
        blinkPath: null,
      });
      continue;
    }
    if (bPath && !hPath) {
      screens.push({
        persona,
        screen,
        status: 'missing',
        changedPixels: null,
        ratio: null,
        regionCount: 0,
        a11ySummary: '—',
        errorCount: 0,
        compositePath: null,
        blinkPath: null,
      });
      continue;
    }

    const rawBefore = readPng(bPath);
    const rawAfter = readPng(hPath);
    const width = Math.max(rawBefore.width, rawAfter.width);
    const height = Math.max(rawBefore.height, rawAfter.height);
    const pBefore = padPng(rawBefore, width, height);
    const pAfter = padPng(rawAfter, width, height);
    const mBefore = maskTopBand(pBefore, opts.maskTop);
    const mAfter = maskTopBand(pAfter, opts.maskTop);

    const diffImg = new PNG({ width, height });
    const changedPixels = pixelmatch(
      mBefore.data,
      mAfter.data,
      diffImg.data,
      width,
      height,
      {
        threshold: opts.threshold,
        includeAA: false,
        diffColor: [239, 91, 91],
        alpha: 0.25,
      },
    );

    const totalPixels = width * height;
    const ratio = totalPixels > 0 ? changedPixels / totalPixels : 0;
    const isChanged = changedPixels >= opts.minChangedPixels;

    let regions = [];
    let compositePath = null;
    let blinkPath = null;

    if (isChanged) {
      changedCount++;
      const mask = new Uint8Array(totalPixels);
      for (let i = 0; i < totalPixels; i++) {
        const off = i * 4;
        if (
          diffImg.data[off] === 239 &&
          diffImg.data[off + 1] === 91 &&
          diffImg.data[off + 2] === 91
        ) {
          mask[i] = 1;
        }
      }
      regions = findRegions(mask, width, height);
      const slug = `${persona}__${screen}`;
      compositePath = path.join(opts.out, `${slug}__pair.png`);
      blinkPath = path.join(opts.out, `${slug}__blink.gif`);
      const comp = buildThreeUpComposite(pBefore, pAfter, diffImg, regions);
      fs.writeFileSync(compositePath, PNG.sync.write(comp));
      writeBlinkGif(pBefore, pAfter, blinkPath);
    }

    screens.push({
      persona,
      screen,
      status: isChanged ? 'changed' : 'unchanged',
      changedPixels,
      ratio,
      regionCount: regions.length,
      regions,
      a11ySummary,
      errorCount,
      compositePath,
      blinkPath,
    });
  }

  const verdict =
    screens.length === 0
      ? 'No captures found yet'
      : changedCount === 0
        ? 'No visual regressions detected'
        : `${changedCount} screen(s) visually changed`;

  const report = {
    timestamp: new Date().toISOString(),
    baseDir: opts.base,
    headDir: opts.head,
    verdict,
    totalScreens: screens.length,
    changedCount,
    screens,
  };

  fs.mkdirSync(path.dirname(opts.report), { recursive: true });
  fs.writeFileSync(opts.report, JSON.stringify(report, null, 2), 'utf8');
  if (opts.updateMd) {
    updateUiChangeMd(report);
  }

  console.log(JSON.stringify(report, null, 2));
  process.exit(changedCount > 0 ? 1 : 0);
}

main();
