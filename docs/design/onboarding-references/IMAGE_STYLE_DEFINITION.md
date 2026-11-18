# Tack Onboarding — Reference Image Style Definition & Screen Blueprint

> **Folder location:** `docs/design/onboarding-references/`  
> **App:** Tack (Android Flutter — local-first notes, sticky notes, whiteboards, tasks & clipboard)  
> **Alignment:** Strictly extends [`lib/core/theme/app_colors.dart`](../../../lib/core/theme/app_colors.dart), [`docs/design/07-design-system.md`](../07-design-system.md), [`docs/design/11-reference-ui-style.md`](../11-reference-ui-style.md), and the Locked Product Decisions in [`AGENTS.md`](../../../AGENTS.md).

---

## 1. Reference Asset Inventory

| # | Stored File | Original Upload | Visual Genre | Primary Role in Tack Onboarding |
|---|---|---|---|---|
| 01 | [`01-floating-cloud-meadows.jpg`](./01-floating-cloud-meadows.jpg) | `media_1794982719919_f5c47975.jpg` | Weightless surreal sky diorama (clouds + miniature flower meadows + butterflies) | **"Floating Thought Space"** metaphor — weightless spatial ideas (notes, stickies, boards) drifting clearly in open mental space without clutter |
| 02 | [`02-soft-lavender-narrative-panels.jpg`](./02-soft-lavender-narrative-panels.jpg) | `media_1794982723416_26755876.jpg` | Lineless airbrushed editorial narrative panels (2×3 rounded cards, lavender-blush glow) | **Onboarding Slide Rhythm & Emotional Restraint** — calm human warmth, rounded frame geometry, gentle radial illumination, translucent frosted focal pills |
| 03 | [`03-clear-horizon-meadow-ocean.jpg`](./03-clear-horizon-meadow-ocean.jpg) | `media_1794982726527_0405ccf4.jpg` | Crisp 3-band sunlit daylight horizon (meadow / calm ocean / cumulus sky) | **"Local-First Clarity & Fresh Start"** backdrop — expansive uncluttered sky headroom for clean display typography and serene pacing |
| 04 | [`04-soft-3d-clay-icons.png`](./04-soft-3d-clay-icons.png) | `media_1794982730560_e1d9af2e.png` | Plush matte 3D clay micro-objects isolated on `#FFFFFF` with soft contact shadows | **Core Tack Object Props** — inviting tactile tokens representing chat/quick capture bubble, reminder bell, archive/clipboard parcel, and whiteboard pointer |
| 05 | [`05-diecut-sticker-icons-paper-grid.jpg`](./05-diecut-sticker-icons-paper-grid.jpg) | `media_1794982733717_b84ec5fd.jpg` | Die-cut white-bordered paper stickers on warm cream dot-grid notebook paper | **Signature Tack Brand DNA ("Paper & Pin")** — physical sticky-note & sticker cutout feel connecting directly to Tack's grid cards, stickers, and flow nodes |
| 06 | [`06-risograph-grain-botanicals-dark.jpg`](./06-risograph-grain-botanicals-dark.jpg) | `media_1794982738130_69498b6a.jpg` | Geometric botanical shapes with fine stippled risograph grain on deep navy `#1E2740` | **Dark Mode Calibration & Knowledge Growth** — proves how dark-mode onboarding keeps organic print warmth, saturated pastel glow, and sharp geometric silhouettes |

---

## 2. How These 6 References Synthesize into Tack's Onboarding Screen

Individually, the 6 references span 3D sky landscapes, matte clay icons, paper die-cut stickers, soft vector storytelling, and dark risograph florals. Used raw without a unifying rule, mixing them would feel like a collage. Used intentionally as an art-direction system for **Tack**, each image owns a specific layer of the screen:

1. **The Canvas & Stage (`05` + `02` + `11-reference-ui-style.md`)**  
   - **Light Mode:** Onboarding sits on Tack's neutral light canvas (`AppColors.lightCanvas` `#F3F4F6`) with a **rounded squircle hero stage card** (`24–28dp` corner radius, `0.60` corner smoothing). Inside the hero card, alternate calmly between warm dot-grid paper (`#F5F3EA` from `05`) for tactile feature slides and airy sky/lavender washes (`01`, `02`, `03`) for atmospheric/privacy slides.
   - **Dark Mode:** Screen canvas drops to carbon (`AppColors.darkCanvas` `#0F1012`) and hero artwork sits inside deep elevated slate-indigo (`#18191C`–`#1E2740` inspired by `06`), keeping dark mode warm and editorial rather than inverted neon.
