# Monch Mascot UX Design

## Decisions (Confirmed ✅)

| Question | Decision |
|----------|----------|
| Tap header → expand? | ✅ **Yes** — Full-screen "Monch View" on tap |
| Text tone | ✅ **User-focused** — Monch implies mood visually, text speaks to user |
| Widgets/Lock Screen | ✅ **Yes** — Priority feature |
| Animation approach | See below 👇 |

---

## Animation from Static Images

**Yes, absolutely possible!** SwiftUI can animate static images with:

### Simple Effects (No extra assets needed)
- **Idle breathing:** Subtle `scaleEffect` pulse (1.0 → 1.02 → 1.0)
- **Tail wag:** Slight `rotationEffect` oscillation
- **Bounce on state change:** Spring animation when mood transitions
- **Floating:** Gentle Y-offset oscillation

### Example Code
```swift
Image("monch_neutral")
    .scaleEffect(isAnimating ? 1.02 : 1.0)
    .animation(.easeInOut(duration: 1.5).repeatForever(), value: isAnimating)
```

### State-Specific Effects
| State | Animation |
|-------|-----------|
| Neutral | Gentle breathing (scale pulse) |
| Hungry | Eager bounce + slight rotation toward food bubble |
| Spiking | Rapid vibration (`offset` jitter) + sparkle overlay |
| Crashing | Slow droop (Y offset down) + slight desaturation |
| Sleepy | Very slow breathing, occasional "nod" (rotation) |
| Strong | Power pulse (scale 1.0 → 1.1) + glow overlay |
| Digesting | Slower breathing, content sway |

---

## Where Monch Appears

| Surface | Variant | Size | Priority | Status |
|---------|---------|------|----------|--------|
| **Home Header** | In-App | 64×64 | P0 | ✅ Done |
| **Monch View** (tap to expand) | In-App | 200×200 | P0 | To build |
| **Empty State** | In-App | 120×120 | P0 | To build |
| **Insight Cards** | In-App | 48×48 | P1 | To build |
| **Notifications** | 8-Bit | 32×32 | P1 | To build |
| **Dynamic Island** | 8-Bit | 32×32 | P1 | To build |
| **Widget** | 8-Bit | 48×48 | P1 | To build |
| **Lock Screen** | 8-Bit | 48×48 | P1 | To build |
| **Onboarding** | In-App | 200×200 | P2 | Later |

---

## Monch View (Expanded) — Concept

When user taps header, full-screen sheet slides up:

```
┌─────────────────────────────┐
│                         ✕   │  ← Dismiss
│                             │
│         🐊 MONCH 🐊         │  ← Large animated mascot (200×200)
│        (current state)      │
│                             │
│   "You haven't eaten in     │  ← Primary insight text
│    4 hours. Time for        │
│    lunch?"                  │
│                             │
│  ┌─────────┐ ┌─────────┐   │
│  │ Log Meal│ │ Snooze  │   │  ← Quick actions
│  └─────────┘ └─────────┘   │
│                             │
│  ──────── Details ────────  │
│  • Last meal: 10:30am       │  ← Supporting context
│  • Blood sugar: Stable      │
│  • Next eating window: Now  │
│                             │
└─────────────────────────────┘
```
