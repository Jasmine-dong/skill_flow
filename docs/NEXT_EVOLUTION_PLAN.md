# 项目工作流助手下一步演进方案

## 背景

当前项目工作流助手已经具备以下能力：

- 跨 Codex、Claude Code、AGENTS.md 的统一安装。
- 以项目为维度，通过 `pipeline.project.yaml` 和 `project-details.md` 建立项目画像。
- 以 feature 为单位，通过 `status.yaml` 驱动工作流状态。
- 支持 Product、Backend、Frontend、Test、Designer 等角色卡。
- 支持需求文档、接口文档、测试 case、设计稿等素材输入并归档。
- 支持接口先行、开发前确认、分段测试、UI 验收、全量测试。
- 支持项目画像错误时中止流程并重扫。

在对比 Multica 和 Vibe Kanban 后，可以吸收二者的优点，但仍保持本项目的轻量协议定位。

## 对标结论

### Multica 可借鉴点

Multica 更像完整的 managed agents platform，核心是把 coding agents 当成团队成员：

- assign tasks
- track progress
- report blockers
- update statuses
- compound reusable skills
- support multiple coding agent runtimes

项目工作流助手可以借鉴它的“角色像队友”的状态反馈和进度可见性，但不需要一开始做完整 agent platform。

### Vibe Kanban 可借鉴点

Vibe Kanban 更像 AI coding kanban 和执行工作区：

- kanban issues
- agent workspace
- branch / terminal / dev server
- diff review
- app preview
- PR creation

项目工作流助手可以借鉴它的“看板视图、工作区信息、review 体验”，但不需要一开始托管 runtime 或做完整 Web 平台。

## 产品定位

项目工作流助手不应直接复制 Multica 或 Vibe Kanban。

更合适的定位是：

```text
一个轻量级 AI 开发流程协议。
比 Vibe Kanban 更关注交付门禁；
比 Multica 更轻，不提供完整 agent 平台；
把 Codex、Claude Code 等 AI 编程工具接入同一套项目级研发流程。
```

## 演进原则

- 继续保持轻量，不急着做完整平台。
- 优先增强聊天界面的状态反馈、交接记录和状态可读性。
- 保持文件协议优先，所有状态和产物都能落在项目仓库中。
- 可被 Codex、Claude Code、AGENTS.md 工具共同读取。
- 后续如需接入 Multica / Vibe Kanban，也能通过文件协议映射。

## 方向一：聊天界面实时状态反馈

### 目标

让用户在当前对话中直接看到流程正在做什么、卡在哪里、下一步是谁，而不是必须打开文件或等待生成看板。

这更符合当前项目的 skill / command 定位，也不会引入 Web 服务、daemon、数据库或长连接。

### 反馈协议

每个角色执行时，在聊天界面输出三类状态：

```text
[开始] frontend-agent
- feature: 2026-06-24--login
- phase: frontend_development
- 本轮目标：实现登录页交互并补充前端交接文档
```

```text
[阻塞] backend-agent
- feature: 2026-06-24--login
- 原因：接口文档缺少验证码错误码定义
- 需要使用者确认：验证码错误码是否统一使用 AUTH_CAPTCHA_INVALID？
- 状态处理：写入 blockers，不推进 phase
```

```text
[完成] test-agent
- feature: 2026-06-24--login
- 完成：前端分段测试通过
- 产物：test/frontend-report.md
- 下一步：full_test
```

### 文件沉淀

聊天反馈负责实时可见，文件负责可追溯。

同一事件应同步追加到：

```text
features/<feature-id>/activity.md
```

必要时也可以在 `status.yaml` 中保留当前活动摘要：

```yaml
current_activity:
  role: frontend-agent
  state: running
  summary: 正在实现登录页交互
  updated_at: 2026-06-24 15:30
```

### 价值

- 用户能在聊天界面实时感知流程进展。
- 遇到不确定问题时，能立即发起确认并暂停推进。
- 不需要把项目升级成完整看板平台。
- 后续如果生成看板，也能复用 `activity.md` 和 `status.yaml`。

## 方向二：新增 Activity Log

### 目标

提升进度可读性，补足 `status.history` 太轻的问题。

`status.history` 适合机器读，但不适合用户了解完整过程。

### 建议新增文件

```text
features/<feature-id>/activity.md
```

### 示例