2. **Hero Objects & Tactile Affordance (`04` + `05`)**  
   - Tack is literally built around desktop sticky notes and paper cards reimagined for mobile. Every object depicted in the onboarding hero should feel **pinnable, tactile, and light**: either a **plush matte 3D clay object (`04`)** (speech bubble, bell, clipboard parcel, whiteboard cursor) or a **die-cut white-bordered paper sticker (`05`)** floating gently above a subtle dotted surface with diffused soft shadows.
3. **Atmospheric Calm & Headroom (`01` + `03`)**  
   - Productivity onboarding frequently feels stressful or overcrowded. `01` and `03` establish **mental breathing room**: layered floating cloud-meadow islands and crisp horizontal bands teach the visual principle of keeping **60%+ unobstructed calm negative space** around focal subjects so headlines in `DM Sans` read effortlessly.
4. **Human Warmth Without Clutter (`02`)**  
   - Whenever an onboarding slide shows human intent (focus, evening capture, peace of mind, privacy), use `02`'s **lineless airbrushed shapes, warm peach-coral skin accents, soft radial light beams, and frosted translucent pill badges** rather than stiff corporate flat-illustration characters or heavy stroke outlines.
5. **Organic Print Texture on Dark Surfaces (`06`)**  
   - Pure flat dark gradients look sterile on OLED phones. `06` introduces **subtle risograph/airbrush micro-grain** inside dark-mode illustrations paired with vibrant coral, cream, cobalt, and teal-emerald hues, ensuring Tack's dark onboarding feels crafted and collectible.

### Alignment with Tack's Locked UI Rules
- **Neutral chrome, colorful objects:** Navigation dots, Skip button, and primary CTAs remain strict ink/neutral (`#111214` / `#FFFFFF` light; `#F5F6F8` / `#0F1012` dark) with sparingly used `accentPin` (`#EF5B5B`). Color stays inside the onboarding illustration stage and sticker elements.
- **No redundant controls:** Single primary pill/squircle CTA per slide (`Continue` / `Start Writing`), one unobtrusive top-right `Skip` exit route (omitted on the final slide so there are no duplicate exits), and clear back-swipe support across the horizontal `PageView`.
- **Grid-native preview consistency:** When Slide 2 previews Tack's workspace, render **cards in grid layout only** (never list rows or layout toggles, honoring `AGENTS.md` §0 Rule 1).
- **Local-first honesty:** Slide copy states zero accounts required and on-device storage plainly (`AppSpacing` + WCAG AA contrast >= 4.5:1 on all body and button text).

---

## 3. Unified Image Style Definition ("Tactile Daylight & Paper-Grain Studio")

### 3.1 Visual Pillars
1. **Tactile Softness over Sharp Chrome:** Every rendered prop uses generous corner rounding, puffy bevels (`04`), or thick crisp paper sticker contours (`05`). Avoid razor-sharp edges, noisy realism, or heavy black outlines.
2. **Diffused Studio Daylight & Soft Glows:** Lighting comes consistently from **top-left (~45°)** with broad soft falloff (`01`, `04`). Ambient shadows are wide, low-opacity (`alpha 0.06–0.12`), and tinted gently by the surface behind them (sky blue or warm charcoal—never harsh pitch-black).
3. **Subtle Material Contrast:** Pair smooth matte gradients (`02`, `04`) with delicate **micro-dot paper grids (`05`)** in light mode and **fine risograph speckled grain (`06`)** in dark mode.
4. **Spacious Single-Subject Clarity:** Maximum **1–4 grouped hero objects** or **3 serene horizon/cloud layers** per frame. At least half of every illustration remains open negative space (sky, cream dot-paper, misty lavender, or deep indigo).

### 3.2 Color Grammar Mapped to Tack Tokens

| Style Layer | Reference Palette | Tack Codebase Token (`app_colors.dart`) | Usage Rules |
|---|---|---|---|
| **App Canvas (Light)** | Cool light neutral | `AppColors.lightCanvas` (`#F3F4F6`) | Behind the onboarding layout chrome & typography |
| **App Canvas (Dark)** | Soft carbon | `AppColors.darkCanvas` (`#0F1012`) | Dark-mode screen backdrop behind hero frame |
| **Paper Grid Ground** | Warm cream `#F5F3EA` + faint dot grid | Pair with `AppColors.lightSurface` (`#FFFFFF`) | Light-mode sticker/desk-surface illustration stages (`05`) |
| **Sky & Horizon Washes** | Cerulean `#2F82DC`–`#5DB3F9` → Mist `#A9D8F6`–`#BCE0FB`, Meadow `#66B54C`–`#A7DB67` | Harmonizes with `pastelCyanSoft` (`#ECF8FB`) / `pastelLimeSoft` (`#F6FAEB`) | Open-air "mental space" & local-first freedom stages (`01`, `03`) |
| **Calm Dusk Wash** | Lavender `#AEADD9` → Blush `#F5ECF4` | Harmonizes with `pastelLavenderLight` (`#C9B8F2`) / `pastelLavenderSoft` (`#F5F1FD`) | Calm focus, evening journaling & emotional vignettes (`02`) |
| **Dark Illustration Ground** | Deep indigo `#1E2740` | Harmonizes with `AppColors.darkSurface` (`#18191C`) | Dark-mode hero stages for `06`-inspired riso artwork |
| **Primary Objects & Stickers** | Coral `#F64F45`, Azure `#3A9BFF`, Amber `#FFC23B`, Mint `#4FD16E`, Violet `#7047EB` | Map onto Tack's 8 pastels: `pastelPeachLight`, `pastelAmberLight`, `pastelCyanLight`, `pastelLimeLight`, `pastelLavenderLight`, `pastelRoseLight` | Reserve saturated fills strictly for sticky cards, 3D clay props, and botanical accents |
| **Sticker Die-Cut Stroke** | Crisp white `#FFFFFF` (`3–4dp`) | `AppColors.lightSurface` (`#FFFFFF`) | Outer paper border around 2D/2.5D sticker badges (`05`) |
| **Chrome & CTAs** | Ink `#111214` / Off-white `#F5F6F8`, Pin `#EF5B5B` | `lightActionPrimary` / `darkActionPrimary` / `lightAccentPin` | UI buttons, indicators, headlines — never rainbow buttons |

### 3.3 Rendering Rules: Do / Don't

- **Do:**
  - Anchor flat/layered UI metaphors with a crisp white die-cut sticker rim (`05`) or plush 3D clay volume (`04`).
  - Use horizontal 3-band separation (`03`) or staggered floating islands (`01`) when building full-bleed landscape metaphors.
  - Use **radial frosted white glow (`02`)** for focus beams, pinned highlights, and candle/idea sparks.
  - Preserve **fine stippled print grain (`06`)** inside dark-mode botanicals, graph nodes, and overlapping color transitions so shapes retain handmade tactility.
- **Don't:**
  - Do not draw hard black ink outlines (`stroke > 0` black line art) or heavy beveled metallic chrome.
  - Do not mix **photorealistic gritty textures** with flat UI cards—keep nature elements (`01`, `03`) cleanly curated, high-key, and miniature/serene.
  - Do not crowd the bottom or top edges of an illustration where headline text or floating pill controls sit.
  - Do not apply dark drop shadows on pastel elements (`rgba(0,0,0,0.4)`); keep shadow opacity soft (`0.06–0.14`) with generous blur.

---

## 4. Per-Reference Style Breakdown

### `01-floating-cloud-meadows.jpg`
- **Observed Traits:** Volumetric fluffy cumulus clouds carrying lush grass caps speckled with coral, yellow, and white flowers plus tiny yellow/pink butterflies against a smooth top-to-bottom azure sky gradient. Soft aerial haze lowers contrast on the furthest left cloud island.
- **Borrow:** Staggered floating depth clusters (3–4 foreground/midground/background layers); weightless elevation above open sky negative space; tiny accent particles (butterflies / sparks) to create gentle upward scale.
- **Avoid:** Overly intricate grass blades at small mobile thumbnail sizes—simplify meadow tufts when rendering at <200dp height.

### `02-soft-lavender-narrative-panels.jpg`
- **Observed Traits:** 6 self-contained rounded vignette cards in muted lavender-to-blush gradient (`~#AEADD9` -> `#F5ECF4`). Lineless coral-peach hands (`#EB948C`) hold glowing soft-white translucent shapes (candle flame, star, frosted glass pill reading `"HOPE"`), plus clean stylized dark-haired silhouettes reaching across a glowing divide or resting with a bright wedge of light.
- **Borrow:** Rounded inner storyboard card geometry; radial milky luminescence behind key icons/focus moments; translucent frosted capsule badge overlays; serene low-contrast storytelling palette.
- **Avoid:** Dense multi-panel grids on a single onboarding slide (pick **1 large focal vignette** per slide on mobile).

