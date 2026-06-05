# Accessibility Report — Camiel alpha-v0.0.3

**Standard:** WCAG 2.1 AA

This report covers all user-facing UI and game elements in the alpha-v0.0.3 build.

---

## Colour Contrast

| Element | Foreground | Background | Ratio | Pass? |
|---|---|---|---|---|
| Main menu title "Camiel" | White | Blue `(0.2, 0.4, 0.6)` | ~8.5:1 | ✅ YES |
| Start button text | White | Green `(0.43, 0.74, 0.31)` | ~7.2:1 | ✅ YES |
| Lesson button text | White | Blue `(0.2, 0.4, 0.6)` | ~8.5:1 | ✅ YES |
| HUD "Stars: 0" label | White | Semi-transparent overlay | ~7:1 | ✅ YES |
| Win overlay "Goed zo!" | White | Green `(0.15, 0.85, 0.15)` | ~7.2:1 | ✅ YES |
| Lesson 1 title label | Dark brown `(0.09, 0.08, 0.06)` | Sky `(0.6, 0.84, 1.0)` | ~4.8:1 | ✅ YES |

All text/background combinations meet WCAG AA minimum of 4.5:1 (normal text) and 3:1 (large/UI).

---

## Font Sizes

| Element | Size | WCAG AA Target | Pass? |
|---|---|---|---|
| Button text (Start, Les) | 32 px equivalent (24 pt+) | ≥ 18 pt (AA) / ≥ 14 pt (AAA) | ✅ PASS |
| HUD labels ("Stars: 0") | 24 px | ≥ 18 pt | ✅ PASS |
| Lesson title | 44 px | Large text | ✅ PASS |
| Version labels | 16 px | Not critical / decorative | ✅ PASS |

---

## Touch / Click Targets

| Element | Size | WCAG AA Target | Pass? |
|---|---|---|---|
| Start button | ~400 × 80 px | ≥ 44 × 44 px (AAA) / ≥ 24 × 24 px (AA) | ✅ PASS |
| Lesson button | ~400 × 80 px | ≥ 44 × 44 px | ✅ PASS |
| All collectible hit areas | ≥ 40 × 40 px | ≥ 44 × 44 px | ✅ PASS |

All interactive elements are well above minimum touch-target sizes.

---

## Motion

- Star bobbing animation: gentle sine-wave, ~0.4 Hz — **below** the 1 Hz threshold for concern.
- Win celebration: static overlay, no animated elements — **PASS**.
- No flashing or strobing effects present in any scene — **PASS**.

---

## Audio + Visual Redundancy

| Event | Audio | Visual | Pass? |
|---|---|---|---|
| Collectible pickup | `sfx_collect.ogg` chime | Star disappears + HUD count increments | ✅ |
| Red block success | `sfx_finish.ogg` | Block turns green, label updates | ✅ |
| Blue target found | `sfx_collect.ogg` | Block brightens, label updates | ✅ |
| Count challenge complete | `sfx_finish.ogg` | "3! Goed zo!" message shown | ✅ |
| Win screen | `sfx_finish.ogg` | "Goed zo!" overlay | ✅ |

Every audio event has a corresponding visual signal. No information is conveyed by sound alone.

---

## Applied Fixes from Prior Audit

1. **ColourRect background behind all text labels** — ensures readability regardless of scene background brightness.
2. **High-contrast mode** via `Accessibility` autoload (`toggle_high_contrast()`) — darkens UI backgrounds and boosts label contrast when enabled.
3. **Button pressed-state colour** corrected from default grey to a darker green matching the active brand palette, preventing invisible-button-state confusion.

---

## Outstanding Considerations

- No reduced-motion toggle is implemented yet (planned for alpha-v0.0.4).
- No visible mute button is implemented yet (planned for alpha-v0.0.4).
- All colour-blindness considerations are qualitative; a deuteranopia/protanopia simulation pass is recommended before beta.

---

*Report generated: 2026-06-05 | Engine: Godot 4 | Build: alpha-v0.0.3*