#!/usr/bin/env python3
"""Bande son du motion design 990prep : 15 s, 120 BPM, en fa majeur.

Musique et bruitages sont entièrement synthétisés (numpy/scipy), sans aucun
échantillon externe : la bande son est donc libre de droits.
Les repères temporels suivent ceux de src/anim.js (objet T).

    python3 scripts/audio.py out/audio.wav
"""
import math
import sys

import numpy as np
from scipy import signal
from scipy.io import wavfile

SR = 48000
DUR = 15.0
N = int(SR * DUR)
BEAT = 0.5  # 120 BPM
rng = np.random.default_rng(990)


# ------------------------------------------------------------------ outils
def tt(d):
    return np.arange(int(round(d * SR))) / SR


def midi(n):
    return 440.0 * 2 ** ((n - 69) / 12)


def _sos(kind, f, order=2):
    return signal.butter(order, f, btype=kind, fs=SR, output='sos')


def lp(x, f, order=2):
    return signal.sosfilt(_sos('lowpass', f, order), x)


def hp(x, f, order=2):
    return signal.sosfilt(_sos('highpass', f, order), x)


def bp(x, f1, f2, order=2):
    return signal.sosfilt(_sos('bandpass', [f1, f2], order), x)


def svf(x, fc, damp=0.7, mode='bp'):
    """Filtre d'état variable (Chamberlin) à fréquence de coupure variable."""
    fc = np.broadcast_to(np.asarray(fc, dtype=float), x.shape)
    f = (2 * np.sin(np.pi * np.minimum(fc, SR / 6.5) / SR)).tolist()
    xs = x.tolist()
    lo = ba = 0.0
    out = [0.0] * len(xs)
    for i, v in enumerate(xs):
        hi = v - lo - damp * ba
        ba += f[i] * hi
        lo += f[i] * ba
        out[i] = ba if mode == 'bp' else (lo if mode == 'lp' else hi)
    return np.array(out)


def pad_to(x, n):
    return np.concatenate([x, np.zeros(max(0, n - len(x)))])[:n]


def noise(n):
    return rng.standard_normal(n)


class Bus:
    def __init__(self):
        self.l = np.zeros(N)
        self.r = np.zeros(N)

    def add(self, x, t0, gain=1.0, pan=0.0):
        x = np.asarray(x, dtype=float)
        xl, xr = (x[0], x[1]) if x.ndim == 2 else (x, x)
        i0 = int(round(t0 * SR))
        if i0 < 0:
            xl, xr, i0 = xl[-i0:], xr[-i0:], 0
        n = min(len(xl), N - i0)
        if n <= 0:
            return
        a = (pan + 1) * np.pi / 4
        self.l[i0:i0 + n] += xl[:n] * gain * np.cos(a) * math.sqrt(2)
        self.r[i0:i0 + n] += xr[:n] * gain * np.sin(a) * math.sqrt(2)

    def stereo(self):
        return np.stack([self.l, self.r])


# ------------------------------------------------------------ instruments
def kick(f0=165, f1=46, dur=0.55, decay=0.3):
    t = tt(dur)
    f = f1 + (f0 - f1) * np.exp(-t / 0.038)
    body = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / decay)
    click = hp(noise(len(t)), 2500) * np.exp(-t / 0.003) * 0.3
    x = (body + click) * np.clip(t / 0.0015, 0, 1)
    return np.tanh(1.5 * x)


def clap():
    t = tt(0.45)
    n = bp(noise(len(t)), 900, 3800)
    e = np.zeros(len(t))
    for off in (0.0, 0.011, 0.023):
        e += np.exp(-np.clip(t - off, 0, None) / 0.006) * (t >= off)
    e += 0.55 * np.exp(-np.clip(t - 0.03, 0, None) / 0.12) * (t >= 0.03)
    return n * e * 0.55


def hat(decay=0.035):
    t = tt(decay * 6)
    return hp(noise(len(t)), 7500, 2) * np.exp(-t / decay) * 0.4


def crash():
    t = tt(2.2)
    x = hp(noise(len(t)), 4000, 2) * np.exp(-t / 0.6) * 0.5
    return np.stack([x, hp(noise(len(t)), 4000, 2) * np.exp(-t / 0.6) * 0.5])


def saw(freq, t, parts=14, phase=0.0):
    kmax = max(1, min(parts, int(9000 / freq)))
    return sum(np.sin(2 * np.pi * freq * k * t + phase * k) / k for k in range(1, kmax + 1)) * (2 / np.pi)


