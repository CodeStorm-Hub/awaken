# User Stories



### 1. Track the Run

> **As a** runner,
> **I want to** see my live location on a map and record my path when I start jogging,
> **So that** the app accurately knows the route I took.

* **Simple Acceptance Criteria:**
* The user taps a "Start" button to begin tracking GPS coordinates.
* The map draws a line tracking their live path.
* The user can tap a "Stop" button to finish the run.
* *Anti-Cheat:* If the user moves faster than a running pace (e.g., >25 km/h), the run is flagged or invalidated.



### 2. Claim & Expand Territory (The Closed Loop)

> **As a** runner,
> **I want to** finish my run within a few meters of where I started it,
> **So that** the app encloses that path and marks that area as mine.

* **Simple Acceptance Criteria:**
* When "Stop" is pressed, the backend checks if the final GPS coordinate is within 20 meters of the starting GPS coordinate.
* If **yes**, the map fills the inside of that loop with the user's color.
* If this new loop touches or overlaps territory the user *already* owns, the two areas merge into one larger continuous shape.
* If **no** (the loop didn't close), the run counts as a normal workout but no territory is claimed.



### 3. Steal Rival Territory (The Takeover)

> **As a** competitive runner,
> **I want to** complete a closed loop that overlaps a rival's colored territory,
> **So that** I instantly steal that overlapping portion away from them.

* **Simple Acceptance Criteria:**
* When a user successfully closes a loop, the system checks for intersections with other players' shapes.
* Any area where the shapes overlap is instantly subtracted from the rival and added to the runner.
* The map colors update instantly to reflect the new boundaries.



### 4. The Leaderboard

> **As a** player,
> **I want to** see a list of top players ranked by the size of their land,
> **So that** I know who the dominant runners are in my area.

* **Simple Acceptance Criteria:**
* A simple list view showing usernames ranked from highest to lowest.
* The ranking metric is purely the total square mileage or kilometers currently owned by each user.



---

## The Simplified Game Flow

```
      [ Start Run ]
            │
            ▼
     [ Jog a Route ]
            │
            ▼
     [ Press 'Stop' ]
            │
    (Is it a closed loop?)
       ├── NO  ──► Save workout stats only.
       │
       └── YES ──► [ Calculate Shapes ]
                         │
                         ├── Overlaps empty map? ──► Claim it.
                         ├── Overlaps own map?   ──► Merge it.
                         └── Overlaps rival map? ──► Steal it!

```



---

## Critical Mechanic Refinements (Edge Cases to Solve)

Before writing code, you need to define the exact rules of engagement. Location games can be easily broken if the rules are too loose.

* **The "Drive-by" Cheat:** What prevents someone from turning on your app while driving a car or riding a bike to claim an entire city?
* *Solution:* Implement speed caps. If the user's velocity exceeds 20–25 km/h for more than a few seconds, invalidate the run or pause tracking.


* **The "GPS Drift" Nightmare:** GPS naturally drifts, especially around high-rise buildings. A jagged, drifting line could create accidental overlapping loops.
* *Solution:* Use a path-snapping or path-smoothing algorithm (like a Kalman filter) before validating the final polygon shape.


* **The "Dead Zone" Problem:** If a user claims a massive park and then moves to a different country, they shouldn't own that park forever.
* *Solution:* Introduce **Territory Decay**. If a user doesn't run through or near their territory once every 7 days, its boundaries begin to shrink, or it becomes "Neutral Gray" for anyone to claim easily.



---

## Suggested Feature Improvements

To make the app highly addictive, consider adding these elements:

* **Fog of War:** When a user opens the map for the first time, the entire world is covered in mist. Jogging literally clears the mist, revealing landmarks, roads, and rival territories.
* **Fortresses / Home Base:** Allow users to designate a specific area (like their home or office) as a "Headquarters." This area requires a rival to run through it multiple times to flip ownership, acting as a defensive shield.
* **Team Mode (Factions):** Instead of just solo players, users can join teams (e.g., Team Red vs. Team Blue). The leaderboard tracks which faction dominates a city, encouraging community building and group runs.

---
