# 990prep · motion design 9:16

Vidéo promotionnelle verticale (TikTok, Reels, Shorts) pour [990prep.com/fr](https://990prep.com/fr) :
15 secondes, les fonctionnalités phares, un appel à l'action final.

## Livrables (`out/`)

| Fichier | Contenu |
| --- | --- |
| `990prep-motion-9x16.mp4` | 1080 × 1920, 15 s, 60 i/s, H.264 + AAC, -13,4 LUFS |
| `990prep-motion-9x16-sans-son.mp4` | même vidéo sans son, pour poser un son tendance dans TikTok |
| `990prep-bande-son.m4a` | bande son seule (musique + bruitages) |
| `cover-accroche.png`, `cover-marque.png` | couvertures 1080 × 1920 |

## Storyboard (120 BPM, une scène par mesure)

| Temps | Scène | Texte à l'écran |
| --- | --- | --- |
| 0 à 2 s | Accroche sur fond encre. Les lunettes du renard apparaissent, la caméra plonge à travers le verre | Tu révises le TOEIC® à l'aveugle ? |
| 2 à 4 s | Lockup vertical (mascotte + wordmark), reflet sur les lunettes | 990prep te montre où tu perds des points. |
| 4 à 6 s | Test blanc : chrono, Reading · Partie 5, question 112 / 200 | Des tests blancs en conditions réelles |
| 6 à 8 s | Correction : mauvaise réponse, bonne réponse, explication | Chaque erreur, expliquée. |
| 8 à 10 s | Score par partie, la Partie 7 ressort en « Point faible » | Tes points faibles, partie par partie. |
| 10 à 12 s | Flashcard retournée, « Je savais », prochaine révision dans 4 jours | Plus de 1 800 mots en répétition espacée. |
| 12 à 15 s | Appel à l'action : renard jetpack, wordmark, bouton | Rejoins plus de 7 700 étudiants · Commence gratuitement · 990prep.com/fr |

## Charte appliquée

- **Couleurs** : encre `#0F172B`, orange accent `#F97415` (le « 0 » du wordmark), bleu `#1565C0`,
  vert succès `#43A047`, Listening `#2979FF`, Reading `#2E7D32`, fond clair `#F3F5F8`.
- **Typographie** : Outfit (licence OFL, `assets/fonts/`). Le wordmark est reconstruit à l'identique
  (Outfit 700, approche -0,025 em, « 0 » orange) ; variante fond sombre en `#E5E5E5`.
- **Logo** : lockup vertical aux proportions du kit (mascotte = 3,1 × hauteur des capitales, écart = 0,55 ×),
  zone de protection d'une hauteur de « 9 » respectée autour du wordmark.
- **Mascotte et illustrations** : images publiques du site (`assets/img/`).
- **Rédaction** : tutoiement, pas de tiret cadratin, aucune promesse de score, uniquement des chiffres
  publics autorisés (« plus de 7 700 étudiants », « plus de 1 800 mots »), mention ETS, lien vers `/fr`.
- **Format court** : accroche dans les 2 premières secondes sans logo, appel à l'action non agressif
  (« gratuit pour commencer »).

Les écrans produit sont des maquettes animées inspirées de l'interface réelle ; les valeurs affichées
(chrono, pourcentages) sont illustratives.

## Regénérer

Prérequis : Node 18+ avec Playwright (Chromium), Python 3 avec numpy et scipy, ffmpeg.

```bash
npm install                                    # Playwright (navigateur déjà installé dans l'environnement)
pip install -r requirements.txt
python3 scripts/audio.py out/audio.wav         # bande son synthétisée (libre de droits)
node scripts/render.mjs --audio out/audio.wav  # vidéo finale -> out/990prep-motion-9x16.mp4
node scripts/render.mjs --frames 1.3,6.8,14.9  # captures ponctuelles -> out/preview/
```

Le binaire ffmpeg se choisit avec la variable `FFMPEG`. Options du rendu : `--fps` (60), `--crf` (16),
`--workers` (navigateurs en parallèle), `--out`.

Pour un aperçu dans le navigateur, servir ce dossier et ouvrir `src/index.html?t=6.8`.

## Structure

- `src/index.html`, `src/style.css` : scènes et composants (UI produit, flashcards, CTA).
- `src/anim.js` : moteur d'animation déterministe, `window.renderAt(t)` pose chaque image en fonction du temps.
- `scripts/render.mjs` : capture image par image dans Chromium headless, encodage H.264 avec ffmpeg.
- `scripts/audio.py` : musique (fa majeur, 120 BPM) et bruitages calés sur les repères de l'animation.