def bass(freq, dur):
    t = tt(dur)
    x = 0.55 * saw(freq, t, 12) + 0.9 * np.sin(2 * np.pi * freq * t)
    x = lp(x, 520, 2)
    e = np.clip(t / 0.004, 0, 1) * np.exp(-t / 0.26) * np.clip((dur - t) / 0.012, 0, 1)
    return np.tanh(1.3 * x * e)


def pluck(freq, dur=0.55, bright=2.4, decay=0.2):
    t = tt(dur)
    idx = bright * np.exp(-t / 0.055)
    x = np.sin(2 * np.pi * freq * t + idx * np.sin(2 * np.pi * freq * 2.0 * t))
    x += 0.22 * np.sin(2 * np.pi * freq * 4.0 * t) * np.exp(-t / 0.04)
    return x * np.clip(t / 0.002, 0, 1) * np.exp(-t / decay)


def bell(freq, dur=1.3, decay=0.5):
    t = tt(dur)
    idx = 2.6 * np.exp(-t / 0.22)
    x = np.sin(2 * np.pi * freq * t + idx * np.sin(2 * np.pi * freq * 3.5 * t))
    x += 0.3 * np.sin(2 * np.pi * freq * 2.0 * t) * np.exp(-t / 0.3)
    return x * np.clip(t / 0.002, 0, 1) * np.exp(-t / decay)


def pad(notes, dur, cutoff=1500, attack=0.3, release=0.35):
    t = tt(dur + release)
    chans = []
    for _ in range(2):
        x = np.zeros(len(t))
        for n in notes:
            for det in (-0.09, 0.0, 0.09):
                x += saw(midi(n) * 2 ** (det / 12), t, 12, rng.uniform(0, 6.28))
        x = lp(x, cutoff, 2) / (len(notes) * 3)
        e = np.clip(t / attack, 0, 1) * np.clip((dur + release - t) / release, 0, 1)
        chans.append(x * e)
    return np.stack(chans)


# --------------------------------------------------------------- bruitages
def riser(dur, f0=250, f1=7000):
    t = tt(dur)
    p = t / dur
    x = svf(noise(len(t)), f0 * (f1 / f0) ** (p ** 1.6), damp=0.5) * 0.45
    tone = np.sin(2 * np.pi * np.cumsum(180 * 4 ** p) / SR) * 0.12
    return (x + tone) * p ** 1.3


def whoosh(dur=0.5, f0=350, f1=3200, peak=0.55, pan=(-0.6, 0.6)):
    t = tt(dur)
    p = t / dur
    x = svf(noise(len(t)), f0 * (f1 / f0) ** p, damp=0.55)
    e = np.where(p < peak, (p / peak) ** 2, np.exp(-(p - peak) / (1 - peak) * 4))
    x = x * e
    a = (np.interp(p, [0, 1], pan) + 1) * np.pi / 4
    return np.stack([x * np.cos(a), x * np.sin(a)]) * math.sqrt(2)


def impact():
    t = tt(1.8)
    boom = np.sin(2 * np.pi * np.cumsum(36 + 70 * np.exp(-t / 0.07)) / SR) * np.exp(-t / 0.55)
    dust = lp(noise(len(t)), 1600) * np.exp(-t / 0.22) * 0.35
    k = pad_to(kick(), len(t))
    return np.tanh((boom * 0.9 + dust + k * 0.7) * 1.2)


def pop(f0=240, f1=1150, dur=0.14):
    t = tt(dur)
    f = f0 + (f1 - f0) * (1 - np.exp(-t / 0.022))
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / 0.038) * np.clip(t / 0.002, 0, 1)


def click():
    t = tt(0.06)
    n = bp(noise(len(t)), 1800, 7000) * np.exp(-t / 0.004)
    s = np.sin(2 * np.pi * 1500 * t) * np.exp(-t / 0.011) * 0.5
    return n * 0.7 + s


def tick(f=3300):
    t = tt(0.03)
    return np.sin(2 * np.pi * f * t) * np.exp(-t / 0.0035)


def bonk():
    out = np.zeros(int(0.4 * SR))
    for n, off in ((64, 0.0), (59, 0.09)):
        t = tt(0.24)
        f = midi(n)
        x = signal.square(2 * np.pi * f * t) * 0.35 + np.sin(2 * np.pi * f * t)
        x = lp(x, 1300) * np.exp(-t / 0.07) * np.clip(t / 0.003, 0, 1)
        i0 = int(off * SR)
        out[i0:i0 + len(x)] += x[:len(out) - i0]
    return out


