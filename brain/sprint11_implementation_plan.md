# Sprint 11: River UI, Patterns & Streaks

## Summary

Sprint 11 focuses on visual polish and engagement features:
1. **River UI** — Organic spline path behind timeline items
2. **Pattern Drill-Down** — Tap patterns to see linked entries
3. **Streak Celebrations** — Milestone confetti and "Start Fresh" messaging

---

## User Review Required

> [!IMPORTANT]
> **River UI Scope**: The spline is a purely decorative background element. It does NOT affect item layout or functionality. Confirm if you want it static or lightly animated (breathing/pulse).

> [!NOTE]
> **Streak Types**: Currently tracking "logging streaks" (days with at least one food log). Should we also track "insight-free streaks" or "sleep goal streaks"?

---

## Proposed Changes

### Phase 1: River UI (~4 hours)

#### [NEW] `RiverSplineView.swift`
Canvas-based organic spline that flows behind timeline items.

**Algorithm:**
- Generate control points based on timeline item positions
- Use Catmull-Rom spline interpolation for smooth curves
- Gradient stroke (sage → periwinkle) that follows the mood

**Integration:**
- ZStack layer behind timeline items in `TimelineView.swift`
- Animates subtly (optional breathing effect)

---

#### [MODIFY] [TimelineView.swift](file:///Users/ananthradhakrishnan/Documents/Projects/Monch/monch/Views/Timeline/TimelineView.swift)

Add `RiverSplineView` as background layer:
```swift
ZStack {
    RiverSplineView(itemCount: timelineItems.count, mood: currentMood)
    // Existing timeline content
}
```

---

### Phase 2: Pattern Drill-Down (~4 hours)

#### [NEW] `PatternDetailView.swift`
Modal showing entries that contributed to a detected pattern.

**Contents:**
- Pattern summary (e.g., "Late meals 5/7 days this week")
- Mini-timeline of affected entries
- "Set Goal" button to create reminder

---

#### [MODIFY] [WeekView.swift](file:///Users/ananthradhakrishnan/Documents/Projects/Monch/monch/Views/Dashboard/WeekView.swift)

Make pattern cards tappable:
```swift
PatternCard(pattern: pattern)
    .onTapGesture { selectedPattern = pattern }
```

Add sheet modifier for `PatternDetailView`.

---

#### [MODIFY] [DashboardModels.swift](file:///Users/ananthradhakrishnan/Documents/Projects/Monch/monch/Models/DashboardModels.swift)

Add linked entry IDs to `Pattern` struct:
```swift
struct Pattern {
    // existing properties...
    var linkedMealIDs: [UUID]
    var linkedInsightIDs: [UUID]
}
```

---

### Phase 3: Streak Celebrations (~3 hours)

#### [NEW] `StreakCelebrationView.swift`
Confetti modal for streak milestones (7, 14, 30 days).

**Design:**
- Confetti particle animation
- Mascot celebration pose
- "Keep it up!" messaging

---

#### [MODIFY] [ContentView.swift](file:///Users/ananthradhakrishnan/Documents/Projects/Monch/monch/ContentView.swift)

Add streak milestone detection:
```swift
.onAppear {
    if streakTracker.didReachMilestone {
        showStreakCelebration = true
    }
}
```

---

#### [NEW] `StreakTracker.swift`
Service to calculate and persist streak data.

**Logic:**
- Count consecutive days with at least one `MealLog`
- Persist `currentStreak` and `longestStreak` to UserDefaults
- Detect milestones (7, 14, 30, 100 days)
- Handle streak breaks gracefully

---

## Verification Plan

### Automated Tests
- Unit tests for `StreakTracker` milestone detection
- Spline control point generation with varying item counts

### Manual Verification
- Visual inspection of River UI on Timeline
- Pattern drill-down navigation flow
- Streak celebration triggers at 7-day mark (testable with mock data)

---

## Estimated Effort

| Phase | Hours |
|-------|-------|
| River UI | 4 |
| Pattern Drill-Down | 4 |
| Streak Celebrations | 3 |
| **Total** | **11 hours** |

