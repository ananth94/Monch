# Monch Design System: The "Cozy Science" Edition

## 1. Design Philosophy: "Metabolic Tamagotchi"
*Monch* is not a medical device; it is a companion. The goal is to make metabolic tracking feel **Warm**, **Forgiving**, and **Delightful**.
*   **Core Values:**
    *   **Kawaii over Clinical:** Data is presented through emotion and character, reducing the anxiety of "bad numbers."
    *   **Soft & Organic:** Visuals should feel like watercolor paintings or soft clay, avoiding sharp edges and neon data lines.
    *   **Supportive:** The app never judges. A sugar crash is just a "dizzy moment" for Monch, not a failure for the user.

---

## 2. The Mascot: "Monch"
Monch is the heart of the UI. It is a reactive character that serves as the primary status indicator.

### 2.1 Reactive States (The "Face" of the Data)
Monch changes appearance based on the user's real-time metabolic context.

| State | Trigger | Visual Description |
|-------|---------|-------------------|
| **Neutral** | Baseline | Happy, round, soft blob. Breathing slowly. |
| **Hungry** | Ghrelin signal | Looking at a thought bubble of food. |
| **Full / Digesting** | Lipid load | Rounder, slower animation, holding belly. |
| **Spiking** | Sugar rush | Vibrating, wide-eyed, rapid color shifts. |
| **Crashing** | Hypoglycemia | Melting into a puddle, dizzy eyes ("Snorlax" tired vibe). |
| **Sleepy** | Circadian cue | Wearing a nightcap, eyes closing. |
| **Strong** | Anabolic window | Flexing, glowing aura (post-workout). |

### 2.2 Functional Role & Tone
*   **Visual Status:** Monch provides the *ambient context*. If Monch is sleepy, the user visually understands it's time to wind down without reading text.
*   **Direct Coaching (Copy):** Text and Actions are always framed around the **User**, not the mascot.
    *   ❌ *Bad:* "Monch is hungry! Feed him!"
    *   ✅ *Good:* "You haven't eaten in 4 hours. Time for lunch?"
    *   ❌ *Bad:* "Monch is crashing."
    *   ✅ *Good:* "Your heart rate is unstable. Consider a fiber-rich snack to stabilize."
*   **Insight Cards:** The card visual might feature a dizzy Monch illustration, but the insight text remains direct and actionable for the user.

---

## 3. Color System: "Watercolor Mode"
We replace clinical neons with a soft, natural pastel palette. We leverage **Mesh Gradients** to create fluid, organic backgrounds that mimic watercolor bleed.

### 3.1 The "Mood" Palette

| Mood | Primary | Secondary | Feeling |
|------|---------|-----------|---------|
| 🍑 **Acute / Spike** | Soft Coral `#FFA07A` | Warm Peach `#FFB7B2` | Energetic but not alarming |
| 🌿 **Anabolic / Fuel** | Sage Green `#88B04B` | Mint Cream `#F5FFFA` | Fresh, healthy, restorative |
| 🔮 **Sleep / Circadian** | Periwinkle `#CCCCFF` | Soft Lavender `#E6E6FA` | Calming, twilight |

### 3.2 Background Colors (The Canvas)

| Mode | Color | Hex | Notes |
|------|-------|-----|-------|
| Dark | Midnight Navy | `#1A1B26` | Primary dark background |
| Dark | Warm Charcoal | `#2E2E2E` | Elevated surfaces |
| Light | Cream / Paper | `#FDFBF7` | Primary light background |

> [!IMPORTANT]
> Avoid pure `#000000` or `#FFFFFF` — keep backgrounds soft.

### 3.3 Semantic Colors

| Token | Light Mode | Dark Mode | Usage |
|-------|------------|-----------|-------|
| `success` | `#4CAF50` | `#81C784` | Completed goals, positive feedback |
| `warning` | `#FFB74D` | `#FFCC80` | Gentle alerts (not alarm) |
| `error` | `#E57373` | `#EF9A9A` | Soft error states (not harsh red) |

### 3.4 Text Colors

