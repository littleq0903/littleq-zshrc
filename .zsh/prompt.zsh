# =============================================================================
# prompt.zsh - Two-line prompt matching original zshrc style
# =============================================================================

setopt PROMPT_SUBST

# -----------------------------------------------------------------------------
# Colors and Characters Setup
# -----------------------------------------------------------------------------
autoload -Uz colors zsh/terminfo
if [[ "$terminfo[colors]" -ge 8 ]]; then
    colors
fi

# Bold colors
for color in RED GREEN YELLOW BLUE MAGENTA CYAN WHITE; do
    eval PR_$color='%{$terminfo[bold]$fg[${(L)color}]%}'
    eval PR_LIGHT_$color='%{$fg[${(L)color}]%}'
done
PR_NO_COLOUR="%{$terminfo[sgr0]%}"

# Line drawing characters
typeset -A altchar
set -A altchar ${(s..)terminfo[acsc]}
PR_SET_CHARSET="%{$terminfo[enacs]%}"
PR_SHIFT_IN="%{$terminfo[smacs]%}"
PR_SHIFT_OUT="%{$terminfo[rmacs]%}"
PR_HBAR=${altchar[q]:--}
PR_HBAR_EMPTY=" "
PR_ULCORNER=${altchar[l]:--}
PR_LLCORNER=${altchar[m]:--}
PR_LRCORNER=${altchar[j]:--}
PR_URCORNER=${altchar[k]:--}

# Color definitions
PR_PARENTHESE_COLOR=${PR_NO_COLOUR}
PR_CORNER_COLOR=${PR_GREEN}
PR_LINE_COLOR=${PR_LIGHT_GREEN}
PR_CWD_COLOR=${PR_BLUE}
PR_DATETIME_COLOR=${PR_GREEN}
PR_SEPERATOR_COLOR=${PR_NO_COLOUR}
PR_SEPERATOR=${PR_SEPERATOR_COLOR}\|

PR_WITH_ROOT_COLOR=${PR_RED}
PR_WITHOUT_ROOT_COLOR=${PR_NO_COLOUR}
PR_SUCCESS_COLOR=${PR_LIGHT_GREEN}
PR_FAIL_COLOR=${PR_RED}

# -----------------------------------------------------------------------------
# Command Execution Timer
# -----------------------------------------------------------------------------
__cmd_start_time=0

__timer_preexec() {
    __cmd_start_time=$SECONDS
}

__timer_precmd() {
    if [[ $__cmd_start_time -gt 0 ]]; then
        local elapsed=$((SECONDS - __cmd_start_time))
        __cmd_start_time=0

        if [[ $elapsed -eq 0 ]]; then
            __last_cmd_time=""
        elif [[ $elapsed -lt 60 ]]; then
            __last_cmd_time="${elapsed}s"
        elif [[ $elapsed -lt 3600 ]]; then
            __last_cmd_time="$((elapsed / 60))m$((elapsed % 60))s"
        else
            __last_cmd_time="$((elapsed / 3600))h$((elapsed % 3600 / 60))m"
        fi
    else
        __last_cmd_time=""
    fi
}

# -----------------------------------------------------------------------------
# Terminal Title
# -----------------------------------------------------------------------------
case $TERM in
    xterm*)
        PR_TITLEBAR=$'%{\e]0;%(!.-=*[ROOT]*=- | .)%n@%m:%~ | ${COLUMNS}x${LINES} | %y\a%}'
        ;;
    screen*)
        PR_TITLEBAR=$'%{\e_screen \005 (\005t) | %(!.-=[ROOT]=- | .)%n@%m:%~ | ${COLUMNS}x${LINES} | %y\e\\%}'
        PR_STITLE=$'%{\ekzsh\e\\%}'
        ;;
    *)
        PR_TITLEBAR=''
        PR_STITLE=''
        ;;
esac