---

# 🌊 RIVER TIMELINE: Detailed UX Design Spec

## Design Philosophy

The River is not just a decorative element — it's the **visual metaphor for time flowing through your day**. Each entry is a "stepping stone" in the stream of your metabolic journey. The aesthetic should feel like a hand-illustrated children's book or a Studio Ghibli background painting.

### Core Aesthetic Pillars

| Pillar | Description |
|--------|-------------|
| **Watercolor Softness** | No hard edges. Everything bleeds, blurs, and softens at boundaries. |
| **Kawaii Whimsy** | Subtle personality in every element — stones have gentle shadows, the river has a slight shimmer. |
| **Organic Movement** | Nothing is perfectly straight. The river meanders, stones are slightly askew. |
| **Living Illustration** | The timeline feels like a page from a picture book that gently breathes. |

---

## 1. THE RIVER (The Path)

### 1.1 Visual Treatment

```
                    ╭─────╮
              ╭────╯       ╰──╮
       ╭─────╯                 ╰───╮
      ╯                              ╰─╮
    ╭╯                                  ╰╮
   ╯                                      ╰
```

**Shape:** A soft, meandering spline that gently curves left and right as it flows down the screen. NOT a straight line. The curve should feel natural, like a real stream.

**Width:** Variable. The river is wider in the middle (~80pt) and narrows at the edges (~40pt), creating a gentle "waist" effect that makes it feel more organic.

### 1.2 Color & Texture

| Layer | Treatment |
|-------|-----------|
| **Base Fill** | Soft gradient from `Sage #88B04B` (top) → `Periwinkle #CCCCFF` (bottom), representing the flow from day into evening. |
| **Texture Overlay** | Subtle watercolor paper texture at 5-10% opacity. Feels like paint on rough paper. |
| **Edge Treatment** | Feathered edges using a radial gradient mask. No hard boundaries — the river "bleeds" into the background. |
| **Sparkle Layer** | Occasional tiny white circles (2-4pt) at random positions to simulate sunlight catching water. Animate with gentle fade in/out. |

### 1.3 Mood Reactivity

The river subtly shifts its color palette based on the current `MascotMoodState`:

| Mood | River Tint | Effect |
|------|------------|--------|
| **Neutral** | Base gradient (Sage → Periwinkle) | Calm, steady flow |
| **Spiking** | Warmer tint (+15% Coral overlay) | Water looks "excited" |
| **Crashing** | Cooler tint (+10% Lavender) | Water looks "slow" |
| **Strong** | Brighter saturation (+10%) | Water looks "energized" |
| **Sleepy** | Deeper Periwinkle, less Sage | Evening twilight feel |

### 1.4 Animation

| Animation | Description | Duration |
|-----------|-------------|----------|
| **Gentle Sway** | The spline control points shift ±2pt horizontally in a sine wave pattern | 4s loop |
| **Sparkle Twinkle** | Random sparkles fade in (0.3s), hold (0.5s), fade out (0.3s) | Staggered |
| **Scroll Parallax** | River scrolls at 0.8x the speed of content, creating depth | Continuous |

---

## 2. THE STONES (Timeline Cards)

Each timeline entry is a "stepping stone" in the river. They should feel like hand-painted river rocks with a slightly raised, tactile quality.

### 2.1 Card Shape

**NOT rectangular.** Cards should have an organic, slightly irregular rounded shape — like a smooth river stone.

```
     ╭─────────────────────────╮
    ╱                           ╲
   │                             │
   │      CARD CONTENT           │
   │                             │
    ╲                           ╱
     ╰─────────────────────────╯
```

**Implementation:** Use `CornerRadius.xl` (24pt) with subtle variations:
- Top-left: 24pt
- Top-right: 22pt
- Bottom-left: 20pt
- Bottom-right: 26pt

This creates an organic, hand-drawn feel without looking broken.

### 2.2 Card Positioning

