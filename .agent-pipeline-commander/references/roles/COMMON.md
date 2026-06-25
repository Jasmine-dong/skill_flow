# 角色通用规则

所有角色都必须遵守这些规则。

## 项目画像

- 每次执行任何 feature 任务前，都必须先读取 `pipeline.project.yaml`
- `pipeline.project.yaml` 必须通过 `knowledge.project_details` 指向项目画像文件，例如 `lightweight-pipeline/project-details.md`
- 如果项目画像文件不存在，不能进入 feature 开发流程；必须先扫描项目并生成项目画像，交由使用者确认后再继续
- 所有角色执行前都必须读取项目画像，并以它作为项目结构、技术栈、命令、封装方式、测试入口和已知坑点的事实源
- 项目画像只记录可复用项目事实，不记录一次性需求细节、未验证猜测或临时调试过程
- 每次开发、测试或验收结束后，如果发现新的可复用项目事实，必须补充到项目画像的对应章节和 Update Log
- 如果开发中发现项目画像与真实代码、命令或项目结构冲突，必须废弃当前推进步骤，不得继续开发
- 发现项目画像冲突时，将 `features/<feature-id>/status.yaml` 的 `phase` 改为 `project_rescan_required`，`next` 改为 `product-agent`，在 `blockers` 写明冲突证据和需要重扫的范围
- 进入 `project_rescan_required` 后，必须重新扫描项目、更新项目画像，并在使用者确认后重新开启当前 feature 流程

## 遇到问题或不确定时

- 遇到需求、范围、接口、设计、测试、环境、权限、数据或验收标准不确定时，先向使用者发起确认
- 使用者确认或补充信息后，才能继续执行相关任务
- 不要基于猜测补齐产品规则、接口字段、视觉细节、验收结论或测试通过结论
- 如果确认前无法继续，把问题写入 `features/<feature-id>/status.yaml` 的 `blockers`
- 提问要具体，说明缺什么、为什么会阻塞、需要使用者确认哪几个点
- 如果可以安全推进无争议部分，只处理无争议部分；有争议部分必须等待确认
- 使用者确认后，继续任务时要把确认内容记录到对应产物或 `status.history`

## 状态推进

- 只有当前角色职责内的产物完成，且门禁满足时，才能推进 `status.yaml`
- 遇到阻塞或验证失败时，不要强行推进
- 每次修改 `status.yaml` 都必须追加 `history`

## Chat Status Protocol

所有角色在聊天界面必须输出状态事件，让使用者能直接看到当前流程进展。

### 开始任务时

执行角色任务前，先输出：

```text
[开始] <role>
Feature：<feature-id>
Phase：<current-phase>
本轮目标：<本次要完成的事情>
状态处理：
- 已读取 COMMON.md、角色卡、pipeline.project.yaml、项目画像和 status.yaml
- 将按当前 phase / next 门禁执行
```

### 遇到阻塞时

遇到问题或不确定，且需要使用者确认后才能继续时，输出：

```text
[阻塞] <role>
Feature：<feature-id>
Phase：<current-phase>
阻塞原因：<为什么无法继续>
需要使用者确认：
1. <问题一>
2. <问题二>
状态处理：
- 已写入 status.yaml blockers
- 已追加 activity.md
- 不推进 phase / next
```

### 完成任务时

当前角色任务完成，且门禁检查通过或已明确下一步时，输出：

```text
[完成] <role>
Feature：<feature-id>
Phase：<new-or-current-phase>
完成内容：
- <完成项一>
- <完成项二>
产物：
- <产物路径一>
- <产物路径二>
交接：
- 摘要：<给下一角色的一句话结论>
- 影响范围：<页面 / 接口 / 数据 / 流程 / 测试范围>
- 建议测试点：<建议 Test 或下游优先检查的点>
- 已知风险：<未覆盖项、限制或待观察风险；没有则写无>
下一步：
- <下一角色或下一状态>
状态处理：
- 已追加 activity.md
- 已更新 status.yaml history
- next = <next-role-or-none>
```

### 记录要求

- 不输出百分比或进度条；只输出开始、阻塞、完成三类状态事件
- 每次输出 `[阻塞]` 或 `[完成]` 时，都必须同步追加 `features/<feature-id>/activity.md`
- 如果当前 feature 还没有 `activity.md`，先创建再追加
- `[开始]` 事件推荐追加到 `activity.md`；如果只是读取上下文且未进入实际任务，可以只在聊天界面输出
- 状态事件必须反映真实文件变更；不能声称已写入未实际写入的文件

## Handoff 标准

每个角色完成任务时，必须在自己的主要产物中写入 `## Handoff` 章节；聊天界面的 `[完成]` 状态只摘出简版交接。

### 通用字段

```yaml
handoff:
  role: <role>
  state: completed | blocked | needs_fix | accepted
  summary: <一句话说明本角色结论>
  deliverables:
    - <本角色产物路径>
  changed_files:
    - <真实修改过的代码或文档路径；没有则为空数组>
  impact_scope:
    - <受影响页面、接口、数据、流程、权限、测试范围或用户路径>
  suggested_tests:
    - <建议下游或 Test 优先验证的点>
  known_risks:
    - <未覆盖项、环境限制、数据限制、待观察风险；没有则为空数组>
  blockers:
    - <仍阻塞推进的问题；没有则为空数组>
  next_recommended:
    role: <next role or none>
    reason: <为什么建议交给该角色或进入该阶段>
```

### 写入位置

- `product-agent` 写入 `brief.md`、`confirmations/development-confirmation.md` 或产品验收记录中的 `## Handoff`
- `backend-agent` 写入 `backend/notes.md` 的 `## Handoff`
- `frontend-agent` 写入 `frontend/integration.md` 的 `## Handoff`
- `designer-agent` 写入 `design/ui-review.md` 的 `## Handoff`
- `test-agent` 写入对应测试报告的 `## Handoff`

### 角色重点字段

- Product 重点补充 `requirement_scope`、`open_questions_resolved`、`acceptance_criteria`
- Backend 重点补充 `api_changes`、`data_changes`、`contract_notes`
- Frontend 重点补充 `changed_views`、`api_dependencies`、`ui_states`
- Designer 重点补充 `ui_findings`、`severity_summary`、`pass_or_fix_needed`
- Test 重点补充 `tested_scope`、`failed_cases`、`untested_risks`、`quality_gate`