def ding():
    out = np.zeros(int(1.3 * SR))
    for n, off, g in ((84, 0.0, 0.75), (91, 0.085, 1.0)):
        b = bell(midi(n), 1.1, 0.42) * g
        i0 = int(off * SR)
        out[i0:i0 + len(b)] += b[:len(out) - i0]
    return out


def sparkle(dur=0.8, count=10, fmin=2600, fmax=7800):
    out = np.zeros(int(dur * SR))
    for _ in range(count):
        f, off = rng.uniform(fmin, fmax), rng.uniform(0, dur * 0.5)
        t = tt(0.3)
        x = np.sin(2 * np.pi * f * t) * np.exp(-t / 0.07) * np.clip(t / 0.001, 0, 1)
        i0 = int(off * SR)
        m = min(len(x), len(out) - i0)
        out[i0:i0 + m] += x[:m] * rng.uniform(0.4, 1.0)
    return out / math.sqrt(count)


def flip():
    t = tt(0.2)
    x = svf(noise(len(t)), 5200 * np.exp(-t / 0.05) + 500, damp=0.4)
    return x * np.clip(t / 0.008, 0, 1) * np.exp(-t / 0.055)


def blip(freq):
    t = tt(0.14)
    x = np.sin(2 * np.pi * freq * t) + 0.3 * np.sin(2 * np.pi * freq * 2 * t)
    return x * np.exp(-t / 0.045) * np.clip(t / 0.002, 0, 1)


def shing():
    t = tt(0.7)
    p = t / 0.7
    x = svf(noise(len(t)), 2500 + 9000 * p, damp=0.35) * np.sin(np.pi * np.clip(p * 1.6, 0, 1)) ** 2 * 0.5
    return x + sparkle(0.7, 8, 4000, 9000) * 0.8


def jet(dur=1.1):
    t = tt(dur)
    p = t / dur
    rumble = lp(noise(len(t)), 900) * 0.8 + bp(noise(len(t)), 1500, 5000) * 0.25
    e = np.clip(p / 0.12, 0, 1) * np.exp(-np.clip(p - 0.3, 0, None) * 3.5)
    x = rumble * e
    a = (np.interp(p, [0, 1], [-0.8, 0.5]) + 1) * np.pi / 4
    return np.stack([x * np.cos(a), x * np.sin(a)]) * math.sqrt(2)


def reverb(x, rt=1.35, pre=0.018, wet=1.0):
    n = int((rt * 1.1 + pre) * SR)
    t = np.arange(n) / SR
    out = []
    for ch in range(2):
        ir = noise(n) * np.exp(-6.9 * t / rt)
        ir = lp(ir, 5500)
        ir[: int(pre * SR)] = 0
        ir /= np.sqrt(np.sum(ir ** 2))
        out.append(signal.fftconvolve(x[ch], ir)[:N] * wet)
    return np.stack(out)


# ------------------------------------------------------------------ musique
music, keys, drums, sfx, verb = Bus(), Bus(), Bus(), Bus(), Bus()

# Grille harmonique : une mesure (2 s) par scène
CHORDS = [  # (début, fin, basse, accord du pad, notes de l'arpège)
    (0.0, 2.0, 38, [50, 53, 57], [74, 77, 81, 84]),         # Rém   accroche
    (2.0, 4.0, 41, [53, 57, 60], [77, 81, 84, 81]),         # Fa    révélation
    (4.0, 6.0, 36, [52, 55, 60], [76, 79, 84, 79]),         # Do    tests blancs
    (6.0, 8.0, 38, [50, 53, 57], [74, 77, 81, 77]),         # Rém   correction
    (8.0, 10.0, 34, [50, 53, 58], [74, 77, 82, 77]),        # Sib   statistiques
    (10.0, 11.0, 43, [50, 53, 58, 62], [74, 77, 79, 82]),   # Solm7 vocabulaire
    (11.0, 12.0, 36, [52, 55, 60], [76, 79, 84, 88]),       # Do    montée
    (12.0, 14.0, 41, [53, 57, 60, 64], [77, 81, 84, 88]),   # Fa7M  appel à l'action
    (14.0, 15.0, 41, [53, 57, 60, 65], [77, 81, 84, 89]),   # Fa    fin
]

