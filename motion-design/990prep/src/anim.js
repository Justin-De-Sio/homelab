/* 990prep · motion design 9:16 · moteur d'animation déterministe.
 *
 * Tout l'état visuel est une fonction pure du temps t (en secondes) :
 * window.renderAt(t) place chaque élément pour l'image demandée, ce qui
 * permet un rendu image par image (scripts/render.mjs) sans saut ni dérive.
 *
 * Tempo : 120 BPM, une mesure = 2 s, une scène = une mesure.
 *   0 à 2 s    accroche            "Tu révises le TOEIC® à l'aveugle ?"
 *   2 à 4 s    révélation           990prep te montre où tu perds des points
 *   4 à 6 s    tests blancs en conditions réelles
 *   6 à 8 s    correction détaillée
 *   8 à 10 s   points faibles, partie par partie
 *   10 à 12 s  vocabulaire en répétition espacée
 *   12 à 15 s  appel à l'action
 */
(() => {
  'use strict';

  const DURATION = 15;
  const $ = (s) => document.querySelector(s);
  const $$ = (s) => [...document.querySelectorAll(s)];

  const C = {
    ink: '#0F172B', orange: '#F97415', blue: '#1565C0', green: '#43A047',
    listen: '#2979FF', read: '#2E7D32', light: '#F3F5F8', dim: '#5A6478',
    line: '#E3E7EE', red: '#EF4444', white: '#FFFFFF',
  };

  // Repères temporels (secondes). scripts/audio.py suit les mêmes repères.
  const T = {
    hookHits: [0.0, 0.125, 0.375, 0.5, 0.75, 0.875, 1.125],
    glassesPop: 1.46, lensGrow: [1.7, 2.08],
    fox: 2.0, wm2: 2.14, s2txt: 2.36, glint: 2.64, s2out: 3.72,
    cardIn: 3.84, timer0: 4.3,
    ft3: [3.96, 5.7], ft4: [6.04, 7.7], ft5: [8.04, 9.7], ft6: [10.04, 11.8],
    tapC: 6.06, wrongC: 6.28, rightB: 6.52, explain: 6.74,
    statsSwap: 7.88, bars: 8.2, weak: 9.0,
    cardOut: 9.84, deckIn: 9.92, flip: 10.5, tapYes: 11.08, toast: 11.24,
    wipe: 11.84,
    hero: 12.1, wm7: 12.42, proof: 12.76, btn: 12.96, url: 13.16, legal: 13.32,
    shine: 13.7, pulse: 14.0, tap7: 14.16,
  };

  // ------------------------------------------------------------------ maths
  const clamp = (x, a = 0, b = 1) => Math.min(b, Math.max(a, x));
  const lerp = (a, b, p) => a + (b - a) * p;
  const E = {
    lin: (p) => p,
    inQuad: (p) => p * p,
    outQuad: (p) => 1 - (1 - p) * (1 - p),
    inOutQuad: (p) => (p < 0.5 ? 2 * p * p : 1 - Math.pow(-2 * p + 2, 2) / 2),
    inCubic: (p) => p * p * p,
    outCubic: (p) => 1 - Math.pow(1 - p, 3),
    inOutCubic: (p) => (p < 0.5 ? 4 * p * p * p : 1 - Math.pow(-2 * p + 2, 3) / 2),
    outQuint: (p) => 1 - Math.pow(1 - p, 5),
    inOutQuart: (p) => (p < 0.5 ? 8 * p * p * p * p : 1 - Math.pow(-2 * p + 2, 4) / 2),
    outBack: (p) => { const s = 1.70158; return 1 + (s + 1) * Math.pow(p - 1, 3) + s * Math.pow(p - 1, 2); },
    inBack: (p) => { const s = 1.70158; return (s + 1) * p * p * p - s * p * p; },
  };
  // progression de t entre a et b, avec easing
  const P = (t, a, b, ease = E.lin) => ease(clamp((t - a) / (b - a)));
  // ressort amorti (0 -> 1) ; f : fréquence propre en Hz, z : amortissement
  function spring(dt, f = 2.2, z = 0.45) {
    if (dt <= 0) return 0;
    const w = 2 * Math.PI * f;
    const wd = w * Math.sqrt(1 - z * z);
    return 1 - Math.exp(-z * w * dt) * (Math.cos(wd * dt) + ((z * w) / wd) * Math.sin(wd * dt));
  }
  function rgb(h) { const n = parseInt(h.slice(1), 16); return [(n >> 16) & 255, (n >> 8) & 255, n & 255]; }
  function mix(a, b, p) {
    const A = rgb(a), B = rgb(b);
    return `rgb(${A.map((v, i) => Math.round(v + (B[i] - v) * p)).join(',')})`;
  }
  function rgba(h, a) { const [r, g, b] = rgb(h); return `rgba(${r},${g},${b},${a.toFixed(3)})`; }

  function vis(el, on) { el.style.visibility = on ? 'inherit' : 'hidden'; }
  function css(el, { x = 0, y = 0, s = 1, sx, sy, r = 0, o } = {}) {
    const SX = sx ?? s, SY = sy ?? s;
    el.style.transform = `translate(${x.toFixed(2)}px, ${y.toFixed(2)}px) rotate(${r.toFixed(3)}deg) scale(${SX.toFixed(4)}, ${SY.toFixed(4)})`;
    if (o !== undefined) el.style.opacity = clamp(o).toFixed(3);
  }
  function circleMask(el, cx, cy, r) {
    const m = `radial-gradient(circle ${Math.max(r, 0).toFixed(1)}px at ${cx}px ${cy}px, #000 99%, transparent 100%)`;
    el.style.webkitMaskImage = m; el.style.maskImage = m;
  }
  function noMask(el) { el.style.webkitMaskImage = 'none'; el.style.maskImage = 'none'; }

  // ------------------------------------------------------------ construction
  // Titre : tableau de lignes, chaque ligne = tableau de mots [html, classes]
  function buildHeadline(el, lines) {
    const words = [];
    el.innerHTML = '';
    lines.forEach((line) => {
      const L = document.createElement('div');
      L.className = 'line';
      line.forEach(([html, cls = ''], i) => {
        if (i > 0 && !cls.includes('tight')) L.appendChild(document.createTextNode(' '));
        const w = document.createElement('span');
        w.className = `w ${cls}`.trim();
        const inner = document.createElement('span');
        inner.className = 'wi';
        inner.innerHTML = html;
        w.appendChild(inner);
        L.appendChild(w);
        words.push(inner);
      });
      el.appendChild(L);
    });
    return words;
  }
  // Wordmark : "990prep", Outfit 700, le "0" (3e caractère) en orange
  function buildWordmark(el) {
    el.innerHTML = '990prep'.split('').map((c, i) => `<span class="l${i === 2 ? ' o' : ''}">${c}</span>`).join('');
    return [...el.children];
  }
  // Réduit la taille du titre si une ligne dépasse maxW
  function fitHeadline(el, maxW) {
    const lines = [...el.querySelectorAll('.line')];
    lines.forEach((l) => { l.style.display = 'block'; l.style.width = 'max-content'; });
    const widest = Math.max(...lines.map((l) => l.offsetWidth));
    if (widest > maxW) {
      const fs = parseFloat(getComputedStyle(el).fontSize);
      el.style.fontSize = `${((fs * maxW) / widest).toFixed(2)}px`;
    }
    if (el.classList.contains('center')) lines.forEach((l) => { l.style.margin = '0 auto'; });
  }

  const hookWords = buildHeadline($('#hook'), [
    [['Tu'], ['révises']],
    [['le'], ['TOEIC<sup>®</sup>']],
    [['à', 'hi'], ['l’aveugle', 'hi'], ['?', 'hi free tight']],
  ]);
  const s2Letters = buildWordmark($('#s2wm'));
  const s2Words = buildHeadline($('#s2txt'), [
    [['te'], ['montre'], ['où'], ['tu'], ['perds']],
    [['des', 'hi'], ['points.', 'hi']],
  ]);
  const FT = [
    ['#ft3', [[['Des'], ['tests'], ['blancs']], [['en', 'hi'], ['conditions', 'hi'], ['réelles', 'hi']]], T.ft3],
    ['#ft4', [[['Chaque'], ['erreur,']], [['expliquée.', 'hi']]], T.ft4],
    ['#ft5', [[['Tes'], ['points', 'hi'], ['faibles,', 'hi']], [['partie'], ['par'], ['partie.']]], T.ft5],
    ['#ft6', [[['Plus'], ['de'], ['1&nbsp;800', 'hi'], ['mots', 'hi']], [['en'], ['répétition'], ['espacée.']]], T.ft6],
  ].map(([sel, lines, [tin, tout]]) => {
    const el = $(sel);
    return { el, bar: el.querySelector('.bar'), hl: el.querySelector('.headline'), words: buildHeadline(el.querySelector('.headline'), lines), tin, tout };
  });
  const ctaLetters = buildWordmark($('#ctaWm'));

  // Statistiques par partie (Listening 1 à 4 en bleu, Reading 5 à 7 en vert)
  const STATS = [[1, 92, 'l'], [2, 84, 'l'], [3, 76, 'l'], [4, 71, 'l'], [5, 88, 'r'], [6, 79, 'r'], [7, 52, 'r']];
  const rows = STATS.map(([n, v, k]) => {
    const row = document.createElement('div');
    row.className = 'srow';
    row.innerHTML = `<span class="slab">Partie ${n}</span><span class="track"><span class="fill"></span></span><span class="sval">0&nbsp;%</span>`;
    $('#srows').appendChild(row);
    const fill = row.querySelector('.fill');
    fill.style.background = k === 'l' ? C.listen : C.read;
    return { row, fill, track: row.querySelector('.track'), val: row.querySelector('.sval'), v, k };
  });
  const tip = document.createElement('div');
  tip.id = 'weakTip';
  tip.innerHTML = '<svg class="i"><use href="#i-target"/></svg>Point faible';
  $('#pStats').appendChild(tip);

  // Timer du test blanc (section Reading : 75 min)
  const timerEl = $('#timerTxt');
  let lastTimer = -1;
  function setTimer(sec) {
    if (sec === lastTimer) return;
    lastTimer = sec;
    const h = Math.floor(sec / 3600), m = Math.floor((sec % 3600) / 60), s = sec % 60;
    const str = `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
    timerEl.innerHTML = str.split('').map((ch) => (ch === ':' ? '<span class="c">:</span>' : `<span class="d">${ch}</span>`)).join('');
  }

  // Étincelles du CTA (pseudo-aléatoire déterministe)
  let seed = 7;
  const rnd = () => ((seed = (seed * 16807) % 2147483647) / 2147483647);
  const sparks = Array.from({ length: 22 }, () => {
    const el = document.createElement('div');
    el.className = 'spark';
    const size = 4 + rnd() * 9;
    Object.assign(el.style, { width: `${size}px`, height: `${size}px`, background: rnd() < 0.55 ? C.orange : '#FFFFFF' });
    $('#sparks').appendChild(el);
    return { el, x: 60 + rnd() * 960, y: 200 + rnd() * 1300, sp: 20 + rnd() * 50, ph: rnd() * 6.28, a: 0.25 + rnd() * 0.5 };
  });

  // Mesures (après chargement des polices)
  const L = {};
  function layout() {
    fitHeadline($('#hook'), 900);
    fitHeadline($('#s2txt'), 960);
    FT.forEach((f) => fitHeadline(f.hl, 936));
    const common = Math.min(...FT.map((f) => parseFloat(getComputedStyle(f.hl).fontSize)));
    FT.forEach((f) => { f.hl.style.fontSize = `${common}px`; });

    // lentilles du renard (repérées sur mascotte.webp, 512 px)
    const k = $('#foxHead').offsetWidth / 512;
    [['#lensL', 190, 303], ['#lensR', 322, 303]].forEach(([sel, cx, cy]) => {
      const r = 50 * k;
      Object.assign($(sel).style, { left: `${cx * k - r}px`, top: `${cy * k - r}px`, width: `${2 * r}px`, height: `${2 * r}px` });
    });

    // points de toucher
    const card = $('#card');
    const cardX = card.offsetLeft, cardY = card.offsetTop;
    const oC = $('#oC');
    L.tap1 = { x: cardX + 40 + 250, y: cardY + oC.offsetTop + oC.offsetHeight / 2 };
    const yes = $('#btnYes'), deck = $('#deck');
    L.tap2 = { x: deck.offsetLeft + 36 + (740 - 72 - 18) * 0.75 + 18, y: deck.offsetTop + 530 - 36 - 42 };
    const btn = $('#ctaBtn');
    L.tap3 = { x: btn.offsetLeft + btn.offsetWidth * 0.84, y: btn.offsetTop + btn.offsetHeight * 0.62 };
    void yes;

    // hauteur naturelle de l'explication
    L.explainH = $('#explain .inner').offsetHeight + 4;
    // étiquette "Point faible" sur la ligne Partie 7
    const r7 = rows[6], srows = $('#srows');
    L.tip = {
      x: srows.offsetLeft + r7.row.offsetLeft + r7.track.offsetLeft + r7.track.offsetWidth * (r7.v / 100) + 18,
      y: srows.offsetTop + r7.row.offsetTop + (r7.row.offsetHeight - 58) / 2,
    };
    Object.assign(tip.style, { left: `${L.tip.x}px`, top: `${L.tip.y}px` });
  }

  // --------------------------------------------------------------- scènes
  // décalage hors masque : assez grand pour que ni accents ni jambages ne dépassent
  const OFF = 135;
  function animWords(words, t, tin, tout, { stagger = 0.055, dur = 0.5, ostagger = 0.025, odur = 0.3 } = {}) {
    words.forEach((w, i) => {
      const p = P(t, tin + i * stagger, tin + i * stagger + dur, E.outQuint);
      const po = tout == null ? 0 : P(t, tout + i * ostagger, tout + i * ostagger + odur, E.inCubic);
      w.style.transform = `translate(0, ${((1 - p) * OFF - po * OFF).toFixed(2)}%)`;
    });
  }

  function scene1(t) {
    const on = t < 2.12;
    vis($('#s1'), on);
    if (!on) return;
    hookWords.forEach((w, i) => {
      const t0 = T.hookHits[i] - (i === hookWords.length - 1 ? 0.03 : 0.08);
      if (i === hookWords.length - 1) {
        // le "?" rebondit
        const k = t < t0 ? 0 : spring(t - t0, 2.3, 0.33);
        w.style.opacity = t < t0 ? 0 : 1;
        w.style.transform = `translate(0, ${((1 - k) * 60).toFixed(2)}px) rotate(${((1 - k) * -40).toFixed(2)}deg) scale(${(0.2 + 0.8 * k).toFixed(4)})`;
      } else {
        const p = P(t, t0, t0 + 0.46, E.outQuint);
        w.style.transform = `translate(0, ${((1 - p) * OFF).toFixed(2)}%)`;
      }
    });
    if (t < T.lensGrow[0]) {
      const hook = $('#hook');
      hook.style.transformOrigin = '590px 760px';
      hook.style.transform = `scale(${(1 + 0.02 * P(t, 0, 1.7, E.outQuad)).toFixed(4)})`;
      hook.style.filter = 'none';
    }
  }

  // Transition : les lunettes du renard apparaissent, puis la caméra plonge à
  // travers le verre droit (zoom exponentiel centré sur ce verre).
  const G = { cy: 1300, cxL: 400, cxR: 680, r0: 118, bx: 540, by: 1262 };
  function lens(t) {
    const world = $('#world'), g = $('#glasses'), hook = $('#hook');
    if (t < T.glassesPop) { vis(world, false); vis(g, false); return; }
    vis(world, t < 12.45);
    if (t >= T.lensGrow[1]) { noMask(world); vis(g, false); return; }
    vis(g, true);
    const pop = spring(t - T.glassesPop, 2.5, 0.46);
    const p = P(t, T.lensGrow[0], T.lensGrow[1]);
    const S = Math.pow(17, p * p);
    const ox = G.cxR, oy = G.cy;
    const cxL = ox + (G.cxL - ox) * S;
    const r = G.r0 * pop * S;
    const sw = 17 * S;
    const inner = Math.max(r - sw / 2, 0);
    const m = (cx) => `radial-gradient(circle ${inner.toFixed(1)}px at ${cx.toFixed(1)}px ${oy}px, #000 99%, transparent 100%)`;
    world.style.webkitMaskImage = `${m(cxL)}, ${m(ox)}`;
    world.style.maskImage = world.style.webkitMaskImage;
    const rimO = 1 - P(t, T.lensGrow[0] + 0.14, T.lensGrow[1] - 0.04, E.inQuad);
    [['#gL', cxL], ['#gR', ox]].forEach(([sel, cx]) => {
      const c = $(sel);
      c.setAttribute('cx', cx.toFixed(1)); c.setAttribute('cy', oy);
      c.setAttribute('r', r.toFixed(1)); c.setAttribute('stroke-width', sw.toFixed(1));
      c.style.opacity = rimO.toFixed(3);
    });
    const b = $('#gBridge');
    b.setAttribute('stroke-width', '17');
    b.setAttribute('transform', `translate(${ox} ${oy}) scale(${S.toFixed(4)}) translate(${-ox} ${-oy}) translate(${G.bx} ${G.by}) scale(${pop.toFixed(4)}) translate(${-G.bx} ${-G.by})`);
    b.style.opacity = rimO.toFixed(3);
    // l'accroche suit le mouvement (parallaxe) et passe hors mise au point
    const sh = 1 + (S - 1) * 0.3;
    hook.style.transformOrigin = `${ox - 90}px ${oy - 540}px`;
    hook.style.transform = `scale(${(sh * (1 + 0.02 * P(t, 0, 1.7, E.outQuad))).toFixed(4)})`;
    hook.style.filter = p > 0.001 ? `blur(${(p * p * 14).toFixed(2)}px)` : 'none';
  }

  function worldBg(t) {
    css($('#blobA'), { x: Math.sin(t * 0.55) * 50, y: Math.cos(t * 0.42) * 40 });
    css($('#blobB'), { x: Math.cos(t * 0.47) * 60, y: Math.sin(t * 0.38) * 50 });
    $('#dots').style.backgroundPosition = `20px ${(20 - t * 8).toFixed(2)}px`;
  }

  function scene2(t) {
    const on = t > 1.9 && t < 4.3;
    vis($('#s2'), on);
    if (!on) return;
    const out = P(t, T.s2out, T.s2out + 0.24, E.inBack);
    const k = t < T.fox ? 0 : spring(t - T.fox, 2.0, 0.42);
    const bob = Math.sin((t - T.fox) * Math.PI * 1.7) * 7;
    css($('#foxWrap'), {
      y: (1 - k) * 140 + bob * P(t, T.fox + 0.3, T.fox + 0.8) + out * 60,
      s: (0.3 + 0.7 * k) * (1 - 0.85 * clamp(out)),
      r: (1 - k) * -18 + out * 14,
      o: clamp((t - T.fox) * 7) * (1 - clamp(out * 1.3)),
    });
    const gp = P(t, T.glint, T.glint + 0.42, E.inOutQuad);
    $$('.glint').forEach((g) => { g.style.transform = `translateX(${lerp(-170, 330, gp).toFixed(1)}%) rotate(22deg)`; });
    s2Letters.forEach((l, i) => {
      const t0 = T.wm2 + i * 0.035;
      const p = P(t, t0, t0 + 0.55, E.outQuint);
      const po = P(t, T.s2out + i * 0.012, T.s2out + i * 0.012 + 0.22, E.inCubic);
      l.style.transform = `translate(0, ${((1 - p) * 90 - po * 70).toFixed(2)}px)`;
      l.style.opacity = (clamp(p * 1.6) * (1 - po)).toFixed(3);
    });
    animWords(s2Words, t, T.s2txt, T.s2out + 0.02, { stagger: 0.05, ostagger: 0.012, odur: 0.22 });
  }

  function titles(t) {
    FT.forEach(({ el, bar, words, tin, tout }) => {
      const on = t > tin - 0.06 && t < tout + 0.5;
      vis(el, on);
      if (!on) return;
      const pb = P(t, tin - 0.04, tin + 0.36, E.outCubic);
      const pbo = P(t, tout, tout + 0.26, E.inCubic);
      bar.style.transformOrigin = pbo > 0 ? '100% 50%' : '0 50%';
      bar.style.transform = `scaleX(${(pb * (1 - pbo)).toFixed(4)})`;
      animWords(words, t, tin + 0.04, tout, { stagger: 0.05, ostagger: 0.015, odur: 0.24 });
    });
  }

  // --- carte produit
  const optEls = { A: $('#oA'), B: $('#oB'), C: $('#oC'), D: $('#oD') };
  function optState(el, { border, bg, letterBg, letterFg, icon, iconBg, shake = 0, scale = 1, collapse = 0 }) {
    el.style.borderColor = border;
    el.style.background = bg;
    const letter = el.querySelector('.letter');
    letter.style.background = letterBg;
    letter.style.color = letterFg;
    const ic = el.querySelector('.oicon');
    ic.style.opacity = clamp(icon * 3).toFixed(3);
    ic.style.background = iconBg;
    ic.style.transform = `scale(${icon.toFixed(4)})`;
    el.style.height = `${(92 * (1 - collapse)).toFixed(2)}px`;
    el.style.marginBottom = `${(12 * (1 - collapse)).toFixed(2)}px`;
    el.style.borderWidth = `${(2 * (1 - collapse)).toFixed(2)}px`;
    el.dataset.shake = shake;
    el.dataset.scale = scale;
    el.dataset.collapse = collapse;
  }

  function panelTest(t) {
    const p = $('#pTest');
    const off = P(t, T.statsSwap - 0.04, T.statsSwap + 0.14, E.inCubic);
    vis(p, off < 1);
    css(p, { y: -off * 34, o: 1 - off });
    if (off >= 1) return;

    // états des réponses
    const sel = P(t, T.tapC + 0.04, T.tapC + 0.16);
    const wrong = P(t, T.wrongC, T.wrongC + 0.14);
    const right = P(t, T.rightB, T.rightB + 0.16);
    const col = P(t, T.explain, T.explain + 0.38, E.inOutCubic);
    const kC = t < T.wrongC ? 0 : spring(t - T.wrongC, 3.0, 0.4);
    const kB = t < T.rightB ? 0 : spring(t - T.rightB, 3.0, 0.4);
    const shake = t < T.wrongC ? 0 : Math.sin((t - T.wrongC) * Math.PI * 2 * 8) * 11 * Math.exp(-(t - T.wrongC) * 7);
    const neutral = { border: C.line, bg: C.white, letterBg: C.light, letterFg: C.dim, icon: 0, iconBg: C.white };
    optState(optEls.A, { ...neutral, collapse: col });
    optState(optEls.D, { ...neutral, collapse: col });
    optState(optEls.C, {
      border: wrong > 0 ? mix(C.ink, C.red, wrong) : mix(C.line, C.ink, sel),
      bg: wrong > 0 ? rgba(C.red, 0.08 * wrong) : mix(C.white, '#F6F7FA', sel),
      letterBg: mix(C.light, C.red, wrong), letterFg: mix(C.dim, C.white, wrong),
      icon: kC, iconBg: C.red, shake,
    });
    optState(optEls.B, {
      border: mix(C.line, C.green, right), bg: rgba(C.green, 0.1 * right),
      letterBg: mix(C.light, C.green, right), letterFg: mix(C.dim, C.white, right),
      icon: kB, iconBg: C.green, scale: 1 + 0.035 * Math.sin(Math.PI * P(t, T.rightB, T.rightB + 0.34)),
    });

    // apparition échelonnée du contenu
    const parts = [$('#pTest .row.head'), $('#pTest .prog'), $('#pTest .qmeta'), $('#question'), optEls.A, optEls.B, optEls.C, optEls.D];
    parts.forEach((el, i) => {
      const t0 = T.cardIn + 0.2 + i * 0.045;
      const pe = P(t, t0, t0 + 0.45, E.outCubic);
      const sh = parseFloat(el.dataset.shake || 0);
      const sc = parseFloat(el.dataset.scale || 1);
      const colp = parseFloat(el.dataset.collapse || 0);
      el.style.opacity = (pe * (1 - clamp(colp * 1.5))).toFixed(3);
      el.style.transform = `translate(${sh.toFixed(2)}px, ${((1 - pe) * 28).toFixed(2)}px) scale(${sc.toFixed(4)})`;
    });
    $('#progFill').style.width = `${lerp(0, 56, P(t, T.cardIn + 0.45, T.cardIn + 1.2, E.outCubic)).toFixed(2)}%`;

    // chrono : défile en accéléré (un tick par croche)
    const ticks = t < T.timer0 ? 0 : Math.floor((t - T.timer0) / 0.25) + 1;
    setTimer(4187 - ticks);
    $('#pTest .rec').style.opacity = (0.35 + 0.65 * (0.5 + 0.5 * Math.cos(t * Math.PI * 2))).toFixed(3);

    // réponse qui vient remplir le blanc
    const bf = P(t, T.rightB + 0.06, T.rightB + 0.4, E.outCubic);
    const blank = $('#blankFill');
    blank.style.opacity = bf.toFixed(3);
    blank.style.transform = `translate(0, ${((1 - bf) * 26).toFixed(2)}px)`;

    // explication
    const ex = $('#explain');
    const pe = P(t, T.explain + 0.06, T.explain + 0.48, E.inOutCubic);
    ex.style.height = `${(L.explainH * pe).toFixed(2)}px`;
    ex.style.opacity = clamp(pe * 1.8).toFixed(3);
    ex.style.borderWidth = `${(2 * clamp(pe * 4)).toFixed(2)}px`;
  }

  function panelStats(t) {
    const p = $('#pStats');
    const pin = P(t, T.statsSwap + 0.14, T.statsSwap + 0.5, E.outCubic);
    vis(p, pin > 0);
    if (pin <= 0) return;
    css(p, { y: (1 - pin) * 34, o: pin });
    rows.forEach((r, i) => {
      const t0 = T.bars + i * 0.07;
      const pf = P(t, t0, t0 + 0.62, E.outCubic);
      r.fill.style.width = `${(r.v * pf).toFixed(2)}%`;
      r.val.innerHTML = `${Math.round(r.v * pf)}&nbsp;%`;
      r.val.style.color = C.ink;
    });
    const r7 = rows[6];
    const pw = P(t, T.weak, T.weak + 0.3, E.outCubic);
    r7.row.style.background = rgba(C.orange, 0.1 * pw);
    r7.fill.style.background = mix(C.read, C.orange, pw);
    r7.val.style.color = mix(C.ink, C.orange, pw);
    const k = t < T.weak + 0.06 ? 0 : spring(t - T.weak - 0.06, 2.4, 0.42);
    tip.style.opacity = clamp(k * 4).toFixed(3);
    tip.style.transform = `translate(${((1 - k) * -30).toFixed(2)}px, 0) scale(${k.toFixed(4)})`;
    tip.style.transformOrigin = '0% 50%';
  }

  function card(t) {
    const el = $('#card');
    const on = t > T.cardIn - 0.02 && t < T.cardOut + 0.5;
    vis(el, on);
    if (!on) return;
    const k = t < T.cardIn ? 0 : spring(t - T.cardIn, 1.65, 0.62);
    const out = P(t, T.cardOut, T.cardOut + 0.36, E.inCubic);
    css(el, { y: (1 - k) * 1300 + out * 260, r: (1 - k) * 8 + out * -4, s: 1 - out * 0.1, o: 1 - out });
    panelTest(t);
    panelStats(t);
    const hTest = $('#pTest').offsetHeight, hStats = $('#pStats').offsetHeight;
    const ph = P(t, T.statsSwap + 0.02, T.statsSwap + 0.44, E.inOutCubic);
    el.style.height = `${lerp(hTest, hStats, ph).toFixed(2)}px`;
  }

  // --- flashcards
  function deck(t) {
    const d = $('#deck'), toast = $('#toast');
    const on = t > T.deckIn - 0.02 && t < 12.45;
    vis(d, on);
    vis(toast, on && t > T.toast);
    if (!on) return;
    const base = [{ r: -7, x: -34, y: 34 }, { r: 5, x: 30, y: 16 }, { r: 0, x: 0, y: 0 }];
    const flip = P(t, T.flip, T.flip + 0.48, E.inOutCubic);
    ['#fcB2', '#fcB1', '#fcFront'].forEach((sel, i) => {
      const t0 = T.deckIn + i * 0.07;
      const k = t < t0 ? 0 : spring(t - t0, 1.8, 0.58);
      const b = base[i];
      const el = $(sel);
      el.style.opacity = clamp(k * 5).toFixed(3);
      let tr = `translate(${b.x.toFixed(1)}px, ${(b.y + (1 - k) * 1200).toFixed(2)}px) rotate(${(b.r + (1 - k) * (i - 1) * 14).toFixed(2)}deg)`;
      if (i === 2) {
        const lift = Math.sin(Math.PI * flip);
        const press = P(t, T.tapYes, T.tapYes + 0.08) * (1 - P(t, T.tapYes + 0.08, T.tapYes + 0.3, E.outCubic));
        tr += ` translate(0, ${(-lift * 40).toFixed(2)}px) rotateY(${(180 * flip).toFixed(2)}deg) scale(${(1 + 0.05 * lift - 0.015 * press).toFixed(4)})`;
      }
      el.style.transform = tr;
    });
    const press = P(t, T.tapYes, T.tapYes + 0.08) * (1 - P(t, T.tapYes + 0.1, T.tapYes + 0.34, E.outCubic));
    $('#btnYes').style.transform = `scale(${(1 - 0.07 * press).toFixed(4)})`;
    const kt = t < T.toast ? 0 : spring(t - T.toast, 2.2, 0.5);
    toast.style.opacity = clamp(kt * 4).toFixed(3);
    toast.style.transform = `translate(0, ${((1 - kt) * 40).toFixed(2)}px) scale(${(0.6 + 0.4 * kt).toFixed(4)})`;
  }

  // --- indicateurs de toucher
  function tapAnim(t, tapSel, ripSel, pos, t0) {
    const tap = $(tapSel), rip = $(ripSel);
    const on = t > t0 - 0.3 && t < t0 + 0.6;
    vis(tap, on); vis(rip, on);
    if (!on) return;
    const pin = P(t, t0 - 0.28, t0 - 0.02, E.outCubic);
    const pout = P(t, t0 + 0.2, t0 + 0.45, E.inCubic);
    const press = P(t, t0 - 0.02, t0 + 0.06) * (1 - P(t, t0 + 0.06, t0 + 0.2));
    Object.assign(tap.style, { left: `${pos.x}px`, top: `${pos.y}px` });
    css(tap, { x: (1 - pin) * 60, y: (1 - pin) * 90, s: (1.25 - 0.25 * pin) * (1 - 0.2 * press), o: pin * (1 - pout) });
    const pr = P(t, t0, t0 + 0.5, E.outCubic);
    Object.assign(rip.style, { left: `${pos.x}px`, top: `${pos.y}px` });
    css(rip, { s: 0.7 + 1.6 * pr, o: t < t0 ? 0 : 0.9 * (1 - pr) });
  }

  // --- mascottes
  const MASC = [
    { el: $('#mTests'), tin: 4.2, tout: 5.84 },
    { el: $('#mDrills'), tin: 6.14, tout: 7.84 },
    { el: $('#mVocab'), tin: 10.14, tout: 11.84 },
  ];
  function mascots(t) {
    MASC.forEach(({ el, tin, tout }) => {
      const on = t > tin && t < tout + 0.3;
      vis(el, on);
      if (!on) return;
      const k = spring(t - tin, 2.1, 0.4);
      const po = P(t, tout, tout + 0.28, E.inBack);
      const idle = Math.sin((t - tin) * Math.PI * 2 * 0.85) * 2.2;
      css(el, { y: (1 - k) * 180 + po * 260, s: (0.4 + 0.6 * k) * (1 - 0.35 * po), r: idle + (1 - k) * 12, o: clamp(k * 4) * (1 - po) });
    });
  }

  // --- transition anneau orange -> CTA
  function wipe(t) {
    const cx = 540, cy = 860, R = 2150;
    const po = P(t, T.wipe, T.wipe + 0.42, E.inOutCubic);
    const pi = P(t, T.wipe + 0.1, T.wipe + 0.52, E.inOutCubic);
    const w = $('#wipeO'), s7 = $('#s7');
    vis(w, po > 0 && pi < 1);
    if (po > 0 && pi < 1) circleMask(w, cx, cy, po * R);
    vis(s7, pi > 0);
    if (pi <= 0) return;
    if (pi >= 1) noMask(s7); else circleMask(s7, cx, cy, pi * R);
  }

  // --- CTA
  function scene7(t) {
    if (t < T.wipe) return;
    const k = t < T.hero ? 0 : spring(t - T.hero, 1.2, 0.6);
    const fl = P(t, T.hero + 0.5, T.hero + 1.3, E.inOutQuad);
    const fy = Math.sin((t - T.hero) * Math.PI * 2 * 0.55) * 12 * fl;
    const fr = Math.sin((t - T.hero) * Math.PI * 2 * 0.4 + 1) * 1.6 * fl;
    css($('#hero'), { x: lerp(-780, 0, k), y: lerp(860, 0, k) + fy, r: lerp(-20, 0, k) + fr, s: lerp(0.55, 1, k), o: clamp((t - T.hero) * 5) });

    ctaLetters.forEach((l, i) => {
      const t0 = T.wm7 + i * 0.035;
      const p = P(t, t0, t0 + 0.55, E.outQuint);
      l.style.transform = `translate(0, ${((1 - p) * 90).toFixed(2)}px)`;
      l.style.opacity = clamp(p * 1.6).toFixed(3);
    });
    const fade = (sel, t0, dy = 34) => {
      const p = P(t, t0, t0 + 0.45, E.outCubic);
      css($(sel), { y: (1 - p) * dy, o: p });
    };
    fade('#ctaProof', T.proof);
    fade('#ctaUrl', T.url);
    fade('#legal', T.legal, 16);

    const kb = t < T.btn ? 0 : spring(t - T.btn, 2.3, 0.42);
    const pulse = Math.sin(Math.PI * P(t, T.pulse, T.pulse + 0.3)) * 0.045;
    const press = P(t, T.tap7 - 0.02, T.tap7 + 0.06) * (1 - P(t, T.tap7 + 0.06, T.tap7 + 0.22));
    css($('#ctaBtn'), { s: (0.5 + 0.5 * kb) * (1 + pulse - 0.04 * press), o: clamp(kb * 5) });
    const arrow = $('#ctaBtn svg');
    arrow.style.transform = `translate(${(Math.max(0, Math.sin((t - T.btn) * Math.PI * 2 * 1.0)) * 10 * P(t, T.btn + 0.4, T.btn + 0.6)).toFixed(2)}px, 0)`;
    const sh = P(t, T.shine, T.shine + 0.55, E.inOutQuad);
    $('#ctaBtn .shine').style.transform = `translateX(${lerp(-220, 1000, sh).toFixed(1)}px) skewX(-20deg)`;

    sparks.forEach((s) => {
      const age = t - T.hero;
      const a = clamp(age * 2) * s.a * (0.55 + 0.45 * Math.sin(t * 3 + s.ph));
      s.el.style.opacity = a.toFixed(3);
      s.el.style.transform = `translate(${(s.x + Math.sin(t * 0.8 + s.ph) * 14).toFixed(1)}px, ${(s.y - age * s.sp).toFixed(1)}px)`;
    });
  }

  function renderAt(t) {
    t = clamp(t, 0, DURATION);
    scene1(t);
    lens(t);
    worldBg(t);
    scene2(t);
    titles(t);
    card(t);
    deck(t);
    mascots(t);
    tapAnim(t, '#tap1', '#rip1', L.tap1, T.tapC);
    tapAnim(t, '#tap2', '#rip2', L.tap2, T.tapYes);
    wipe(t);
    scene7(t);
    tapAnim(t, '#tap3', '#rip3', L.tap3, T.tap7);
  }

  window.DURATION = DURATION;
  window.renderAt = renderAt;
  window.ready = (async () => {
    await Promise.all(['400', '500', '600', '700', '800'].map((w) => document.fonts.load(`${w} 40px Outfit`)));
    await document.fonts.ready;
    await Promise.all($$('img').map((img) => (img.complete ? img.decode() : new Promise((r) => { img.onload = r; })).catch(() => {})));
    layout();
    const q = new URLSearchParams(location.search).get('t');
    renderAt(q ? parseFloat(q) : 0);
    return true;
  })();
})();