# -----------------------------------------------------------------------------
# Status Line Builder
# -----------------------------------------------------------------------------
# Builds STATUS_LINE (plain) and STATUS_LINE_PR (with colors) for prompt
__build_status_line() {
    STATUS_LINE=''
    STATUS_LINE_PR=''

    # Git status
    local git_info=$(__git_info)
    if [[ -n "$git_info" ]]; then
        STATUS_LINE+="|git:${git_info}"
        STATUS_LINE_PR+="${PR_PARENTHESE_COLOR}|${PR_LIGHT_GREEN}git:${git_info}"
    fi

    # Claude.md status
    local claude_info=$(__claude_status)
    if [[ -n "$claude_info" ]]; then
        STATUS_LINE+="|${claude_info}"
        STATUS_LINE_PR+="${PR_PARENTHESE_COLOR}|${PR_CYAN}${claude_info}"
    fi

    # Node status
    local node_info=$(__node_status)
    if [[ -n "$node_info" ]]; then
        STATUS_LINE+="|${node_info}"
        STATUS_LINE_PR+="${PR_PARENTHESE_COLOR}|${PR_YELLOW}${node_info}"
    fi

    # Virtualenv status
    local venv_info=$(__venv_status)
    if [[ -n "$venv_info" ]]; then
        STATUS_LINE+="|${venv_info}"
        STATUS_LINE_PR+="${PR_PARENTHESE_COLOR}|${PR_RED}${venv_info}"
    fi

    # Jobs status
    local jobs_info=$(__jobs_status)
    if [[ -n "$jobs_info" ]]; then
        STATUS_LINE+="|${jobs_info}"
        STATUS_LINE_PR+="${PR_PARENTHESE_COLOR}|${PR_BLUE}${jobs_info}"
    fi

    # Command time
    if [[ -n "$__last_cmd_time" ]]; then
        STATUS_LINE+="|⏱${__last_cmd_time}"
        STATUS_LINE_PR+="${PR_PARENTHESE_COLOR}|${PR_CYAN}⏱${__last_cmd_time}"
    fi
}