GROOVE = lambda b: (2.0 <= b < 11.5) or (12.0 <= b < 14.0)

# Pad (discret pendant l'accroche, plein ensuite)
for t0, t1, _, notes, _ in CHORDS:
    g = 0.2 if t0 < 2 else 0.24
    cut = 900 if t0 < 2 else (1900 if t0 >= 12 else 1500)
    keys.add(pad(notes, t1 - t0, cutoff=cut, attack=0.5 if t0 < 2 else 0.12), t0, g)

# Basse en croches
for t0, t1, root, _, _ in CHORDS:
    if t0 < 2.0:
        continue
    b = t0
    while b < t1 - 1e-6:
        if GROOVE(b) or t0 >= 14.0 or (11.5 <= b < 11.75):
            dur = 0.24 if t0 < 14.0 else 0.9
            keys.add(bass(midi(root + (12 if (round(b / 0.25) % 4 == 3) else 0)), dur), b, 0.5)
            if t0 >= 14.0:
                break
        b += 0.25

# Arpège en doubles croches (discret)
for t0, t1, _, _, arp in CHORDS:
    if t0 < 2.0 or t0 >= 14.0:
        continue
    i = 0
    b = t0
    while b < t1 - 1e-6 and b < 11.84:
        acc = 1.0 if i % 4 == 0 else 0.7
        keys.add(pluck(midi(arp[i % len(arp)]), 0.4, bright=1.8, decay=0.12), b, 0.1 * acc, pan=-0.35 if i % 2 else 0.35)
        i += 1
        b += 0.125

# Batterie
for i in range(30):
    b = i * BEAT
    if GROOVE(b) or b == 14.0:
        drums.add(kick(), b, 0.95)
    if GROOVE(b) and (b % 2.0) in (0.5, 1.5):
        drums.add(clap(), b, 0.42)
    if GROOVE(b):
        drums.add(hat(0.18 if b >= 12.0 else 0.035), b + 0.25, 0.22 if b >= 12.0 else 0.2, pan=0.25)
        drums.add(hat(0.025), b + 0.125, 0.07, pan=-0.3)
        drums.add(hat(0.025), b + 0.375, 0.07, pan=-0.3)
# roulement de caisse claire avant le CTA
for k, b in enumerate(np.arange(11.5, 11.84, 0.0625)):
    drums.add(clap(), b, 0.24 + 0.07 * k)

# Pompage (sidechain) de la musique sur la grosse caisse
t_all = np.arange(N) / SR
duck = np.ones(N)
for i in range(30):
    b = i * BEAT
    if GROOVE(b) or b == 14.0:
        m = t_all >= b
        duck[m] = np.minimum(duck[m], 1 - 0.5 * np.exp(-(t_all[m] - b) / 0.11))
keys.l *= duck
keys.r *= duck

# ------------------------------------------------------------------ accroche
# Chaque mot de l'accroche déclenche une note : l'arpège monte avec la phrase
HOOK_HITS = [0.0, 0.125, 0.375, 0.5, 0.75, 0.875, 1.125]
HOOK_NOTES = [74, 77, 81, 84, 86, 89, 93]
for b, n in zip(HOOK_HITS, HOOK_NOTES):
    verb.add(pluck(midi(n), 0.7, bright=2.6, decay=0.26), b, 0.42, pan=0.0)
    sfx.add(click(), b, 0.08)
sfx.add(pop(300, 1300), 1.125, 0.25)                                    # "?" qui rebondit

# ------------------------------------------------------------------ bruitages
sfx.add(pop(200, 900, 0.16), 1.46, 0.45)                                # lunettes
sfx.add(riser(0.6, 300, 8000), 1.44, 0.75)                              # plongée
swell = hp(noise(int(0.5 * SR)), 3000, 2) * np.linspace(0, 1, int(0.5 * SR)) ** 2 * 0.35
sfx.add(swell, 1.5, 0.8)
sfx.add(whoosh(0.5, 300, 4200, 0.8, (0.4, 0.0)), 1.62, 0.55)
sfx.add(impact(), 2.0, 0.85)                                            # drop
sfx.add(pop(260, 1200), 2.02, 0.35)                                     # renard
verb.add(sparkle(0.9, 12), 2.64, 0.5)                                   # reflet des lunettes
sfx.add(whoosh(0.4, 400, 2600, 0.7, (0.3, -0.3)), 3.62, 0.42)           # carte
sfx.add(pop(), 4.2, 0.35)                                               # mascotte tests
for k in range(int((5.86 - 4.3) / 0.25) + 1):                           # chrono
    sfx.add(tick(3300 if k % 2 else 2700), 4.3 + k * 0.25, 0.07)
