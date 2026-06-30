# Agent Pipeline Commander

一个可跨 AI 编程工具安装的轻量级多角色工作流包。它用一个入口 `pipeline-commander` 根据功能包状态推进产品、后端、前端、测试和设计走查任务。

## 快速安装

同一个命令，自动检测当前环境并安装适配器：

```bash
curl -fsSL https://raw.githubusercontent.com/Jasmine-dong/skill_flow/main/install.sh | bash
```

默认 `auto` 规则：

- 检测到 Codex：安装到 `${CODEX_HOME:-~/.codex}/skills/agent-pipeline`
- 检测到 Claude Code：安装到 `~/.claude/commands/pipeline-commander.md`
- 两者都没检测到：在当前项目安装 `AGENTS.md` 和 `.agent-pipeline-commander/`

也可以指定目标：

```bash
curl -fsSL https://raw.githubusercontent.com/Jasmine-dong/skill_flow/main/install.sh | bash -s -- --target codex
curl -fsSL https://raw.githubusercontent.com/Jasmine-dong/skill_flow/main/install.sh | bash -s -- --target claude
curl -fsSL https://raw.githubusercontent.com/Jasmine-dong/skill_flow/main/install.sh | bash -s -- --target agents
curl -fsSL https://raw.githubusercontent.com/Jasmine-dong/skill_flow/main/install.sh | bash -s -- --target all
```

本地 clone 后也可以运行：

```bash
./install.sh --target all
```

## 支持的安装目标

| target | 适用工具 | 安装内容 |
|---|---|---|
| `codex` | Codex | `agent-pipeline` skill |
| `claude` | Claude Code | `/pipeline-commander` slash command |
| `agents` | 支持 `AGENTS.md` 的通用 AI 编程工具 | 项目级 `AGENTS.md` 和资源目录 |
| `auto` | 自动检测 | 优先安装已检测到的工具，否则安装 `agents` |
| `all` | 全部 | 同时安装 Codex、Claude Code、AGENTS.md 适配 |

## 设计目标

- 统一安装命令，不要求用户记不同工具的安装方式
- `shared/` 是唯一事实来源，避免多个工具适配产生重复配置
- 只有一个工作流入口：`pipeline-commander`
- 多角色不拆成多个 skill，只用角色卡片约束边界
- 所有角色遇到问题或不确定时必须向使用者确认，确认或补充后再继续
- 所有角色在聊天界面输出 `[开始]`、`[阻塞]`、`[完成]` 状态事件
- 所有角色完成任务时，在自己的主要产物中写入 `## Handoff`
- 状态机保持轻量，用 `workflow + phase + next + task_map`
- 用户只需要给功能 ID，由 Commander 判断下一步
- 具体任务仍落到功能包文件，不依赖聊天历史

## 仓库结构

```text
agent-pipeline-commander/
  install.sh
  README.md
  LICENSE
  docs/
    ARCHITECTURE.md
  shared/
    tasks.yaml
    roles/COMMON.md
    roles/*.md
    pipeline.project.yaml.example
    project-details.md
    feature-template/
      status.yaml
      brief.md
      activity.md
      bugs/BUG-001.md
      commit/notes.md
      design/feedback.md
      frontend/review-fixes.md
      development-confirmation.md
  adapters/
    codex/
      SKILL.md
      agents/openai.yaml
    claude-code/
      commands/pipeline-commander.md
    agents/
      AGENTS.md
```

架构图见 [docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md)。

## 维护方式

仓库只维护源码和适配器，不提交安装产物：

- `shared/` 是状态机、角色卡和模板的唯一事实源。
- `adapters/` 只保留 Codex、Claude Code、AGENTS.md 的入口差异。
- `.agent-pipeline-commander/` 是 `install.sh --target agents` 生成的项目本地资源目录，不进仓库。
- 根目录 `AGENTS.md` 也是 `agents` 目标的安装产物，不进仓库。

修改 `shared/` 或 `adapters/agents/AGENTS.md` 后，可以运行：

```bash
./scripts/check-install-artifacts.sh
```

它会在临时目录执行 `install.sh --target agents`，并确认生成的 `AGENTS.md`、`.agent-pipeline-commander/references` 和 `.agent-pipeline-commander/assets` 与源码一致。

## 项目首次使用

在目标项目根目录创建 `pipeline.project.yaml`：

```yaml
project:
  name: my-project
  prd:
    primary: docs/prd.md

roots:
  project: .
  docs: lightweight-pipeline

knowledge:
  project_details: lightweight-pipeline/project-details.md

features:
  root: lightweight-pipeline/features

apps:
  backend:
    path: services/api
    dev:
      base_url: http://localhost:3000/api
  frontend:
    path: packages/web
    dev:
      base_url: http://localhost:5173
```

