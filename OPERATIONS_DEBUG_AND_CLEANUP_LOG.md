# Dosifi Operations, Debugging, and Cleanup Log

This document captures operational history, known issues and fixes, debugging playbooks, and post-cleanup status. It consolidates prior cleanup and analysis reports.

Contents
- Operational history highlights
- Debugging playbooks
- Known issues and fixes
- Cleanup outcomes and rationale
- Navigation and accessibility (summary)
- Agent/MCP usage notes

Operational history highlights
- Major refactors completed; removed unused code and stabilized scheduling and notifications.
- Database structure audited; indices added for DoseEvent queries by medication and time.
- Accessibility pass completed for core flows.

Debugging playbooks
- Notifications
  - Verify OS permission and battery/background settings.
  - Reconcile schedules on timezone changes; trigger manual reschedule.
- Schedule generation
  - Enable verbose logging around rule evaluation and event creation.
  - Check invariant: no duplicate events for same medicationId+scheduledAt.
- Crash/ANR
  - Collect device logs with flutter logs; correlate with reproduction steps.

Known issues and fixes
- Fixed race conditions when rescheduling notifications during rapid edits of a medication.
- Resolved null edge cases in medication form dynamic fields.
- Addressed localization of dosage units and formatting.

Cleanup outcomes and rationale
- Removed legacy notification helper; replaced with unified NotificationService.
- Consolidated schedule calculators into a single deterministic generator.
- Archived analysis docs under docs/archive/ for provenance.

Navigation and accessibility (summary)
- Ensured focus order and semantic labels for form fields and action buttons.
- Large tap targets and clear error messaging; supports TalkBack.
- Full report retained in docs/archive/NAVIGATION_ACCESSIBILITY_REPORT.md.

Agent/MCP usage notes
- Service extension ext.dosifi.screenshot available in debug/profile.
- Use dart tool/mcp_capture.dart --vm-service-url ws://... --out screenshots/<name>.png.
- Prefer emulator-5554 for deterministic captures.