Cards should **not** be centered on the river. They alternate sides and have slight rotations:

| Position | Horizontal Offset | Rotation |
|----------|-------------------|----------|
| Odd items | -8pt (left of center) | -1° to -2° |
| Even items | +8pt (right of center) | +1° to +2° |

This creates a natural "stepping path" down the river.

### 2.3 Card Shadows

**Watercolor Shadow:** Instead of iOS drop shadows, use a soft, colored shadow that mimics watercolor "bleeding."

```swift
.shadow(color: Color.Monch.sage.opacity(0.15), radius: 16, x: 0, y: 8)
.shadow(color: Color.Monch.periwinkle.opacity(0.1), radius: 24, x: 0, y: 12)
```

The double shadow with different hue tints creates the watercolor impression of paint bleeding beyond the boundary.

### 2.4 Card Types Visual Language

Each card type has a subtle visual distinction while maintaining the stone metaphor:

| Card Type | Accent | Icon Treatment |
|-----------|--------|----------------|
| **Meal** | Warm cream background | 🍽️ Small plate illustration (not SF Symbol) |
| **Insight** | Loop-colored left border (Coral/Sage/Periwinkle) | Mascot mini-illustration |
| **Workout** | Sage tint | 🏃 Simple line art figure |
| **Sleep** | Periwinkle tint | 🌙 Hand-drawn moon |

### 2.5 Card Illustrations

Replace generic SF Symbols with **tiny hand-drawn illustrations** for key elements:

| Element | Current | Kawaii Replacement |
|---------|---------|-------------------|
| Meal icon | `fork.knife` | Tiny plate with steam wisps |
| Coffee | ☕ emoji | Cute mug with heart steam |
| Workout | `figure.run` | Simple stick figure in motion |
| Sleep | 😴 emoji | Sleeping Monch face (eyes closed, "zzz") |
| Insight (Spike) | 📈 | Dizzy Monch face |
| Insight (Recovery) | 💪 | Flexing Monch arm |

**Asset format:** PNG with transparency, watercolor style, 48x48pt @3x.

---

## 3. THE RIPPLES (Entry Interactions)

When users interact with timeline entries, gentle ripple effects emanate from the touch point.

### 3.1 Tap Ripple

On tap, a circular ripple expands outward from the touch point:

```
Frame 0:  ·
Frame 1:  ○
Frame 2:  ◯
Frame 3:  ◎ (fading)
Frame 4:  (gone)
```

**Implementation:**
- Starting radius: 0pt
- Ending radius: 120pt
- Duration: 0.4s
- Color: White at 30% opacity → 0%
- Easing: easeOut

### 3.2 Press & Hold (Long Press)

During long press, concentric ripples pulse outward:

```
Step 1:  ◯
Step 2:  ○ ◯
Step 3:  · ○ ◯
```

- New ripple every 0.3s
- Maximum 3 concurrent ripples
- Indicates "edit mode" or "more options" coming

### 3.3 Scroll Splash

When scrolling quickly, tiny "splash" particles appear near the edges of the river:

- 3-5 small circles (3pt diameter)
- Scatter in direction of scroll
- Fade out over 0.2s
- Only visible when scroll velocity > threshold

---

## 4. THE ISLANDS (Day Headers)

Day headers are "islands" or "sandbars" that break up the river flow.

### 4.1 Visual Treatment

```
    ╭───────────────────────────────╮
   ╱   🌅  TODAY, JANUARY 4         ╲
  │                                   │
   ╲                                 ╱
    ╰───────────────────────────────╯
```

**Shape:** Wide, flattened oval — like a sandbar in a stream.

**Color:** 
- Light mode: Warm sand `#F5DEB3` with cream border
- Dark mode: Soft charcoal with subtle sage border

**Texture:** Subtle dot pattern to simulate sand grains (3% opacity).

### 4.2 Island Decorations

Each day header has a tiny decorative element based on the time of day when most entries occurred:

