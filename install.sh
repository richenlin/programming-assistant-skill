#!/bin/bash
################################################################################
# 编程助手 Skill 一键安装脚本
#
# 功能:
#   安装到 OpenCode (全局)
#   安装到 Cursor (全局规则)
#   自动配置 MCP 服务器
#   覆盖确认和备份
#
# 使用方法:
#   ./install.sh                    # 交互式安装（两个平台都装）
#   ./install.sh --opencode         # 仅安装到 OpenCode
#   ./install.sh --cursor           # 仅安装到 Cursor
#   ./install.sh --with-mcp         # 同时配置 MCP 服务器
#   ./install.sh --all              # 完整安装（推荐）
#   ./install.sh --dry-run          # 预览模式，不实际执行
#   ./install.sh --help             # 显示帮助信息
#
################################################################################

set -euo pipefail

################################################################################
# 配置常量
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
VERSION="1.2.1"

# OpenCode 路径（官方文档：https://opencode.ai/docs/skills/）
# OpenCode 支持两种路径：~/.config/opencode/skill/ 和 ~/.claude/skills/（Claude兼容）
OPENCODE_SKILLS_DIR="$HOME/.config/opencode/skill"
OPENCODE_SKILL_DIR="$OPENCODE_SKILLS_DIR/programming-assistant"
OPENCODE_SKILL_FILE="$OPENCODE_SKILL_DIR/SKILL.md"

# Claude Code 路径（官方文档：https://docs.anthropic.com/en/docs/claude-code/skills）
# Claude Code 使用 ~/.claude/skills/<name>/SKILL.md
CLAUDE_CODE_SKILLS_DIR="$HOME/.claude/skills"
CLAUDE_CODE_SKILL_DIR="$CLAUDE_CODE_SKILLS_DIR/programming-assistant"
CLAUDE_CODE_SKILL_FILE="$CLAUDE_CODE_SKILL_DIR/SKILL.md"

# Cursor 路径
# Cursor 使用 ~/.cursor/rules/ 目录存放全局规则
CURSOR_DIR="$HOME/.cursor"  # Cursor 主目录（用于检测和 MCP 配置）
CURSOR_RULES_DIR="$CURSOR_DIR/rules"  # Cursor 全局规则目录
CURSOR_RULE_FILE="$CURSOR_RULES_DIR/programming-assistant.md"

# 源文件
SOURCE_SKILL_FILE="$SCRIPT_DIR/SKILL.md"
SOURCE_LEGACY_SKILL_FILE="$SCRIPT_DIR/programming-assistant.skill.md"
SOURCE_TEMPLATES_DIR="$SCRIPT_DIR/templates"
SOURCE_COMMAND_DIR="$SCRIPT_DIR/command"
SOURCE_REFERENCE_FILE="$SCRIPT_DIR/reference.md"
SOURCE_EXAMPLES_FILE="$SCRIPT_DIR/examples.md"

# 备份目录（按源目录分类）
OPENCODE_BACKUP_DIR="$HOME/.config/opencode/skill/.backup"
CLAUDE_CODE_BACKUP_DIR="$HOME/.claude/skills/.backup"
CURSOR_BACKUP_DIR="$HOME/.cursor/rules/.backup"
BACKUP_TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

################################################################################
# 辅助函数
################################################################################

# 打印信息
info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

# 打印成功
success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

# 打印警告
warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

# 打印错误
error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

# 打印分隔线
separator() {
    echo "========================================================================"
}

# 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 确认提示
confirm() {
    local message="$1"
    local default="${2:-n}"

    if [ "$default" = "y" ]; then
        read -p "$message [Y/n] " -n 1 -r response
        response=${response:-y}
    else
        read -p "$message [y/N] " -n 1 -r response
        response=${response:-n}
    fi
    echo

    [[ "$response" =~ ^[Yy]$ ]]
}