### `03-clear-horizon-meadow-ocean.jpg`
- **Observed Traits:** Crisp calm daylight composition divided cleanly into three pure planes: lush bright sunlit grass in the foreground bottom ~18%, saturated cerulean ocean band ~25%, and clear light sky with towering bright white clouds across the upper ~57%.
- **Borrow:** Generous clean upper sky zone built intentionally to hold headlines or floating badge chips cleanly; crisp calm color-blocking between foreground texture and expansive horizon openness.
- **Avoid:** Busy horizon clutter or lens flares that wash out text contrast.

### `04-soft-3d-clay-icons.png`
- **Observed Traits:** Four chunky, plump matte-clay 3D objects arranged with ample spacing on pure white `#FFFFFF`: sky-blue chat bubble, golden rounded bell, isometric sand parcel box with white tape strap, and rich purple navigation pointer. Smooth soft highlights, rounded edges everywhere, delicate grey ambient shadow directly beneath each object.
- **Borrow:** Tactile squishy geometry for hero feature props representing **Notes (bubble)**, **Reminders (bell)**, **Saved Clips / Vault (box)**, and **Whiteboard Flow / Cursor (violet pointer)**; pure neutral ground contrast so objects pop effortlessly.
- **Avoid:** Shiny mirror-like chrome plastics or sharp 90-degree mechanical corners.

### `05-diecut-sticker-icons-paper-grid.jpg`
- **Observed Traits:** Four colorful layered icons wrapped in crisp thick white sticker borders (`~3–4dp`), hovering slightly above a warm cream dot-grid notebook background (`#F5F3EA`) with tight ambient drop shadows. Icons use flat/slightly graded paper hues (coral, sky blue, mint green) and clean white circle/pill accents.
- **Borrow:** The **dot-grid cream paper background** and **thick white die-cut sticker cutlines**—this visually connects the illustrations straight to Tack's physical sticky-note & pin identity (`"Paper & Pin"`).
- **Avoid:** Tiny 1–2px unreadable micro-details inside sticker shapes when displayed on small Android viewports.

### `06-risograph-grain-botanicals-dark.jpg`
- **Observed Traits:** Eight symmetric botanical icons in two tidy rows against deep slate-navy (`#1E2740`). Sharp stylized geometric silhouettes filled with gradient-blended coral pink, ivory cream, cobalt blue, and teal emerald, enriched by coarse-to-fine dark stippled grain shadows and rhythmic petal repetition.
- **Borrow:** Deep rich indigo-slate dark backdrop instead of muddy `#222222`; lively geometric symmetry; tactile stipple/grain noise inside shaded edges so dark-mode illustrations stay vibrant and artistic.
- **Avoid:** High-frequency dot patterns behind body copy text—keep risograph grain strictly inside illustration shapes.

---

## 5. Tactile Onboarding Screen Blueprint (4-Slide Proposal for Tack)

Using these 6 references together produces a **4-slide swipeable onboarding flow** tailored to Tack's actual architecture:

### Screen Skeleton (Shared Across All 4 Slides)
- **Top Bar (`AppSpacing.lg` padding):**
  - Left: Minimal Tack brand mark (`icon.png` / pin mark `24dp` + `Tack` wordmark in `DM Sans` Bold, `-0.4` tracking).
  - Right: Quiet text action `Skip` (`48×48dp` minimum touch target, tertiary/secondary gray) on Slides 1–3; omitted on Slide 4 to avoid redundant exits.
- **Upper Stage (~52–58% viewport height):**
  - Centered rounded squircle showcase card (`24–28dp` radius, horizontal screen gutter `20dp`, `Clip.antiAlias`, `RepaintBoundary` isolated for smooth swipe & fade transitions).
  - Displays the custom slide hero illustration following this style spec + subtle parallax / gentle floating elevation.
- **Lower Copy & Action Dock (~42–48% viewport height, `SafeArea` protected):**
  - **Slide Counter / Pager Dots:** 4 minimal capsules/dots (active = pill in `actionPrimary` `#111214` / `#F5F6F8`, inactive = muted `borderStrong`).
  - **Headline (`26–30sp` `DM Sans` Bold, tracking `-0.5`):** 2 short lines max, optionally pairing a crisp upright phrase with one subtle `accentPin` or `Newsreader` italic key word (per `11-reference-ui-style.md`).
  - **Supporting Copy (`15sp` `DM Sans` Regular, `textSecondary`):** 2 concise lines communicating tangible benefit—never marketing fluff.
  - **Primary Action Button (`54dp` height, `16dp` smooth squircle radius, full width):** `Next` on Slides 1–3, **`Open Workspace`** (or **`Start Your First Note`**) on Slide 4. `minimumSize >= 48dp` height, high-contrast ink fill (`lightActionPrimary` / `darkActionPrimary`).

