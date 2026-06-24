# Agent Pipeline Commander

一个可跨 AI 编程工具安装的轻量级多角色工作流包。它用一个入口 `pipeline-commander` 根据功能包状态推进产品、后端、前端、测试和设计走查任务。

## 快速安装

同一个命令，自动检测当前环境并安装适配器：

```bash
curl -fsSL https://raw.githubusercontent.com/Jasmine-dong/skill_flow/main/install.sh | bash
```

默认 `auto` 规则：

- 检测到 Codex：安装到 `${CODEX_HOME:-~/.codex}/skills/pipeline-commander`
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
| `codex` | Codex | `pipeline-commander` skill |
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

然后创建功能包：

```text
lightweight-pipeline/features/2026-05-25--greeting/
  status.yaml
  brief.md
```

`status.yaml` 示例：

```yaml
feature: 2026-05-25--greeting
title: Greeting
workflow: backend-only
phase: planned
owner: product-agent
next: product-agent
blockers: []
history:
  - at: "2026-05-25T00:00:00+08:00"
    phase: planned
    by: product-agent
    note: 创建功能包
```

## 推荐调用

Codex：

```text
推进 2026-05-25--greeting
```

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

如果开发中发现项目画像与真实代码、命令或目录结构冲突，当前流程必须停止，feature 状态进入：

```yaml
phase: project_rescan_required
next: product-agent
blockers:
  - type: project_details_mismatch
    message: project-details.md 中的项目事实与真实代码不一致，需要重扫
```

重扫并更新项目画像，使用者确认后，才重新开启当前 feature 流程。

## 支持的流程类型

功能包通过 `status.yaml` 声明自己的流程类型：

```yaml
workflow: backend-only
```

初始 `next` 应与该 workflow 的 `start` 任务所属角色一致。例如：

| workflow | 初始 next |
|---|---|
| `full-stack` / `backend-only` / `frontend-only` / `product-only` / `docs-only` | `product-agent` |
| `design-review-only` | `designer-agent` |
| `test-only` | `test-agent` |

当前内置流程：

| workflow | 适用场景 | 主路径 |
|---|---|---|
| `full-stack` | 产品、后端、前端、测试、设计都参与 | 需求澄清 -> 接口文档/TODO -> 使用者确认 -> Backend/FE 开发 -> 后端分段测试 / UI 验收 -> 前端分段测试 -> 全量测试 -> 通知 |
| `backend-only` | 只有服务端、API、数据处理、任务调度 | 需求澄清 -> 接口文档/TODO -> 使用者确认 -> 后端开发 -> 后端分段测试 -> 全量测试 -> 通知 |
| `frontend-only` | 只有页面、交互、样式、前端 Mock | 需求澄清 -> 前端 TODO -> 使用者确认 -> 前端开发 -> UI 验收 -> 前端分段测试 -> 全量测试 -> 通知 |
| `product-only` | 只有需求、范围、验收标准、产品文档 | 产品整理 -> done |
| `design-review-only` | 只有 UI/UX 走查、视觉验收 | 设计走查 -> 验收 |
| `test-only` | 只有测试补充、回归验证、复测报告 | 测试回归 -> done |
| `docs-only` | 只有说明文档、配置说明、流程文档 | 文档整理 -> done |

不确定 workflow 时，Commander 应先判断或询问，不默认套全流程。

常规开发不会在拿到需求文档后立刻写代码。Product 先做需求澄清；如果有 Backend 介入，Backend 先出 `api.openapi.yaml` 和 `backend/todo.md`，FE 基于接口契约拆 `frontend/todo.md`；使用者确认接口文档和开发 TODO 后才进入开发阶段。进入 `development_ready` 后，Backend 和 FE 可以同步推进。

开发过程中允许分段验收：Backend 完成后必须在 `backend/notes.md` 里提供建议测试点、影响范围和扩测建议，再由 Test 测后端部分；FE 完成后必须在 `frontend/integration.md` 里提供建议测试点、影响范围和扩测建议，再由 Designer 做 UI 验收，UI 通过后 Test 测前端部分；Test 需要依据 Backend / FE 提供的信息判断是否扩大测试范围，并在报告中记录采纳或不采纳原因。所有开发与分段验收完成后，Test 执行全量测试。发现问题时进入对应修复阶段，修复后回到对应的 Test 或 UI 验收。全量测试通过后状态改为 `done`，并通知使用者。所有阶段都必须有文档记录。

## 最小心智模型

```text
用户只找 Commander
Commander 看 workflow + 状态机
workflow 决定本功能走哪条路径
状态机决定当前角色
角色卡限制边界
功能包记录产物
```