| Token | Light Mode | Dark Mode | Contrast Ratio |
|-------|------------|-----------|----------------|
| `labelPrimary` | `#1A1B26` | `#FDFBF7` | ≥7:1 (AAA) |
| `labelSecondary` | `#5A5A6E` | `#A0A0B0` | ≥4.5:1 (AA) |
| `labelTertiary` | `#8A8A9E` | `#707080` | ≥3:1 (AA Large) |
| `labelDisabled` | `#C0C0C8` | `#505058` | Decorative only |

### 3.5 Dividers & Borders

| Token | Light Mode | Dark Mode |
|-------|------------|-----------|
| `divider` | `#E8E8EC` | `#3A3A42` |
| `border` | `#D0D0D8` | `#4A4A52` |
| `borderFocused` | `#88B04B` | `#88B04B` |

---

## 4. Typography

### 4.1 Font Family
**SF Pro Rounded** — Friendly, approachable, with soft terminals.

### 4.2 Type Scale

| Style | Weight | Size | Line Height | Letter Spacing | Usage |
|-------|--------|------|-------------|----------------|-------|
| `largeTitle` | Heavy | 34pt | 41pt | -0.4pt | Hero numbers |
| `title1` | Bold | 28pt | 34pt | 0.36pt | Screen titles |
| `title2` | Bold | 22pt | 28pt | 0.35pt | Section headers |
| `title3` | Semibold | 20pt | 25pt | 0.38pt | Card titles |
| `headline` | Semibold | 17pt | 22pt | -0.4pt | Emphasized body |
| `body` | Medium | 17pt | 22pt | -0.4pt | Primary content |
| `callout` | Medium | 16pt | 21pt | -0.3pt | Supporting text |
| `subheadline` | Regular | 15pt | 20pt | -0.2pt | Metadata |
| `footnote` | Regular | 13pt | 18pt | -0.1pt | Timestamps, labels |
| `caption1` | Regular | 12pt | 16pt | 0pt | Tertiary info |
| `caption2` | Medium | 11pt | 13pt | 0.1pt | Badges, tags |

### 4.3 Styling Rules
*   **Lowercase headers:** Use lowercase for a casual feel (e.g., "sugar spike" not "Sugar Spike").
*   **Chunky values:** Use `largeTitle` (Heavy) for data values — feels friendlier than thin fonts.
*   **Dynamic Type:** All text must support iOS Dynamic Type scaling.

---

## 5. Spacing & Layout

### 5.1 Base Grid
8pt base grid. All spacing should be multiples of 4pt, preferring 8pt increments.

### 5.2 Spacing Scale

| Token | Value | Usage |
|-------|-------|-------|
| `xxs` | 2pt | Hairline gaps |
| `xs` | 4pt | Icon-to-label gaps, tight padding |
| `sm` | 8pt | Default padding, inline spacing |
| `md` | 16pt | Card padding, section gaps |
| `lg` | 24pt | Section separators |
| `xl` | 32pt | Screen margins |
| `xxl` | 48pt | Hero spacing |

### 5.3 Corner Radius Scale

| Token | Value | Usage |
|-------|-------|-------|
| `radiusXS` | 4pt | Badges, tags |
| `radiusSM` | 8pt | Buttons, small cards |
| `radiusMD` | 12pt | Input fields |
| `radiusLG` | 16pt | Modals, sheets |
| `radiusXL` | 24pt | Timeline bubbles, insight cards |
| `radiusFull` | 9999pt | Pills, avatars |

---

## 6. Accessibility

### 6.1 Contrast Requirements
*   **Body text:** Minimum 4.5:1 contrast ratio (WCAG AA).
*   **Large text (≥18pt or 14pt bold):** Minimum 3:1.
*   **Interactive elements:** Minimum 3:1 against adjacent colors.

### 6.2 Color Blind Considerations
The Coral/Sage palette may be indistinguishable for users with deuteranopia (red-green color blindness).

**Mitigation strategies:**
*   Always pair color with **shape or icon** (e.g., upward arrow for spike, leaf for anabolic).
*   Use **pattern or texture** in charts when color-only isn't enough.
*   Monch's **state animations** provide redundant non-color signals.