### Slide-by-Slide Reference Mapping

| Slide | Focus | Reference Blend | Hero Visual Description | Proposed Copy |
|---|---|---|---|---|
| **1. Capture Without Noise** | Quick Notes, Stickies & Clipboard | `01` + `05` | Cream dot-grid paper backdrop (`05`) opening upward into soft cerulean sky (`01`). 3 weightless floating die-cut sticky notes & a plump matte-clay blue speech bubble (`04`) drifting calmly above subtle cloud tufts and a coral pin badge. | **Capture thoughts as easily as pinning a note.**<br>Jot quick notes, colored stickies, and saved clips into one tactile grid—never buried in nested menus. |
| **2. Think Visually & Plan Today** | Whiteboards, Tasks & Reminders | `04` + `05` + `02` | Layered whiteboard canvas snippet on warm dot-paper: two pastel squircle cards linked by a soft curved arrow (`04` violet pointer + `05` white sticker rim checklist card & golden clay reminder bell), framed with gentle `02` ambient highlight glow. | **Turn scattered ideas into clear plans.**<br>Sketch flowcharts on infinite whiteboards, check off daily tasks, and schedule reminders when focus matters. |
| **3. Calm Focus, Day & Night** | Light / Dark Craft & Distraction-Free Read Mode | `02` + `06` | Split-diagonal or gentle cross-dissolve preview: calm lavender-blush evening reading glow with soft hand/star vignette (`02`) on one side, paired cleanly with dark-mode indigo-slate botanicals with subtle riso grain (`06`) representing growing linked notes. | **Built for quiet reading and deep focus.**<br>Tap any note to read cleanly without toolbars—or switch seamlessly between bright paper and calm dark mode. |
| **4. 100% Yours, On Your Device** | Local-First Storage & Privacy Promise | `03` + `01` | Open luminous horizon meadow & sky (`03`) with a translucent frosted pill badge (`02`) reading `"Stored Locally"` anchored cleanly over a floating cloud-meadow island (`01`) and locked kraft parcel icon (`04`). High contrast sky headroom ensures crystal-clear balance. | **Private by design, saved right on your phone.**<br>No forced sign-ups, no cloud lock-in, and offline JSON/Markdown export whenever you need it. |

---

## 6. Generative / Illustration Prompt Templates

Use these standardized formulas if generating bespoke illustrations with `image_generation` or external tools so all slides belong to the same world:

### A. Light Mode Sticker + Matte Clay Scene (`04` + `05` style)
> `"Minimalist tactile mobile app onboarding illustration on a warm cream dot-grid notebook paper background (#F5F3EA). Feature [SUBJECTS: e.g., soft coral sticky card, plump matte 3D clay reminder bell in warm amber (#FFC23B), violet pointer dart (#7047EB)], styled as crisp die-cut paper stickers with clean 4px white borders and soft diffused drop shadows mixed with plush matte clay 3D objects. Top-left soft daylight, generous 60% negative space, clean rounded geometry, zero black outlines, no text, editorial app-store polish."`

### B. Calm Sky / Floating Island Metaphor (`01` + `03` style)
> `"Serene, high-key minimalist daylight illustration for a mobile note-taking app onboarding screen. [SUBJECT: e.g., soft fluffy white cloud islands topped with miniature emerald grass meadows and tiny pastel coral/yellow wildflowers hovering over a luminous tranquil sky-blue gradient (#5DB3F9 to #BCE0FB)]. Crisp airy atmosphere, uncluttered upper negative space for typography, subtle dreamy miniature scale, no harsh lens flare, no text."`

### C. Emotional Warmth / Dark Mode Riso-Grain (`02` + `06` style)
> `"Editorial minimalist illustration with lineless soft airbrushed shapes and delicate risograph stipple grain. On a deep slate-indigo background (#1E2740) [or soft lavender-blush #AEADD9 to #F5ECF4 gradient for light mode], show [SUBJECT: e.g., symmetric stylized geometric leaves/nodes blooming cleanly or stylized minimal hands holding a warm translucent glowing frosted star]. Warm coral (#F64F45 / #EB948C), cream (#F7EEDB), cobalt blue (#326CE5), and teal (#0B6B5F) accents. High breathing room, smooth rounded forms, no hard cartoon outlines, no text."`
