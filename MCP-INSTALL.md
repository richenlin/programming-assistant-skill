# MCP 安装过程总结

本文档总结了在 OpenCode 和 Cursor 中配置 MCP (Model Context Protocol) 服务器的完整过程。

## 概述

MCP (Model Context Protocol) 是一个协议,允许 AI 助手通过标准化的方式访问外部工具和数据源。本项目集成了三个常用的 MCP 服务器:

1. **context7** - 文档搜索工具
2. **sequential-thinking** - 结构化思考工具
3. **mcp-feedback-enhanced** - 交互反馈工具

## OpenCode MCP 配置

### 配置文件位置
- **配置文件**: `~/.config/opencode/opencode.json`
- **配置字段**: `mcp`

### 配置格式

OpenCode 使用以下 JSON 格式配置 MCP 服务器:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "context7": {
      "type": "remote",
      "url": "https://mcp.context7.com/mcp"
    },
    "sequential-thinking": {
      "type": "local",
      "command": ["npx", "-y", "@modelcontextprotocol/server-sequential-thinking"],
      "enabled": true
    },
    "mcp-feedback-enhanced": {
      "type": "local",
      "command": ["uvx", "mcp-feedback-enhanced@latest"],
      "enabled": true,
      "environment": {
        "MCP_WEB_HOST": "127.0.0.1",
        "MCP_WEB_PORT": "8765",
        "MCP_DEBUG": "false"
      }
    }
  }
}
```

### 配置说明

#### context7
- **类型**: `remote` (远程服务器)
- **URL**: `https://mcp.context7.com/mcp`
- **描述**: 提供文档搜索功能,可以在 AI 助手需要查找文档时使用

#### sequential-thinking
- **类型**: `local` (本地服务器)
- **命令**: `npx -y @modelcontextprotocol/server-sequential-thinking`
- **描述**: 提供结构化思考功能,帮助 AI 进行逐步推理
- **依赖**: 需要 Node.js 和 npx

#### mcp-feedback-enhanced
- **类型**: `local` (本地服务器)
- **命令**: `uvx mcp-feedback-enhanced@latest`
- **描述**: 提供交互式反馈界面,支持 Web UI 和桌面应用
- **依赖**: 需要 Python 和 uvx
- **环境变量**:
  - `MCP_WEB_HOST`: Web 服务器主机地址 (默认: 127.0.0.1)
  - `MCP_WEB_PORT`: Web 服务器端口 (默认: 8765)
  - `MCP_DEBUG`: 调试模式 (默认: false)

### 验证配置

运行以下命令验证 MCP 服务器是否配置成功:

```bash
opencode mcp list
```

成功输出示例:

```
┌  MCP Servers
│
●  ✓ context7  connected
│      https://mcp.context7.com/mcp
│
●  ✓ sequential-thinking  connected
│      npx -y @modelcontextprotocol/server-sequential-thinking
│
●  ✓ mcp-feedback-enhanced  connected
│      uvx mcp-feedback-enhanced@latest
│
└  3 server(s)
```

## Cursor MCP 配置

### 配置文件位置
- **配置文件**: `~/.cursor/mcp.json`
- **配置字段**: `mcpServers`

### 配置格式

Cursor 使用以下 JSON 格式配置 MCP 服务器:

```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp"]
    },
    "sequential-thinking": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"],
      "autoApprove": ["sequentialthinking"]
    },
    "mcp-feedback-enhanced": {
      "command": "uvx",
      "args": ["mcp-feedback-enhanced@latest"],
      "timeout": 600,
      "autoApprove": ["interactive_feedback"]
    }
  }
}
```

### 配置说明

#### context7
- **命令**: `npx -y @upstash/context7-mcp`
- **描述**: 提供文档搜索功能

#### sequential-thinking
- **命令**: `npx -y @modelcontextprotocol/server-sequential-thinking`
- **自动批准**: `["sequentialthinking"]`
- **描述**: 提供结构化思考功能

#### mcp-feedback-enhanced
- **命令**: `uvx mcp-feedback-enhanced@latest`
- **超时**: 600 秒
- **自动批准**: `["interactive_feedback"]`
- **描述**: 提供交互式反馈界面

## 自动安装脚本

本项目的 `install.sh` 脚本支持自动配置 MCP 服务器。

### 使用方法

```bash
# 完整安装（推荐）
./install.sh --all --with-mcp

# 仅安装 OpenCode 并配置 MCP
./install.sh --opencode --with-mcp

# 仅安装 Cursor 并配置 MCP
./install.sh --cursor --with-mcp
```

### 脚本功能

1. **检测环境**: 自动检测已安装的工具 (npx, uvx)
2. **创建配置文件**: 如果配置文件不存在,自动创建
3. **合并配置**: 智能合并 MCP 配置,不覆盖现有配置
4. **备份原文件**: 自动备份配置文件
5. **验证安装**: 验证 MCP 服务器配置是否完整

## 手动配置步骤

如果需要手动配置,请按照以下步骤操作:

### OpenCode

1. 打开配置文件:
   ```bash
   vim ~/.config/opencode/opencode.json
   ```

2. 添加 `mcp` 字段和服务器配置

3. 验证配置:
   ```bash
   opencode mcp list
   ```

### Cursor

1. 打开配置文件:
   ```bash
   vim ~/.cursor/mcp.json
   ```

2. 添加 `mcpServers` 字段和服务器配置

3. 重启 Cursor 以使配置生效

## 常见问题

### Q: npx 命令未找到
A: 需要安装 Node.js。访问 [https://nodejs.org](https://nodejs.org) 下载并安装。

### Q: uvx 命令未找到
A: 需要安装 uv (Python 包管理器)。运行:
```bash
pip install uv
```

### Q: MCP 服务器连接失败
A: 检查以下几点:
- 网络连接是否正常
- 依赖工具是否已正确安装
- 配置文件格式是否正确
- 环境变量是否设置正确

### Q: 如何禁用某个 MCP 服务器?
A: 在配置中设置 `"enabled": false` (OpenCode) 或删除对应的服务器配置 (Cursor)。

### Q: 如何查看 MCP 服务器的状态?
A: OpenCode: `opencode mcp list`

## 参考资料

- [MCP 官方文档](https://modelcontextprotocol.io/)
- [OpenCode MCP 文档](https://opencode.ai/docs/mcp-servers/)
- [Context7 文档](https://github.com/upstash/context7)
- [Sequential Thinking 文档](https://github.com/arben-adm/mcp-sequential-thinking)
- [MCP Feedback Enhanced 文档](https://github.com/Minidoracat/mcp-feedback-enhanced)

## 更新日志

### v1.3.0 (2025-01-16)
- 添加自动 MCP 配置功能
- 支持 OpenCode 和 Cursor 的 MCP 配置
- 智能合并配置,不覆盖现有配置
- 自动备份原配置文件
