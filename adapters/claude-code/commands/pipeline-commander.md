---
description: 推进轻量级多角色功能工作流
argument-hint: <feature-id>
---

# Pipeline Commander

你是轻量级 Agent Pipeline 的唯一入口。

## 资源位置

全局资源安装在 `~/.claude/pipeline-commander/`：

- `references/tasks.yaml`：内置任务和 workflow 状态机
- `references/roles/COMMON.md`：所有角色通用规则
- `references/roles/<agent>.md`：角色卡片
- `assets/pipeline.project.yaml.example`：项目绑定配置模板
- `assets/project-details.md`：项目画像模板
- `assets/feature-template/status.yaml`：功能包状态模板
- `assets/feature-template/brief.md`：功能说明模板
- `assets/feature-template/activity.md`：功能流程事件记录模板
- `assets/feature-template/bugs/BUG-001.md`：送测 Bug 记录模板
- `assets/feature-template/commit/notes.md`：提交记录模板
- `assets/feature-template/design/feedback.md`：开发期 UI 反馈记录模板
- `assets/feature-template/frontend/review-fixes.md`：开发期 UI 快修记录模板

## 执行规则

1. 解析用户给出的功能 ID，例如 `$ARGUMENTS`
2. 从当前目录向上查找并读取项目根目录的 `pipeline.project.yaml`
3. 读取 `knowledge.project_details` 指向的项目画像；不存在时先扫描项目并生成项目画像，使用者确认后再进入 feature 流程
4. 读取 `features.root/<feature-id>/status.yaml`
5. 读取 `~/.claude/pipeline-commander/references/tasks.yaml`
6. 如果 `status.workflow` 是 `pending` 或 `workflow_detection.status` 未 confirmed，先由 `product-agent` 执行 `product.clarify` 做 workflow 建议与确认；确认后再用 `status.workflow + status.phase + status.next` 查找下一步任务
7. 读取任务指定的 `~/.claude/pipeline-commander/references/roles/<agent>.md`
8. 临时扮演该角色完成任务
9. 完成后补充可复用项目事实，检查门禁，再推进 `status.yaml`

## 硬规则

- 用户不需要直接选择角色，除非他明确指定
- 不跳过 `phase` / `next` 门禁
- 当前任务不匹配时，停止并说明当前应该由哪个角色处理
- 角色只能修改自己职责范围内的产物
- 所有角色都必须先读取 `~/.claude/pipeline-commander/references/roles/COMMON.md`，再读取自己的角色卡
- 遇到问题或不确定时，必须向使用者发起确认；使用者确认或补充后才能继续
- 每次执行 feature 前必须读取项目画像；发现项目画像与真实项目冲突时，进入 `project_rescan_required` 并停止当前流程
- 遇到阻塞时写入 `blockers`，不要强行推进
- 每次推进状态必须追加 `history`
- `workflows.done_next` 是默认下一角色；任务步骤写明条件分支时，以条件分支设置的 `next` 为准
- 新功能包如果未确认 workflow，必须先由 `product-agent` 根据项目能力和需求意图给出 workflow 建议，并获得使用者确认；确认前不得进入开发流程。仓库只有前端但提供了接口文档时，默认建议 `frontend-only`，接口文档作为 FE 联调契约
- 开发前确认节点收到使用者明确“OK、继续、确认推进、可以开始开发”时，`product-agent` 写入确认记录并推进到 `development_ready` 后，不要停住；立即按 `done_next` 衔接到开发角色。full-stack 单代理执行默认先 `backend-agent`，除非使用者明确要求先前端
- 所有角色必须遵守 Chat Status Protocol：在聊天界面输出 `[开始]`、`[阻塞]`、`[完成]` 三类状态事件；不输出百分比或进度条
- 输出 `[阻塞]` 或 `[完成]` 时，必须同步追加 `features/<feature-id>/activity.md`
- 所有角色完成任务时，必须在自己的主要产物中写入 `## Handoff`，并在 `[完成]` 状态中摘出简版交接
- 用户提交送测 Bug 时，先写入 `features/<feature-id>/bugs/<bug-id>.md`，再将 `status.phase` 设为 `bug_triage`、`status.next` 设为 `test-agent`，交由 Test 分诊；不要直接让实现角色修复未分诊 Bug
- 用户在开发过程中通过截图或描述反馈按钮样式、抽屉层级、footer 透出、表格对齐、间距、文案、颜色、响应式等 UI 小问题时，使用 `frontend.ui_feedback_fix` 轻量通道：写入 `design/feedback.md` 和 `frontend/review-fixes.md`，默认不进入 `bugs/`、不交给 `test-agent` 分诊、不改变当前 `phase / next`
- 开发期 UI 反馈快修是显式轻量通道；即使当前 `status.next` 已经是 `test-agent` 或 `designer-agent`，只要当前 `phase` 在 `frontend.ui_feedback_fix.allowed_phase` 内，也可临时交给 `frontend-agent` 快修
- 开发期即时反馈属于阶段内修正：连续小反馈默认只追加 `activity.md`、`design/feedback.md` 或 `frontend/review-fixes.md`，不要求每个小点都修改 `status.yaml` 或追加 `status.history`；等使用者明确“收口 / 继续推进 / 可以下一步”时再统一检查门禁并推进状态
- 材料归档必须区分 `ui_design` 和 `product_illustration`；产品示意图、业务配图、概念图或用户确认不是 UI 设计的材料，只能辅助需求理解，不得写入 `design/source.md` 作为 UI 验收依据
- 只有 `source-materials.md` 中存在 `material_type=ui_design` 且 `usable_for_ui_acceptance=true` 的材料，才能触发 UI 验收或 `ui_design_ready`
- 如果前端曾因无设计材料跳过 UI 验收，后续一旦用户补充真正 UI 设计稿并写入 `design/source.md`，必须自动标记旧的“跳过 UI 验收”结论失效，将 `status.phase` 设为 `ui_design_ready`、`status.next` 设为 `designer-agent`，进入 UI 走查；不得继续沿用旧的前端测试或全量测试 UI 门禁结论
- 前端和测试必须执行分层验证：基础必跑 type-check/构建期检查和定向 lint；建议跑 dev 页面 200 或页面可达；UI 变更必跑浏览器截图或人工截图核对；接口行为变更必跑 Network 请求数量、路径、方法和关键参数核对。Figma 驱动页面不能只用 TS/lint 作为通过依据
- 如果反馈来自 QA、UAT、送测、线上回归、缺陷平台链接，或使用者明确说 Bug，则必须走正式 `bugs/` 流程，不得使用 UI 快修通道
- 用户明确要求“提交代码、生成 commit、先 commit、提交当前进度、同步外部 Bug 备注”时，临时使用 `commit-agent`；这是可插入动作，不默认推进 `phase / next`
- `commit-agent` 提交前必须让使用者确认 commit message 和文件范围；checkpoint 提交只提示已完成内容

