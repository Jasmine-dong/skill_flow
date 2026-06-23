# Pipeline Commander Skill

一个可独立安装的 Codex skill，用一个入口 `pipeline-commander` 管理轻量级多角色工作流。

## 快速安装

在 Codex 里直接发送：

```text
安装这个 skill：https://github.com/<owner>/<repo>/tree/main/skills/pipeline-commander
```

安装后重启 Codex。

如果使用命令行安装：

```bash
python ~/.codex/skills/.system/skill-installer/scripts/install-skill-from-github.py \
  --repo <owner>/<repo> \
  --path skills/pipeline-commander
```

把 `<owner>/<repo>` 换成实际 GitHub 仓库，例如：

```bash
python ~/.codex/skills/.system/skill-installer/scripts/install-skill-from-github.py \
  --repo your-name/agent-skillflow \
  --path skills/pipeline-commander
```

## 设计目标

- 只有一个入口：`pipeline-commander`
- 多角色不拆成多个 skill，只用角色卡片约束边界
- 状态机保持轻量，用 `workflow + phase + next + task_map`
- 用户只需要给功能 ID，由 Commander 判断下一步
- 具体任务仍落到功能包文件，不依赖聊天历史

## 安装内容

安装单元是 `skills/pipeline-commander`，目录已经自包含：

```text
skills/pipeline-commander/
  SKILL.md
  references/
    pipeline/tasks.yaml
    roles/*.md
  assets/
    pipeline.project.yaml.example
    templates/feature/status.yaml
    templates/feature/brief.md
```

因此用户只安装这个目录即可，不需要手动复制仓库根目录的 `roles/`、`pipeline/`、`templates/`。

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

```text
推进 2026-05-25--greeting
```

Commander 执行：

1. 读取 `pipeline.project.yaml`
2. 读取 `features/<feature-id>/status.yaml` 里的 `workflow`、`phase`、`next`
3. 按 skill 内置 `references/pipeline/tasks.yaml` 的 `workflows.<workflow>.next_task_map` 找任务
4. 读取 skill 内置 `references/roles/<agent>.md`
5. 按任务步骤执行
6. 完成后按门禁推进 `status.yaml`

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
| `full-stack` | 产品、后端、前端、测试、设计都参与 | 产品 -> 后端 -> API 测试 -> 前端 -> E2E -> 设计 -> 验收 |
| `backend-only` | 只有服务端、API、数据处理、任务调度 | 产品 -> 后端 -> API 测试 -> 验收 |
| `frontend-only` | 只有页面、交互、样式、前端 Mock | 产品 -> 前端 -> 设计走查 -> 验收 |
| `product-only` | 只有需求、范围、验收标准、产品文档 | 产品整理 -> done |
| `design-review-only` | 只有 UI/UX 走查、视觉验收 | 设计走查 -> 验收 |
| `test-only` | 只有测试补充、回归验证、复测报告 | 测试回归 -> done |
| `docs-only` | 只有说明文档、配置说明、流程文档 | 文档整理 -> done |

不确定 workflow 时，Commander 应先判断或询问，不默认套全流程。

## 目录结构

```text
agent-skillflow/
  README.md
  ARCHITECTURE.md
  pipeline.project.yaml.example
  skills/
    pipeline-commander/
      SKILL.md
      references/
        pipeline/tasks.yaml
        roles/*.md
      assets/
        pipeline.project.yaml.example
        templates/feature/status.yaml
        templates/feature/brief.md
  pipeline/
    tasks.yaml
  roles/
    product-agent.md
    backend-agent.md
    test-agent.md
    frontend-agent.md
    designer-agent.md
  templates/
    feature/
      status.yaml
      brief.md
```

架构图见 [ARCHITECTURE.md](./ARCHITECTURE.md)。

## 和完整版的区别

| 项 | 轻量版 | 完整版 |
|---|---|---|
| 入口 | 1 个 Commander skill | 多个 pipeline 命令和适配器 |
| 角色 | Markdown 角色卡 | rules、roles、adapter 多处生成 |
| 状态机 | `tasks.yaml` 内按 workflow 分组的轻量映射 | CLI/MCP/doctor/advance 完整工具链 |
| 适用场景 | 小团队、个人项目、先跑通方法 | 多工具、多入口、可检查的工程化工作流 |

## 最小心智模型

```text
用户只找 Commander
Commander 看 workflow + 状态机
workflow 决定本功能走哪条路径
状态机决定当前角色
角色卡限制边界
功能包记录产物
```