| Dominant Time | Decoration |
|---------------|------------|
| Morning (6am-12pm) | ☀️ Tiny sun peeking from edge |
| Afternoon (12pm-6pm) | 🌸 Small flower on sandbar |
| Evening (6pm-12am) | 🌙 Crescent moon and star |
| Mixed | Simple pebbles |

### 4.3 Sticky Behavior

When scrolling, the day header "sticks" to the top but with a subtle effect:
- Slight shadow appears below (the "island" is now floating)
- Background becomes slightly more opaque
- Gentle scale up to 1.02x

---

## 5. THE CREATURES (Empty States & Ambient Elements)

### 5.1 Empty Timeline

When no entries exist, the river is peaceful with subtle ambient life:

```
┌─────────────────────────────────────┐
│                                     │
│     [River flowing peacefully]      │
│                                     │
│         🐸                          │  ← Tiny frog on lily pad
│              ~~~                    │  ← Small ripples
│                                     │
│     [Hungry Monch on riverbank]     │
│     "The river is quiet...          │
│      Log your first meal?"          │
│                                     │
│     [ Start Logging → ]             │
│                                     │
└─────────────────────────────────────┘
```

**Ambient elements:**
- 1-2 lily pads floating gently
- Occasional small fish "blip" (circle appears, wiggles, disappears)
- Tiny dragonfly that loops across the screen every 30s

### 5.2 Few Items State

When only 1-2 items exist, add encouraging ambient elements:

- Small Monch footprints leading to/from the stones
- "Splash" marks around stones suggesting recent activity
- Subtle text: "Your journey is just beginning..."

---

## 6. SOUND DESIGN (Optional — Accessibility)

If we add sound (muted by default, respects system settings):

| Action | Sound |
|--------|-------|
| Scroll | Gentle water trickle (very subtle) |
| Card tap | Soft "plop" (stone dropping in water) |
| Meal logged | Satisfied "munch" sound |
| Insight appeared | Gentle chime |
| Streak milestone | Celebration jingle |

> [!NOTE]
> All sounds must have visual equivalents. Sound is enhancement, not requirement.

---

## 7. MICRO-INTERACTIONS DETAIL

### 7.1 Card Appear Animation

When a new card appears (after logging):

1. Card starts below final position, small (0.8x), 0% opacity
2. Card moves up with spring bounce, grows to 1.0x, fades to 100%
3. Ripples emanate from card position
4. River "splashes" slightly near the new stone

**Duration:** 0.5s total
**Easing:** spring(response: 0.4, dampingFraction: 0.7)

### 7.2 Card Delete Animation

When a card is deleted:

1. Card shrinks to 0.9x
2. "Sinks" downward with slight rotation
3. Ripples spread outward as it "falls in"
4. Fades to 0%

**Duration:** 0.4s
**Easing:** easeIn for the "sinking" feel

### 7.3 Day Transition

When scrolling past a day boundary:

1. Current day header slides up and fades
2. New day header slides in from below with gentle bounce
3. Brief "shimmer" across the river (like sunlight moving)

---

## 8. ACCESSIBILITY CONSIDERATIONS

| Concern | Solution |
|---------|----------|
| Motion sensitivity | Respect `reduceMotion`. Replace animations with crossfades. |
| Color blindness | All information is also conveyed via shape/icon, not just color. |
| VoiceOver | River is decorative; cards are the interactive elements. River is marked `accessibilityHidden`. |
| Dynamic Type | Card content scales; river and decorations remain fixed. |

---

## 9. TECHNICAL IMPLEMENTATION NOTES

### 9.1 Canvas vs. SwiftUI

The river should be implemented using `Canvas` for performance:

```swift
Canvas { context, size in
    // Draw spline path
    // Draw watercolor texture overlay
    // Draw sparkles
}
.allowsHitTesting(false) // River is purely decorative
```

### 9.2 Performance Considerations

- Sparkle animations should use `TimelineView` for GPU-efficient updates
- Limit concurrent animations to 10-15 elements
- Use `drawingGroup()` if needed for complex compositions
- River texture can be a pre-rendered image asset

