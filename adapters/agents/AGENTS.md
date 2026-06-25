# Pipeline Commander

当用户说“推进 <feature-id>”、“看下 <feature-id> 下一步”、“继续这个功能”或“跑一下当前工作流”时，使用本项目的 Pipeline Commander 流程。

## 资源位置

资源安装在当前项目的 `.agent-pipeline-commander/`：

- `.agent-pipeline-commander/references/tasks.yaml`：内置任务和 workflow 状态机
- `.agent-pipeline-commander/references/roles/COMMON.md`：所有角色通用规则
- `.agent-pipeline-commander/references/roles/<agent>.md`：角色卡片
- `.agent-pipeline-commander/assets/pipeline.project.yaml.example`：项目绑定配置模板
- `.agent-pipeline-commander/assets/project-details.md`：项目画像模板
- `.agent-pipeline-commander/assets/feature-template/status.yaml`：功能包状态模板
- `.agent-pipeline-commander/assets/feature-template/brief.md`：功能说明模板
- `.agent-pipeline-commander/assets/feature-template/activity.md`：功能流程事件记录模板
- `.agent-pipeline-commander/assets/feature-template/bugs/BUG-001.md`：送测 Bug 记录模板
- `.agent-pipeline-commander/assets/feature-template/commit/notes.md`：提交记录模板

## 执行规则

1. 解析用户给出的功能 ID，例如 `2026-05-25--greeting`
2. 从当前目录向上查找并读取项目根目录的 `pipeline.project.yaml`
3. 读取 `knowledge.project_details` 指向的项目画像；不存在时先扫描项目并生成项目画像，使用者确认后再进入 feature 流程
4. 读取 `features.root/<feature-id>/status.yaml`
5. 读取 `.agent-pipeline-commander/references/tasks.yaml`
6. 用 `status.workflow + status.phase + status.next` 查找下一步任务
7. 读取任务指定的 `.agent-pipeline-commander/references/roles/<agent>.md`
8. 临时扮演该角色完成任务
9. 完成后补充可复用项目事实，检查门禁，再推进 `status.yaml`

## 硬规则

- 用户不需要直接选择角色，除非他明确指定
- 不跳过 `phase` / `next` 门禁
- 当前任务不匹配时，停止并说明当前应该由哪个角色处理
- 角色只能修改自己职责范围内的产物
- 所有角色都必须先读取 `.agent-pipeline-commander/references/roles/COMMON.md`，再读取自己的角色卡
- 遇到问题或不确定时，必须向使用者发起确认；使用者确认或补充后才能继续
- 每次执行 feature 前必须读取项目画像；发现项目画像与真实项目冲突时，进入 `project_rescan_required` 并停止当前流程
- 遇到阻塞时写入 `blockers`，不要强行推进
- 每次推进状态必须追加 `history`
- `workflows.done_next` 是默认下一角色；任务步骤写明条件分支时，以条件分支设置的 `next` 为准
- 所有角色必须遵守 Chat Status Protocol：在聊天界面输出 `[开始]`、`[阻塞]`、`[完成]` 三类状态事件；不输出百分比或进度条
- 输出 `[阻塞]` 或 `[完成]` 时，必须同步追加 `features/<feature-id>/activity.md`
- 所有角色完成任务时，必须在自己的主要产物中写入 `## Handoff`，并在 `[完成]` 状态中摘出简版交接
- 用户提交送测 Bug 时，先写入 `features/<feature-id>/bugs/<bug-id>.md`，再将 `status.phase` 设为 `bug_triage`、`status.next` 设为 `test-agent`，交由 Test 分诊；不要直接让实现角色修复未分诊 Bug
- 用户明确要求“提交代码、生成 commit、先 commit、提交当前进度、同步外部 Bug 备注”时，临时使用 `commit-agent`；这是可插入动作，不默认推进 `phase / next`
- `commit-agent` 提交前必须让使用者确认 commit message 和文件范围；checkpoint 提交只提示已完成内容

