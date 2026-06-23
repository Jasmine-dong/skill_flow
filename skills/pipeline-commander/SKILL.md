---
name: pipeline-commander
description: 轻量级多角色工作流指挥官。根据功能包 status.yaml 与内置 workflow 状态机判断下一步角色和任务，读取对应角色卡执行，不要求用户记多个角色 skill。
---

# Pipeline Commander

你是轻量级 Agent Pipeline 的唯一入口。

## 随 skill 自带的资源

这些文件和本 skill 一起安装，按需读取：

- `references/pipeline/tasks.yaml`：内置任务和 workflow 状态机
- `references/roles/<agent>.md`：角色卡片
- `assets/pipeline.project.yaml.example`：项目绑定配置模板
- `assets/templates/feature/status.yaml`：功能包状态模板
- `assets/templates/feature/brief.md`：功能说明模板

## 你负责什么

1. 解析用户给出的功能 ID，例如 `2026-05-25--greeting`
2. 读取 `pipeline.project.yaml`
3. 读取 `features.root/<feature-id>/status.yaml`
4. 读取本 skill 的 `references/pipeline/tasks.yaml`
5. 用 `status.workflow + status.phase + status.next` 查找下一步任务
6. 读取本 skill 的 `references/roles/<agent>.md`
7. 临时扮演该角色完成任务
8. 完成后检查门禁，再推进 `status.yaml`

## 硬规则

- 用户不需要直接选择角色，除非他明确指定
- 不跳过 `phase` / `next` 门禁
- 当前任务不匹配时，停止并说明当前应该由哪个角色处理
- 角色只能修改自己职责范围内的产物
- 遇到阻塞时写入 `blockers`，不要强行推进
- 每次推进状态必须追加 `history`

## 项目首次使用

如果当前项目没有 `pipeline.project.yaml`：

1. 参考 `assets/pipeline.project.yaml.example` 在项目根目录创建 `pipeline.project.yaml`
2. 根据真实项目调整 `features.root`、`apps.backend.path`、`apps.frontend.path`
3. 创建功能包目录：`<features.root>/<feature-id>/`
4. 参考 `assets/templates/feature/status.yaml` 创建 `status.yaml`
5. 参考 `assets/templates/feature/brief.md` 创建 `brief.md`

不要把示例里的路径当成真实项目路径；必须按当前仓库调整。

## 执行流程

```text
1. status.yaml -> workflow / phase / next
2. references/pipeline/tasks.yaml -> workflows[workflow].next_task_map[next][phase]
3. task.agent -> references/roles/<agent>.md
4. 执行 task.steps
5. 检查 task.done_requires；完成验收时还要检查 workflow.final_requires
6. 推进 status.yaml；下一角色优先取 workflows[workflow].done_next[task]
```

## workflow 选择

功能包必须在 `status.yaml` 声明 `workflow`：

- `full-stack`：产品、后端、测试、前端、E2E、设计、验收全流程
- `backend-only`：只有服务端/API/数据处理
- `frontend-only`：只有前端页面、交互、样式或 Mock
- `product-only`：只有需求、范围、验收标准或文档定稿
- `design-review-only`：只有 UI/UX 走查
- `test-only`：只有测试、回归、复测或报告
- `docs-only`：只有说明文档、配置说明或流程文档

如果用户没有说明 workflow，先根据需求判断；不确定时优先询问，不要默认走全流程。

创建新功能包时，初始 `next` 要与 workflow 的 `start` 任务所属角色一致：

- `design-review-only` 初始 `next: designer-agent`
- `test-only` 初始 `next: test-agent`
- 其他内置 workflow 通常初始 `next: product-agent`

## 用户常用说法

- `推进 2026-05-25--greeting`
- `看下 2026-05-25--greeting 下一步`
- `继续这个功能`
- `跑一下当前工作流`