### 9.3 Assets Required

| Asset | Size | Notes |
|-------|------|-------|
| `river_texture.png` | 375×812pt @3x | Tileable watercolor paper texture |
| `meal_icon_kawaii.png` | 48×48pt @3x | Hand-drawn plate illustration |
| `coffee_kawaii.png` | 48×48pt @3x | Cute coffee mug |
| `workout_kawaii.png` | 48×48pt @3x | Simple running figure |
| `sleep_kawaii.png` | 48×48pt @3x | Sleeping moon |
| `lily_pad.png` | 32×32pt @3x | For empty state |
| `splash_particle.png` | 8×8pt @3x | Circular splash drop |

---

## 10. REVISED EFFORT ESTIMATE

Given the depth of this design spec:

| Component | Original | Revised | Notes |
|-----------|----------|---------|-------|
| Basic spline | 4h | 2h | Foundation only |
| Watercolor treatment | — | 3h | Texture, gradient, feathering |
| Card styling updates | — | 2h | Asymmetric radius, shadows |
| Micro-animations | — | 3h | Ripples, parallax, sparkles |
| Kawaii assets | — | 4h | Illustration or asset sourcing |
| Accessibility | — | 1h | Reduce motion, VoiceOver |
| **New Total** | 4h | **15h** | +11h for delightful experience |

---

## 11. VISUAL REFERENCE MOOD BOARD

*Inspirations to guide asset creation:*

- Studio Ghibli background paintings (Spirited Away bathhouse, Totoro forest)
- Animal Crossing: New Horizons UI (soft shadows, rounded everything)
- Kirby's Epic Yarn (yarn/fabric texture, playful shapes)
- Duolingo empty states (illustrated characters with personality)
- Headspace meditation app (soft gradients, gentle animations)

---

# 🎨 ASSET PROMPT LIBRARY

> [!IMPORTANT]
> **Status: ✅ INTEGRATED INTO PROJECT**
> All 19 assets have been generated, resized (@1x, @2x, @3x), and organized into `monch/Assets.xcassets/River/`.
> See the [Asset Verification Report](../.gemini/antigravity/brain/8957ac79-548a-4ba1-b590-870f59dda32b/river_assets_verification.md) for initial visual review.

## Base Character Reference

All assets should match this style description:
> **Style:** Soft watercolor illustration, Studio Ghibli-inspired, kawaii aesthetic. Gentle gradients, no harsh outlines. Colors should feel like pigment on wet paper — soft edges that bleed slightly. Minimal detail, maximum charm.

---

## 1. TIMELINE CARD ICONS (48×48pt @3x)

### 1.1 Meal Icon — `meal_kawaii.png`

**Prompt:**
```
A tiny watercolor illustration of a round ceramic plate with a small dome of rice and 
a leaf garnish. Soft steam wisps rise in gentle curves. Warm cream and soft brown 
tones. Simple, minimal details. Transparent background. Soft edges like watercolor 
paint bleeding on paper. Kawaii, cute, Studio Ghibli food illustration style.
```

**Usage in Code:**
```swift
// In MealCardView.swift
Image("meal_kawaii")
    .resizable()
    .frame(width: 32, height: 32)
```

---

### 1.2 Coffee/Caffeine Icon — `coffee_kawaii.png`

**Prompt:**
```
A tiny watercolor illustration of a cute round coffee mug, ceramic, light blue or 
cream colored. A small heart shape formed in the steam rising from the cup. Simple, 
minimal, no text. Soft watercolor edges, transparent background. Kawaii aesthetic, 
cozy cafe illustration style.
```

**Usage in Code:**
```swift
// In CaffeineQuickAddView.swift
Image("coffee_kawaii")
    .resizable()
    .frame(width: 24, height: 24)
```

---

### 1.3 Green Tea Icon — `tea_kawaii.png`

**Prompt:**
```
A tiny watercolor illustration of a traditional Japanese tea cup (yunomi), soft sage 
green color. Gentle steam curling upward. A tiny tea leaf floating near the rim. 
Minimal, cute, kawaii style. Transparent background, soft watercolor edges.
```