# -----------------------------------------------------------------------------
# Precmd - runs before each prompt
# -----------------------------------------------------------------------------
precmd() {
    # Timer
    __timer_precmd

    # Build status line
    __build_status_line

    # Update battery info
    __update_battery_info

    # Calculate terminal width and path truncation
    local TERMWIDTH=${COLUMNS:-80}

    # Get path (git-relative if in repo, with powerline icon prefix)
    PR_PWD=$(__compact_path)
    [[ -z "$PR_PWD" ]] && PR_PWD="${(%):-%~}"

    # Calculate sizes for fill bar
    # Format: ┌─(user@host>tty|status)─────────────────(path)─┐
    local user_at_host="${(%):-%n@%m}"
    local tty_name="${(%):-%l}"

    # Left side: "┌─(" + user@host + ">" + tty + status + ")"
    # Corner and hbar are single-width characters
    local left_size=$((3 + ${#user_at_host} + 1 + ${#tty_name} + ${#STATUS_LINE} + 1))

    # Right side: "─(" + path + ")─┐"
    local right_size=$((2 + ${#PR_PWD} + 3))

    local total_occupied=$((left_size + right_size))

    PR_FILLBAR=""
    PR_PWDLEN=""

    if [[ $total_occupied -gt $TERMWIDTH ]]; then
        # Path needs truncation - truncate PR_PWD from the left
        (( PR_PWDLEN = TERMWIDTH - left_size - 5 ))
        [[ $PR_PWDLEN -lt 10 ]] && PR_PWDLEN=10
        if [[ ${#PR_PWD} -gt $PR_PWDLEN ]]; then
            PR_PWD="...${PR_PWD: -$((PR_PWDLEN - 3))}"
        fi
        PR_FILLBAR=""
    else
        # Calculate fill length
        local fill_len=$((TERMWIDTH - total_occupied))
        # Build the fill bar directly as a string of PR_HBAR characters
        PR_FILLBAR=""
        local i
        for ((i=0; i<fill_len; i++)); do
            PR_FILLBAR+="$PR_HBAR"
        done
    fi
}

preexec() {
    __timer_preexec

    # Set screen/tmux window title
    if [[ "$TERM" == screen* ]]; then
        local CMD=${1[(wr)^(*=*|sudo|-*)]}
        print -Pn "\ek$CMD\e\\"
    fi
}

chpwd() {
    ls
}

# -----------------------------------------------------------------------------
# Battery Info
# -----------------------------------------------------------------------------
# Battery status icons:
#   🔋 - Discharging (on battery)
#   ⚡ - Charging
#   🔌 - Fully charged / on AC power (not using battery)
__update_battery_info() {
    PR_BATTERY_INFO=""
    PR_CHARGING_STATUS=""
    PR_BATTERY_ICON=""
    PR_BATTERY_COLOR=${PR_NO_COLOUR}
    PR_CHARGING_STATUS_COLOR=${PR_NO_COLOUR}

    if [[ "$MACHINE_OS" == "macosx" ]]; then
        local batt_output
        batt_output=$(pmset -g batt 2>/dev/null)

        if [[ -n "$batt_output" ]]; then
            # Extract battery percentage using parameter expansion
            if [[ "$batt_output" =~ ([0-9]+)% ]]; then
                PR_BATTERY_INFO="${match[1]}"
            fi
            # Detect charging status
            # IMPORTANT: Check "discharging" BEFORE "charging" since "discharging" contains "charging"
            if [[ "$batt_output" == *"discharging"* ]]; then
                PR_CHARGING_STATUS="discharging"
                PR_CHARGING_STATUS_COLOR=${PR_RED}
                PR_BATTERY_ICON="🔋"
            elif [[ "$batt_output" == *"charged"* ]]; then
                PR_CHARGING_STATUS="charged"
                PR_CHARGING_STATUS_COLOR=${PR_GREEN}
                PR_BATTERY_ICON="🔌"
            elif [[ "$batt_output" == *"finishing charge"* ]]; then
                PR_CHARGING_STATUS="finishing"
                PR_CHARGING_STATUS_COLOR=${PR_YELLOW}
                PR_BATTERY_ICON="⚡"
            elif [[ "$batt_output" == *"charging"* ]]; then
                PR_CHARGING_STATUS="charging"
                PR_CHARGING_STATUS_COLOR=${PR_YELLOW}
                PR_BATTERY_ICON="⚡"
            elif [[ "$batt_output" == *"AC Power"* ]]; then
                PR_CHARGING_STATUS="on AC"
                PR_CHARGING_STATUS_COLOR=${PR_GREEN}
                PR_BATTERY_ICON="🔌"
            fi
        fi
    elif [[ "$MACHINE_OS" == "ubuntu" ]]; then
        local bat_paths=("/sys/class/power_supply/BAT0" "/sys/class/power_supply/BAT1")
        for bat_path in "${bat_paths[@]}"; do
            if [[ -f "$bat_path/capacity" ]]; then
                PR_BATTERY_INFO=$(< "$bat_path/capacity")
                local status=$(< "$bat_path/status" 2>/dev/null)
                case "$status" in
                    Full|Charged)
                        PR_CHARGING_STATUS="charged"
                        PR_CHARGING_STATUS_COLOR=${PR_GREEN}
                        PR_BATTERY_ICON="🔌"
                        ;;
                    Charging)
                        PR_CHARGING_STATUS="charging"
                        PR_CHARGING_STATUS_COLOR=${PR_YELLOW}
                        PR_BATTERY_ICON="⚡"
                        ;;
                    Discharging)
                        PR_CHARGING_STATUS="discharging"
                        PR_CHARGING_STATUS_COLOR=${PR_RED}
                        PR_BATTERY_ICON="🔋"
                        ;;
                esac
                break
            fi
        done

        # WSL
        if [[ -n "$WSL_DISTRO_NAME" ]] && (( $+commands[powershell.exe] )); then
            PR_BATTERY_INFO=$(powershell.exe -Command "(Get-WmiObject Win32_Battery).EstimatedChargeRemaining" 2>/dev/null | tr -d '\r\n')
            PR_CHARGING_STATUS="battery"
            PR_BATTERY_ICON="🔋"
        fi
    fi

    # Battery color based on level
    if [[ -n "$PR_BATTERY_INFO" ]]; then
        if [[ "$PR_BATTERY_INFO" -le 20 ]]; then
            PR_BATTERY_COLOR=${PR_RED}
        elif [[ "$PR_BATTERY_INFO" -le 40 ]]; then
            PR_BATTERY_COLOR=${PR_YELLOW}
        elif [[ "$PR_BATTERY_INFO" -le 70 ]]; then
            PR_BATTERY_COLOR=${PR_BLUE}
        else
            PR_BATTERY_COLOR=${PR_GREEN}
        fi
    fi
}

# -----------------------------------------------------------------------------
# Prompt Definition (matching original style)
# -----------------------------------------------------------------------------
# Line 1: ┌─(user@host>tty|status)────────────────────(repo/path)─┐
#         Path shows git-relative path with  powerline icon when in a repo
# Line 2: └─(exitcode|$$|#)─>
# Right:  (datetime|🔋85%)─┘

PROMPT='$PR_SET_CHARSET${PR_STITLE:-}${(e)PR_TITLEBAR}\
$PR_LINE_COLOR$PR_SHIFT_IN$PR_CORNER_COLOR$PR_ULCORNER$PR_LINE_COLOR$PR_HBAR$PR_SHIFT_OUT$PR_PARENTHESE_COLOR(\
$PR_BLUE%(!.%SROOT%s.%n)$PR_RED@%m>$PR_YELLOW%l$STATUS_LINE_PR\
$PR_PARENTHESE_COLOR)$PR_LINE_COLOR$PR_SHIFT_IN$PR_FILLBAR$PR_SHIFT_OUT$PR_PARENTHESE_COLOR(\
$PR_CWD_COLOR$PR_PWD\
$PR_PARENTHESE_COLOR)$PR_LINE_COLOR$PR_SHIFT_IN$PR_HBAR$PR_CORNER_COLOR$PR_URCORNER$PR_SHIFT_OUT
$PR_LINE_COLOR$PR_SHIFT_IN$PR_CORNER_COLOR$PR_LLCORNER$PR_LINE_COLOR$PR_HBAR$PR_SHIFT_OUT$PR_PARENTHESE_COLOR(\
%(?.$PR_SUCCESS_COLOR.$PR_FAIL_COLOR)%(?..$?${PR_NO_COLOUR}${PR_SEPERATOR})$PR_YELLOW$$\
$PR_GREEN$PR_SEPERATOR%(!.$PR_WITH_ROOT_COLOR.$PR_WITHOUT_ROOT_COLOR)%#$PR_PARENTHESE_COLOR)\
$PR_LINE_COLOR$PR_SHIFT_IN$PR_HBAR$PR_SHIFT_OUT$PR_NO_COLOUR> '

RPROMPT='$PR_PARENTHESE_COLOR($PR_DATETIME_COLOR%D{%c}$PR_NO_COLOUR$PR_SEPERATOR$PR_CHARGING_STATUS_COLOR$PR_BATTERY_ICON$PR_BATTERY_COLOR$PR_BATTERY_INFO%%$PR_PARENTHESE_COLOR)$PR_LINE_COLOR$PR_SHIFT_IN$PR_HBAR$PR_CORNER_COLOR$PR_LRCORNER$PR_LINE_COLOR$PR_SHIFT_OUT$PR_NO_COLOUR'

PS2='$PR_LINE_COLOR$PR_SHIFT_IN$PR_HBAR$PR_SHIFT_OUT\
$PR_SHIFT_IN$PR_HBAR$PR_SHIFT_OUT$PR_PARENTHESE_COLOR(\
$PR_YELLOW%_$PR_PARENTHESE_COLOR)$PR_LINE_COLOR$PR_SHIFT_IN$PR_HBAR$PR_SHIFT_OUT\
$PR_LINE_COLOR$PR_SHIFT_IN$PR_HBAR$PR_SHIFT_OUT$PR_PARENTHESE_COLOR>$PR_NO_COLOUR '
