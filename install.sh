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
VERSION="1.0.0"

# OpenCode 路径（官方文档：https://opencode.ai/docs/skills/）
OPENCODE_SKILLS_DIR="$HOME/.config/opencode/skill"
OPENCODE_SKILL_DIR="$OPENCODE_SKILLS_DIR/programming-assistant"
OPENCODE_SKILL_FILE="$OPENCODE_SKILL_DIR/SKILL.md"

# Cursor 路径
CURSOR_DIR="$HOME/.cursor"
CURSOR_RULES_DIR="$CURSOR_DIR/rules"
CURSOR_RULE_FILE="$CURSOR_RULES_DIR/programming-assistant.md"

# 源文件
SOURCE_SKILL_FILE="$SCRIPT_DIR/SKILL.md"
SOURCE_LEGACY_SKILL_FILE="$SCRIPT_DIR/programming-assistant.skill.md"
SOURCE_TEMPLATES_DIR="$SCRIPT_DIR/templates"

# 备份目录
BACKUP_DIR="$SCRIPT_DIR/.backup"
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
backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        mkdir -p "$BACKUP_DIR"
        local backup_file="$BACKUP_DIR/$(basename "$file").$BACKUP_TIMESTAMP"
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

        backup_file "$OPENCODE_SKILL_FILE"
    fi

    if [ "$DRY_RUN" = true ]; then
        info "DRY-RUN: 将创建目录 $OPENCODE_SKILL_DIR"
        info "DRY-RUN: 将复制 $SOURCE_SKILL_FILE -> $OPENCODE_SKILL_FILE"
        return 0
    fi

    # 创建目录
    mkdir -p "$OPENCODE_SKILL_DIR"

    cp "$SOURCE_SKILL_FILE" "$OPENCODE_SKILL_FILE"

    if [ -d "$SOURCE_TEMPLATES_DIR" ]; then
        mkdir -p "$OPENCODE_SKILL_DIR/templates"
        cp -r "$SOURCE_TEMPLATES_DIR"/* "$OPENCODE_SKILL_DIR/templates/" 2>/dev/null || true
        info "模板文件已安装到: $OPENCODE_SKILL_DIR/templates/"
    fi

    success "OpenCode Skill 安装完成: $OPENCODE_SKILL_FILE"
}

# 配置 OpenCode MCP 服务器
configure_opencode_mcp() {
    info "配置 OpenCode MCP 服务器..."

    local opencode_mcp_file="$HOME/.config/opencode/mcp.json"
    local script_mcp_file="$SCRIPT_DIR/3.MCP.txt"

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

# 验证 OpenCode 安装
verify_opencode() {
    info "验证 OpenCode 安装..."

    if [ ! -f "$OPENCODE_SKILL_FILE" ]; then
        error "SKILL.md 文件不存在"
        return 1
    fi

    info "✓ SKILL.md 文件存在"

    # 检查 YAML frontmatter
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
# 安装 Cursor Skill
################################################################################

install_cursor_skill() {
    info "安装 Cursor Skill..."

    # 检查是否覆盖
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

        backup_file "$CURSOR_RULE_FILE"
    fi

    if [ "$DRY_RUN" = true ]; then
        info "DRY-RUN: 将创建目录 $CURSOR_RULES_DIR"
        info "DRY-RUN: 将复制 $SOURCE_SKILL_FILE -> $CURSOR_RULE_FILE"
        return 0
    fi

    mkdir -p "$CURSOR_RULES_DIR"
    cp "$SOURCE_SKILL_FILE" "$CURSOR_RULE_FILE"

    if [ -d "$SOURCE_TEMPLATES_DIR" ]; then
        mkdir -p "$CURSOR_RULES_DIR/templates"
        cp -r "$SOURCE_TEMPLATES_DIR"/* "$CURSOR_RULES_DIR/templates/" 2>/dev/null || true
        info "模板文件已安装到: $CURSOR_RULES_DIR/templates/"
    fi

    success "Cursor Skill 安装完成: $CURSOR_RULE_FILE"
}

# 更新 Cursor MCP 配置
configure_cursor_mcp() {
    info "配置 Cursor MCP 服务器..."

    if [ ! -d "$CURSOR_DIR" ]; then
        warn "Cursor 目录不存在，跳过 MCP 配置"
        return 1
    fi

    local cursor_mcp_file="$CURSOR_DIR/mcp.json"
    local script_mcp_file="$SCRIPT_DIR/3.MCP.txt"

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

# 验证 Cursor 安装
verify_cursor() {
    info "验证 Cursor 安装..."

    if [ ! -f "$CURSOR_RULE_FILE" ]; then
        error "Cursor 规则文件不存在"
        return 1
    fi

    info "✓ Cursor 规则文件存在"

    # 检查 MCP 配置
    local cursor_mcp_file="$CURSOR_DIR/mcp.json"
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

# 显示帮助
show_help() {
    cat << EOF
编程助手 Skill 一键安装脚本 v${VERSION}

用法:
    $SCRIPT_NAME [选项]

选项:
    --opencode              仅安装到 OpenCode
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
    $SCRIPT_NAME --dry-run          # 预览安装

安装路径:
    OpenCode: $OPENCODE_SKILL_FILE
    Cursor:   $CURSOR_RULE_FILE

更多信息: https://github.com/your-org/programming-assistant-skill
EOF
}

# 卸载
uninstall() {
    info "开始卸载..."

    # 卸载 OpenCode
    if [ -d "$OPENCODE_SKILL_DIR" ]; then
        info "卸载 OpenCode Skill..."
        backup_file "$OPENCODE_SKILL_DIR"
        rm -rf "$OPENCODE_SKILL_DIR"
        success "OpenCode Skill 已卸载"
    else
        info "OpenCode Skill 未安装"
    fi

    # 卸载 Cursor
    if [ -f "$CURSOR_RULE_FILE" ]; then
        info "卸载 Cursor Skill..."
        backup_file "$CURSOR_RULE_FILE"
        rm -f "$CURSOR_RULE_FILE"
        success "Cursor Skill 已卸载"
    else
        info "Cursor Skill 未安装"
    fi

    success "卸载完成"
    exit 0
}

# 主函数
main() {
    # 解析参数
    local install_opencode=false
    local install_cursor=false
    local configure_mcp=false
    local dry_run=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            --opencode)
                install_opencode=true
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

    # 检查源文件
    check_source_file

    # 如果没有指定平台，交互式选择
    if [ "$install_opencode" = false ] && [ "$install_cursor" = false ]; then
        separator
        info "选择要安装的平台:"
        info "1) OpenCode"
        info "2) Cursor"
        info "3) 两个都安装"
        info "4) 退出"
        separator

        read -p "请选择 [1-4]: " choice
        case $choice in
            1)
                install_opencode=true
                ;;
            2)
                install_cursor=true
                ;;
            3)
                install_opencode=true
                install_cursor=true
                ;;
            4)
                info "退出安装"
                exit 0
                ;;
            *)
                error "无效选择"
                exit 1
                ;;
        esac

        # 询问是否配置 MCP
        if confirm "是否配置 MCP 服务器？"; then
            configure_mcp=true
        fi
    fi

    # 安装 OpenCode
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

    # 安装 Cursor
    if [ "$install_cursor" = true ]; then
        separator
        info "=== 安装 Cursor Skill ==="
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
            info "  OpenCode: $OPENCODE_SKILL_FILE"
        fi
        if [ -f "$CURSOR_RULE_FILE" ]; then
            info "  Cursor:   $CURSOR_RULE_FILE"
        fi

        info ""
        info "后续步骤:"
        info "1. 重启 OpenCode 和 Cursor 以使更改生效"
        info "2. 在 OpenCode 中使用: skill({ name: 'programming-assistant' })"
        info "3. 在 Cursor 中直接使用，无需额外配置"
        info ""
        info "如有问题，请查看备份目录: $BACKUP_DIR"
    fi
}

# 执行主函数
main "$@"