**Usage in Code:**
```swift
// In CaffeineQuickAddView.swift (Green Tea option)
Image("tea_kawaii")
```

---

### 1.4 Workout/Exercise Icon — `workout_kawaii.png`

**Prompt:**
```
A simple watercolor illustration of a cute stick figure in a running pose. Soft 
coral/peach body color with rosy cheeks. Motion lines behind suggesting movement. 
Minimal, playful, kawaii aesthetic. Transparent background. No detailed anatomy, 
just a joyful simple running shape.
```

**Usage in Code:**
```swift
// In WorkoutCardView.swift
Image("workout_kawaii")
    .resizable()
    .frame(width: 32, height: 32)
```

---

### 1.5 Sleep/Moon Icon — `sleep_kawaii.png`

**Prompt:**
```
A tiny watercolor crescent moon wearing a small sleeping cap (nightcap). Soft 
periwinkle/lavender color. A few tiny stars around it. Eyes closed peacefully, 
maybe a small "zzz" in a thought bubble. Kawaii, cute, dreamy. Transparent 
background, soft watercolor edges.
```

**Usage in Code:**
```swift
// In SleepCardView.swift
Image("sleep_kawaii")
    .resizable()
    .frame(width: 32, height: 32)
```

---

### 1.6 Insight Spike Icon — `insight_spike_kawaii.png`

**Prompt:**
```
A tiny watercolor illustration of a cute crocodile/dragon face (Monch mascot) 
looking dizzy — spiral eyes, tongue slightly out, small sweat drops. Teal/aqua 
body color. Expression is comical not scary. Kawaii, transparent background, 
soft watercolor style.
```

**Usage in Code:**
```swift
// In InsightCardView.swift when type == .sugarSpike
Image("insight_spike_kawaii")
```

---

### 1.7 Insight Recovery Icon — `insight_recovery_kawaii.png`

**Prompt:**
```
A tiny watercolor illustration of a cute crocodile/dragon arm (Monch mascot) 
flexing proudly. Small sparkles around the bicep. Teal/aqua color. Confident, 
triumphant expression implied. Kawaii style, transparent background, soft 
watercolor edges.
```

**Usage in Code:**
```swift
// In InsightCardView.swift when type == .muscleSponge
Image("insight_recovery_kawaii")
```

---

### 1.8 Supplement Stack Icon — `supplement_kawaii.png`

**Prompt:**
```
A tiny watercolor illustration of 2-3 soft-colored vitamin capsules in a small 
ceramic dish. Pastel colors (soft orange, mint green, lavender). Simple, minimal, 
no text. Kawaii wellness aesthetic. Transparent background, watercolor soft edges.
```

**Usage in Code:**
```swift
// In SupplementStackView.swift
Image("supplement_kawaii")
```

---

## 2. ENVIRONMENTAL TEXTURES

### 2.1 River Watercolor Texture — `river_texture.png`

**Prompt:**
```
Seamless tileable watercolor paper texture. Subtle organic paper fiber patterns. 
Light cream/ivory base color. Soft variations in tone suggesting wet watercolor 
paper. No distinct patterns, just natural paper texture. Should tile seamlessly 
both horizontally and vertically.
```

**Size:** 512×512pt @3x (tileable)

**Usage in Code:**
```swift
// In RiverSplineView.swift
Image("river_texture")
    .resizable(resizingMode: .tile)
    .opacity(0.08)
    .blendMode(.overlay)
```

---

### 2.2 Sand/Island Texture — `sand_texture.png`

**Prompt:**
```
Seamless tileable subtle dot texture simulating fine sand grains. Very light warm 
beige/tan color. Tiny scattered dots at random intervals, very subtle and light. 
Should tile seamlessly. Transparent background with only the dots visible.
```

**Size:** 256×256pt @3x (tileable)