第一次使用时，如果 `knowledge.project_details` 指向的项目画像不存在，先扫描项目并生成：

```text
lightweight-pipeline/project-details.md
```

项目画像需要由使用者确认后，才允许创建或推进 feature 流程。它记录长期可复用的项目事实，例如技术栈、目录职责、启动命令、测试命令、接口封装、路由规则、状态管理、权限、常见坑点和回归入口。

项目画像还会记录项目能力识别结果：

- 是否检测到可开发后端、后端路径、证据和置信度
- 是否检测到可开发前端、前端路径、证据和置信度
- BFF、mock、proxy、fixture、纯 OpenAPI 文档等低置信度情况

然后创建功能包：

```text
lightweight-pipeline/features/2026-05-25--greeting/
  status.yaml
  brief.md
  activity.md
```

`status.yaml` 示例：

```yaml
feature: 2026-05-25--greeting
title: Greeting
workflow: pending
workflow_detection:
  status: pending
  suggested:
  confirmed_by_user: false
phase: planned
owner: product-agent
next: product-agent
blockers: []
active_bugs: []
history:
  - at: "2026-05-25T00:00:00+08:00"
    phase: planned
    by: product-agent
    note: 创建功能包
```

## 推荐调用

Codex：

```text
$agent-pipeline
```

也可以输入 `$` 后搜索 `项目工作流助手`、`agent-pipeline` 或 `pipeline-commander` 选择该 skill，再输入要推进的 feature：

```text
推进 2026-05-25--greeting
```

也可以在调用时直接提供素材来源，Commander 会先归档到功能包，再整理到目标位置：

```text
$agent-pipeline

功能：2026-05-25--greeting
需求文档：docs/greeting-prd.md
接口文档：docs/greeting-api.md
测试case：docs/greeting-test-cases.md
设计稿：https://www.figma.com/design/xxx
产品示意图：docs/greeting-flow.png
当前项目仅有前端部分，不需要后端实现，但前端需要按接口文档联调。
```

也可以批量提供材料，或把多类内容放在一个整合文件里：

```text
功能：2026-05-25--greeting
材料：
- docs/greeting-prd.md：需求文档
- docs/greeting-api.md：接口文档
- docs/greeting-cases.md：测试case
- https://www.figma.com/design/xxx：设计稿
- docs/greeting-flow.png：产品示意图
```

```text
功能：2026-05-25--greeting
整合材料：docs/greeting-all-in-one.md
```

`材料：` 会先逐项识别类型；`整合材料：` 会先按章节、标题和内容语义拆分。每项材料都会记录 `material_type`、`usable_for_ui_acceptance`、`confidence` 和 `user_confirmed`。识别或拆分不确定时，Commander 必须先向使用者确认，不会猜测归档。

产品示意图和 UI 设计稿会被严格区分：

- `ui_design`：Figma、Sketch、蓝湖或明确的 UI 页面设计稿，可设置 `usable_for_ui_acceptance=true`，用于 UI 验收。
- `product_illustration`：产品示意图、流程配图、概念图或用户明确说明“不是 UI 设计”的视觉材料，只辅助理解需求，`usable_for_ui_acceptance=false`，不会触发 UI 验收。
- 用户纠正优先级最高；一旦使用者确认“这是产品示意图，不是 UI 设计”，后续不得再把它当成设计稿。

素材会被整理到：

| 调用标签 | 目标位置 |
|---|---|
| `需求文档：` | `features/<feature-id>/brief.md` |
| `接口文档：` | `features/<feature-id>/api.openapi.yaml` |
| `测试case：` | `features/<feature-id>/test/cases.md` |
| `设计稿：` | `features/<feature-id>/design/source.md`，仅限可 UI 验收的设计材料 |
| `产品示意图：` | `features/<feature-id>/source-materials.md` 和需求说明，不进入 UI 验收 |
| `材料：` | 先写入 `source-materials.md` 的材料识别，再按类型分发 |
| `整合材料：` | 先写入 `source-materials.md` 的整合材料拆分，再按内容分发 |
| 调用原文和处理状态 | `features/<feature-id>/source-materials.md` |

Claude Code：

```text
/pipeline-commander 2026-05-25--greeting
```

通用 `AGENTS.md` 工具：

```text
推进 2026-05-25--greeting
```

Commander 执行：

