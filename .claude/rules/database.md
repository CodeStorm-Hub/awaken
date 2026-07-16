---
globs:
  - "supabase/**/*.sql"
  - "lib/features/**/data/**/*.dart"
---

# Database (Supabase) Guidelines
- RLS (Row-Level Security) is enabled on all user tables (alarms, sessions, streaks, territory tables).
- Queries/inserts must be restricted to user-owned data using `auth.uid()`.
- Use security definer functions carefully. Revoke public/anon execute access unless explicitly required.
- Do not commit Google Client IDs or Supabase secrets; use environment configurations.