**Usage in Code:**
```swift
// In DayHeaderView.swift
Image("sand_texture")
    .resizable(resizingMode: .tile)
    .opacity(0.03)
```

---

## 3. AMBIENT RIVER ELEMENTS

### 3.1 Lily Pad — `lily_pad.png`

**Prompt:**
```
A single watercolor lily pad, top-down view. Soft sage green with subtle vein 
patterns. Slightly rounded edges with one small V-notch. A tiny water droplet 
sitting on top catching light. Kawaii, simple, transparent background. Soft 
watercolor style.
```

**Size:** 48×48pt @3x

**Usage in Code:**
```swift
// In EmptyTimelineView.swift
Image("lily_pad")
    .offset(x: lilyPadOffset)
    .animation(.easeInOut(duration: 3).repeatForever())
```

---

### 3.2 Lily Flower — `lily_flower.png`

**Prompt:**
```
A tiny watercolor lotus/water lily flower, simple 5-petal shape. Soft pink or 
white petals with a small yellow center. Cute, minimal, kawaii style. Sitting 
on water. Transparent background.
```

**Size:** 32×32pt @3x

**Usage in Code:**
```swift
// Optional decoration next to lily_pad
Image("lily_flower")
```

---

### 3.3 Water Splash Particle — `splash_particle.png`

**Prompt:**
```
A tiny single watercolor water droplet/splash, perfect circle with a small 
highlight. Very soft blue-white color, almost transparent. Simple, minimal. 
Should work when animated/faded. Transparent background.
```

**Size:** 12×12pt @3x

**Usage in Code:**
```swift
// In RiverSplineView.swift for sparkle/splash effects
ForEach(sparklePositions) { pos in
    Image("splash_particle")
        .opacity(sparkleOpacity)
        .position(pos)
}
```

---

### 3.4 Tiny Fish — `fish_blip.png`

**Prompt:**
```
A tiny simple watercolor fish shape, top-down view as if swimming in water. 
Just a simple elongated oval with a small tail fin. Soft orange/gold color 
like a koi. Extremely minimal, almost like a brushstroke. Transparent background.
```

**Size:** 16×24pt @3x

**Usage in Code:**
```swift
// In EmptyTimelineView.swift - ambient animation
Image("fish_blip")
    .rotationEffect(fishAngle)
    .offset(fishOffset)
```

---

### 3.5 Dragonfly — `dragonfly.png`

**Prompt:**
```
A tiny simple watercolor dragonfly, side view. Soft teal body, translucent 
lavender/periwinkle wings. Very simple, almost like a small brushstroke with 
wing shapes. Kawaii, minimal. Transparent background.
```

**Size:** 24×16pt @3x

**Usage in Code:**
```swift
// In EmptyTimelineView.swift - periodic fly-across animation
Image("dragonfly")
    .offset(x: dragonflyX)
    .animation(.linear(duration: 8).repeatForever())
```

---

## 4. DAY HEADER DECORATIONS

### 4.1 Morning Sun — `decoration_sun.png`

**Prompt:**
```
A tiny cute watercolor sun peeking from below, as if rising. Soft warm yellow/
orange gradient. Simple rays like a child's drawing. Maybe one small happy eye 
visible. Kawaii, minimal. Transparent background.
```

**Size:** 24×24pt @3x

**Usage in Code:**
```swift
// In DayHeaderView.swift when dominantTime == .morning
Image("decoration_sun")
    .offset(x: -40, y: 2)
```

---

### 4.2 Afternoon Flower — `decoration_flower.png`

**Prompt:**
```
A tiny watercolor cherry blossom or simple 5-petal flower. Soft pink petals 
with yellow center. Minimal, cute, kawaii. Single flower, not a bunch. 
Transparent background.
```

**Size:** 20×20pt @3x

**Usage in Code:**
```swift
// In DayHeaderView.swift when dominantTime == .afternoon
Image("decoration_flower")
```

---

### 4.3 Evening Moon/Star — `decoration_moon.png`

