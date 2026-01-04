# HRV Insights UX Specification

**Status:** Design Review  
**Sprint:** 12 (HRV Intelligence)  
**Design Language:** Cozy Science

---

## 1. Design Philosophy: "The Nervous System Whisperer"

HRV insights reveal the **invisible conversation** between food and the autonomic nervous system. Unlike HR-based insights (visible as heart pounding), HRV is subtle—the user can't feel it directly. This requires:

- **Trust Building**: Explain *why* HRV matters before showing the data
- **Gentle Framing**: HRV variability is natural; low isn't "bad", it's *information*
- **Actionable Optimism**: Every insight should connect to something the user can do

> [!TIP]
> **Copy Principle**: Never say "Your HRV is low." Instead: "Your body is working hard to recover."

---

## 2. Insight Tiers & Display Hierarchy

### 2.1 Tier System

To avoid overwhelming users with 15 insight types, we introduce **tiered visibility**:

| Tier | Visibility | Insight Types | UI Treatment |
|------|------------|---------------|--------------|
| **Primary** | Always shown | Sugar Spike, Muscle Sponge, Digestion Debt, Morning Readiness | Full card, mascot reaction, potential notification |
| **Secondary** | Shown on request | Anxiety Mimic, Caffeine Jitter, Recovery Gap, Meal Impact Score | Collapsed card, expandable, subtle mascot awareness |
| **Contextual** | Triggered by patterns | Stress Buffer, Fasting Benefit, Alcohol Impact | Celebration modal or weekly summary, never timeline card |
| **Chronic** | Weekly digest only | Mineral Gap, Brain Fog Forecast, Deep Sleep Robber | Weekly insight summary, not individual cards |

### 2.2 Display Rules

```
┌─────────────────────────────────────────┐
│  Timeline View                          │
├─────────────────────────────────────────┤
│  [Primary Insights]                     │
│  • Full InsightCard with mascot         │
│  • Inline with meals/workouts           │
│  • Max 3 per day                        │
│─────────────────────────────────────────│
│  [Secondary Insights]                   │
│  • Collapsed "HRV pulse" mini-card      │
│  • Tap to expand                        │
│  • Grouped if multiple                  │
│─────────────────────────────────────────│
│  [Contextual]                           │
│  • Modal celebration (positive)         │
│  • Morning summary banner (neutral)     │
└─────────────────────────────────────────┘
```

---

## 3. Visual Design: HRV-Specific Elements

### 3.1 The "Pulse" Indicator

A small, ambient HRV status indicator that appears on Primary insight cards:

```
┌──────────────────────────────────┐
│  ◉ ◉ ◉ ◉ ◉   HRV Pulse           │
│  ●━●━●━●━○   (animated line)     │
└──────────────────────────────────┘
```

| HRV State | Visual | Animation |
|-----------|--------|-----------|
| **High (recovered)** | 🟢 Green pulse, wide spacing | Slow, rhythmic wave |
| **Normal (baseline)** | ⚪ Neutral dots | Steady, calm |
| **Low (stressed)** | 🟠 Coral pulse, tight spacing | Quick, compressed wave |
| **Suppressed (deep recovery)** | 🟣 Periwinkle | Very slow, minimal |

### 3.2 Insight Card Anatomy (HRV-Enhanced)

```
┌─────────────────────────────────────────────────┐
│  ╭──────────────────────────────────────────╮   │
│  │  🧸 [Mascot State]     ◉◉◉◉◉ HRV Pulse   │   │
│  │                                           │   │
│  │  "Your body is still processing          │   │
│  │   last night's dinner"                    │   │
│  │                                           │   │
│  │  ┌─────────────────────────────────┐     │   │
│  │  │  📊 Overnight HRV Chart         │     │   │
│  │  │  ▁▂▃▂▁▁▁▁▁▂▃               │     │   │
│  │  │  ↳ 15% below normal             │     │   │
│  │  └─────────────────────────────────┘     │   │
│  │                                           │   │
│  │  💡 Linked: Pasta (9:45 PM)              │   │
│  │                                           │   │
│  │  [Take a Walk]  [Dismiss]                │   │
│  ╰──────────────────────────────────────────╯   │
└─────────────────────────────────────────────────┘
```

### 3.3 Color Mapping for HRV Insights

