#!/bin/bash
################################################################################
# 编程助手 Skill 卸载脚本
#
# 功能:
#   卸载 OpenCode Skill
#   卸载 Cursor Skill
#   可选：卸载 MCP 服务器配置
#   自动备份删除的文件
#
# 使用方法:
#   ./uninstall.sh                  # 交互式卸载
#   ./uninstall.sh --opencode       # 仅卸载 OpenCode
#   ./uninstall.sh --cursor         # 仅卸载 Cursor
#   ./uninstall.sh --with-mcp        # 同时卸载 MCP 配置
#   ./uninstall.sh --all            # 完整卸载
#   ./uninstall.sh --dry-run         # 预览模式
#   ./uninstall.sh --help           # 显示帮助信息
#
################################################################################

set -euo pipefail

################################################################################
# 配置常量
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
VERSION="1.2.0"

# OpenCode 路径（官方文档：https://opencode.ai/docs/skills/）
OPENCODE_SKILLS_DIR="$HOME/.config/opencode/skill"
OPENCODE_SKILL_DIR="$OPENCODE_SKILLS_DIR/programming-assistant"
OPENCODE_SKILL_FILE="$OPENCODE_SKILL_DIR/SKILL.md"

# Claude Code 路径（官方文档：https://docs.anthropic.com/en/docs/claude-code/skills）
CLAUDE_CODE_SKILLS_DIR="$HOME/.claude/skills"
CLAUDE_CODE_SKILL_DIR="$CLAUDE_CODE_SKILLS_DIR/programming-assistant"
CLAUDE_CODE_SKILL_FILE="$CLAUDE_CODE_SKILL_DIR/SKILL.md"

# Cursor 路径
CURSOR_DIR="$HOME/.cursor"
CURSOR_RULES_DIR="$CURSOR_DIR/rules"
CURSOR_RULE_FILE="$CURSOR_RULES_DIR/programming-assistant.md"

# 备份目录（按源目录分类，与 install.sh 保持一致）
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
    
    if [ -e "$file" ]; then
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
        cp -r "$file" "$backup_file"
        info "已备份: $file -> $backup_file"
    fi
}

################################################################################
# 卸载 OpenCode Skill
################################################################################

uninstall_opencode_skill() {
    info "卸载 OpenCode Skill..."

    if [ ! -d "$OPENCODE_SKILL_DIR" ] && [ ! -f "$OPENCODE_SKILL_FILE" ]; then
        info "OpenCode Skill 未安装"
        return 0
    fi

    if [ "$DRY_RUN" = true ]; then
        info "DRY-RUN: 将删除 $OPENCODE_SKILL_DIR"
        return 0
    fi

    if ! confirm "确认删除 OpenCode Skill？"; then
        info "跳过 OpenCode 卸载"
        return 1
    fi

    backup_file "$OPENCODE_SKILL_DIR" "opencode"
    rm -rf "$OPENCODE_SKILL_DIR"

    success "OpenCode Skill 已卸载"
}

################################################################################
# 卸载 Claude Code Skill
################################################################################

uninstall_claude_code_skill() {
    info "卸载 Claude Code Skill..."

    if [ ! -d "$CLAUDE_CODE_SKILL_DIR" ] && [ ! -f "$CLAUDE_CODE_SKILL_FILE" ]; then
        info "Claude Code Skill 未安装"
        return 0
    fi

    if [ "$DRY_RUN" = true ]; then
        info "DRY-RUN: 将删除 $CLAUDE_CODE_SKILL_DIR"
        return 0
    fi

    if ! confirm "确认删除 Claude Code Skill？"; then
        info "跳过 Claude Code 卸载"
        return 1
    fi

    backup_file "$CLAUDE_CODE_SKILL_DIR" "claude_code"
    rm -rf "$CLAUDE_CODE_SKILL_DIR"

    success "Claude Code Skill 已卸载"
}

# 卸载 OpenCode MCP 服务器
uninstall_opencode_mcp() {
    info "卸载 OpenCode MCP 服务器配置..."

    if ! command_exists opencode; then
        warn "OpenCode CLI 不可用"
        return 1
    fi

    local mcp_servers=("context7" "sequential-thinking" "mcp-feedback-enhanced")

    for server in "${mcp_servers[@]}"; do
        info "卸载 MCP 服务器: $server"
        if [ "$DRY_RUN" = true ]; then
            info "DRY-RUN: opencode mcp remove $server"
        else
            opencode mcp remove "$server" 2>/dev/null || warn "卸载失败或不存在: $server"
        fi
    done

    success "OpenCode MCP 配置已清理"
}

################################################################################
# 卸载 Cursor Skill
################################################################################

uninstall_cursor_skill() {
    info "卸载 Cursor Skill..."

    if [ ! -f "$CURSOR_RULE_FILE" ]; then
        info "Cursor Skill 未安装"
        return 0
    fi

    if [ "$DRY_RUN" = true ]; then
        info "DRY-RUN: 将删除 $CURSOR_RULE_FILE"
        return 0
    fi

    # 确认删除
    if ! confirm "确认删除 Cursor Skill？"; then
        info "跳过 Cursor 卸载"
        return 1
    fi

    # 备份
    backup_file "$CURSOR_RULE_FILE" "cursor"

    # 删除
    rm -f "$CURSOR_RULE_FILE"

    # 如果 rules 目录为空，删除它
    if [ -d "$CURSOR_RULES_DIR" ] && [ -z "$(ls -A "$CURSOR_RULES_DIR")" ]; then
        rmdir "$CURSOR_RULES_DIR"
        info "已删除空目录: $CURSOR_RULES_DIR"
    fi

    success "Cursor Skill 已卸载"
}