### 6.3 Dynamic Type Support
*   All text uses system text styles that scale with user preferences.
*   Layouts must accommodate 200% text scaling without truncation.
*   Test with "Larger Accessibility Sizes" enabled.

### 6.4 Motion Sensitivity
*   Respect `UIAccessibility.isReduceMotionEnabled`.
*   Replace animations with crossfades when reduced motion is on.
*   Monch state changes become simple crossfades, not bouncy transitions.

---

## 7. Visual Components (The "Cozy" UI)

### 7.1 The Timeline (`RiverTimeline`)
*   **Style:** A "River" rather than a line.
*   **Cards:** Log entries are "Bubbles" or "Stones" in the river. Corner radius: `radiusXL` (24pt).
*   **Illustrations:** Each log type (Coffee, Meal, Run) has a hand-drawn or watercolor-style icon (asset-based) rather than generic SF Symbols.

### 7.2 Insight Cards (`InsightCard`)
*   **Container:** Looks like a journal entry or speech bubble from the mascot.
*   **Background:** Subtle watercolor texture or mesh gradient corresponding to the Loop (Coral/Sage/Lavender).
*   **Chart:** Spline area chart (curved, filled) — never jagged line charts.
*   **States:** `.loading`, `.content(insight)`, `.empty`, `.error(message)`

### 7.3 Buttons

| Variant | Background | Text Color | Usage |
|---------|------------|------------|-------|
| `primary` | Sage Green gradient | White | Main CTAs |
| `secondary` | Transparent | Sage Green | Secondary actions |
| `ghost` | Transparent | labelSecondary | Tertiary actions |
| `destructive` | Soft error tint | Error color | Dangerous actions |

### 7.4 Charts
*   **Line style:** Spline (curved interpolation), never linear segments.
*   **Fill:** Gradient fill from line color to transparent.
*   **Gridlines:** Subtle, use `divider` color, dashed.
*   **Axis labels:** `footnote` style, `labelTertiary` color.

---

## 8. Mascot Asset Specification

### 8.1 Asset Variants
Monch requires **two visual treatments** for different contexts:

| Variant | Style | Usage | Format |
|---------|-------|-------|--------|
| **In-App** | Full watercolor, soft gradients, high detail | Main UI, insight cards, onboarding | Lottie (animated) or PNG@3x |
| **8-Bit** | Pixel art, 32x32 base, limited palette | Notifications, Live Activity, Dynamic Island | PNG@3x (static) |

### 8.2 States to Generate
Each variant requires **7 states**:

| State ID | File Name (In-App) | File Name (8-Bit) |
|----------|--------------------|--------------------|
| `neutral` | `monch_neutral.json` | `monch_8bit_neutral@3x.png` |
| `hungry` | `monch_hungry.json` | `monch_8bit_hungry@3x.png` |
| `digesting` | `monch_digesting.json` | `monch_8bit_digesting@3x.png` |
| `spiking` | `monch_spiking.json` | `monch_8bit_spiking@3x.png` |
| `crashing` | `monch_crashing.json` | `monch_8bit_crashing@3x.png` |
| `sleepy` | `monch_sleepy.json` | `monch_8bit_sleepy@3x.png` |
| `strong` | `monch_strong.json` | `monch_8bit_strong@3x.png` |

### 8.3 Generation Guidelines

#### In-App (Watercolor)
*   **Style prompt anchor:** "Soft watercolor blob character, Studio Ghibli-inspired, pastel palette, no hard edges, kawaii aesthetic"
*   **Resolution:** Export at 512x512 minimum for Lottie source, 300x300@3x for static PNG.
*   **Color constraints:** Use only colors from the Mood Palette (§3.1).
*   **Animation:** Idle loop should be 2-4 seconds, subtle breathing/bobbing.

#### 8-Bit (Pixel Art)
*   **Style prompt anchor:** "Cute 8-bit pixel art character, 32x32 pixel grid, limited 16-color palette, rounded blob shape, retro game aesthetic"
*   **Resolution:** 32x32 base, export at 96x96 (@3x).
*   **Color constraints:** 
    *   Max 16 colors per sprite.
    *   Include Midnight Navy for outlines.
    *   Use 2-3 colors from relevant Mood Palette per state.
*   **No animation** — static sprites only for system UI.

