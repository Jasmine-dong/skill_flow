# 轻量级 Agent Pipeline 架构图

## 总览

```mermaid
flowchart TD
  User["用户\n只提供功能 ID / 推进意图"]
  Commander["pipeline-commander\n唯一入口 Skill"]
  Config["pipeline.project.yaml\n项目目录 / 文档目录 / URL"]
  Status["features.root/<feature-id>/status.yaml\nworkflow / phase / owner / next / blockers / history"]
  Tasks["pipeline/tasks.yaml\ntasks + workflows + next_task_map"]
  Role["roles/<agent>.md\n角色边界卡片"]
  Feature["features.root/<feature-id>/\nbrief / api / test / notes / design"]

  User --> Commander
  Commander --> Config
  Commander --> Status
  Commander --> Tasks
  Tasks --> Role
  Commander --> Role
  Role --> Feature
  Commander --> Feature
  Commander --> Status
```

## 调度流程

```mermaid
sequenceDiagram
  participant U as 用户
  participant C as Commander Skill
  participant S as status.yaml
  participant T as tasks.yaml
  participant R as role card
  participant F as 功能包文件

  U->>C: 推进 2026-05-25--greeting
  C->>S: 读取 workflow / phase / next
  C->>T: 查询 workflows[workflow].next_task_map[next][phase]
  T-->>C: 返回任务 key 与 agent
  C->>R: 读取 roles/<agent>.md
  C->>F: 按任务步骤读写产物
  C->>S: 检查 done_requires
  alt 门禁通过
    C->>S: 更新 phase / next / history
    C-->>U: 汇报已推进到下一阶段
  else 门禁失败
    C->>S: 写入或保留 blockers
    C-->>U: 汇报阻塞项和当前应处理角色
  end
```

## 流程类型

```mermaid
flowchart TD
  Status["status.yaml\nworkflow 字段"]
  Full["full-stack\n产品 -> 后端 -> API 测试 -> 前端 -> E2E -> 设计 -> 验收"]
  Backend["backend-only\n产品 -> 后端 -> API 测试 -> 验收"]
  Frontend["frontend-only\n产品 -> 前端 -> 设计走查 -> 验收"]
  Product["product-only\n产品整理 -> done"]
  Design["design-review-only\n设计走查 -> 验收"]
  Test["test-only\n测试回归 -> done"]
  Docs["docs-only\n文档整理 -> done"]

  Status --> Full
  Status --> Backend
  Status --> Frontend
  Status --> Product
  Status --> Design
  Status --> Test
  Status --> Docs
```

## 全流程状态机

```mermaid
stateDiagram-v2
  [*] --> planned
  planned --> contract_ready: product.contract
  contract_ready --> backend_done: backend.implement
  backend_done --> tested: test.api
  tested --> frontend_done: frontend.integrate
  frontend_done --> e2e_verified: test.e2e
  e2e_verified --> ui_reviewed: designer.review
  ui_reviewed --> done: product.accept
  done --> [*]
```

## 常用轻量流程

```mermaid
stateDiagram-v2
  direction LR

  state "backend-only" as BackendOnly {
    [*] --> b_planned
    b_planned --> b_contract_ready: product.contract
    b_contract_ready --> b_backend_done: backend.implement
    b_backend_done --> b_tested: test.api
    b_tested --> b_done: product.accept
    b_done --> [*]
  }

  state "frontend-only" as FrontendOnly {
    [*] --> f_planned
    f_planned --> f_contract_ready: product.contract
    f_contract_ready --> f_frontend_done: frontend.implement
    f_frontend_done --> f_ui_reviewed: designer.review
    f_ui_reviewed --> f_done: product.accept
    f_done --> [*]
  }

  state "product/docs/test-only" as TinyFlows {
    [*] --> t_planned
    t_planned --> t_done: product.document / test.regression
    t_done --> [*]
  }
```

## 文件责任

```mermaid
flowchart LR
  Commander["Commander\n调度 / 门禁 / 状态推进"]
  Product["product-agent\nbrief / AC / 验收"]
  Backend["backend-agent\nAPI 实现 / notes"]
  Test["test-agent\nAPI/E2E 报告"]
  Frontend["frontend-agent\n页面 / 联调"]
  Designer["designer-agent\nUI 走查"]

  Commander --> Product
  Commander --> Backend
  Commander --> Test
  Commander --> Frontend
  Commander --> Designer

  Product --> Brief["brief.md\napi.openapi.yaml\ntest/coverage.md"]
  Backend --> BackendNotes["backend/notes.md"]
  Test --> TestReports["test/report.md\ntest/e2e-report.md"]
  Frontend --> FrontendNotes["frontend/integration.md"]
  Designer --> DesignNotes["design/ui-review.md"]
```

## 一句话理解

```text
用户只找 Commander；
Commander 看 status.yaml 的 workflow、phase、next；
tasks.yaml 按 workflow 决定下一个角色；
角色卡限制职责边界；
功能包保存所有交接产物。
```
