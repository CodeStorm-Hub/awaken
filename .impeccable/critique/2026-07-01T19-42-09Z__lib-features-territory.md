---
target: "J:\\GitHub\\awaken\\lib\\features\\territory"
total_score: 18
p0_count: 0
p1_count: 4
timestamp: 2026-07-01T19-42-09Z
slug: lib-features-territory
---
## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 2 | The run/map HUD is busy, and the meaning of several overlays competes instead of clarifying. |
| 2 | Match System / Real World | 3 | Strong physical metaphor, but some labels skew too gamey for a real outdoor task. |
| 3 | User Control and Freedom | 2 | Back/discard flows and follow-me toggles are functional but easy to miss. |
| 4 | Consistency and Standards | 2 | The territory shell and app shell patterns feel split, and the navigation voice differs slightly. |
| 5 | Error Prevention | 2 | Location/auth/performance failures are handled, but not surfaced early or distinctly enough. |
| 6 | Recognition Rather Than Recall | 2 | A few critical actions are hidden behind icons, dialogs, or map gestures. |
| 7 | Flexibility and Efficiency | 2 | Good raw power, but the UI doesn't separate novice guidance from power-user control. |
| 8 | Aesthetic and Minimalist Design | 2 | Dense overlays, cards, and glow treatments create visual congestion on small screens. |
| 9 | Error Recovery | 2 | Recovery paths exist, but they are too quiet when the user is under pressure. |
| 10 | Help and Documentation | 1 | The flow lacks enough inline guidance for first-time runners and offline users. |
| **Total** | | **18/40** | **Needs focused UX simplification** |

## Anti-Patterns Verdict

**LLM assessment:** The territory feature feels ambitious and differentiated, but it is also the most visually overworked area in the app. The map, overlays, side rails, and HUD pieces compete for attention, and the app leans on repeated dark cards and tiny tracked labels to unify them. That keeps it coherent, but the tradeoff is higher cognitive load and weaker hierarchy.

**Deterministic scan:** The detector returned a clean result for `lib/features/territory` (`[]`). No rule hits were emitted, so the critique is based on source/UI structure rather than automated slop flags.

## Overall Impression

The territory feature is the app's most distinctive idea and the riskiest UI at the same time. The map-first experience has real energy, but the screen composition needs to calm down so the user can understand where to look first and what action matters most.

## What's Working

- The territory map and neon polygon system are memorable and clearly on-brand.
- The run lifecycle has strong feedback moments when states change.
- The leaderboard and decay systems give the feature long-term motivation.

## Priority Issues

- **[P1] Run screen is visually overloaded**: Map, top bar, right rail, stats sheet, banners, and start/stop control all compete at once. **Why it matters:** the user needs a quick read of state while moving outdoors, often in poor light and motion. **Fix:** reduce the number of simultaneous overlays, simplify the HUD hierarchy, and let one primary control dominate.
- **[P1] Instruction and recovery states are too quiet**: locating, permission denial, offline play, and discard confirmations are readable in code but not strongly legible in the UI. **Why it matters:** first-time users can mistake a waiting state for a failure. **Fix:** add clearer guidance, stronger state labeling, and a more obvious fallback path.
- **[P1] Leaderboard presentation is too generic compared to the run screen**: the podium and tiles work, but they flatten the feature's energy and read like a standard ranking view. **Why it matters:** the territory concept should feel competitive and spatial, not like a plain list. **Fix:** strengthen the personal-relevance cues, clean up the podium, and make nearby/global mode more explanatory.
- **[P1] Navigation and shell consistency drift**: territory routing and shell structure are not visually or architecturally unified with the rest of the app. **Why it matters:** the feature feels stitched in rather than fully part of one coherent mobile system. **Fix:** standardize the shell pattern and make the territory entry points feel intentional.
- **[P2] Motion and glow are used everywhere, not selectively**: the pulsing indicators, glow rings, rail buttons, and map overlays all fight for attention. **Why it matters:** state emphasis loses power when everything is emphasized. **Fix:** reserve motion for only the most critical state transition per screen.

## Persona Red Flags

**Jordan (First-Timer)**
- The territory run screen assumes they already understand follow-me, capture, and loop closure.
- The sign-in/offline decision is buried inside a modal at the exact moment they want to start moving.
- The leaderboard empty state is too thin to teach the mode.

**Alex (Power User)**
- The run HUD is information-rich but not scannable enough for quick outdoor use.
- Map rail controls are compact, but their purpose is not explained.
- The leaderboard and run result banners feel less efficient than the rest of the feature.

**Mia (High-Stakes / In-Motion User)**
- Small labels in the run stats sheet are hard to parse while walking or running.
- The discard dialog and error banner compete with map context instead of landing as decisive guidance.

## Minor Observations

- `RunStatsSheet` is the weakest readability point because it relies on blur plus small text.
- The red/blue point markers are clear, but they are visually similar to other accent elements.
- The podium medals feel a little playful compared with the otherwise disciplined system.
- `Reachability`/location loading needs a more explicit promise of what will happen next.

## Questions to Consider

- What if the run screen had one obvious hero state instead of four or five competing layers?
- Would the territory experience feel more confident if the overlay language were cut by half?
- Should nearby/global leaderboard be more educational, or more competitive, on first open?
