# Field Alignment Gate

字段级对齐关卡用于闭环追踪“产品字段 -> 接口字段 -> 页面实现 -> mock 覆盖 -> UI 字段巡检”。涉及列表、表单、弹窗、详情页、筛选项或状态展示时必须维护本文件；不涉及字段展示时写 `not_applicable` 和原因。

## Scope

- Feature:
- Pages / modules:
- Source docs:
- Status: draft | ready_for_dev | implemented | checked | blocked | not_applicable

## Requirement Field Checklist

| ID | View Type | UI Area | Field Name | Display Condition | Source API Field | Format Rule | Empty State Rule | Implemented | Has Mock | Notes |
|---|---|---|---|---|---|---|---|---|---|---|
| F-001 | list |  |  |  |  |  |  | no | no |  |

## API Field Mapping

| UI Field | API Field Candidates | Chosen API Field | Required | Transform / Fallback | Missing / Conflict |
|---|---|---|---|---|---|
| 终止原因 | terminateReasonCode / terminateReason / failureSummary |  | yes |  |  |
| 提交时间 | createdAt |  | yes |  |  |
| 更新时间 | updatedAt |  | yes |  |  |

## Implementation Tracking

| Field ID | Code Location | Component / Column Key | Implemented | Reverse Check Result | Notes |
|---|---|---|---|---|---|
| F-001 |  |  | no | not_checked |  |

## Mock Coverage

| Scenario | Required Fields | Covered | Mock Location | Notes |
|---|---|---|---|---|
| 执行中 | 时间字段完整；终止原因为空 | no |  |  |
| 已完成 | 时间字段完整；终止原因为空 | no |  |  |
| 已终止-手动终止 | terminateReasonCode / terminateReason | no |  |  |
| 已终止-平仓失败 | failureSummary / terminateReason | no |  |  |
| 已终止-开仓失败 | failureSummary / terminateReason | no |  |  |

## Reverse Check

- Requirement fields missing in UI:
- UI fields missing in API docs:
- Mock gaps:
- Formatting / empty-state gaps:

## UI Field Inspection

| Check Item | Result | Notes |
|---|---|---|
| 字段是否全 | not_checked |  |
| 顺序是否对 | not_checked |  |
| 文案是否对 | not_checked |  |
| 空态是否对 | not_checked |  |
| 格式是否对 | not_checked |  |
| 条件展示是否对 | not_checked |  |

## Handoff

```yaml
handoff:
  role: product-agent
  state: completed
  summary: ""
  deliverables:
    - field-alignment.md
  changed_files: []
  impact_scope: []
  suggested_tests: []
  validation_evidence: []
  user_feedback_fixes: []
  known_risks: []
  blockers: []
  next_recommended:
    role: null
    reason: ""
  field_alignment:
    status: draft
    missing_ui_fields: []
    missing_api_fields: []
    mock_gaps: []
```
