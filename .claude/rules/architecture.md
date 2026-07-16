---
globs:
  - "lib/**/*.dart"
  - "test/**/*.dart"
---

# Architecture & Naming Guidelines
- Feature-First Clean Architecture structure: `presentation → domain ← data`.
- Each feature must be contained in its own folder under `lib/features/` containing `data/`, `domain/`, and `presentation/` layers.
- Code against abstract repositories in `domain/repositories`; do not assume local or cloud implementation is active (swapped dynamically based on Auth state).
- File structure conventions:
  - Data: `data/datasources/`, `data/models/`, `data/repositories/`
  - Domain: `domain/entities/`, `domain/repositories/`, `domain/services/`
  - Presentation: `presentation/providers/`, `presentation/screens/`, `presentation/widgets/`
