#!/usr/bin/env node
// Rendu image par image de src/index.html (animation déterministe) vers un MP4 H.264.
//
//   node scripts/render.mjs                         -> out/990prep-motion-9x16.mp4 (sans son)
//   node scripts/render.mjs --audio out/audio.wav   -> vidéo + bande son
//   node scripts/render.mjs --frames 0.5,2,6.6      -> captures PNG dans out/preview/
//
// Variables : FFMPEG (binaire ffmpeg, défaut "ffmpeg"), options --fps (60), --out, --crf (16),
// --workers (navigateurs en parallèle, défaut : nombre de cœurs, 4 au plus).
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { spawn } from 'node:child_process';
import os from 'node:os';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const argv = process.argv.slice(2);
const opt = (name, def) => { const i = argv.indexOf(`--${name}`); return i >= 0 ? argv[i + 1] : def; };
const FPS = parseInt(opt('fps', '60'), 10);
const CRF = opt('crf', '16');
const OUT = path.resolve(opt('out', path.join(ROOT, 'out', '990prep-motion-9x16.mp4')));
const AUDIO = opt('audio', null);
const FRAMES = opt('frames', null);
const FFMPEG = process.env.FFMPEG || 'ffmpeg';
const WORKERS = parseInt(opt('workers', String(Math.min(4, os.cpus().length))), 10);

// ------------------------------------------------------------ serveur statique
const MIME = {
  '.html': 'text/html; charset=utf-8', '.css': 'text/css', '.js': 'text/javascript',
  '.webp': 'image/webp', '.png': 'image/png', '.woff2': 'font/woff2', '.svg': 'image/svg+xml',
};
const server = http.createServer((req, res) => {
  const file = path.join(ROOT, decodeURIComponent(new URL(req.url, 'http://local').pathname));
  if (!file.startsWith(ROOT) || !fs.existsSync(file) || fs.statSync(file).isDirectory()) {
    res.writeHead(404); res.end(); return;
  }
  res.writeHead(200, { 'Content-Type': MIME[path.extname(file)] || 'application/octet-stream' });
  fs.createReadStream(file).pipe(res);
});
await new Promise((r) => server.listen(0, '127.0.0.1', r));
const url = `http://127.0.0.1:${server.address().port}/src/index.html`;

// ------------------------------------------------------------ navigateur
let chromium;
try { ({ chromium } = await import('playwright')); } catch {
  ({ chromium } = await import('/opt/node22/lib/node_modules/playwright/index.mjs'));
}
async function openPage() {
  const browser = await chromium.launch({
    args: ['--no-proxy-server', '--force-color-profile=srgb', '--font-render-hinting=none', '--disable-lcd-text'],
  });
  const page = await browser.newPage({ viewport: { width: 1080, height: 1920 }, deviceScaleFactor: 1 });
  page.on('pageerror', (e) => console.error('[page error]', e.message));
  page.on('console', (m) => { if (m.type() === 'error' || m.type() === 'warning') console.error('[page]', m.text()); });
  await page.goto(url);
  await page.evaluate(() => window.ready);
  const shot = async (t, file) => {
    await page.evaluate((tt) => window.renderAt(tt), t);
    return page.screenshot({ type: 'png', path: file });
  };
  return { browser, page, shot };
}

function ffmpeg(args) {
  return new Promise((resolve, reject) => {
    const ff = spawn(FFMPEG, args, { stdio: ['ignore', 'inherit', 'inherit'] });
    ff.on('close', (c) => (c === 0 ? resolve() : reject(new Error(`ffmpeg a échoué (${c})`))));
  });
}

if (FRAMES) {
  const { browser, shot } = await openPage();
  const dir = path.resolve(opt('dir', path.join(ROOT, 'out', 'preview')));
  fs.mkdirSync(dir, { recursive: true });
  for (const s of FRAMES.split(',')) {
    const t = parseFloat(s);
    await shot(t, path.join(dir, `t${t.toFixed(2).padStart(5, '0')}.png`));
  }
  await browser.close();
  console.log(`captures -> ${dir}`);
} else {
  // Rendu des images en parallèle (l'animation est sans état : l'ordre n'importe pas)
  const probe = await openPage();
  const duration = await probe.page.evaluate(() => window.DURATION);
  await probe.browser.close();
  const n = Math.round(duration * FPS);
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), '990prep-frames-'));
  const t0 = Date.now();
  let done = 0;
  await Promise.all(Array.from({ length: WORKERS }, async (_, w) => {
    const { browser, shot } = await openPage();
    for (let i = w; i < n; i += WORKERS) {
      await shot(i / FPS, path.join(tmp, `f${String(i).padStart(5, '0')}.png`));
      done += 1;
      if (done % FPS === 0) process.stdout.write(`\rimage ${done}/${n}  (${((Date.now() - t0) / 1000).toFixed(0)} s)`);
    }
    await browser.close();
  }));
  fs.mkdirSync(path.dirname(OUT), { recursive: true });
  const args = ['-y', '-loglevel', 'error', '-framerate', String(FPS), '-i', path.join(tmp, 'f%05d.png')];
  if (AUDIO) args.push('-i', AUDIO);
  args.push(
    '-vf', 'scale=out_color_matrix=bt709:out_range=tv,format=yuv420p',
    '-c:v', 'libx264', '-preset', 'slow', '-crf', CRF, '-profile:v', 'high', '-level:v', '4.2',
    '-g', String(FPS * 2), '-r', String(FPS),
    '-colorspace', 'bt709', '-color_primaries', 'bt709', '-color_trc', 'bt709', '-color_range', 'tv',
  );
  if (AUDIO) args.push('-c:a', 'aac', '-b:a', '192k', '-ar', '48000', '-shortest');
  args.push('-movflags', '+faststart', OUT);
  await ffmpeg(args);
  if (opt('keep-frames', null) === null) fs.rmSync(tmp, { recursive: true, force: true });
  else console.log(`\nimages conservées dans ${tmp}`);
  console.log(`\n${n} images (${WORKERS} navigateurs, ${((Date.now() - t0) / 1000).toFixed(0)} s) -> ${OUT}`);
}
server.close();
