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
PR_LTEE=${altchar[t]:--}
PR_RTEE=${altchar[u]:--}

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

# Initialize variables used for dynamic prompt sizing
PR_FILLBAR=""
PR_FILLBAR2=""
PR_PWD=""
PR_THREE_LINE_MODE=0
PR_HOST="${(%):-%m}"  # Initialize to full hostname, may be shortened dynamically

# Initialize status line variables (set by __build_status_line)
STATUS_LINE=""
STATUS_LINE_PR=""
STATUS_LINE_NO_GIT=""
STATUS_LINE_NO_GIT_PR=""
GIT_STATUS=""
GIT_STATUS_PR=""

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
# Hostname Shortening
# -----------------------------------------------------------------------------
# Shortens a hostname by keeping first 5 chars + "..." + last 3 chars
# e.g., "Colins-MacBook-Pro-Max" -> "Colin...-Max"
__shorten_hostname() {
    local host="$1"
    local max_len="${2:-12}"

    if [[ ${#host} -le $max_len ]]; then
        echo "$host"
        return
    fi

    # Keep first 5 chars and last 3 chars with "..." in between
    local prefix_len=5
    local suffix_len=3
    local prefix="${host:0:$prefix_len}"
    local suffix="${host: -$suffix_len}"
    echo "${prefix}...${suffix}"
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
# Also builds GIT_STATUS (plain) and GIT_STATUS_PR (with colors) separately for three-line mode
__build_status_line() {
    STATUS_LINE=''
    STATUS_LINE_PR=''
    GIT_STATUS=''
    GIT_STATUS_PR=''

    # Git status (stored separately for three-line mode)
    local git_info=$(__git_info)
    if [[ -n "$git_info" ]]; then
        GIT_STATUS="git:${git_info}"
        GIT_STATUS_PR="${PR_LIGHT_GREEN}git:${git_info}"
        # Also add to main status line (used in two-line mode)
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

    # Build status line WITHOUT git (for three-line mode line 1)
    STATUS_LINE_NO_GIT=''
    STATUS_LINE_NO_GIT_PR=''
    [[ -n "$claude_info" ]] && STATUS_LINE_NO_GIT+="|${claude_info}" && STATUS_LINE_NO_GIT_PR+="${PR_PARENTHESE_COLOR}|${PR_CYAN}${claude_info}"
    [[ -n "$node_info" ]] && STATUS_LINE_NO_GIT+="|${node_info}" && STATUS_LINE_NO_GIT_PR+="${PR_PARENTHESE_COLOR}|${PR_YELLOW}${node_info}"
    [[ -n "$venv_info" ]] && STATUS_LINE_NO_GIT+="|${venv_info}" && STATUS_LINE_NO_GIT_PR+="${PR_PARENTHESE_COLOR}|${PR_RED}${venv_info}"
    [[ -n "$jobs_info" ]] && STATUS_LINE_NO_GIT+="|${jobs_info}" && STATUS_LINE_NO_GIT_PR+="${PR_PARENTHESE_COLOR}|${PR_BLUE}${jobs_info}"
    [[ -n "$__last_cmd_time" ]] && STATUS_LINE_NO_GIT+="|⏱${__last_cmd_time}" && STATUS_LINE_NO_GIT_PR+="${PR_PARENTHESE_COLOR}|${PR_CYAN}⏱${__last_cmd_time}"
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

    # Get hostname (start with full hostname)
    local full_host="${(%):-%m}"
    PR_HOST="$full_host"

    # Get other parts
    local username="${(%):-%n}"
    local tty_name="${(%):-%l}"

    # Calculate left side size
    # Format: ┌─(user@host>tty|status)
    # = 3 (corner+hbar+paren) + user + 1 (@) + host + 1 (>) + tty + status + 1 (paren)
    local left_size=$((3 + ${#username} + 1 + ${#PR_HOST} + 1 + ${#tty_name} + ${#STATUS_LINE} + 1))

    # Calculate right side size
    # Format: (path)─┐ = 1 (paren) + path + 1 (paren) + 1 (hbar) + 1 (corner) = path + 4
    # Plus the fill bar separator: ─( = 2
    local right_size=$((2 + ${#PR_PWD} + 3))

    local total_occupied=$((left_size + right_size))

    PR_FILLBAR=""
    PR_FILLBAR2=""
    PR_PWDLEN=""
    PR_THREE_LINE_MODE=0

    # Count wide characters that display as 2 columns but are counted as 1
    # Powerline icon , checkmark ✓, emojis, etc.
    local wide_chars=0
    # Count in STATUS_LINE (each special char adds ~1 extra column)
    [[ "$STATUS_LINE" == *"✓"* ]] && ((wide_chars+=1))
    [[ "$STATUS_LINE" == *"⏱"* ]] && ((wide_chars+=1))
    # Count in PR_PWD (powerline git icon)
    [[ "$PR_PWD" == *$'\ue0a0'* ]] && ((wide_chars+=2))

    # Add buffer: base 5 + extra per wide character
    local width_buffer=$((5 + wide_chars))

    # Strategy 1: Try with full hostname
    if [[ $((total_occupied + width_buffer)) -le $TERMWIDTH ]]; then
        # Everything fits, calculate fill bar
        local fill_len=$((TERMWIDTH - total_occupied))
        local i
        for ((i=0; i<fill_len; i++)); do
            PR_FILLBAR+="$PR_HBAR"
        done
        __build_prompt
        return
    fi

    # Strategy 2: Try with shortened hostname
    local short_host=$(__shorten_hostname "$full_host" 12)
    if [[ "$short_host" != "$full_host" ]]; then
        PR_HOST="$short_host"
        # Recalculate left_size with shortened hostname
        left_size=$((3 + ${#username} + 1 + ${#PR_HOST} + 1 + ${#tty_name} + ${#STATUS_LINE} + 1))
        total_occupied=$((left_size + right_size))

        if [[ $((total_occupied + width_buffer)) -le $TERMWIDTH ]]; then
            local fill_len=$((TERMWIDTH - total_occupied))
            local i
            for ((i=0; i<fill_len; i++)); do
                PR_FILLBAR+="$PR_HBAR"
            done
            __build_prompt
            return
        fi
    fi

    # Strategy 3: Use three-line mode (with shortened hostname)
    # In three-line mode, git info moves to line 2, so recalculate line 1 size without git
    local left_size_no_git=$((3 + ${#username} + 1 + ${#PR_HOST} + 1 + ${#tty_name} + ${#STATUS_LINE_NO_GIT} + 1))
    local line1_min=$((left_size_no_git + 1))

    # Line 2 content: git:branch|path (if git exists)
    local line2_content_len=${#PR_PWD}
    [[ -n "$GIT_STATUS" ]] && line2_content_len=$((${#GIT_STATUS} + 1 + line2_content_len))  # +1 for |

    if [[ $line1_min -le $TERMWIDTH ]]; then
        PR_THREE_LINE_MODE=1

        # In three-line mode, shorten lines 1 and 2 by 1 char to align with RPROMPT's trailing space
        local three_line_adjust=1

        # Calculate fill for line 1 (status line without git)
        local fill_len1=$((TERMWIDTH - left_size_no_git - 1 - three_line_adjust))
        [[ $fill_len1 -lt 0 ]] && fill_len1=0
        local i
        for ((i=0; i<fill_len1; i++)); do
            PR_FILLBAR+="$PR_HBAR"
        done

        # Calculate fill for line 2 (git + path line)
        # Line 2 format: ├(fill)(git:branch|path)─┤
        # Size: 1 (ltee) + fill + 1 (() + content_len + 1 ()) + 1 (hbar) + 1 (rtee) = 5 + content_len
        local line2_fixed=$((5 + line2_content_len))
        local fill_len2=$((TERMWIDTH - line2_fixed - three_line_adjust))
        [[ $fill_len2 -lt 0 ]] && fill_len2=0
        PR_FILLBAR2=""
        for ((i=0; i<fill_len2; i++)); do
            PR_FILLBAR2+="$PR_HBAR"
        done

        # If line 2 content is still too long, truncate path (keep git branch)
        if [[ $line2_fixed -gt $((TERMWIDTH - three_line_adjust)) ]]; then
            local git_len=0
            [[ -n "$GIT_STATUS" ]] && git_len=$((${#GIT_STATUS} + 1))
            local max_path=$((TERMWIDTH - 5 - git_len - three_line_adjust))
            [[ $max_path -lt 10 ]] && max_path=10
            if [[ ${#PR_PWD} -gt $max_path ]]; then
                PR_PWD="...${PR_PWD: -$((max_path - 3))}"
            fi
            # Recalculate
            line2_content_len=${#PR_PWD}
            [[ -n "$GIT_STATUS" ]] && line2_content_len=$((${#GIT_STATUS} + 1 + line2_content_len))
            line2_fixed=$((5 + line2_content_len))
            fill_len2=$((TERMWIDTH - line2_fixed - three_line_adjust))
            [[ $fill_len2 -lt 0 ]] && fill_len2=0
            PR_FILLBAR2=""
            for ((i=0; i<fill_len2; i++)); do
                PR_FILLBAR2+="$PR_HBAR"
            done
        fi

    else
        # Strategy 4: Status line itself is too long (even without git)
        # Still use three-line mode (line 1 may wrap, but at least git+path is separate)
        PR_THREE_LINE_MODE=1
        PR_FILLBAR=""  # No fill bar for line 1 (it will wrap)

        # In three-line mode, shorten line 2 by 1 char to align with RPROMPT's trailing space
        local three_line_adjust=1

        # Calculate fill for line 2 (git + path line)
        local line2_fixed=$((5 + line2_content_len))
        local fill_len2=$((TERMWIDTH - line2_fixed - three_line_adjust))
        [[ $fill_len2 -lt 0 ]] && fill_len2=0
        PR_FILLBAR2=""
        local i
        for ((i=0; i<fill_len2; i++)); do
            PR_FILLBAR2+="$PR_HBAR"
        done

        # If line 2 content is still too long, truncate path
        if [[ $line2_fixed -gt $((TERMWIDTH - three_line_adjust)) ]]; then
            local git_len=0
            [[ -n "$GIT_STATUS" ]] && git_len=$((${#GIT_STATUS} + 1))
            local max_path=$((TERMWIDTH - 5 - git_len - three_line_adjust))
            [[ $max_path -lt 10 ]] && max_path=10
            if [[ ${#PR_PWD} -gt $max_path ]]; then
                PR_PWD="...${PR_PWD: -$((max_path - 3))}"
            fi
            # Recalculate fill (including git length)
            line2_content_len=${#PR_PWD}
            [[ -n "$GIT_STATUS" ]] && line2_content_len=$((${#GIT_STATUS} + 1 + line2_content_len))
            line2_fixed=$((5 + line2_content_len))
            fill_len2=$((TERMWIDTH - line2_fixed - three_line_adjust))
            [[ $fill_len2 -lt 0 ]] && fill_len2=0
            PR_FILLBAR2=""
            for ((i=0; i<fill_len2; i++)); do
                PR_FILLBAR2+="$PR_HBAR"
            done
        fi
    fi

    # Build the prompt based on mode
    __build_prompt
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
# Prompt Builder
# -----------------------------------------------------------------------------
# Builds PROMPT dynamically based on whether three-line mode is needed
__build_prompt() {
    local prompt_header='$PR_SET_CHARSET${PR_STITLE:-}${(e)PR_TITLEBAR}'

    # Bottom line (same for both modes)
    local prompt_bottom='$PR_LINE_COLOR$PR_SHIFT_IN$PR_CORNER_COLOR$PR_LLCORNER$PR_LINE_COLOR$PR_HBAR$PR_SHIFT_OUT$PR_PARENTHESE_COLOR(\
%(?.$PR_SUCCESS_COLOR.$PR_FAIL_COLOR)%(?..$?${PR_NO_COLOUR}${PR_SEPERATOR})$PR_YELLOW$$\
$PR_GREEN$PR_SEPERATOR%(!.$PR_WITH_ROOT_COLOR.$PR_WITHOUT_ROOT_COLOR)%#$PR_PARENTHESE_COLOR)\
$PR_LINE_COLOR$PR_SHIFT_IN$PR_HBAR$PR_SHIFT_OUT$PR_NO_COLOUR> '

    # RPROMPT (same for both modes)
    RPROMPT='($PR_DATETIME_COLOR%D{%c}$PR_NO_COLOUR|$PR_CHARGING_STATUS_COLOR$PR_BATTERY_ICON$PR_BATTERY_COLOR$PR_BATTERY_INFO%%$PR_NO_COLOUR)$PR_LINE_COLOR$PR_SHIFT_IN$PR_HBAR$PR_CORNER_COLOR$PR_LRCORNER$PR_SHIFT_OUT'

    if [[ $PR_THREE_LINE_MODE -eq 1 ]]; then
        # Three-line mode:
        # Line 1: ┌─(user@host>tty|claude:✓|node:xx)─────────────────┐
        # Line 2: ├────────────────────────(git:branch|path)─┤
        # Line 3: └─($$|%)─>                      (datetime|🔋)─┘
        PROMPT="${prompt_header}"'
$PR_LINE_COLOR$PR_SHIFT_IN$PR_CORNER_COLOR$PR_ULCORNER$PR_LINE_COLOR$PR_HBAR$PR_SHIFT_OUT$PR_PARENTHESE_COLOR(\
$PR_BLUE%(!.%SROOT%s.%n)$PR_RED@$PR_HOST>$PR_YELLOW%l$STATUS_LINE_NO_GIT_PR\
$PR_PARENTHESE_COLOR)$PR_LINE_COLOR$PR_SHIFT_IN$PR_FILLBAR$PR_CORNER_COLOR$PR_URCORNER$PR_SHIFT_OUT
$PR_LINE_COLOR$PR_SHIFT_IN$PR_CORNER_COLOR$PR_LTEE$PR_LINE_COLOR$PR_FILLBAR2$PR_SHIFT_OUT$PR_PARENTHESE_COLOR(\
$GIT_STATUS_PR${GIT_STATUS:+$PR_PARENTHESE_COLOR|}$PR_CWD_COLOR$PR_PWD\
$PR_PARENTHESE_COLOR)$PR_LINE_COLOR$PR_SHIFT_IN$PR_HBAR$PR_CORNER_COLOR$PR_RTEE$PR_SHIFT_OUT
'"${prompt_bottom}"
    else
        # Normal two-line mode:
        # Line 1: ┌─(user@host>tty|status)────────(path)─┐
        # Line 2: └─(exitcode|$$|#)─>          (datetime)─┘
        PROMPT="${prompt_header}"'
$PR_LINE_COLOR$PR_SHIFT_IN$PR_CORNER_COLOR$PR_ULCORNER$PR_LINE_COLOR$PR_HBAR$PR_SHIFT_OUT$PR_PARENTHESE_COLOR(\
$PR_BLUE%(!.%SROOT%s.%n)$PR_RED@$PR_HOST>$PR_YELLOW%l$STATUS_LINE_PR\
$PR_PARENTHESE_COLOR)$PR_LINE_COLOR$PR_SHIFT_IN$PR_FILLBAR$PR_SHIFT_OUT$PR_PARENTHESE_COLOR(\
$PR_CWD_COLOR$PR_PWD\
$PR_PARENTHESE_COLOR)$PR_LINE_COLOR$PR_SHIFT_IN$PR_HBAR$PR_CORNER_COLOR$PR_URCORNER$PR_SHIFT_OUT
'"${prompt_bottom}"
    fi
}

# -----------------------------------------------------------------------------
# Prompt Definition (matching original style)
# -----------------------------------------------------------------------------
# Two-line mode:
#   Line 1: ┌─(user@host>tty|status)────────────────────(repo/path)─┐
#           Path shows git-relative path with  powerline icon when in a repo
#   Line 2: └─(exitcode|$$|#)─>                    (datetime|🔋85%)─┘
#
# Three-line mode (when content overflows):
#   Line 1: ┌─(user@host>tty|status)────────────────────────────────┐
#   Line 2: ├───────────────────────────────────────────(repo/path)─┤
#   Line 3: └─(exitcode|$$|#)─>                    (datetime|🔋85%)─┘

# Initialize with default two-line prompt (will be rebuilt by precmd)
PROMPT='$PR_SET_CHARSET${PR_STITLE:-}${(e)PR_TITLEBAR}\
$PR_LINE_COLOR$PR_SHIFT_IN$PR_CORNER_COLOR$PR_ULCORNER$PR_LINE_COLOR$PR_HBAR$PR_SHIFT_OUT$PR_PARENTHESE_COLOR(\
$PR_BLUE%(!.%SROOT%s.%n)$PR_RED@$PR_HOST>$PR_YELLOW%l$STATUS_LINE_PR\
$PR_PARENTHESE_COLOR)$PR_LINE_COLOR$PR_SHIFT_IN$PR_FILLBAR$PR_SHIFT_OUT$PR_PARENTHESE_COLOR(\
$PR_CWD_COLOR$PR_PWD\
$PR_PARENTHESE_COLOR)$PR_LINE_COLOR$PR_SHIFT_IN$PR_HBAR$PR_CORNER_COLOR$PR_URCORNER$PR_SHIFT_OUT
$PR_LINE_COLOR$PR_SHIFT_IN$PR_CORNER_COLOR$PR_LLCORNER$PR_LINE_COLOR$PR_HBAR$PR_SHIFT_OUT$PR_PARENTHESE_COLOR(\
%(?.$PR_SUCCESS_COLOR.$PR_FAIL_COLOR)%(?..$?${PR_NO_COLOUR}${PR_SEPERATOR})$PR_YELLOW$$\
$PR_GREEN$PR_SEPERATOR%(!.$PR_WITH_ROOT_COLOR.$PR_WITHOUT_ROOT_COLOR)%#$PR_PARENTHESE_COLOR)\
$PR_LINE_COLOR$PR_SHIFT_IN$PR_HBAR$PR_SHIFT_OUT$PR_NO_COLOUR> '

RPROMPT='($PR_DATETIME_COLOR%D{%c}$PR_NO_COLOUR|$PR_CHARGING_STATUS_COLOR$PR_BATTERY_ICON$PR_BATTERY_COLOR$PR_BATTERY_INFO%%$PR_NO_COLOUR)$PR_LINE_COLOR$PR_SHIFT_IN$PR_HBAR$PR_CORNER_COLOR$PR_LRCORNER$PR_SHIFT_OUT'

PS2='$PR_LINE_COLOR$PR_SHIFT_IN$PR_HBAR$PR_SHIFT_OUT\
$PR_SHIFT_IN$PR_HBAR$PR_SHIFT_OUT$PR_PARENTHESE_COLOR(\
$PR_YELLOW%_$PR_PARENTHESE_COLOR)$PR_LINE_COLOR$PR_SHIFT_IN$PR_HBAR$PR_SHIFT_OUT\
$PR_LINE_COLOR$PR_SHIFT_IN$PR_HBAR$PR_SHIFT_OUT$PR_PARENTHESE_COLOR>$PR_NO_COLOUR '