## 项目首次使用

如果当前项目没有 `pipeline.project.yaml`：

1. 参考 `.agent-pipeline-commander/assets/pipeline.project.yaml.example` 在项目根目录创建 `pipeline.project.yaml`
2. 根据真实项目调整 `knowledge.project_details`、`features.root`、`apps.backend.path`、`apps.frontend.path`
3. 如果项目画像不存在，参考 `.agent-pipeline-commander/assets/project-details.md` 扫描并生成 `knowledge.project_details` 指向的文件
4. 使用者确认项目画像后，创建功能包目录：`<features.root>/<feature-id>/`
5. 参考 `.agent-pipeline-commander/assets/feature-template/status.yaml` 创建 `status.yaml`
6. 参考 `.agent-pipeline-commander/assets/feature-template/brief.md` 创建 `brief.md`
7. 参考 `.agent-pipeline-commander/assets/feature-template/activity.md` 创建 `activity.md`
8. 需要提交代码时，参考 `.agent-pipeline-commander/assets/feature-template/commit/notes.md` 创建 `commit/notes.md`

## 素材输入格式

用户可以在调用时提供：

```text
需求文档：docs/prd.md
接口文档：docs/api.md
测试case：docs/cases.md
设计稿：https://figma.com/...
材料：
- docs/prd.md：需求文档
- docs/api.md：接口文档
- docs/cases.md：测试case
整合材料：docs/all-in-one.md
```

先归档到 `source-materials.md`，再分别整理到 `brief.md`、`api.openapi.yaml`、`test/cases.md`、`design/source.md`。

`材料：` 表示批量材料，必须先逐项识别类型并写入 `source-materials.md` 的“材料识别 / 批量材料”。`整合材料：` 表示单个文件或长文本中混合了需求、接口、测试或设计内容，必须先拆分并写入“材料识别 / 整合材料拆分”。分类或拆分不确定时，先向使用者确认，不要猜测归档。

前端开发阶段 UI 验收是条件流程：有 `design/source.md` 或使用者明确要求 UI 验收时，前端完成后先交给 `designer-agent`；没有设计材料时，前端完成后直接交给 `test-agent` 做前端分段测试，并在 `frontend/integration.md` 记录跳过原因。后续补充设计稿时，可以显式调用 `designer-agent` 或使用 `design-review-only` 单独做 UI 走查。

## 送测 Bug 输入格式

```text
Bug：登录页验证码输错后没有错误提示
关联功能：2026-05-25--greeting
缺陷来源：QA
严重级别：P1
复现步骤：...
期望结果：...
实际结果：...
证据：截图、日志或缺陷单链接
```

先归档到 `bugs/<bug-id>.md`，再进入 `bug_triage`。

也可以提交外部缺陷链接：

```text
Bug链接：https://meegle.example.com/...
Bug平台：meegle
关联功能：2026-05-25--greeting
```

先识别平台和工作项 ID，并写入 `bugs/<bug-id>.md` 的 `external_issue`。如果是 Meegle 且当前环境存在 Meegle MCP，优先调用 MCP 读取工作项详情和评论。读取成功后进入 `bug_triage`；读取失败时写入 `fetch_status` 和 blockers，向使用者索要授权、project_key/work_item_id 或 Bug 正文。

## 提交代码

```text
先提交一下当前进度
```

```text
测试通过了，生成 commit 信息
```

```text
提交并同步 Meegle Bug 备注
```

当用户要求提交代码时，写入 `commit/notes.md`。中途提交使用 `checkpoint`，只标注已完成内容，不推进流程；完成后提交使用 `final`，必须记录验证报告和交付范围。Bug 修复提交时，回写 `bugs/<bug-id>.md`；外部平台可写时同步修复备注，同步失败只记录失败原因，不回滚本地提交。
