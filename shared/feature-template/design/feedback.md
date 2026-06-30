# UI Feedback

## Scope

- Feature:
- Stage: development
- Rule: development UI feedback only; QA/UAT/release/production defects must use `bugs/`.
- Status handling: in-phase fixes keep current `phase / next`; update `status.yaml` only when the feedback round is closed or workflow is blocked.

## Feedback Items

| ID | Source | Screenshot / Link | Page / Area | Feedback | Severity | In-Phase Fix | Status | Owner | Notes |
|---|---|---|---|---|---|---|---|---|---|
| UI-FB-001 | user |  |  |  | minor | true | pending | frontend-agent |  |

## Decisions

- 

## Handoff

```yaml
handoff:
  role: frontend-agent
  state: completed
  summary: ""
  deliverables:
    - design/feedback.md
  changed_files: []
  impact_scope: []
  suggested_tests: []
  known_risks: []
  blockers: []
  next_recommended:
    role: null
    reason: ""
```