# 创建备份
# 参数: $1 - 要备份的文件, $2 - 备份类型 (opencode|claude_code|cursor)
backup_file() {
    local file="$1"
    local backup_type="${2:-opencode}"
    
    if [ -f "$file" ]; then
        local backup_dir
        case "$backup_type" in
            cursor)
                backup_dir="$CURSOR_BACKUP_DIR"
                ;;
            claude_code)
                backup_dir="$CLAUDE_CODE_BACKUP_DIR"
                ;;
            *)
                backup_dir="$OPENCODE_BACKUP_DIR"
                ;;
        esac
        
        mkdir -p "$backup_dir"
        local backup_file="$backup_dir/$(basename "$file").$BACKUP_TIMESTAMP"
        cp "$file" "$backup_file"
        info "已备份: $file -> $backup_file"
    fi
}

################################################################################
# 检测和验证
################################################################################

# 检测源文件是否存在
check_source_file() {
    if [ ! -f "$SOURCE_SKILL_FILE" ]; then
        error "找不到源文件: $SOURCE_SKILL_FILE"
        if [ -f "$SOURCE_LEGACY_SKILL_FILE" ]; then
            info "发现遗留文件，将使用: $SOURCE_LEGACY_SKILL_FILE"
            SOURCE_SKILL_FILE="$SOURCE_LEGACY_SKILL_FILE"
        else
            exit 1
        fi
    fi
}

# 检查 OpenCode 安装
check_opencode() {
    if command_exists opencode; then
        local version=$(opencode --version 2>/dev/null || echo "unknown")
        info "检测到 OpenCode CLI: v$version"
        return 0
    else
        warn "未检测到 OpenCode CLI，将跳过 OpenCode 安装"
        return 1
    fi
}

# 检查 Claude Code 安装
check_claude_code() {
    if command_exists claude; then
        local version=$(claude --version 2>/dev/null || echo "unknown")
        info "检测到 Claude Code CLI: $version"
        return 0
    else
        warn "未检测到 Claude Code CLI，将跳过 Claude Code 安装"
        return 1
    fi
}

# 检查 Cursor 安装
check_cursor() {
    if [ -d "$CURSOR_DIR" ]; then
        info "检测到 Cursor 安装: $CURSOR_DIR"
        return 0
    else
        warn "未检测到 Cursor，将跳过 Cursor 安装"
        return 1
    fi
}

# 检查 MCP 工具是否可用
check_mcp_tools() {
    local missing_tools=()
    local all_available=true

    # 检查 npx
    if ! command_exists npx; then
        missing_tools+=("npx (需要Node.js)")
        all_available=false
    fi

    # 检查 uvx
    if ! command_exists uvx; then
        missing_tools+=("uvx (需要Python的uv工具)")
        all_available=false
    fi

    if [ "$all_available" = false ]; then
        warn "以下MCP工具未安装:"
        for tool in "${missing_tools[@]}"; do
            warn "  - $tool"
        done
        warn "MCP功能将不可用，但skill仍然可以正常使用"
        warn "建议安装缺失的工具以启用完整MCP功能"
        return 1
    else
        info "所有MCP工具已安装"
        return 0
    fi
}

################################################################################
# 安装 OpenCode Skill
################################################################################