1. 从当前目录向上查找 `pipeline.project.yaml`，确定项目根目录
2. 读取 `knowledge.project_details` 指向的项目画像
3. 读取 `features/<feature-id>/status.yaml` 里的 `workflow`、`phase`、`next`
4. 按 `tasks.yaml` 的 `workflows.<workflow>.next_task_map` 找任务
5. 读取对应 `roles/<agent>.md`
6. 按任务步骤执行
7. 完成后补充可复用项目事实，并按门禁推进 `status.yaml`

所有角色执行前都必须读取 `roles/COMMON.md` 和项目画像。遇到需求、接口、设计、测试、环境、权限、数据或验收标准不确定时，先向使用者发起确认；使用者确认或补充后再继续。

所有角色必须遵守 Chat Status Protocol，在聊天界面输出三类状态事件，不输出百分比或进度条：

```text
[开始] product-agent
Feature：2026-05-25--greeting
Phase：requirement_clarification
本轮目标：整理需求边界、验收标准和待确认问题
状态处理：
- 已读取 COMMON.md、角色卡、pipeline.project.yaml、项目画像和 status.yaml
- 将按当前 phase / next 门禁执行
```

```text
[阻塞] product-agent
Feature：2026-05-25--greeting
Phase：requirement_clarification
阻塞原因：需求文档缺少错误态处理规则
需要使用者确认：
1. 接口异常时是否展示后端 message？
2. 是否需要重试入口？
状态处理：
- 已写入 status.yaml blockers
- 已追加 activity.md
- 不推进 phase / next
```

```text
[完成] product-agent
Feature：2026-05-25--greeting
Phase：requirement_confirmed
完成内容：
- 已整理需求边界和验收标准
- 已确认无剩余 P0 待确认问题
产物：
- brief.md
- source-materials.md
下一步：
- backend-agent 输出接口文档与后端 TODO
状态处理：
- 已追加 activity.md
- 已更新 status.yaml history
- next = backend-agent
```

输出 `[阻塞]` 或 `[完成]` 时，必须同步追加 `features/<feature-id>/activity.md`，保证聊天反馈和文件记录一致。

完成任务时，每个角色还必须在自己的主要产物中写入 `## Handoff`。文件里保存完整交接，聊天里的 `[完成]` 只摘出摘要：

```yaml
handoff:
  role: frontend-agent
  state: completed
  summary: 完成登录页 UI、表单校验和验证码接口联调
  deliverables:
    - frontend/integration.md
  changed_files:
    - src/pages/login/index.tsx
  impact_scope:
    - 登录页
    - Auth API 调用
    - 表单校验
  suggested_tests:
    - 验证验证码倒计时
    - 验证接口异常提示
  known_risks:
    - 未覆盖弱网场景
  blockers: []
  next_recommended:
    role: test-agent
    reason: 当前未提供可用于 UI 验收的设计材料，已记录跳过 UI 验收，下一步进入前端分段测试；如果后续补充真正 UI 设计稿，可单独交给 designer-agent
```

如果开发中发现项目画像与真实代码、命令或目录结构冲突，当前流程必须停止，feature 状态进入：

```yaml
phase: project_rescan_required
next: product-agent
blockers:
  - type: project_details_mismatch
    message: project-details.md 中的项目事实与真实代码不一致，需要重扫
```

重扫并更新项目画像，使用者确认后，才重新开启当前 feature 流程。

## 开发期 UI 反馈快修

开发过程中，使用者经常会直接贴截图指出 UI 小问题，例如按钮样式、抽屉层级、footer 透出、表格对齐、间距、颜色、文案或响应式细节。这类问题不需要走完整 `Bug -> test-agent 分诊 -> frontend-agent`。

可以这样输入：

```text
推进 2026-05-25--greeting
截图里按钮太高，抽屉层级压住 footer，表格金额列没有右对齐
```

Commander 会使用 `frontend.ui_feedback_fix` 轻量通道：

1. 记录反馈到 `features/<feature-id>/design/feedback.md`
2. 由 `frontend-agent` 做最小 UI 修复
3. 记录修复到 `features/<feature-id>/frontend/review-fixes.md`
4. 追加 `activity.md` 和 `status.history`
5. 默认不改变当前 `phase / next`，不进入 `bugs/`，不交给 `test-agent` 分诊

只有这些情况才走正式 Bug 流程：

- QA、UAT、送测、线上回归发现的问题
- 缺陷平台链接，例如 Meegle、Jira、GitLab Issue
- 使用者明确说“这是 Bug”
- 涉及接口、数据、权限、产品规则、主流程阻塞或验收标准变化

## 送测 Bug 流程

真实送测、UAT、线上回归或用户反馈阶段发现 Bug 时，不需要新建一个完整需求流程，可以在关联 feature 下补一条 Bug 记录：

