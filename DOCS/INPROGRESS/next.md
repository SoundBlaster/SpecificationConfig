# Next Task: B5 — Add Redaction Support

**Source:** PRD Phase B
**Priority:** Medium
**Phase:** B
**Effort:** M (½–1d)
**Dependencies:** B4 (completed)
**Status:** Selected

## Description

Create formal redaction support and utilities to ensure sensitive configuration values (secrets) are properly redacted in diagnostics, snapshots, and logs.

While redaction has been implemented inline in previous tasks (B1 Binding's isSecret flag, B3 Snapshot's displayValue, B4 DiagnosticItem's redaction), this task formalizes and consolidates the pattern:

- Create `Redaction.swift` with helper types/functions
- Standardize redaction marker (currently "[REDACTED]")
- Document best practices for handling secrets
- Add comprehensive tests for redaction scenarios
- Ensure consistency across all types that display values

## Next Step

Run PLAN to generate an implementation-ready task PRD for this item.