```md
# Activity

## 2026-06-24 14:20 frontend-agent

- 事件：开始
- 状态：frontend_development
- 本轮目标：实现登录页 UI、验证码接口联调

## 2026-06-24 14:30 frontend-agent

- 事件：完成
- 状态：frontend_done
- 完成：登录页 UI、验证码接口联调
- 产物：
  - frontend/integration.md
- 影响范围：
  - 登录页
  - Auth API
  - 表单校验
- 建议测试点：
  - 验证验证码倒计时
  - 验证验证码错误提示
  - 验证接口超时
- 下一步：designer-agent UI 验收

## 2026-06-24 15:10 designer-agent

- 事件：完成
- 状态：ui_reviewed
- 完成：登录页 UI 验收
- 产物：
  - design/ui-review.md
- 结论：无 P0/P1 阻塞
- 下一步：test-agent 前端分段测试
```

### 价值

- 类似 Multica 的 progress timeline。
- 用户可以快速理解 feature 推进过程。
- 出现问题时可以回溯是谁在什么阶段发现的。
- 可以作为后续自动周报、日报、交付说明的素材。

## 方向三：强化角色状态反馈

### 目标

让每个角色完成任务时像真实队友一样交接，而不是只更新 `phase`。

### 建议新增结构

可以在 feature 目录中新增：

```text
features/<feature-id>/role-status.yaml
```

也可以先写入每个角色自己的产物中。

### 标准结构

```yaml
role_status:
  role: frontend-agent
  state: completed
  summary: 完成登录页页面和验证码接口联调
  blockers: []
  next_recommended: designer-agent
  handoff:
    docs:
      - frontend/integration.md
      - design/source.md
    suggested_tests:
      - 验证验证码倒计时
      - 验证接口异常提示
      - 验证未登录跳转
    impact_scope:
      - 登录页
      - Auth API
      - 表单校验
```

### 价值

- 用户能快速知道角色做了什么。
- 下一个角色能直接读取交接摘要。
- Test 能依据建议测试点和影响范围决定是否扩测。
- 后续生成看板或日报更容易。

## 方向四：生成式看板视图

### 目标

让用户能一眼看到当前项目中所有 feature 的状态。

当前状态都在各自的 `status.yaml` 中，用户需要逐个打开，缺少全局视图。

### 重要结论

生成式看板可以做，但它不等于真正实时状态。

它的工作模式是：

```text
读取 status.yaml / activity.md -> 生成 pipeline-board.md 或 dashboard.html -> 用户刷新查看
```

因此它只能提供“可刷新汇总视图”，不能像真正看板一样自动感知每一次状态变化。

如果要做到真实实时变化，需要引入：

- 本地 server。
- 文件 watcher。
- websocket 或轮询。
- 前端看板页面。
- 运行时进程管理。

这会把项目从“可安装 skill / command”推向 Multica 或 Vibe Kanban 类平台。当前阶段不建议优先做。

### 建议产物

先不做复杂 Web App，优先生成：

```text
lightweight-pipeline/pipeline-board.md
```

或：

```text
lightweight-pipeline/dashboard.html
```

### 看板分组

建议按 phase 聚合：

```text
需求澄清中
接口确认中
开发前确认中
开发中
UI 验收中
测试中
全量测试中
已完成
阻塞
需要重扫项目画像
```

### 示例

```md
# 项目工作流看板

## 需求澄清中

- 2026-06-24--login
  - next: product-agent
  - owner: product-agent
  - blockers: 0

## 开发中

- 2026-06-25--order-list
  - next: frontend-agent
  - owner: frontend-agent
  - blockers: 0

## 需要重扫项目画像

- 2026-06-26--account-filter
  - blocker: project-details.md 中接口目录与真实代码不一致
```

## 方向五：引入工作区元信息

### 目标

借鉴 Vibe Kanban 的 workspace 概念，但不托管 runtime。

项目工作流助手只记录工作区信息，具体执行仍交给 Codex、Claude Code 或其他工具。

### 建议新增到 status.yaml

```yaml
workspace:
  branch: feature/2026-06-24-login
  app_path: packages/web
  backend_path: services/api
  dev_url: http://localhost:5173
  api_base_url: http://localhost:3000/api
  commands:
    install:
      - pnpm install
    dev:
      - pnpm dev
    typecheck:
      - pnpm typecheck
    test:
      - pnpm test
    build:
      - pnpm build
```

### 价值

- 每个 feature 都知道自己在哪个路径、哪个分支、哪个环境下开发。
- Test 和 UI 验收能读取固定入口。
- 后续接入 dev server、PR、preview 会更容易。
- 可以映射到 Vibe Kanban 的 workspace 概念。

## 方向六：把素材输入升级为 Intake

### 当前能力

当前已支持这种调用：

```text
功能：2026-06-24--login
需求文档：docs/login-prd.md
接口文档：docs/login-api.md
测试case：docs/login-test-cases.md
设计稿：https://www.figma.com/design/xxx
产品示意图：docs/login-flow.png
当前项目仅有前端部分，不需要后端实现，但前端需要按接口文档联调。
```

并会整理到：

```text
source-materials.md
brief.md
api.openapi.yaml
test/cases.md
design/source.md
```

视觉材料需要区分置信度和用途：真正 UI 设计稿归档为 `ui_design`，且只有 `usable_for_ui_acceptance=true` 时才进入 `design/source.md` 并触发 UI 验收；产品示意图、业务配图或概念图归档为 `product_illustration`，`usable_for_ui_acceptance=false`，只辅助需求理解，不触发 UI 流程。用户纠正优先级最高。

### 下一步建议

将 `source-materials.md` 正式升级为 intake 协议。

可以继续沿用文件名：

```text
source-materials.md
```

也可以改为更明确的：

```text
intake.md
```

### Intake 结构

```yaml
intake:
  feature_id: 2026-06-24--login
  workflow_hint: frontend-only
  project_scope:
    current_project_only: true
    related_projects: []
  requirement_doc:
    source: docs/login-prd.md
    target: brief.md
    status: processed
  api_doc:
    source: docs/login-api.md
    target: api.openapi.yaml
    status: processed
  test_cases:
    source: docs/login-test-cases.md
    target: test/cases.md
    status: processed
  design:
    source: https://www.figma.com/design/xxx
    material_type: ui_design
    usable_for_ui_acceptance: true
    confidence: high
    user_confirmed: false
    target: design/source.md
    status: processed
  product_illustrations:
    - source: docs/login-flow.png
      material_type: product_illustration
      usable_for_ui_acceptance: false
      confidence: high
      user_confirmed: true
      target: brief.md
      status: processed
  user_notes:
    - 当前项目仅有前端部分，不需要后端实现
    - 前端需要按接口文档联调
```

### 价值

- Product 澄清时输入更稳定。
- 跨项目需求可以明确 related_projects。
- 后续看板和 activity log 可以引用 intake。
- 可以避免素材散落在聊天历史里。

## 建议优先级

### P0：Chat Status Protocol

优先解决用户最关心的“状态变更是不是黑盒”问题。

先要求每个角色在聊天界面输出：

```text
[开始] role / phase / 本轮目标
[阻塞] role / reason / 需要确认的问题
[完成] role / 产物 / 下一步
```

同时遇到问题或不确定时，必须先向使用者确认，不推进状态。

### P1：Activity Log

新增：

```text
features/<feature-id>/activity.md
```

要求每个角色开始、完成任务或遇到阻塞时追加记录。

### P2：Role Status / Handoff 标准化

给每个角色统一交接结构。

可以先写入各角色产物，后续再抽成独立 `role-status.yaml`。

### P3：Workspace Metadata

把 branch、app path、dev url、test command 纳入 feature 状态。

这会为后续接入 preview、PR、dev server 做准备。

### P4：Generated Pipeline Board

新增：

```text
lightweight-pipeline/pipeline-board.md
```

先做 Markdown 汇总，不急着做 Web App。

注意：它是可刷新汇总视图，不承担真正实时状态能力。

### P5：Intake 协议升级

把素材输入从 `source-materials.md` 升级成更结构化的 intake。

## 暂不建议做的事情

短期不建议做：

- 完整 Web 平台。
- Agent daemon。
- 多 runtime 管理。
- 自动创建 PR 和合并。
- 复杂权限系统。
- 云端任务调度。

这些属于 Multica / Vibe Kanban 的重资产。

当前项目的优势是：

- 轻量。
- 可安装。
- 可跨工具。
- 可嵌入任何项目。
- 文件协议优先。

## 下一步建议

建议先做三件事：

1. 新增 Chat Status Protocol，让每个角色在聊天界面输出开始、阻塞、完成状态。
2. 新增 `activity.md` 模板和角色写入规则。
3. 标准化每个角色的 handoff 字段。

生成式看板可以延后做。它是汇总视图，不解决真正实时状态反馈。

这三项能明显提升可见性和交接质量，同时不会把项目推向复杂平台化。