```text
Bug：登录页验证码输错后没有错误提示
关联功能：2026-05-25--greeting
缺陷来源：QA
严重级别：P1
复现步骤：
1. 打开登录页
2. 输入错误验证码并提交
期望结果：展示验证码错误提示
实际结果：无任何错误提示
证据：截图、日志或缺陷单链接
```

Commander 收到后先做三件事：

1. 写入 `features/<feature-id>/bugs/<bug-id>.md`
2. 更新 `status.yaml`：`phase: bug_triage`、`next: test-agent`
3. 交给 `test-agent` 分诊，不直接让实现角色修复未分诊 Bug

分诊后复用现有修复流程：

```text
bug_triage
  -> backend_fix_needed -> backend-agent -> test.backend / test.full
  -> frontend_fix_needed -> frontend-agent -> designer.review / test.frontend / test.full
  -> ui_fix_needed -> frontend-agent -> designer.review / test.frontend / test.full
```

修复角色必须回写 `bugs/<bug-id>.md` 的 Fix 区块，Test 复测时必须回写 Retest 区块，并判断是否需要扩大测试范围。

如果 Bug 来自 Meegle、Jira、GitLab Issue 或其他缺陷平台，也可以只提供链接：

```text
Bug链接：https://meegle.example.com/...
Bug平台：meegle
关联功能：2026-05-25--greeting
```

Commander 会先识别平台和工作项 ID，写入 `bugs/<bug-id>.md` 的 `external_issue`。如果当前 AI 工具已接入并授权 Meegle MCP，则优先通过 MCP 读取工作项详情和评论，自动填充 Bug 标题、严重级别、复现步骤、期望/实际结果和证据。

读取失败时不会猜测 Bug 内容，而是写入阻塞：

```yaml
external_issue:
  platform: meegle
  url: https://meegle.example.com/...
  work_item_id:
  fetch_status: auth_required
```

这时需要使用者重新授权 MCP、补充 `project_key / work_item_id`，或直接提供 Bug 正文。

## 提交代码

提交代码是可选动作，不是默认流程节点。使用者明确要求时，Commander 临时使用 `commit-agent`：

```text
先提交一下当前进度
```

```text
测试通过了，生成 commit 信息
```

```text
提交并同步 Meegle Bug 备注
```

`commit-agent` 会写入：

```text
features/<feature-id>/commit/notes.md
```

轻量规则：

- 中途提交是 `checkpoint`，只提示已完成内容，不推进流程
- 完成后提交是 `final`，必须记录验证报告和交付范围
- 真正执行 git commit 前，必须让使用者确认文件范围和 commit message
- Bug 修复提交后，必须回写 `bugs/<bug-id>.md`
- 外部平台可写时同步修复备注；同步失败只记录失败原因，不回滚本地 commit

## 支持的流程类型

功能包通过 `status.yaml` 声明自己的流程类型。新功能包可以先用 `pending`，由 Product 自动建议并让使用者确认后再改成真实 workflow：

```yaml
workflow: pending
workflow_detection:
  status: pending
```

workflow 确认后，`next` 应与该 workflow 的 `start` 任务所属角色一致。例如：

| workflow | 初始 next |
|---|---|
| `full-stack` / `backend-only` / `frontend-only` / `product-only` / `docs-only` | `product-agent` |
| `design-review-only` | `designer-agent` |
| `test-only` | `test-agent` |

当前内置流程：

| workflow | 适用场景 | 主路径 |
|---|---|---|
| `full-stack` | 产品、后端、前端、测试，可按需接入设计 | 需求澄清 -> 接口文档/TODO -> 使用者确认 -> Backend/FE 开发 -> 后端分段测试 / 条件 UI 验收 -> 前端分段测试 -> 全量测试 -> 通知 |
| `backend-only` | 只有服务端、API、数据处理、任务调度 | 需求澄清 -> 接口文档/TODO -> 使用者确认 -> 后端开发 -> 后端分段测试 -> 全量测试 -> 通知 |
| `frontend-only` | 只有页面、交互、样式、前端 Mock，可按需接入设计 | 需求澄清 -> 前端 TODO -> 使用者确认 -> 前端开发 -> 条件 UI 验收 -> 前端分段测试 -> 全量测试 -> 通知 |
| `product-only` | 只有需求、范围、验收标准、产品文档 | 产品整理 -> done |
| `design-review-only` | 只有 UI/UX 走查、视觉验收 | 设计走查 -> 验收 |
| `test-only` | 只有测试补充、回归验证、复测报告 | 测试回归 -> done |
| `docs-only` | 只有说明文档、配置说明、流程文档 | 文档整理 -> done |

