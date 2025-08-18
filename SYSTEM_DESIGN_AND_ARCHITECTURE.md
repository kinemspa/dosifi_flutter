# Dosifi System Design and Architecture

This document is the single source of truth for Dosifi’s architecture, data model, navigation, and domain logic. It consolidates prior materials including the technical design, architecture matrices, and medication tracking/type breakdowns.

Contents
- Overview and goals
- Architecture overview
- Component map and responsibilities
- State management and navigation
- Data model and persistence
- Domain model: medication types, formulas, and UI rules
- Integrations and extension points
- Non-functional requirements
- Appendices

Overview and goals
- Reliable, accessible medication tracking with clear auditability and predictable schedules.
- Maintainable Flutter codebase with modular layers (presentation, application/services, domain, data).
- Strong developer ergonomics (fast iteration, clear diagnostics, well-defined contracts between layers).

Architecture overview
- Platform: Flutter (Android primary), with support for web/desktop where feasible for dev tooling.
- Layers:
  - Presentation: Widgets, screens, navigation, accessibility semantics.
  - Application/Services: Use cases, coordinators, background tasks, notifications.
  - Domain: Medication entities, dosage rules, validation, schedule generation.
  - Data: Persistence (SQLite/Isar/SharedPreferences as applicable), repositories, data sources.
- Cross-cutting concerns: Logging, error handling, analytics (if enabled), feature flags.

Component map and responsibilities
- Screens
  - Home/Dashboard: overview of upcoming doses, adherence status.
  - Medication List and Detail: CRUD, active/inactive states.
  - Medication Form: guided input with validation and type-specific rules.
  - Schedule/History: calendar or timeline of doses with completion states.
- Services
  - NotificationService: schedules/cancels local notifications; idempotent scheduling.
  - ScheduleService: computes future doses from medication rules; resolves conflicts.
  - Backup/Export (if present): exports data for support.
- Data
  - Repository interfaces: MedicationRepository, DoseRepository, SettingsRepository.
  - Storage: normalized tables/collections described below.

State management and navigation
- Navigation: Typed route definitions; deep links to specific meds or forms when applicable.
- State: Prefer immutable state objects in view models/controllers; minimize global mutable state.
- Accessibility: Each navigable page defines semantics, labels for controls, and focus order. Critical flows (add/edit medication, confirm dose) are fully keyboard and TalkBack accessible.

Data model and persistence
- Core entities
  - Medication { id, name, type, strength, unit, notes, isActive, createdAt, updatedAt }
  - Regimen/ScheduleRule { id, medicationId, frequencyType, interval, timesOfDay[], daysOfWeek[], startDate, endDate, prn }
  - DoseEvent { id, medicationId, scheduledAt, status (scheduled|taken|skipped|missed), takenAt, notes }
  - Settings { timezone, notificationPrefs, accessibilityPrefs }
- Indices
  - DoseEvent: (medicationId), (scheduledAt), compound (medicationId, scheduledAt)
  - Medication: (isActive), (name)
- Invariants
  - For active meds, future DoseEvents are generated up to a configurable horizon (e.g., 30–60 days).
  - ScheduleRule defines recurrence; generator is deterministic and idempotent.
  - Status transitions: scheduled → taken/skipped/missed; taken has takenAt not null.

Domain model: medication types, formulas, and UI rules
- Types and examples (consolidated from medication matrices):
  - Tablet/Capsule: strength per unit; dose = units * strength.
  - Liquid: concentration (mg/mL); dose = volume * concentration.
  - Insulin/Injectable: units with timing relative to meals; hypoglycemia safeguards.
  - Inhaler/Nasal: puffs per event with max daily limits.
- UI constraints
  - Contextual fields by type (e.g., volume vs units), dynamic validation messages, and safe defaults.
  - Preview section showing computed dose (e.g., “Total: 10 mg from 2 x 5 mg tablets”).
  - Guardrails: max dose/day warnings; confirmation modals for edge cases.

Integrations and extension points
- Local notifications: grouped by medication; tap action routes to confirmation screen.
- Service extensions (debug/profile only) for MCP/agent integrations (e.g., ext.dosifi.screenshot).
- Feature flags (e.g., experimental schedule generator v2) are read from config and can be toggled per-build.

Non-functional requirements
- Performance: schedule generation should handle O(1000) DoseEvents within 200ms on mid-tier devices.
- Reliability: notification schedule reconciles on timezone change or missed runs.
- Accessibility: WCAG AA where feasible; tested with TalkBack.
- Observability: structured logs for schedule generation and notification enqueue.

Appendices
- Architecture matrix: see docs/archive/DOSIFI_ARCHITECTURE_MATRIX.md (if present).
- Medication matrices: see docs/archive/MEDICATION_TRACKING_MATRIX.md and docs/archive/MEDICATION_TYPES_BREAKDOWN.md.