| Insight Type | Loop Color | Background Gradient | Mascot State |
|--------------|------------|---------------------|--------------|
| Morning Readiness (good) | 🌿 Sage | Mint → Cream | **Strong** |
| Morning Readiness (poor) | 🔮 Periwinkle | Lavender → Cream | **Sleepy** |
| Anxiety Mimic | 🍑 Coral | Peach → Cream | **Crashing** |
| Caffeine Jitter | 🌿 Sage | Sage → Cream | **Spiking** |
| Recovery Gap | 🍑 Coral | Coral → Peach | **Hungry** |
| Stress Buffer | 🌿 Sage | Mint → Sage | **Strong** |
| Digestion Debt | 🔮 Periwinkle | Periwinkle → Lavender | **Sleepy** |
| Deep Sleep Robber | 🔮 Periwinkle | Lavender → Cream | **Crashing** |
| Meal Impact Score | 🍑 Coral (high) / 🌿 Sage (low) | Dynamic | **Digesting** |
| Fasting Benefit | 🌿 Sage | Mint → Cream | **Strong** |
| Alcohol Impact | 🍑 Coral | Coral → Cream | **Crashing** |
| Mineral Gap | 🔮 Periwinkle | Lavender → Cream | **Neutral** |
| Brain Fog Forecast | 🔮 Periwinkle | Periwinkle → Cream | **Sleepy** |

---

## 4. Copy Guidelines: The HRV Voice

### 4.1 Tone Principles

| ❌ Clinical | ✅ Cozy Science |
|-------------|-----------------|
| "HRV dropped 23%" | "Your body is working hard to recover" |
| "Low overnight HRV" | "Digestion kept your heart busy last night" |
| "Autonomic imbalance" | "Your nervous system needs a breather" |
| "Parasympathetic suppression" | "Rest mode didn't fully kick in" |

### 4.2 Insight Copy Templates

#### Morning Readiness

| State | Main Copy | Sub Copy |
|-------|-----------|----------|
| **High** | "Fully charged! Your recovery was excellent." | "HRV is {X}% above baseline. Great day for intensity." |
| **Normal** | "Steady state. You're ready for a normal day." | "HRV is on target. Listen to your body." |
| **Low** | "Recovery isn't complete yet." | "Consider an easier day or prioritize rest." |

#### Anxiety Mimic

| State | Main Copy | Sub Copy |
|-------|-----------|----------|
| **Detected** | "Feeling anxious? It might be a sugar dip." | "HRV is {X}% below normal, {Y} hours after that {meal}. Try a small snack." |

#### Caffeine Jitter

| State | Main Copy | Sub Copy |
|-------|-----------|----------|
| **Positive** | "Alert mode activated! ☕" | "That's {X}mg caffeine working. HRV stable—this is focus, not stress." |

#### Recovery Gap

| State | Main Copy | Sub Copy |
|-------|-----------|----------|
| **Detected** | "Your body is asking for fuel." | "You burned {X} kcal but only ate {Y}. HRV recovery is slow—time to eat!" |

#### Digestion Debt (HRV-Enhanced)

| State | Main Copy | Sub Copy |
|-------|-----------|----------|
| **Mild** | "Late dinner = lighter recovery." | "Overnight HRV dipped only {X}%. Not bad, but earlier is better." |
| **Moderate** | "Your heart worked overtime last night." | "Digesting that {meal} suppressed HRV by {X}%. Recovery took a hit." |
| **Severe** | "Sleep was more 'digest' than 'rest'." | "Overnight HRV was {X}% below normal. Consider an earlier kitchen closing." |

#### Fasting Benefit

| State | Main Copy | Sub Copy |
|-------|-----------|----------|
| **Detected** | "Your fast is working! 🌿" | "HRV improved {X}% over the last {Y} hours as digestion rested." |

#### Alcohol Impact

| State | Main Copy | Sub Copy |
|-------|-----------|----------|
| **Detected** | "Last night's drinks took a toll." | "Overnight HRV was suppressed by {X}%. Recovery will take an extra day." |

#### Stress Buffer

| State | Main Copy | Sub Copy |
|-------|-----------|----------|
| **Positive** | "You handled that stress well! 💪" | "Despite a tough day, your {X}g protein kept HRV stable." |

#### Mineral Gap

| State | Main Copy | Sub Copy |
|-------|-----------|----------|
| **Flagged** | "Your nervous system seems 'stuck'." | "HRV has been flat for 2 weeks. Consider checking Magnesium or Zinc." |

#### Brain Fog Forecast

| State | Main Copy | Sub Copy |
|-------|-----------|----------|
| **Predicted** | "Focus might be tricky today." | "Morning HRV is {X}% below normal. Tackle hard work early." |

#### Meal Impact Score

| Score | Main Copy | Sub Copy |
|-------|-----------|----------|
| **High impact** | "That meal hit hard." | "HRV dropped {X}% after eating. Your body is working to process it." |
| **Low impact** | "Smooth sailing! 🌊" | "That meal barely touched your HRV. Well-tolerated." |

---

## 5. Mascot Integration

### 5.1 HRV-Specific Mascot States

