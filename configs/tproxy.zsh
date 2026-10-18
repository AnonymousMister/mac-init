# ==========================================
# 动态终端网络代理管理 (自动适配 Loon / Clash / Surge)
# ==========================================

tproxy() {
    local action="${1:-status}"
    local wifi_name="Wi-Fi"

    case "$action" in
        on)
            local http_port=$(networksetup -getwebproxy "$wifi_name" 2>/dev/null | awk '/Port:/ {print $2}')
            local socks_port=$(networksetup -getsocksfirewallproxy "$wifi_name" 2>/dev/null | awk '/Port:/ {print $2}')

            if [ -z "$http_port" ] || [ "$http_port" = "0" ]; then
                echo "❌ 未检测到系统代理端口，请确认代理软件的'系统代理'已开启"
                return 1
            fi

            export http_proxy="http://127.0.0.1:$http_port"
            export https_proxy="http://127.0.0.1:$http_port"
            export all_proxy="socks5://127.0.0.1:$socks_port"

            echo "✅ 终端代理已开启 (HTTP:$http_port / SOCKS:$socks_port)"
            ;;
        off)
            unset http_proxy https_proxy all_proxy
            echo "⭕️ 终端代理已关闭"
            ;;
        status)
            if [ -n "$http_proxy" ] || [ -n "$all_proxy" ]; then
                echo "🟢 终端代理当前状态: 已开启"
                echo "   http_proxy  = ${http_proxy:-未设置}"
                echo "   https_proxy = ${https_proxy:-未设置}"
                echo "   all_proxy   = ${all_proxy:-未设置}"
            else
                echo "⚪️ 终端代理当前状态: 未开启"
            fi
            ;;
        *)
            echo "用法: tproxy [on|off|status]"
            return 1
            ;;
    esac
}

# 终端打开时自动检查：如果 Loon/Clash 系统代理已开启，则自动为当前终端注入代理
if networksetup -getwebproxy Wi-Fi 2>/dev/null | grep -q "Enabled: Yes"; then
    tproxy on > /dev/null
fi
