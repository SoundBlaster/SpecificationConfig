# Next Task: B3 — Define Snapshot Model

**Source:** PRD §5.2, Phase B
**Priority:** High
**Phase:** B
**Effort:** M (½–1d)
**Dependencies:** B1 (completed)
**Status:** Selected

## Description

Define the `Snapshot` model that captures the resolved configuration state including values, provenance (source), and diagnostics. This provides visibility into where each configuration value came from and supports debugging/observability.

The Snapshot holds:
- Resolved values (stringified & redacted for secrets)
- Resolved source/provenance (which provider supplied each value)
- Timing information (optional)
- List of diagnostics items (errors/warnings)

## Next Step

Run PLAN to generate an implementation-ready task PRD for this item.
