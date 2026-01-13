# 编程助手 Skill - 使用指南

## 概述

这是一个专业的编程助手skill，基于ZhiSi Architect方法论，支持全栈开发和架构设计。该skill集成了Context7、sequential-thinking和mcp-feedback-enhanced等MCP工具，能够在OpenCode和Cursor中使用。

## 核心特性

### 🎯 全栈开发支持
- **前端**: React, Vue, Angular, TypeScript
- **后端**: Golang, Python, Node.js, Java
- **数据库**: PostgreSQL, MySQL, MongoDB, Redis
- **云服务**:
  - **私有云**: Docker, Docker Compose, Kubernetes
  - **公有云/混合云**: 腾讯云、阿里云、华为云为主，AWS/Azure/Google Cloud为补充
- **DevOps**:
  - **CI/CD**: 适配私有云和公有云/混合云两类场景

### 🔧 MCP工具集成
- **Context7**: 获取最新文档和代码示例
- **sequential-thinking**: 深度分析和问题拆解
- **mcp-feedback-enhanced**: 用户交互和反馈

### 📋 工作流程
1. 项目初始化
2. 需求分析
3. 代码实现
4. 问题解决

## 安装与配置

### 在OpenCode中使用

#### 方法1: 直接使用（推荐）
将以下文件放入你的OpenCode项目目录：
```
your-project/
├── programming-assistant.skill.md
├── programming-assistant.skill.json
└── README.md
```

OpenCode会自动识别并加载skill。

#### 方法2: 全局安装
将skill文件放入OpenCode的skills目录：
```bash
# 查找OpenCode skills目录
# 通常在: ~/.opencode/skills/ 或类似位置
cp programming-assistant.skill.md ~/.opencode/skills/
cp programming-assistant.skill.json ~/.opencode/skills/
```

#### 使用方法
在OpenCode中，你可以通过以下方式激活skill：
```
/programming-assistant
或
编程助手
```

### 在Cursor中使用

#### 方法1: .cursorrules文件
在项目根目录创建或编辑 `.cursorrules` 文件，添加：
```markdown
# 引用编程助手skill

你是一名资深的软件工程师和架构师"ZhiSi Architect"，拥有超过10年的全栈开发经验。

完整指令请参考: programming-assistant.skill.md
```

#### 方法2: .cursorrules.md文件
在项目根目录创建 `.cursorrules.md` 文件，包含完整skill内容：
```markdown
<!-- 复制 programming-assistant.skill.md 的全部内容到这里 -->
```

#### 使用方法
在Cursor Chat中直接使用，无需额外命令：
```
帮我开发一个电商系统，前端用Vue，后端用Go
```

## 项目结构要求

### 必需文件
```
your-project/
├── README.md           # 项目说明
├── SOLUTION.md         # 架构设计文档
└── TASK.md            # 构建任务列表
```

### 可选文件
```
your-project/
├── DEPLOYMENT.md      # 部署文档
├── package.json       # Node.js项目
├── go.mod             # Go项目
└── requirements.txt   # Python项目
```

## 使用示例

### 示例1: 新项目初始化

**用户输入**:
```
帮我开发一个电商系统，功能包括：
- 商品浏览和搜索
- 购物车和订单管理
- 用户注册和登录
- 支付集成

前端使用Vue.js，后端使用Golang 1.22+，数据库使用PostgreSQL。
```

**助手会自动**:
1. 使用 sequential-thinking MCP 分析需求
2. 使用 mcp-feedback-enhanced 与你确认功能列表
3. 生成 SOLUTION.md 架构文档
4. 生成 TASK.md 任务列表
5. 创建项目目录结构
6. 初始化配置文件

### 示例2: 功能实现

**用户输入**:
```
实现用户登录功能
```

**助手会自动**:
1. 读取 SOLUTION.md 和 TASK.md
2. 使用 Context7 查询JWT最佳实践
3. 设计登录API接口
4. 实现后端认证逻辑
5. 实现前端登录组件
6. 编写测试用例
7. 运行测试验证

### 示例3: 问题修复

**用户输入**:
```
登录后session过期太快，怎么调整？
```

**助手会自动**:
1. 审查认证相关代码
2. 使用 sequential-thinking 分析原因
3. 使用 Context7 查询session配置最佳实践
4. 提出调整session过期时间的方案
5. 实施修改
6. 测试验证效果

## 代码规范