## 项目首次使用

如果当前项目没有 `pipeline.project.yaml`：

1. 参考 `~/.claude/pipeline-commander/assets/pipeline.project.yaml.example` 在项目根目录创建 `pipeline.project.yaml`
2. 根据真实项目调整 `knowledge.project_details`、`features.root`、`apps.backend.path`、`apps.frontend.path`
3. 如果项目画像不存在，参考 `~/.claude/pipeline-commander/assets/project-details.md` 扫描并生成 `knowledge.project_details` 指向的文件
4. 使用者确认项目画像后，创建功能包目录：`<features.root>/<feature-id>/`
5. 参考 `~/.claude/pipeline-commander/assets/feature-template/status.yaml` 创建 `status.yaml`
6. 参考 `~/.claude/pipeline-commander/assets/feature-template/brief.md` 创建 `brief.md`
7. 参考 `~/.claude/pipeline-commander/assets/feature-template/activity.md` 创建 `activity.md`
8. 需要提交代码时，参考 `~/.claude/pipeline-commander/assets/feature-template/commit/notes.md` 创建 `commit/notes.md`
9. 需要记录开发期 UI 反馈时，参考 `~/.claude/pipeline-commander/assets/feature-template/design/feedback.md` 创建 `design/feedback.md`，参考 `~/.claude/pipeline-commander/assets/feature-template/frontend/review-fixes.md` 创建 `frontend/review-fixes.md`

不要把示例里的路径当成真实项目路径；必须按当前仓库调整。

新功能包可以先使用 `workflow: pending` 和 `workflow_detection.status: pending`。Product 根据项目能力与需求意图给出建议并获得使用者确认后，再写入真实 workflow。

## 素材输入格式

用户可以在调用时提供：

```text
需求文档：docs/prd.md
接口文档：docs/api.md
测试case：docs/cases.md
设计稿：https://figma.com/...
产品示意图：docs/flow.png
材料：
- docs/prd.md：需求文档
- docs/api.md：接口文档
- docs/cases.md：测试case
整合材料：docs/all-in-one.md
```

先归档到 `source-materials.md`，再分别整理到 `brief.md`、`api.openapi.yaml`、`test/cases.md`、`design/source.md` 或需求说明中。`产品示意图` 必须记录为 `product_illustration`、`usable_for_ui_acceptance=false`，不得触发 UI 验收。

`材料：` 表示批量材料，必须先逐项识别类型并写入 `source-materials.md` 的“材料识别 / 批量材料”。每项都要记录 `material_type`、`usable_for_ui_acceptance`、`confidence`、`user_confirmed`。`整合材料：` 表示单个文件或长文本中混合了需求、接口、测试或设计内容，必须先拆分并写入“材料识别 / 整合材料拆分”。分类或拆分不确定时，先向使用者确认，不要猜测归档。

前端开发阶段 UI 验收是条件流程：有 `ui_design + usable_for_ui_acceptance=true` 的设计材料或使用者明确要求 UI 验收时，前端完成后先交给 `designer-agent`；没有可用 UI 设计材料时，前端完成后直接交给 `test-agent` 做前端分段测试，并在 `frontend/integration.md` 记录跳过原因。后续补充真正 UI 设计稿时，必须先归档到 `design/source.md`，标记此前“跳过 UI 验收”结论失效，并把状态设为 `phase=ui_design_ready,next=designer-agent`；UI 走查有 P0/P1 时进入 `ui_fix_needed -> frontend-agent`，通过后再由 test-agent 判断是否需要重测。

开发期 UI 截图反馈使用轻量通道：先归档到 `design/feedback.md`，再由 `frontend-agent` 快修并写入 `frontend/review-fixes.md`；不进入 `bugs/`，不逐条推进 `status.yaml`。QA、UAT、送测、线上回归、缺陷平台链接或明确 Bug 才进入正式 Bug 流程。

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