### 8.4 Asset Storage
```
monch/
├── Assets.xcassets/
│   ├── Monch/
│   │   ├── InApp/           # Lottie JSON files
│   │   │   ├── monch_neutral.json
│   │   │   └── ...
│   │   └── 8Bit/            # Pixel art PNGs
│   │       ├── monch_8bit_neutral.imageset/
│   │       └── ...
```

### 8.5 Consistency Checklist
Before shipping mascot assets, verify:
- [ ] All 7 states present for both variants
- [ ] Blob shape is consistent across states (same base proportions)
- [ ] Color palette matches design system (no rogue colors)
- [ ] 8-bit versions are legible at 32x32
- [ ] In-app animations loop seamlessly
- [ ] Expressions match state descriptions in §2.1

---

## 9. Implementation Reference

### 9.1 SwiftUI Tokens

#### Colors (`Color+Monch.swift`)
```swift
extension Color {
    struct Monch {
        // Mood: Acute / Spike
        static let coral = Color(hex: "#FFA07A")
        static let peach = Color(hex: "#FFB7B2")
        
        // Mood: Anabolic / Fuel
        static let sage = Color(hex: "#88B04B")
        static let mint = Color(hex: "#F5FFFA")
        
        // Mood: Sleep / Circadian
        static let periwinkle = Color(hex: "#CCCCFF")
        static let lavender = Color(hex: "#E6E6FA")
        
        // Backgrounds
        static let midnightNavy = Color(hex: "#1A1B26")
        static let warmCharcoal = Color(hex: "#2E2E2E")
        static let cream = Color(hex: "#FDFBF7")
        
        // Semantic
        static let success = Color(hex: "#4CAF50")
        static let warning = Color(hex: "#FFB74D")
        static let error = Color(hex: "#E57373")
        
        // Text
        static let labelPrimary = Color(hex: "#1A1B26")
        static let labelSecondary = Color(hex: "#5A5A6E")
        static let labelTertiary = Color(hex: "#8A8A9E")
        static let labelDisabled = Color(hex: "#C0C0C8")
        
        // Borders
        static let divider = Color(hex: "#E8E8EC")
        static let border = Color(hex: "#D0D0D8")
        static let borderFocused = Color(hex: "#88B04B")
    }
}
```

#### Spacing (`Spacing.swift`)
```swift
enum Spacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}
```

#### Corner Radius (`CornerRadius.swift`)
```swift
enum CornerRadius {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let full: CGFloat = 9999
}
```

### 9.2 Gradients
Use SwiftUI `MeshGradient` (iOS 18+) for background "moods."

```swift
// Example: Acute/Spike mood gradient
MeshGradient(
    width: 3, height: 3,
    points: [...],
    colors: [.Monch.coral, .Monch.peach, .Monch.cream, ...]
)
```

### 9.3 Haptics
*   **Soft, "bubbly" haptics** for interactions.
*   Use `.soft` impact style for logging actions.
*   Use `.light` for navigation and selections.
*   Avoid `.heavy` or `.rigid` — too clinical.

---

## 10. Component API Quick Reference

| Component | File | Key Props |
|-----------|------|-----------|
| `MonchAvatar` | `MonchAvatar.swift` | `state: MonchState`, `size: AvatarSize`, `animated: Bool` |
| `InsightCard` | `InsightCard.swift` | `insight: Insight`, `mood: MoodLoop`, `onTap: () -> Void` |
| `RiverTimeline` | `RiverTimeline.swift` | `entries: [LogEntry]`, `onEntryTap: (LogEntry) -> Void` |
| `MoodGradientBackground` | `MoodGradientBackground.swift` | `mood: MoodLoop`, `intensity: Double` |
| `SplineAreaChart` | `SplineAreaChart.swift` | `data: [DataPoint]`, `color: Color`, `showGrid: Bool` |
| `MonchButton` | `MonchButton.swift` | `title: String`, `variant: ButtonVariant`, `action: () -> Void` |

---

## Appendix: Platform Requirements

| Requirement | Value |
|-------------|-------|
| Minimum iOS | 18.0 |
| Swift | 5.9+ |
| Xcode | 16.0+ |
