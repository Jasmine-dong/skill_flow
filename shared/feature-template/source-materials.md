# 输入素材归档

## 调用原文

待补充用户调用时提供的原文。

## 材料识别

用于批量材料或整合材料拆分。没有批量/整合材料时可写 `not_applicable`。

### 材料字段

- `material_type`: `prd`、`api_doc`、`test_case`、`ui_design`、`product_illustration` 或 `unknown`
- `usable_for_ui_acceptance`: `true` 仅表示可作为 UI 验收/设计走查依据；产品示意图、业务配图或概念图必须为 `false`
- `confidence`: `high`、`medium` 或 `low`
- `user_confirmed`: 使用者是否明确确认该材料类型或用途

用户纠正优先级最高。比如使用者说明“配图是产品示意图，不是 UI 设计”时，必须记录为 `material_type=product_illustration`、`usable_for_ui_acceptance=false`、`user_confirmed=true`，不得再用该材料触发 UI 验收。

### 批量材料

| source | material_type | target | usable_for_ui_acceptance | confidence | user_confirmed | status | notes |
|---|---|---|---|---|---|---|---|
|  | prd | `brief.md` | false | high | false | pending |  |
|  | api_doc | `api.openapi.yaml` | false | high | false | pending |  |
|  | test_case | `test/cases.md` | false | high | false | pending |  |
|  | ui_design | `design/source.md` | true | high | false | pending |  |
|  | product_illustration | `brief.md` | false | medium | false | pending |  |

### 整合材料拆分

| source | section_or_range | material_type | target | usable_for_ui_acceptance | confidence | user_confirmed | status | notes |
|---|---|---|---|---|---|---|---|---|
|  |  | prd | `brief.md` | false | high | false | pending |  |
|  |  | api_doc | `api.openapi.yaml` | false | high | false | pending |  |
|  |  | test_case | `test/cases.md` | false | high | false | pending |  |
|  |  | ui_design | `design/source.md` | true | high | false | pending |  |
|  |  | product_illustration | `brief.md` | false | medium | false | pending |  |

### 待确认材料

- source:
  reason:
  question:

## 需求文档

- source:
- material_type: prd
- usable_for_ui_acceptance: false
- confidence:
- user_confirmed: false
- target: `brief.md`
- status: pending
- notes:

## 接口文档

- source:
- material_type: api_doc
- usable_for_ui_acceptance: false
- confidence:
- user_confirmed: false
- target: `api.openapi.yaml`
- status: pending
- notes:

## 测试 Case

- source:
- material_type: test_case
- usable_for_ui_acceptance: false
- confidence:
- user_confirmed: false
- target: `test/cases.md`
- status: pending
- notes:

## 设计稿

- source:
- material_type: ui_design
- usable_for_ui_acceptance: true
- confidence:
- user_confirmed: false
- target: `design/source.md`
- status: pending
- notes:

## 产品示意图

- source:
- material_type: product_illustration
- usable_for_ui_acceptance: false
- confidence:
- user_confirmed: false
- target: `brief.md`
- status: pending
- notes:

## 处理记录

- at:
  role:
  action:
  result:
