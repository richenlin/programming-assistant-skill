# 编程助手 - 快速开始指南

## 5分钟快速上手

### 推荐方式：一键安装（1分钟）

使用提供的安装脚本，自动完成所有配置：

```bash
# 完整安装（OpenCode + Cursor + MCP）
./install.sh --all --with-mcp
```

这个命令会：
1. ✅ 安装到 OpenCode（全局）
2. ✅ 安装到 Cursor（全局规则）
3. ✅ 配置 MCP 服务器（context7, sequential-thinking, mcp-feedback-enhanced）
4. ✅ 验证安装结果

**安装完成后，重启 OpenCode 和 Cursor 即可使用！**

其他选项：
```bash
./install.sh                    # 交互式安装
./install.sh --opencode         # 仅安装到 OpenCode
./install.sh --cursor           # 仅安装到 Cursor
./install.sh --dry-run          # 预览安装，不实际执行
./install.sh --help             # 显示帮助信息
```

卸载：
```bash
./uninstall.sh --all --with-mcp
```

---

### 传统方式：手动安装（5分钟）

#### 第1步：准备文件（1分钟）

#### 如果你使用OpenCode

> 📚 参考: [OpenCode Skills 官方文档](https://opencode.ai/docs/skills/)

**一键安装（推荐）**：
```bash
./install.sh --opencode --with-mcp
```

这将自动：
1. ✅ 安装 skill 到 `~/.config/opencode/skill/programming-assistant/`
2. ✅ 配置 MCP 服务器
3. ✅ 验证安装结果

**手动安装**：
```bash
# 创建全局 skill 目录（注意路径）
mkdir -p ~/.config/opencode/skill/programming-assistant

# 复制 SKILL.md
cp SKILL.md ~/.config/opencode/skill/programming-assistant/

# 配置 MCP 服务器（可选）
mkdir -p ~/.config/opencode
cat > ~/.config/opencode/opencode.json << 'EOF'
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp"]
    },
    "sequential-thinking": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
    },
    "mcp-feedback-enhanced": {
      "command": "uvx",
      "args": ["mcp-feedback-enhanced@latest"]
    }
  }
}
EOF

# 重启 OpenCode
```

**项目级安装**（如果需要项目特定配置）：
```bash
# 在项目根目录
cd /your/project

# 创建项目 skill 目录
mkdir -p .opencode/skill/programming-assistant

# 复制 SKILL.md
cp /path/to/SKILL.md .opencode/skill/programming-assistant/
```

**重要提示**: 
- ✅ 全局路径: `~/.config/opencode/skill/<name>/SKILL.md`
- ✅ 项目路径: `.opencode/skill/<name>/SKILL.md`
- ❌ 错误路径: `~/.opencode/skills/`（注意不是这个！）
- 📖 详细说明: [OPENCODE-SKILLS-正确配置.md](OPENCODE-SKILLS-正确配置.md)

#### 如果你使用Cursor

**一键安装（推荐）**：
```bash
./install.sh --cursor --with-mcp
```

**手动安装（全局规则）**：
```bash
# 创建rules目录（如果不存在）
mkdir -p ~/.cursor/rules

# 复制SKILL.md到全局规则目录
cp SKILL.md ~/.cursor/rules/programming-assistant.md

# 配置MCP服务器（编辑 ~/.cursor/mcp.json）
# 参考 3.MCP.txt 文件

# 重启Cursor以使更改生效
```

**手动安装（项目级）**：
在项目根目录创建 `.cursorrules` 文件，添加：
```markdown
# 引用编程助手skill

你是一名资深的软件工程师和架构师"ZhiSi Architect"，拥有超过10年的全栈开发经验。

完整指令请参考: programming-assistant.skill.md
```

### 第3步：开始使用（2分钟）

#### 场景1：创建新项目
```
帮我开发一个简单的博客系统：
- 文章列表和详情页
- 评论功能
- 用户注册和登录

前端用Vue 3，后端用Go，数据库用PostgreSQL。
```

助手会自动：
1. 与你确认需求
2. 生成 SOLUTION.md 和 TASK.md
3. 创建项目结构
4. 准备开始开发

#### 场景2：实现功能
```
实现用户注册功能
```

助手会自动：
1. 查阅相关文档（通过Context7）
2. 设计API接口
3. 实现前后端代码
4. 编写测试
5. 验证功能

#### 场景3：修复问题
```
用户登录后token过期时间太短，如何延长？
```

助手会自动：
1. 分析问题原因
2. 查找最佳实践
3. 提供解决方案
4. 实施修改
5. 测试验证

## 在OpenCode中使用

> 📚 官方文档: https://opencode.ai/docs/skills/

### 使用方法

安装完成后，**重启 OpenCode**，skill 会自动加载：

```bash
opencode
```

OpenCode 会自动发现可用的 skills，Agent 会在需要时调用：
```javascript
skill({ name: "programming-assistant" })
```

您也可以在对话中明确提示：
```
使用 programming-assistant skill 帮我开发一个 API 服务
```

### 验证安装

**方法 1: 检查文件**
```bash
# 检查全局 skill
ls -la ~/.config/opencode/skill/programming-assistant/SKILL.md

# 检查 frontmatter
head -15 ~/.config/opencode/skill/programming-assistant/SKILL.md
```

**方法 2: 启动 OpenCode**

启动后，Agent 应该能看到 `programming-assistant` 在可用 skills 列表中。

### 故障排查

**问题1: Skill 没有出现**

检查清单：
1. ✅ 文件名是 `SKILL.md`（全大写）
2. ✅ 路径正确: `~/.config/opencode/skill/programming-assistant/SKILL.md`
3. ✅ frontmatter 包含 `name` 和 `description`
4. ✅ `name` 值为 `programming-assistant`（匹配目录名）
5. ✅ 已重启 OpenCode

**问题2: 路径错误**

❌ 错误路径:
- `~/.opencode/skills/` (缺少 `config`，且 `skills` 是复数)
- `~/.opencode/skill/`  (缺少 `config`)

✅ 正确路径:
- `~/.config/opencode/skill/programming-assistant/SKILL.md`

**问题3: MCP 工具无法使用**

MCP 服务器需要单独配置（不包含在 skill 中）：

```bash
# 创建全局 MCP 配置
mkdir -p ~/.config/opencode
cat > ~/.config/opencode/opencode.json << 'EOF'
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp"]
    },
    "sequential-thinking": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
    },
    "mcp-feedback-enhanced": {
      "command": "uvx",
      "args": ["mcp-feedback-enhanced@latest"]
    }
  }
}
EOF
```

或使用安装脚本：
```bash
./install.sh --opencode --with-mcp
```

详细说明请查看 [OPENCODE-SKILLS-正确配置.md](OPENCODE-SKILLS-正确配置.md)。

## 在Cursor中使用

### 配置方法

**方法1: .cursorrules文件**
在项目根目录创建或编辑 `.cursorrules` 文件，添加：
```markdown
# 引用编程助手skill

你是一名资深的软件工程师和架构师"ZhiSi Architect"，拥有超过10年的全栈开发经验。

完整指令请参考: programming-assistant.skill.md
```

**方法2: .cursorrules.md文件**
在项目根目录创建 `.cursorrules.md` 文件，包含完整skill内容：
```markdown
<!-- 复制 programming-assistant.skill.md 的全部内容到这里 -->
```

### 使用方法

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

## 模板文件

### SOLUTION.md 模板
```markdown
# 项目架构设计

## 项目概述
[描述项目目标和核心功能]

## 技术栈
- 前端: [框架和版本]
- 后端: [框架和版本]
- 数据库: [数据库类型和版本]
- 云服务:
  - 私有云: Docker, Docker Compose, Kubernetes
  - 公有云/混合云: 腾讯云、阿里云、华为云为主，AWS/Azure/Google Cloud为补充
- DevOps:
  - CI/CD: 适配私有云和公有云/混合云两类场景
- 其他: [其他工具等]

## 文件结构
```
project/
├── frontend/          # 前端代码
├── backend/           # 后端代码
├── database/          # 数据库脚本
└── docs/              # 文档
```

## 架构说明
[描述各部分的作用和连接方式]

## 数据模型
[描述核心数据表和关系]

## API设计
[列出主要的API端点]

## 状态管理
[描述状态存储位置和管理方式]
```

### TASK.md 模板
```markdown
# 构建任务列表

## 阶段1：项目初始化
- [ ] 创建项目目录结构
- [ ] 初始化前端项目
- [ ] 初始化后端项目
- [ ] 配置数据库连接

## 阶段2：核心功能
- [ ] 实现用户认证模块
- [ ] 实现数据模型
- [ ] 实现API接口
- [ ] 实现前端页面

## 阶段3：测试和优化
- [ ] 编写单元测试
- [ ] 编写集成测试
- [ ] 性能优化
- [ ] 部署准备
```

## 核心原则（牢记）

### 必须遵守
1. 每次只完成一个任务
2. 完成后立即测试
3. 用最少代码完成任务
4. 不破坏现有功能

### 严禁事项
1. 不要使用emoji
2. 不要过度设计
3. 不要做无关修改
4. 不要跳过测试

## MCP工具说明

### Context7
- **用途**: 获取最新文档和代码示例
- **何时使用**: 不熟悉某个库或框架的用法时
- **示例**: "使用Context7查询Vue 3的Composition API最佳实践"

### sequential-thinking
- **用途**: 深度分析复杂问题
- **何时使用**: 需要深入思考或拆解复杂任务时
- **示例**: "使用sequential-thinking分析如何设计高并发的订单系统"

### mcp-feedback-enhanced
- **用途**: 与用户交互，获取反馈
- **何时使用**: 需要确认理解或展示进度时
- **示例**: "使用mcp-feedback-enhanced向用户展示设计原型"

## 常见问题

### Q: 如何更新skill？
A: 替换对应的skill文件后，需要**重启OpenCode**才能使更改生效。

### Q: MCP工具不工作怎么办？
A: 检查以下内容：
1. 确认已安装 `npx` 和 `uvx` 运行时
2. 参考 `3.MCP.txt` 中的配置示例
3. 尝试手动注册 MCP 服务器（见上方"故障排查"）
4. 确认 `programming-assistant.skill.json` 文件正确加载

### Q: 为什么推荐全局安装而不是项目级安装？
A: 全局安装更加稳定，OpenCode 会优先加载全局 skills，避免项目级加载的不确定性和潜在冲突。

### Q: 可以自定义skill吗？
A: 可以，基于现有的skill文件进行修改，添加你自己的规则和工作流程。

### Q: 支持其他编程语言吗？
A: 是的，skill是语言无关的，可以支持任何编程语言和框架。

### Q: 如何禁用某个MCP工具？
A: 编辑 `programming-assistant.skill.json`，将对应工具的 `enabled` 设置为 `false`。

## 文件说明

```
SKILL.md                          # OpenCode/Cursor 规范格式的 skill 文件（新增）
install.sh                        # 一键安装脚本（新增）
uninstall.sh                      # 卸载脚本（新增）
programming-assistant.skill.md     # 传统格式 skill 文件（保留，作为备份）
programming-assistant.skill.json    # skill 配置文件（保留，作为元数据）
README.md                         # 项目说明文档（本文件）
QUICK-START.md                   # 快速开始指南
3.MCP.txt                        # MCP 服务器配置示例
```

## 获取帮助

### 遇到问题？
1. 查看 `README.md` 了解完整文档
2. 检查 `programming-assistant.skill.json` 中的配置
3. 确认MCP服务器是否正常运行
4. 尝试手动注册 MCP 服务器：
   ```bash
   opencode mcp add context7 npx -y @upstash/context7-mcp
   opencode mcp add sequential-thinking npx -y @modelcontextprotocol/server-sequential-thinking
   opencode mcp add mcp-feedback-enhanced uvx mcp-feedback-enhanced@latest
   ```

### 技能提升
- 阅读 `programming-assistant.skill.md` 了解完整工作流程
- 尝试不同的项目类型练习
- 根据实际需求自定义skill规则

## 下一步

1. 阅读完整的 `README.md` 了解详细文档
2. 开始你的第一个项目
3. 记录使用经验和改进建议

祝你编程愉快！