The existing 7 mascot states map to HRV insights:

| Mascot State | HRV Trigger | Animation Modifier |
|--------------|-------------|-------------------|
| **Neutral** | HRV at baseline | Standard breathing |
| **Hungry** | Low HRV + fasted state | Eager + slightly tired |
| **Digesting** | Post-meal HRV dip | Content + working hard |
| **Spiking** | Caffeine jitter (HRV stable, HR up) | Energetic, sparkles |
| **Crashing** | Anxiety mimic, alcohol impact | Dizzy, slumping |
| **Sleepy** | Deep sleep robber, brain fog | Yawning, heavy eyes |
| **Strong** | Morning readiness high, fasting benefit | Power aura, confident |

### 5.2 Mascot in HRV Cards

The mascot appears in the card corner, sized at 48x48, with state matching the insight mood.

---

## 6. Notification Patterns

### 6.1 Which HRV Insights Notify?

| Insight | Notification? | Timing | Priority |
|---------|---------------|--------|----------|
| Morning Readiness (low) | ✅ Yes | 7:00 AM (or wake) | Time Sensitive |
| Anxiety Mimic | ✅ Yes | Real-time | Time Sensitive |
| Recovery Gap | ✅ Yes | 2h post-workout | Default |
| Digestion Debt | ✅ Yes | Next morning 7 AM | Default |
| Brain Fog Forecast | ✅ Yes | Morning (batched) | Default |
| Fasting Benefit | ❌ No | — | — |
| Stress Buffer | ❌ No | — | — |
| Others | ❌ No | Weekly summary | — |

### 6.2 Notification Grouping

Batch morning insights into a single rich notification:

```
┌─────────────────────────────────────────┐
│  🧸 Good morning                        │
│                                         │
│  📊 Your overnight recovery:            │
│     • HRV: 42ms (15% below normal)      │
│     • Deep sleep: 38 min                │
│                                         │
│  💡 That 10 PM pasta might be why.      │
│                                         │
│  [See Details]          [Dismiss]       │
└─────────────────────────────────────────┘
```

---

## 7. Onboarding: "Meet Your Nervous System"

### 7.1 HRV Education Flow (3 Screens)

**Screen 1: What is HRV?**
- Heart Rate Variability = conversation between heart and brain
- High HRV = relaxed and recovered
- Low HRV = working hard right now

**Screen 2: Food Affects HRV**
- Blood flows to digestion → HRV temporarily dips
- Late meals = recovery debt
- Visual: timeline showing meal → HRV drop → recovery

**Screen 3: Requires Apple Watch**
- Continuous monitoring needed
- Wear to sleep for best insights
- Enable HRV Insights button

### 7.2 No-Watch Fallback

If no Apple Watch:
- Show degraded insight mode message
- Still track meal timing patterns
- Encourage pairing Watch later

---

## 8. Empty States & Edge Cases

### 8.1 No HRV Data Yet

"Wear your Apple Watch tonight to start seeing HRV insights. We need at least 7 nights to establish your baseline."

Progress indicator: ○ ○ ○ ○ ○ ○ ○ (0/7 nights)

### 8.2 Contradictory Signals

When HR says one thing but HRV says another:

"Mixed Signals: Heart rate is elevated, but HRV is stable. This could be caffeine, light movement, or excitement—not stress."

---

## 9. Accessibility Considerations

- **HRV Pulse Animation**: Respect `reduceMotion`, replace with static indicators
- **Color-independent**: Always pair color with pattern (spacing, size)
- **VoiceOver**: "HRV status: recovered" / "HRV status: stressed"
- **Copy length**: Main ≤60 chars, Sub ≤120 chars

---

## 10. Component Inventory

| Component | Purpose |
|-----------|---------|
| `HRVPulseView` | Animated HRV status indicator |
| `HRVInsightCard` | Extended InsightCard with HRV data |
| `HRVChartView` | Mini spline chart for overnight HRV |
| `MorningReadinessBanner` | Top-of-timeline morning summary |
| `WeeklySummaryModal` | Sunday digest of chronic insights |
| `HRVOnboardingFlow` | 3-screen education carousel |

---

## 11. Asset Requirements

### New Kawaii Icons Needed

| Asset Name | Description |
|------------|-------------|
| `hrv_high_kawaii` | Smiling heart with wave |
| `hrv_low_kawaii` | Tired heart with flat line |
| `hrv_pulse_kawaii` | Heart with ECG line |
| `brain_fog_kawaii` | Confused cloud over head |
| `fasting_kawaii` | Peaceful empty bowl |
| `alcohol_kawaii` | Dizzy wine glass |
| `mineral_kawaii` | Pill/supplement bottle |