**Prompt:**
```
A tiny watercolor crescent moon with 1-2 small stars next to it. Soft 
periwinkle/lavender moon, stars are pale yellow. Very simple shapes, kawaii 
style. Transparent background.
```

**Size:** 24×24pt @3x

**Usage in Code:**
```swift
// In DayHeaderView.swift when dominantTime == .evening
Image("decoration_moon")
```

---

### 4.4 Pebbles (Default) — `decoration_pebbles.png`

**Prompt:**
```
3-4 tiny watercolor river pebbles/stones grouped together. Various soft gray 
and cream colors. Smooth, rounded shapes. Very simple, minimal. Transparent 
background.
```

**Size:** 32×16pt @3x

**Usage in Code:**
```swift
// In DayHeaderView.swift default decoration
Image("decoration_pebbles")
```

---

## 5. ASSET INTEGRATION CHECKLIST

| Asset | File Name | Size | Priority | Used In |
|-------|-----------|------|----------|---------|
| Meal Icon | `meal_kawaii.png` | 48×48 | P0 | `MealCardView` |
| Coffee Icon | `coffee_kawaii.png` | 48×48 | P0 | `CaffeineQuickAddView` |
| Tea Icon | `tea_kawaii.png` | 48×48 | P1 | `CaffeineQuickAddView` |
| Workout Icon | `workout_kawaii.png` | 48×48 | P0 | `WorkoutCardView` |
| Sleep Icon | `sleep_kawaii.png` | 48×48 | P0 | `SleepCardView` |
| Spike Insight | `insight_spike_kawaii.png` | 48×48 | P0 | `InsightCardView` |
| Recovery Insight | `insight_recovery_kawaii.png` | 48×48 | P1 | `InsightCardView` |
| Supplement Icon | `supplement_kawaii.png` | 48×48 | P1 | `SupplementStackView` |
| River Texture | `river_texture.png` | 512×512 | P0 | `RiverSplineView` |
| Sand Texture | `sand_texture.png` | 256×256 | P1 | `DayHeaderView` |
| Lily Pad | `lily_pad.png` | 48×48 | P2 | `EmptyTimelineView` |
| Lily Flower | `lily_flower.png` | 32×32 | P2 | `EmptyTimelineView` |
| Splash Particle | `splash_particle.png` | 12×12 | P1 | `RiverSplineView` |
| Fish Blip | `fish_blip.png` | 16×24 | P2 | `EmptyTimelineView` |
| Dragonfly | `dragonfly.png` | 24×16 | P2 | `EmptyTimelineView` |
| Sun Decoration | `decoration_sun.png` | 24×24 | P1 | `DayHeaderView` |
| Flower Decoration | `decoration_flower.png` | 20×20 | P1 | `DayHeaderView` |
| Moon Decoration | `decoration_moon.png` | 24×24 | P1 | `DayHeaderView` |
| Pebbles | `decoration_pebbles.png` | 32×16 | P1 | `DayHeaderView` |

---

## 6. EXPORT SPECIFICATIONS

### For AI Image Generation
- Request: 1024×1024px minimum for quality
- Background: Specify "transparent background" or "solid white background to remove"
- Post-process: Remove background if needed, resize to @3x target

### For Xcode Assets
```
Assets.xcassets/
└── River/
    └── Icons/
        ├── meal_kawaii.imageset/
        │   ├── meal_kawaii@1x.png (16×16)
        │   ├── meal_kawaii@2x.png (32×32)
        │   └── meal_kawaii@3x.png (48×48)
        └── ... (repeat for each)
    └── Textures/
        ├── river_texture.imageset/
        └── sand_texture.imageset/
    └── Ambient/
        ├── lily_pad.imageset/
        └── ... (repeat)
    └── Decorations/
        └── ... 
```

### Quality Checklist
- [ ] All assets have transparent backgrounds
- [ ] No harsh black outlines (watercolor soft edges only)
- [ ] Colors match Design System palette
- [ ] Assets look cohesive as a set (same illustration style)
- [ ] Test at 1x size to ensure readability at small sizes