不确定 workflow 时，Commander 应先自动建议并询问，不默认套全流程。建议必须同时看项目能力和本次需求意图：

- 仓库检测到前端和后端，且本次需求同时改接口/服务端和页面/交互：建议 `full-stack`
- 仓库检测到后端，且本次只改接口、数据、权限、任务或消息：建议 `backend-only`
- 仓库检测到前端，且本次只改页面、交互、样式、前端状态、前端联调或 Mock：建议 `frontend-only`
- 仓库只有前端，即使提供了接口文档，也建议 `frontend-only`；接口文档作为 FE 联调契约
- 只有需求、设计、测试或文档时，分别建议 `product-only`、`design-review-only`、`test-only` 或 `docs-only`

建议输出必须包含检测证据、需求意图和判断理由；使用者确认后，才写入 `status.workflow` 并继续流程。

常规开发不会在拿到需求文档后立刻写代码。Product 先做需求澄清；如果有 Backend 介入，Backend 先出 `api.openapi.yaml` 和 `backend/todo.md`，FE 基于接口契约拆 `frontend/todo.md`；使用者确认接口文档和开发 TODO 后才进入开发阶段。如果使用者在开发前确认节点说“OK 继续推进”或“确认，可以开始开发”，Commander 会写入确认记录，推进到 `development_ready`，并立即衔接默认开发角色。full-stack 单代理执行默认先 Backend，除非使用者明确要求先前端；frontend-only 默认进入 Frontend。

开发过程中允许分段验收：Backend 完成后必须在 `backend/notes.md` 里提供建议测试点、影响范围和扩测建议，再由 Test 测后端部分；FE 完成前必须做 UI 关键项自检，并在 `frontend/integration.md` 记录 Figma 节点、按钮、表格、弹窗/抽屉层级、footer 固定区域、disabled/loading/error/empty 状态和响应式等检查结果。类型检查、lint 或单测通过不能替代视觉自检。FE 完成后还必须提供建议测试点、影响范围和扩测建议。当前 feature 有 `ui_design + usable_for_ui_acceptance=true` 的设计材料或使用者明确要求 UI 验收时，FE 完成后先由 Designer 做 UI 验收，UI 通过后 Test 测前端部分；如果开发阶段没有可用 UI 设计材料，FE 在 `frontend/integration.md` 记录跳过 UI 验收的原因，然后直接进入前端分段测试。产品示意图、业务配图或概念图不算 UI 设计材料。后续一旦补充真正 UI 设计稿并写入 `design/source.md`，此前“跳过 UI 验收”的结论自动失效，状态进入 `ui_design_ready`，下一步交给 `designer-agent`；UI 走查有 P0/P1 时进入 `ui_fix_needed -> frontend-agent`，通过后交给 Test 判断是否需要重测前端或全量。Test 需要依据 Backend / FE / UI 走查提供的信息判断是否扩大测试范围，并在报告中记录采纳或不采纳原因。所有开发与分段验收完成后，Test 执行全量测试。发现问题时进入对应修复阶段，修复后回到对应的 Test 或 UI 验收。全量测试通过后状态改为 `done`，并通知使用者。所有阶段都必须有文档记录。

如果后续才提供设计稿，可以单独调用 UI 走查：

```text
推进 2026-05-25--greeting
设计稿：https://figma.com/...
请单独做 UI 验收
```

Commander 会先把真正 UI 设计稿归档到 `design/source.md`，再把 `next` 指向 `designer-agent` 执行 UI 走查。也可以创建 `design-review-only` 类型的功能包，只做 UI/UX 验收。

如果这个 feature 此前因为没有可用 UI 设计材料跳过过 UI 验收，后补真正 UI 设计稿不是普通的“可选走查”，而是强制状态迁移：

```yaml
phase: ui_design_ready
next: designer-agent
```

此时此前 `frontend/integration.md`、`test/frontend-report.md` 或 `test/full-report.md` 中基于“无设计材料”的 UI 跳过结论失效。Designer 必须重新走查；如果有 P0/P1，交回 Frontend 修复；如果通过，再由 Test 判断是否需要重测。

开发期 UI 反馈用 `design/feedback.md` 和 `frontend/review-fixes.md` 快修；真实送测后发现 Bug 时，先进入 `bug_triage`，由 Test 判断归属和复测范围，再接回对应修复阶段。

## 最小心智模型

```text
用户只找 Commander
Commander 看 workflow + 状态机
workflow 决定本功能走哪条路径
状态机决定当前角色
角色卡限制边界
功能包记录产物
```