install_opencode_skill() {
    info "安装 OpenCode Skill..."

    # 检查是否覆盖
    if [ -f "$OPENCODE_SKILL_FILE" ]; then
        warn "目标文件已存在: $OPENCODE_SKILL_FILE"
        if [ "$DRY_RUN" = true ]; then
            info "DRY-RUN: 将覆盖 $OPENCODE_SKILL_FILE"
            return 0
        fi

        if ! confirm "是否覆盖现有文件？"; then
            info "跳过 OpenCode 安装"
            return 1
        fi

        backup_file "$OPENCODE_SKILL_FILE" "opencode"
    fi

    if [ "$DRY_RUN" = true ]; then
        info "DRY-RUN: 将创建目录 $OPENCODE_SKILL_DIR"
        info "DRY-RUN: 将复制 $SOURCE_SKILL_FILE -> $OPENCODE_SKILL_FILE"
        return 0
    fi

    # 创建目录
    mkdir -p "$OPENCODE_SKILL_DIR"

    cp "$SOURCE_SKILL_FILE" "$OPENCODE_SKILL_FILE"

    [ -f "$SOURCE_REFERENCE_FILE" ] && cp "$SOURCE_REFERENCE_FILE" "$OPENCODE_SKILL_DIR/"
    [ -f "$SOURCE_EXAMPLES_FILE" ] && cp "$SOURCE_EXAMPLES_FILE" "$OPENCODE_SKILL_DIR/"

    if [ -d "$SOURCE_TEMPLATES_DIR" ]; then
        mkdir -p "$OPENCODE_SKILL_DIR/templates"
        cp -r "$SOURCE_TEMPLATES_DIR"/* "$OPENCODE_SKILL_DIR/templates/" 2>/dev/null || true
        info "模板文件已安装到: $OPENCODE_SKILL_DIR/templates/"
    fi

    if [ -d "$SOURCE_COMMAND_DIR" ]; then
        mkdir -p "$OPENCODE_SKILL_DIR/command"
        cp -r "$SOURCE_COMMAND_DIR"/* "$OPENCODE_SKILL_DIR/command/" 2>/dev/null || true
        info "命令文件已安装到: $OPENCODE_SKILL_DIR/command/"
    fi

    success "OpenCode Skill 安装完成: $OPENCODE_SKILL_FILE"
}

# 配置 OpenCode MCP 服务器
configure_opencode_mcp() {
    info "配置 OpenCode MCP 服务器..."

    # 检查MCP工具
    if ! check_mcp_tools; then
        warn "MCP工具未完全安装，将跳过MCP配置"
        warn "skill仍然可以使用，但MCP功能将不可用"
        return 0
    fi

    local opencode_mcp_file="$HOME/.config/opencode/mcp.json"
    local script_mcp_file="$SCRIPT_DIR/mcp-config.json"

    if [ ! -f "$script_mcp_file" ]; then
        warn "未找到 MCP 配置模板: $script_mcp_file"
        return 1
    fi

    if [ "$DRY_RUN" = true ]; then
        info "DRY-RUN: 将检查并创建 $opencode_mcp_file"
        return 0
    fi

    if [ ! -f "$opencode_mcp_file" ]; then
        info "创建 OpenCode MCP 配置文件"
        mkdir -p "$(dirname "$opencode_mcp_file")"
        cat > "$opencode_mcp_file" << 'EOF'
{
  "mcpServers": {}
}
EOF
    fi

    info "请手动配置 OpenCode MCP: $opencode_mcp_file"
    info "参考配置: $script_mcp_file"
    info ""
    info "需要在 $opencode_mcp_file 中添加以下 MCP 服务器:"
    info "  - context7"
    info "  - sequential-thinking"
    info "  - mcp-feedback-enhanced"

    success "OpenCode MCP 配置指南完成"
}

verify_opencode() {
    if [ "$DRY_RUN" = true ]; then
        info "DRY-RUN: 跳过验证"
        return 0
    fi

    info "验证 OpenCode 安装..."

    if [ ! -f "$OPENCODE_SKILL_FILE" ]; then
        error "SKILL.md 文件不存在"
        return 1
    fi

    info "✓ SKILL.md 文件存在"

    if grep -q "^name: " "$OPENCODE_SKILL_FILE" && grep -q "^description: " "$OPENCODE_SKILL_FILE"; then
        info "✓ YAML frontmatter 格式正确"
    else
        error "YAML frontmatter 格式不正确"
        return 1
    fi

    local opencode_mcp_file="$HOME/.config/opencode/mcp.json"
    if [ -f "$opencode_mcp_file" ]; then
        info "✓ MCP 配置文件存在: $opencode_mcp_file"
        info "  请手动验证 MCP 服务器配置"
    else
        warn "MCP 配置文件不存在，请手动配置"
    fi

    success "OpenCode 验证完成"
}

################################################################################
# 安装 Claude Code Skill
################################################################################

install_claude_code_skill() {
    info "安装 Claude Code Skill..."

    if [ -f "$CLAUDE_CODE_SKILL_FILE" ]; then
        warn "目标文件已存在: $CLAUDE_CODE_SKILL_FILE"
        if [ "$DRY_RUN" = true ]; then
            info "DRY-RUN: 将覆盖 $CLAUDE_CODE_SKILL_FILE"
            return 0
        fi

        if ! confirm "是否覆盖现有文件？"; then
            info "跳过 Claude Code 安装"
            return 1
        fi

        backup_file "$CLAUDE_CODE_SKILL_FILE" "claude_code"
    fi

    if [ "$DRY_RUN" = true ]; then
        info "DRY-RUN: 将创建目录 $CLAUDE_CODE_SKILL_DIR"
        info "DRY-RUN: 将复制 $SOURCE_SKILL_FILE -> $CLAUDE_CODE_SKILL_FILE"
        return 0
    fi

    mkdir -p "$CLAUDE_CODE_SKILL_DIR"
    cp "$SOURCE_SKILL_FILE" "$CLAUDE_CODE_SKILL_FILE"

    [ -f "$SOURCE_REFERENCE_FILE" ] && cp "$SOURCE_REFERENCE_FILE" "$CLAUDE_CODE_SKILL_DIR/"
    [ -f "$SOURCE_EXAMPLES_FILE" ] && cp "$SOURCE_EXAMPLES_FILE" "$CLAUDE_CODE_SKILL_DIR/"

    if [ -d "$SOURCE_TEMPLATES_DIR" ]; then
        mkdir -p "$CLAUDE_CODE_SKILL_DIR/templates"
        cp -r "$SOURCE_TEMPLATES_DIR"/* "$CLAUDE_CODE_SKILL_DIR/templates/" 2>/dev/null || true
        info "模板文件已安装到: $CLAUDE_CODE_SKILL_DIR/templates/"
    fi

    if [ -d "$SOURCE_COMMAND_DIR" ]; then
        mkdir -p "$CLAUDE_CODE_SKILL_DIR/command"
        cp -r "$SOURCE_COMMAND_DIR"/* "$CLAUDE_CODE_SKILL_DIR/command/" 2>/dev/null || true
        info "命令文件已安装到: $CLAUDE_CODE_SKILL_DIR/command/"
    fi

    success "Claude Code Skill 安装完成: $CLAUDE_CODE_SKILL_FILE"
}

verify_claude_code() {
    if [ "$DRY_RUN" = true ]; then
        info "DRY-RUN: 跳过验证"
        return 0
    fi

    info "验证 Claude Code 安装..."

    if [ ! -f "$CLAUDE_CODE_SKILL_FILE" ]; then
        error "SKILL.md 文件不存在"
        return 1
    fi

    info "✓ SKILL.md 文件存在"

    if grep -q "^name: " "$CLAUDE_CODE_SKILL_FILE" && grep -q "^description: " "$CLAUDE_CODE_SKILL_FILE"; then
        info "✓ YAML frontmatter 格式正确"
    else
        error "YAML frontmatter 格式不正确"
        return 1
    fi

    success "Claude Code 验证完成"
}

################################################################################
# 安装 Cursor Rules
################################################################################

install_cursor_skill() {
    info "安装 Cursor Rules..."

    if [ -f "$CURSOR_RULE_FILE" ]; then
        warn "目标文件已存在: $CURSOR_RULE_FILE"
        if [ "$DRY_RUN" = true ]; then
            info "DRY-RUN: 将覆盖 $CURSOR_RULE_FILE"
            return 0
        fi

        if ! confirm "是否覆盖现有文件？"; then
            info "跳过 Cursor 安装"
            return 1
        fi

        backup_file "$CURSOR_RULE_FILE" "cursor"
    fi

    if [ "$DRY_RUN" = true ]; then
        info "DRY-RUN: 将创建目录 $CURSOR_RULES_DIR"
        info "DRY-RUN: 将复制 $SOURCE_SKILL_FILE (去除frontmatter) -> $CURSOR_RULE_FILE"
        return 0
    fi

    mkdir -p "$CURSOR_RULES_DIR"
    
    # 移除YAML frontmatter后复制到Cursor规则文件
    # 使用awk跳过第一个---到第二个---之间的所有行
    awk '/^---$/ { skip++; next; } skip == 1 { next; } { print }' "$SOURCE_SKILL_FILE" > "$CURSOR_RULE_FILE"

    success "Cursor Rules 安装完成: $CURSOR_RULE_FILE"
}

# 更新 Cursor MCP 配置
configure_cursor_mcp() {
    info "配置 Cursor MCP 服务器..."

    # 检查MCP工具
    if ! check_mcp_tools; then
        warn "MCP工具未完全安装，将跳过MCP配置"
        warn "skill仍然可以使用，但MCP功能将不可用"
        return 0
    fi

    # Cursor MCP 配置在 ~/.cursor/mcp.json，不是 ~/.claude/
    local cursor_dir="$HOME/.cursor"
    if [ ! -d "$cursor_dir" ]; then
        warn "Cursor 目录不存在，跳过 MCP 配置"
        return 1
    fi

    local cursor_mcp_file="$cursor_dir/mcp.json"
    local script_mcp_file="$SCRIPT_DIR/mcp-config.json"

    if [ ! -f "$script_mcp_file" ]; then
        warn "未找到 MCP 配置模板: $script_mcp_file"
        return 1
    fi

    if [ "$DRY_RUN" = true ]; then
        info "DRY-RUN: 将检查并更新 $cursor_mcp_file"
        return 0
    fi

    # 如果 mcp.json 不存在，创建它
    if [ ! -f "$cursor_mcp_file" ]; then
        info "创建 Cursor MCP 配置文件"
        cat > "$cursor_mcp_file" << 'EOF'
{
  "mcpServers": {}
}
EOF
    fi

    info "请检查 Cursor MCP 配置: $cursor_mcp_file"
    info "参考配置: $script_mcp_file"

    success "Cursor MCP 配置指南完成"
}

verify_cursor() {
    if [ "$DRY_RUN" = true ]; then
        info "DRY-RUN: 跳过验证"
        return 0
    fi

    info "验证 Cursor 安装..."

    if [ ! -f "$CURSOR_RULE_FILE" ]; then
        error "Cursor 规则文件不存在"
        return 1
    fi

    info "✓ Cursor 规则文件存在: $CURSOR_RULE_FILE"

    local cursor_mcp_file="$HOME/.cursor/mcp.json"
    if [ -f "$cursor_mcp_file" ]; then
        local mcp_count=$(grep -c "context7\|sequential-thinking\|mcp-feedback-enhanced" "$cursor_mcp_file" || echo "0")
        if [ "$mcp_count" -ge 3 ]; then
            info "✓ MCP 配置已设置 ($mcp_count 个)"
        else
            warn "MCP 配置未完全设置 ($mcp_count/3)"
        fi
    else
        warn "MCP 配置文件不存在: $cursor_mcp_file"
    fi

    success "Cursor 验证完成"
}

################################################################################
# 主流程
################################################################################

show_help() {
    cat << EOF
编程助手 Skill 一键安装脚本 v${VERSION}

用法:
    $SCRIPT_NAME [选项]

选项:
    --opencode              仅安装到 OpenCode
    --claude-code           仅安装到 Claude Code
    --cursor                仅安装到 Cursor
    --with-mcp              同时配置 MCP 服务器
    --all                   完整安装（推荐）
    --dry-run               预览模式，不实际执行
    --uninstall             卸载已安装的 skill
    --help                  显示此帮助信息

示例:
    $SCRIPT_NAME                    # 交互式安装
    $SCRIPT_NAME --all --with-mcp   # 完整安装（推荐）
    $SCRIPT_NAME --opencode         # 仅安装 OpenCode
    $SCRIPT_NAME --claude-code      # 仅安装 Claude Code
    $SCRIPT_NAME --cursor           # 仅安装 Cursor
    $SCRIPT_NAME --dry-run          # 预览安装

安装路径:
    OpenCode:    $OPENCODE_SKILL_FILE
    Claude Code: $CLAUDE_CODE_SKILL_FILE
    Cursor:      $CURSOR_RULE_FILE

更多信息: https://github.com/your-org/programming-assistant-skill
EOF
}

uninstall() {
    info "开始卸载..."

    if [ -d "$OPENCODE_SKILL_DIR" ]; then
        info "卸载 OpenCode Skill..."
        backup_file "$OPENCODE_SKILL_FILE" "opencode"
        rm -rf "$OPENCODE_SKILL_DIR"
        success "OpenCode Skill 已卸载"
    else
        info "OpenCode Skill 未安装"
    fi

    if [ -d "$CLAUDE_CODE_SKILL_DIR" ]; then
        info "卸载 Claude Code Skill..."
        backup_file "$CLAUDE_CODE_SKILL_FILE" "claude_code"
        rm -rf "$CLAUDE_CODE_SKILL_DIR"
        success "Claude Code Skill 已卸载"
    else
        info "Claude Code Skill 未安装"
    fi

    if [ -f "$CURSOR_RULE_FILE" ]; then
        info "卸载 Cursor Rules..."
        backup_file "$CURSOR_RULE_FILE" "cursor"
        rm -f "$CURSOR_RULE_FILE"
        success "Cursor Rules 已卸载"
    else
        info "Cursor Rules 未安装"
    fi

    success "卸载完成"
    exit 0
}

main() {
    local install_opencode=false
    local install_claude_code=false
    local install_cursor=false
    local configure_mcp=false
    local dry_run=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            --opencode)
                install_opencode=true
                shift
                ;;
            --claude-code)
                install_claude_code=true
                shift
                ;;
            --cursor)
                install_cursor=true
                shift
                ;;
            --with-mcp)
                configure_mcp=true
                shift
                ;;
            --all)
                install_opencode=true
                install_claude_code=true
                install_cursor=true
                configure_mcp=true
                shift
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            --uninstall)
                uninstall
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                error "未知选项: $1"
                show_help
                exit 1
                ;;
        esac
    done

    DRY_RUN=$dry_run

    separator
    info "编程助手 Skill 安装脚本 v${VERSION}"
    separator

    if [ "$DRY_RUN" = true ]; then
        warn "DRY-RUN 模式：不会实际执行任何操作"
    fi

    check_source_file

    if [ "$install_opencode" = false ] && [ "$install_claude_code" = false ] && [ "$install_cursor" = false ]; then
        separator
        info "选择要安装的平台:"
        info "1) OpenCode"
        info "2) Claude Code"
        info "3) Cursor"
        info "4) 全部安装"
        info "5) 退出"
        separator

        read -p "请选择 [1-5]: " choice
        case $choice in
            1)
                install_opencode=true
                ;;
            2)
                install_claude_code=true
                ;;
            3)
                install_cursor=true
                ;;
            4)
                install_opencode=true
                install_claude_code=true
                install_cursor=true
                ;;
            5)
                info "退出安装"
                exit 0
                ;;
            *)
                error "无效选择"
                exit 1
                ;;
        esac

        if confirm "是否配置 MCP 服务器？"; then
            configure_mcp=true
        fi
    fi

    if [ "$install_opencode" = true ]; then
        separator
        info "=== 安装 OpenCode Skill ==="
        separator

        if check_opencode; then
            install_opencode_skill

            if [ "$configure_mcp" = true ]; then
                configure_opencode_mcp
            fi

            verify_opencode
        fi
    fi

    if [ "$install_claude_code" = true ]; then
        separator
        info "=== 安装 Claude Code Skill ==="
        separator

        if check_claude_code; then
            install_claude_code_skill
            verify_claude_code
        fi
    fi

    if [ "$install_cursor" = true ]; then
        separator
        info "=== 安装 Cursor Rules ==="
        separator

        if check_cursor; then
            install_cursor_skill

            if [ "$configure_mcp" = true ]; then
                configure_cursor_mcp
            fi

            verify_cursor
        fi
    fi

    separator
    success "安装完成！"
    separator

    if [ "$DRY_RUN" = false ]; then
        info "安装位置:"
        if [ -f "$OPENCODE_SKILL_FILE" ]; then
            info "  OpenCode:    $OPENCODE_SKILL_FILE"
        fi
        if [ -f "$CLAUDE_CODE_SKILL_FILE" ]; then
            info "  Claude Code: $CLAUDE_CODE_SKILL_FILE"
        fi
        if [ -f "$CURSOR_RULE_FILE" ]; then
            info "  Cursor:      $CURSOR_RULE_FILE"
        fi

        info ""
        info "后续步骤:"
        info "1. 重启相应的 IDE/CLI 以使更改生效"
        if [ "$install_opencode" = true ]; then
            info "2. 在 OpenCode 中使用: /programming-assistant"
        fi
        if [ "$install_claude_code" = true ]; then
            info "2. 在 Claude Code 中使用: /programming-assistant"
        fi
        if [ "$install_cursor" = true ]; then
            info "2. 在 Cursor 中全局规则自动生效"
        fi
    fi
}

# 执行主函数
main "$@"