sfx.add(pop(220, 1000), 6.14, 0.3)                                      # mascotte exercices
sfx.add(click(), 6.06, 0.5)                                             # toucher
sfx.add(bonk(), 6.28, 0.32)                                             # mauvaise réponse
verb.add(ding(), 6.52, 0.42)                                            # bonne réponse
sfx.add(whoosh(0.35, 600, 3000, 0.5, (-0.2, 0.2)), 6.76, 0.22)          # explication
sfx.add(whoosh(0.35, 500, 2800, 0.6, (0.3, -0.3)), 7.8, 0.3)            # stats
for i, n in enumerate([72, 74, 76, 77, 79, 81, 83]):                    # barres
    verb.add(blip(midi(n + 12)), 8.24 + i * 0.07, 0.16)
verb.add(pluck(midi(79), 0.8, 3.0, 0.3), 9.06, 0.3)                     # point faible
sfx.add(pop(180, 700, 0.18), 9.06, 0.3)
sfx.add(whoosh(0.4, 700, 2400, 0.5, (0.0, 0.5)), 9.8, 0.3)              # carte qui sort
sfx.add(whoosh(0.35, 400, 2600, 0.6, (-0.5, 0.0)), 9.92, 0.3)           # cartes qui entrent
sfx.add(pop(240, 1100), 10.14, 0.3)                                     # mascotte vocabulaire
sfx.add(flip(), 10.52, 0.55)                                            # carte retournée
sfx.add(click(), 11.08, 0.5)                                            # toucher "Je savais"
verb.add(blip(midi(88)), 11.1, 0.2)
verb.add(blip(midi(95)), 11.17, 0.18)
sfx.add(pop(300, 1300), 11.24, 0.3)                                     # toast
sfx.add(riser(0.84, 250, 7500), 11.0, 0.7)                              # montée
sfx.add(whoosh(0.55, 250, 3800, 0.45, (-0.6, 0.6)), 11.7, 0.55)         # anneau orange
sfx.add(impact(), 12.0, 0.9)
drums.add(crash(), 12.0, 0.35)
sfx.add(jet(1.2), 12.08, 0.5)                                           # renard jetpack
verb.add(sparkle(0.9, 12, 3000, 8000), 12.42, 0.45)                     # wordmark
sfx.add(pop(220, 900, 0.16), 12.96, 0.4)                                # bouton
verb.add(shing(), 13.68, 0.35)                                          # reflet du bouton
sfx.add(click(), 14.16, 0.5)                                            # toucher final
# accord final (fa majeur, arpégé)
for k, n in enumerate([65, 69, 72, 77, 81]):
    verb.add(bell(midi(n), 1.2, 0.55), 14.0 + k * 0.035, 0.18)
drums.add(crash(), 14.0, 0.25)

# ------------------------------------------------------------------- mixage
dry = keys.stereo() * 0.9 + drums.stereo() * 1.0 + sfx.stereo() * 1.0 + verb.stereo()
wet = reverb(verb.stereo() + keys.stereo() * 0.25 + sfx.stereo() * 0.15, rt=1.4) * 0.28
mix = dry + wet
mix = hp(mix[0], 30, 2), hp(mix[1], 30, 2)
mix = np.stack(mix)

# fondu final et léger fondu d'entrée (anti-clic)
fade = np.clip((DUR - t_all) / 0.4, 0, 1) ** 1.5
mix *= fade * np.clip(t_all / 0.004, 0, 1)

# limiteur doux puis normalisation à -1 dBFS
peak = np.max(np.abs(mix))
mix = mix / peak * 1.6
mix = np.tanh(mix) / np.tanh(1.6)
mix *= 10 ** (-1 / 20) / np.max(np.abs(mix))
rms = 20 * np.log10(np.sqrt(np.mean(mix ** 2)))

out = sys.argv[1] if len(sys.argv) > 1 else 'out/audio.wav'
wavfile.write(out, SR, (mix.T * 32767).astype(np.int16))
print(f'{out} : {DUR:.1f} s, crête -1 dBFS, RMS {rms:.1f} dBFS')