# 清理 Cursor MCP 配置（提示用户手动操作）
uninstall_cursor_mcp() {
    info "Cursor MCP 配置..."

    local cursor_mcp_file="$CURSOR_DIR/mcp.json"

    if [ ! -f "$cursor_mcp_file" ]; then
        info "Cursor MCP 配置文件不存在"
        return 0
    fi

    if [ "$DRY_RUN" = true ]; then
        info "DRY-RUN: 将提示检查 $cursor_mcp_file"
        return 0
    fi

    warn "请手动检查并编辑: $cursor_mcp_file"
    info "以下 MCP 服务器可能需要清理:"
    info "  - context7"
    info "  - sequential-thinking"
    info "  - mcp-feedback-enhanced"
    info ""
    info "提示: 编辑 mcp.json 文件，删除对应的 mcpServers 配置项"
}

################################################################################
# 主流程
################################################################################

show_help() {
    cat << EOF
编程助手 Skill 卸载脚本 v${VERSION}

用法:
    $SCRIPT_NAME [选项]

选项:
    --opencode              仅卸载 OpenCode
    --claude-code           仅卸载 Claude Code
    --cursor                仅卸载 Cursor
    --with-mcp              同时卸载 MCP 配置
    --all                   完整卸载（推荐）
    --dry-run               预览模式，不实际执行
    --help                  显示此帮助信息

示例:
    $SCRIPT_NAME                    # 交互式卸载
    $SCRIPT_NAME --all --with-mcp   # 完整卸载（推荐）
    $SCRIPT_NAME --opencode         # 仅卸载 OpenCode
    $SCRIPT_NAME --claude-code      # 仅卸载 Claude Code
    $SCRIPT_NAME --dry-run          # 预览卸载

警告:
    卸载操作不可逆，所有删除的文件将备份到对应的安装目录下的 .backup 文件夹

更多信息: https://github.com/your-org/programming-assistant-skill
EOF
}

main() {
    local uninstall_opencode=false
    local uninstall_claude_code=false
    local uninstall_cursor=false
    uninstall_mcp=false
    local dry_run=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            --opencode)
                uninstall_opencode=true
                shift
                ;;
            --claude-code)
                uninstall_claude_code=true
                shift
                ;;
            --cursor)
                uninstall_cursor=true
                shift
                ;;
            --with-mcp)
                uninstall_mcp=true
                shift
                ;;
            --all)
                uninstall_opencode=true
                uninstall_claude_code=true
                uninstall_cursor=true
                uninstall_mcp=true
                shift
                ;;
            --dry-run)
                dry_run=true
                shift
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
    info "编程助手 Skill 卸载脚本 v${VERSION}"
    separator

    if [ "$DRY_RUN" = true ]; then
        warn "DRY-RUN 模式：不会实际执行任何操作"
    fi

    warn "此操作将删除已安装的 skill 文件"
    info "备份将保存在对应的安装目录下:"
    info "  OpenCode:    $OPENCODE_BACKUP_DIR"
    info "  Claude Code: $CLAUDE_CODE_BACKUP_DIR"
    info "  Cursor:      $CURSOR_BACKUP_DIR"
    echo ""

    if [ "$uninstall_opencode" = false ] && [ "$uninstall_claude_code" = false ] && [ "$uninstall_cursor" = false ]; then
        separator
        info "选择要卸载的平台:"
        info "1) OpenCode"
        info "2) Claude Code"
        info "3) Cursor"
        info "4) 全部卸载"
        info "5) 退出"
        separator

        read -p "请选择 [1-5]: " choice
        case $choice in
            1)
                uninstall_opencode=true
                ;;
            2)
                uninstall_claude_code=true
                ;;
            3)
                uninstall_cursor=true
                ;;
            4)
                uninstall_opencode=true
                uninstall_claude_code=true
                uninstall_cursor=true
                ;;
            5)
                info "退出卸载"
                exit 0
                ;;
            *)
                error "无效选择"
                exit 1
                ;;
        esac

        if confirm "是否卸载 MCP 服务器配置？"; then
            uninstall_mcp=true
        fi
    fi

    if [ "$DRY_RUN" = false ]; then
        separator
        warn "即将执行卸载操作:"
        [ "$uninstall_opencode" = true ] && info "  - OpenCode Skill"
        [ "$uninstall_claude_code" = true ] && info "  - Claude Code Skill"
        [ "$uninstall_cursor" = true ] && info "  - Cursor Rules"
        [ "$uninstall_mcp" = true ] && info "  - MCP 服务器配置"
        separator
        echo ""

        if ! confirm "确认继续？"; then
            info "取消卸载"
            exit 0
        fi
        echo ""
    fi

    if [ "$uninstall_opencode" = true ]; then
        separator
        info "=== 卸载 OpenCode Skill ==="
        separator

        uninstall_opencode_skill

        if [ "$uninstall_mcp" = true ]; then
            uninstall_opencode_mcp
        fi
    fi

    if [ "$uninstall_claude_code" = true ]; then
        separator
        info "=== 卸载 Claude Code Skill ==="
        separator

        uninstall_claude_code_skill
    fi

    if [ "$uninstall_cursor" = true ]; then
        separator
        info "=== 卸载 Cursor Rules ==="
        separator

        uninstall_cursor_skill

        if [ "$uninstall_mcp" = true ]; then
            uninstall_cursor_mcp
        fi
    fi

    separator
    success "卸载完成！"
    separator

    if [ "$DRY_RUN" = false ]; then
        info "备份位置:"
        info "  OpenCode:    $OPENCODE_BACKUP_DIR"
        info "  Claude Code: $CLAUDE_CODE_BACKUP_DIR"
        info "  Cursor:      $CURSOR_BACKUP_DIR"
        info ""
        info "如需恢复，请使用对应备份目录中的文件"
    fi
}

# 执行主函数
main "$@"