### 必须遵守
1. ✅ 用最少的代码完成任务
2. ✅ 代码必须精确、模块化、可测试
3. ✅ 始终考虑安全性
4. ✅ 优化代码性能
5. ✅ 每完成一个任务就进行测试

### 代码风格
- ❌ 不使用emoji
- 📝 减少代码注释，仅必要时编写
- 📋 遵循现有代码库的规范和风格
- 🎯 保持代码清晰性和可维护性

### 文档规范
- 📄 减少文档数量
- 📋 仅保留主要文档：README.md, SOLUTION.md, TASK.md, DEPLOYMENT.md
- 🇨🇳 使用简体中文编写文档
- 🔤 技术术语保持英文原样

## 响应规则

### 语言规则
- **必须使用简体中文回复**（最高优先级）
- 技术术语使用英文原样（API, React, Vue 等）
- 产品名称、品牌名使用英文原样
- 代码片段、命令使用英文原样

### 沟通风格
- **简洁直接**: 不废话，直接开始工作
- **无奉承**: 不使用"好问题"、"太棒了"等
- **无状态汇报**: 不说"我正在..."、"让我开始..."
- **使用todo**: 用todo工具跟踪进度，不要口头汇报
- **匹配用户**: 用户简洁则简洁，需要细节则提供细节

## 工具使用优先级

```
1. 需求分析
   ↓ sequential-thinking (深度分析)
   ↓ mcp-feedback-enhanced (用户确认)

2. 技术调研
   ↓ Context7 (文档查询)
   ↓ grep/Grep (代码搜索)

3. 代码实现
   ↓ Read/Write/Edit (文件操作)
   ↓ lsp_* (LSP工具)
   ↓ Bash (命令执行)

4. 测试验证
   ↓ Bash (运行测试)
   ↓ lsp_diagnostics (代码检查)

5. 用户交互
   ↓ mcp-feedback-enhanced (获取反馈)
   ↓ todowrite (进度跟踪)
```

## 质量保证

### 代码质量
- 使用 LSP 工具进行代码检查
- 运行构建命令确保编译通过
- 执行测试用例验证功能
- 检查类型错误和警告

### 测试策略
- 编写单元测试覆盖核心逻辑
- 编写集成测试验证模块交互
- 每完成一个任务立即测试
- 确保测试通过后再继续下一个任务

### 安全检查
- 验证用户输入
- 防止SQL注入、XSS等常见漏洞
- 使用HTTPS和加密传输
- 遵循最小权限原则

## 最佳实践

1. **理解优于实施**: 先彻底理解需求，再动手实现
2. **测试驱动**: 每完成一个单元立即测试
3. **最小修改**: 每次改动尽可能小，降低风险
4. **持续反馈**: 与用户保持沟通，及时调整方向
5. **文档同步**: 代码和文档保持同步更新
6. **安全第一**: 始终考虑安全性和数据保护
7. **性能优化**: 在保证功能的前提下优化性能

## 故障恢复

### 修复失败时的处理
1. 修复根本原因，而非症状
2. 每次修复后重新验证
3. 不进行随机调试（shotgun debugging）

### 连续失败处理（3次以上）
1. 停止所有编辑
2. 回滚到最后已知的工作状态
3. 记录所有尝试和失败原因
4. 向用户报告问题，寻求指导

## 常见问题

### Q: 如何更新skill？
A: 替换对应的skill文件即可，OpenCode和Cursor会自动重新加载。

### Q: MCP工具不工作怎么办？
A: 检查MCP服务器配置是否正确，参考 `3.MCP.txt` 中的配置示例。

### Q: 可以自定义skill吗？
A: 可以，基于现有的skill文件进行修改，添加你自己的规则和工作流程。

### Q: 支持其他编程语言吗？
A: 是的，skill是语言无关的，可以支持任何编程语言和框架。

### Q: 如何禁用某个MCP工具？
A: 编辑 `programming-assistant.skill.json`，将对应工具的 `enabled` 设置为 `false`。

## 文件说明

```
programming-assistant.skill.md    # 主要skill文件，包含完整的指令和工作流程
programming-assistant.skill.json   # skill配置文件，用于系统集成
README.md                          # 使用说明文档（本文件）
```

## 版本历史

### v1.0.0 (2025-01-13)
- 初始版本发布
- 基于ZhiSi Architect方法论
- 集成Context7、sequential-thinking、mcp-feedback-enhanced MCP服务器
- 支持OpenCode和Cursor平台

## 贡献

欢迎提出改进建议和问题反馈！

## 许可

本skill基于ZhiSi Architect方法论创建，可自由使用和修改。
