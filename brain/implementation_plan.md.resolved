# Implementation Plan: Monch View & Animations

Implement the core mascot experience components as defined in [Mascot_UX.md](file:///Users/ananthradhakrishnan/Documents/Projects/Monch/Mascot_UX.md).

## Proposed Changes

### [Mascot Components]

#### [NEW] [MonchAvatar.swift](file:///Users/ananthradhakrishnan/Documents/Projects/Monch/monch/Views/Mascot/MonchAvatar.swift)
Create a reusable view that handles the static image rendering and the SwiftUI animation system (breathing, jitter, etc.).
- Input: `MascotMoodState`, `size`
- Internal: `@State private var isAnimating`
- Logic: Applications of `scaleEffect`, `offset`, and `rotationEffect` based on state.

#### [NEW] [MonchView.swift](file:///Users/ananthradhakrishnan/Documents/Projects/Monch/monch/Views/Mascot/MonchView.swift)
The full-screen sheet that expands when the header is tapped.
- Large `MonchAvatar` (200x200)
- Detailed status and prompt text
- Quick action buttons (Log Meal, etc.)
- Metadata summary section

#### [NEW] [MonchEmptyStateView.swift](file:///Users/ananthradhakrishnan/Documents/Projects/Monch/monch/Views/Timeline/MonchEmptyStateView.swift)
A dedicated empty state view replacing the `ContentUnavailableView` in `ContentView`.
- Large "Hungry" `MonchAvatar`
- Onboarding call-to-action

#### [MODIFY] [MascotHeader.swift](file:///Users/ananthradhakrishnan/Documents/Projects/Monch/monch/Views/Mascot/MascotHeader.swift)
- Replace internal `mascotImage` logic with the new `MonchAvatar` component.
- Add tap gesture state to trigger `MonchView` sheet.

#### [MODIFY] [ContentView.swift](file:///Users/ananthradhakrishnan/Documents/Projects/Monch/monch/ContentView.swift)
- Replace `ContentUnavailableView` with `MonchEmptyStateView`.
- Manage the presentation state for the `MonchView` sheet.

## Verification Plan

### Manual Verification
1. **Empty State Check:** Launch app with empty data and verify "Hungry" Monch appears with animations.
2. **Animation Smoke Test:** Use a debug menu or preview to cycle through all 7 mascot states and verify:
   - "Spiking" jitters
   - "Crashing" melts
   - "Sleepy" nods
   - "Neutral" breathes
3. **Sheet Interaction:** Tap the header and verify `MonchView` slides up with the large mascot and actions.
4. **Dark Mode:** Verify colors and gradients in `MonchView` adapt correctly to dark/light mode.
