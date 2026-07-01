# BRIEFING — 2026-07-01T12:40:00Z

## Mission
Coordinate the team to implement the Territory Capture feature for the Awaken Flutter app, meeting all requirements of R1-R6.

## 🔒 My Identity
- Archetype: teamwork_preview_orchestrator
- Roles: orchestrator, user_liaison, human_reporter, successor
- Working directory: c:\Users\afsan\Workspace\awaken\.agents\orchestrator
- Original parent: parent
- Original parent conversation ID: 8edeef84-7562-44ce-84ee-ee72e61be321

## 🔒 My Workflow
- **Pattern**: Project
- **Scope document**: PROJECT.md
1. **Decompose**: Decompose the project into milestones (M1–M7) mapping to different layers (DB, data repositories, map view UI, and anti-cheat, decay service).
2. **Dispatch & Execute**:
   - **Delegate (sub-orchestrator)**: Spawn sub-orchestrators for milestones or run the Explorer -> Worker -> Reviewer -> Challenger -> Auditor cycle.
3. **On failure** (in this order):
   - Retry: nudge stuck agent or re-send task
   - Replace: spawn fresh agent with partial progress
   - Skip: proceed without (only if non-critical)
   - Redistribute: split stuck agent's remaining work
   - Redesign: re-partition decomposition
   - Escalate: report to parent (sub-orchestrators only, last resort)
4. **Succession**: Self-succeed at 16 spawns, write handoff.md, spawn successor.
- **Work items**:
  1. Initialize Workspace Metadata [in-progress]
  2. Setup E2E Test Suite [pending]
  3. Database Schema Setup [pending]
  4. Swappable Offline/Online Repository [pending]
  5. Steal Rival Territory / Contestation [pending]
  6. Decay & Decay Warnings [pending]
  7. UI Polish, Zoom Controls, Dark Tiles, Leaderboard toggle [pending]
- **Current phase**: 1
- **Current focus**: Workspace Initialization

## 🔒 Key Constraints
- NEVER write, modify, or create source code files directly.
- NEVER run build/test commands yourself — require workers to do so.
- You MAY use file-editing tools ONLY for metadata/state files (.md) in your .agents/ folder.

## Current Parent
- Conversation ID: 8edeef84-7562-44ce-84ee-ee72e61be321
- Updated: not yet

## Key Decisions Made
- Initialized briefing and plan.

## Team Roster
| Agent | Type | Work Item | Status | Conv ID |
|-------|------|-----------|--------|---------|
| sub_orch_e2e | self | M1: Test Infra & Suite Setup | in-progress | 95e24134-f678-49a4-a9f4-9cf3e69d7f18 |

## Succession Status
- Succession required: no
- Spawn count: 1 / 16
- Pending subagents: [95e24134-f678-49a4-a9f4-9cf3e69d7f18]
- Predecessor: none
- Successor: not yet spawned

## Active Timers
- Heartbeat cron: task-71
- Safety timer: none
- On succession: kill all timers before spawning successor
- On context truncation: run manage_task(Action="list") — re-create if missing

## Artifact Index
- c:\Users\afsan\Workspace\awaken\.agents\orchestrator\BRIEFING.md — Persistent memory briefing file.
- c:\Users\afsan\Workspace\awaken\.agents\orchestrator\plan.md — Detailed orchestrator plan.
- c:\Users\afsan\Workspace\awaken\.agents\orchestrator\progress.md — Milestones and task progress status tracker.
- c:\Users\afsan\Workspace\awaken\.agents\orchestrator\context.md — Context and current state of the codebase.
