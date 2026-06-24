# Agent Pipeline Commander 架构图

## 总览

```mermaid
flowchart TD
  User["用户\n只提供功能 ID / 推进意图"]
  Install["install.sh\n统一安装入口"]
  Shared["shared/\ntasks / roles / templates"]
  Adapters["adapters/\nCodex / Claude Code / AGENTS.md"]
  Commander["pipeline-commander\n唯一工作流入口"]
  Config["pipeline.project.yaml\n项目目录 / 文档目录 / URL"]
  ProjectDetails["project-details.md\n项目画像 / 技术栈 / 目录 / 命令 / 约定 / 坑点"]
  Status["features.root/<feature-id>/status.yaml\nworkflow / phase / owner / next / blockers / history"]
  Tasks["tasks.yaml\ntasks + workflows + next_task_map"]
  Common["roles/COMMON.md\n确认 / 阻塞 / 状态通用规则"]
  Role["roles/<agent>.md\n角色边界卡片"]
  Feature["features.root/<feature-id>/\nbrief / api / todos / confirmations / test / notes / design"]

  Install --> Shared
  Install --> Adapters
  Adapters --> Commander
  User --> Commander
  Commander --> Config
  Config --> ProjectDetails
  Commander --> ProjectDetails
  Commander --> Status
  Commander --> Tasks
  Tasks --> Role
  Commander --> Common
  Common --> Role
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
  participant P as pipeline.project.yaml
  participant K as project-details.md
  participant S as status.yaml
  participant T as tasks.yaml
  participant G as COMMON.md
  participant R as role card
  participant F as 功能包文件

  U->>C: 推进 2026-05-25--greeting
  C->>P: 向上查找并读取项目配置
  C->>K: 读取项目画像
  alt 项目画像不存在
    C->>K: 扫描项目并生成项目画像
    C-->>U: 请求确认项目画像
    U-->>C: 确认或补充
  end
  C->>S: 读取 workflow / phase / next
  C->>T: 查询 workflows[workflow].next_task_map[next][phase]
  T-->>C: 返回任务 key 与 agent
  C->>G: 读取通用确认与阻塞规则
  C->>R: 读取 roles/<agent>.md
  C->>F: 按任务步骤读写产物
  alt 遇到问题或不确定
    C-->>U: 发起确认
    U-->>C: 确认或补充
    C->>F: 继续执行并记录确认内容
  end
  alt 项目画像与真实项目冲突
    C->>S: phase=project_rescan_required, next=product-agent, 写入 blockers
    C-->>U: 汇报需要重扫项目画像
  end
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
  Full["full-stack\n澄清 -> 接口/TODO -> 确认 -> Backend/FE -> 分段验收 -> 全量测试 -> 通知"]
  Backend["backend-only\n澄清 -> 接口/TODO -> 确认 -> 后端 -> 后端测试 -> 全量测试 -> 通知"]
  Frontend["frontend-only\n澄清 -> 前端 TODO -> 确认 -> 前端 -> UI -> 前端测试 -> 全量测试 -> 通知"]
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

下图按单步推进展示主路径。实际 full-stack 开发在 `development_ready` 后允许 Backend 和 FE 同步推进；如果当前 AI 工具只能单步执行，Commander 需要先向使用者确认优先推进哪个分支。

```mermaid
stateDiagram-v2
  [*] --> planned
  planned --> project_rescan_required: project_details_mismatch
  development_ready --> project_rescan_required: project_details_mismatch
  backend_done --> project_rescan_required: project_details_mismatch
  frontend_done --> project_rescan_required: project_details_mismatch
  project_rescan_required --> planned: project.rescan / user confirmation
  planned --> requirements_ready: product.clarify
  requirements_ready --> api_contract_ready: backend.api_contract
  api_contract_ready --> frontend_todo_ready: frontend.todo
  frontend_todo_ready --> development_ready: product.confirm_development / confirmation
  development_ready --> backend_done: backend.implement
  backend_done --> backend_tested: test.backend
  backend_tested --> frontend_done: frontend.implement
  frontend_done --> ui_reviewed: designer.review
  ui_reviewed --> frontend_tested: test.frontend
  frontend_tested --> full_tested: test.full
  full_tested --> done: product.accept / notify
  done --> [*]
```

## 常用轻量流程

```mermaid
stateDiagram-v2
  direction LR

  state "backend-only" as BackendOnly {
    [*] --> b_planned
    b_planned --> b_requirements_ready: product.clarify
    b_requirements_ready --> b_api_contract_ready: backend.api_contract
    b_api_contract_ready --> b_development_ready: product.confirm_development
    b_development_ready --> b_backend_done: backend.implement
    b_backend_done --> b_backend_tested: test.backend
    b_backend_tested --> b_full_tested: test.full
    b_full_tested --> b_done: product.accept
    b_done --> [*]
  }

  state "frontend-only" as FrontendOnly {
    [*] --> f_planned
    f_planned --> f_requirements_ready: product.clarify
    f_requirements_ready --> f_frontend_todo_ready: frontend.todo
    f_frontend_todo_ready --> f_development_ready: product.confirm_development
    f_development_ready --> f_frontend_done: frontend.implement
    f_frontend_done --> f_ui_reviewed: designer.review
    f_ui_reviewed --> f_frontend_tested: test.frontend
    f_frontend_tested --> f_full_tested: test.full
    f_full_tested --> f_done: product.accept
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
  Test["test-agent\n分段 / 全量测试报告"]
  Frontend["frontend-agent\n页面 / 联调"]
  Designer["designer-agent\nUI 走查"]

  Commander --> Product
  Commander --> Backend
  Commander --> Test
  Commander --> Frontend
  Commander --> Designer

  Product --> Brief["brief.md\napi.openapi.yaml\ntest/coverage.md"]
  Backend --> BackendNotes["backend/notes.md"]
  Test --> TestReports["test/backend-report.md\ntest/frontend-report.md\ntest/full-report.md"]
  Frontend --> FrontendNotes["frontend/integration.md"]
  Designer --> DesignNotes["design/ui-review.md"]
```

## 一句话理解

```text
用户只找 Commander；
Commander 看 status.yaml 的 workflow、phase、next；
Commander 每次执行前先读 pipeline.project.yaml 和 project-details.md；
tasks.yaml 按 workflow 决定下一个角色；
角色卡限制职责边界；
功能包保存所有交接产物；
项目画像错误时中止当前流程，重扫确认后重新开启。
```
