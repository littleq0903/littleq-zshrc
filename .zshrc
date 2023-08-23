# use ~/.profile
source $HOME/.profile

# Libraries
source ~/github/littleq-settings/littleq-zshrc/.virtualenv.zsh
source ~/github/littleq-settings/littleq-zshrc/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
alias dircolors=gdircolors
PATH="/opt/homebrew/opt/grep/libexec/gnubin:$PATH"
PATH="/opt/homebrew/bin:$PATH"


MACHINE_OS=${MACHINE_OS:-macosx}

httpserver () {
    sleep 1 && open "http://localhost:$1/" &
    python3 -m SimpleHTTPServer $1 ${@:2}
}

clip_code (){

    local syntax=$1
    local theme_type=$2 # dark or light

    if [ "$theme_type" = "light" ]
    then
        local theme=fine_blue
    elif [ "$theme_type" = "dark" ]
    then
        local theme=zenburn
    elif [ -n "$theme_type" ]
    then
        local theme=$theme_type
    else
        echo "$0 <syntax> <dark|light|theme>"
        return 1
    fi

    plaintext
    pbpaste

    # convert
    #pbpaste | highlight --syntax=$syntax -O rtf --font-size 36 --font "Ubuntu Mono" --style $theme ${@:2} | pbcopy
    pbpaste | highlight --syntax=$syntax -O rtf --font-size 36 --font "Droid Sans Mono" --style $theme | pbcopy
}

man () {
    /usr/bin/man $@ | col -b | vim -R -c 'set ft=man nomod nolist' -
}

function git-conflict {
    vim -p $(git diff --name-only --diff-filter=U);
}

function gen_gitignore () {
    curl http://www.gitignore.io/api/$@ ; 
}


# convert the encoding of files to UTF-8
to_utf8 () {
    enca -L zh_TW -x UTF-8 $1;
}

# convert between zh_TW and zh_CN

sc2tc () {
    iconv -f UTF-8 -t GB2312 $1 | iconv -f GB2312 -t BIG-5 | iconv -f BIG-5 -t UTF-8 > $2;
}

tc2sc () {
    iconv -f UTF-8 -t BIG-5 $1| iconv -f BIG-5 -t GB2312 | iconv -f GB2312 -t UTF-8 > $2;
}

# change the names of two files.
swap_name () {
    temp_swap_filename="aslkdjasldjkas";
    if [ $# != 2 ] ; then
        echo "Please give only two filenames as arguments.";
    else
        mv $1 $temp_swap_filename;
        mv $2 $1;
        mv $temp_swap_filename $2;
        rm $temp_swap_filename
        echo "$2 <--> $1";
    fi
}

appengine () {
    if [ $1 = "startproject" ]; then
        cp -r /usr/local/google_appengine/new_project_template ./$2 
    fi
}

git_branch() {
    git branch | grep "^\*" | tr -d "* "  2> /dev/null
}

plaintext() {
    pbpaste -Prefer txt | pbcopy
}


## Function to connect the instances in the internal cloud (PLSM Cloud)
connect_plsm_instance () {
    if [ $# -ne 1 ]; then
        echo "Usage: connect_plsm_instance <private ip>";
        echo "private ip: the private ip of the instance in the PLSM private cloud";
    fi

    ssh -t littleq@140.119.164.155 "ssh -i ~/.ssh/id_littleq-plsm ubuntu@$1"
}

## Function to check the ports are listening any ports on this machine
openports () {
    sudo lsof -i -P | grep -i "listen"
}


#关于历史纪录的配置
# enhance Chinese supports for auto completion list
export LANG=en_US.UTF-8
# number of lines kept in history
export HISTSIZE=1000
# number of lines saved in the history after logout
export SAVEHIST=1000
# location of history
export HISTFILE=~/.zhistory
# append command to history file once executed
setopt INC_APPEND_HISTORY
# removed the duplicated history
setopt HIST_IGNORE_DUPS

#Disable core dumps
limit coredumpsize 0

#Emacs风格键绑定
#bindkey -e
#设置DEL键为向后删除
bindkey "\e[3~" delete-char

#以下字符视为单词的一部分
WORDCHARS=';*?_-[]~=&!#$%^(){}<>'

bindkey ';5D' backward-word
bindkey ';5C' forward-word

#自动补全功能
setopt AUTO_LIST
setopt AUTO_MENU
setopt MENU_COMPLETE


# Completion caching
zstyle ':completion::complete:*' use-cache on
zstyle ':completion::complete:*' cache-path .zcache
zstyle ':completion:*:cd:*' ignore-parents parent pwd

#Completion Options
zstyle ':completion:*:match:*' original only
zstyle ':completion::prefix-1:*' completer _complete
zstyle ':completion:predict:*' completer _complete
zstyle ':completion:incremental:*' completer _complete _correct
zstyle ':completion:*' completer _complete _prefix _correct _prefix _match _approximate
zstyle ':completion:*' verbose true
zstyle ':completion:*' insecure-directories ''

# Path Expansion
zstyle ':completion:*' expand-or-complete 'yes'
zstyle ':completion:*' squeeze-shlashes 'yes'
zstyle ':completion::complete:*' '\\'

zstyle ':completion:*:*:*:default' menu yes select
zstyle ':completion:*:*:default' force-list always

if [ "$MACHINE_OS" = "macosx" ] ; then
else
	alias gdircolors="dircolors"
    if [ -f /etc/DIR_COLORS ] ; then
        eval $(gdircolors -b /etc/DIR_COLORS);
    else
        eval $(gdircolors -b);
    fi
fi

# GNU Colors 需要/etc/DIR_COLORS文件 否则自动补全时候选菜单中的选项不能彩色显示
[ -f /etc/DIR_COLORS ] && eval $(gdircolors -b /etc/DIR_COLORS)
[ -f /etc/DIR_COLORS ] && eval $(gdircolors -b)


fpath=($HOME/Dropbox/portableLibraries/zsh/completion $fpath)
fpath=(
    $HOME/github/zsh-completions/src
    $HOME/github/maven-zsh-completion
    $fpath)

# debugging gcloud zsh completion
fpath=($HOME/github/gcloud-zsh-completion/src $fpath)

autoload -U compinit compdef
compinit
compdef pkill=kill
compdef pkill=killall
compdef hub=git

#export LSCOLORS='exfxbxdxcxegedabagacad'
#export ZLSCOLORS="${LS_COLORS}"
zmodload zsh/complist
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'

zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*:match:*' original only
zstyle ':completion:*:approximate:*' max-errors 1 numeric

zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:processes' command 'ps -au$USER'

# Group matches and Describe
zstyle ':completion:*:matches' group 'yes'
zstyle ':completion:*:options' description 'yes'
zstyle ':completion:*:options' auto-description '%d'
zstyle ':completion:*:descriptions' format $'\e[01;33m -- %d --\e[0m'
zstyle ':completion:*:messages' format $'\e[01;35m -- ^_^y %d --\e[0m'
zstyle ':completion:*:warnings' format $'\e[01;31m -- O_O! No Matches Found --\e[0m'

# General aliases
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'
alias ls='gls --color'
alias ll='ls -l'
alias la='ls -a'
alias lla='ls -al'
alias sl='ls'
alias grep='grep --color=auto'
alias back='tmux -2 attach'
alias q='exit'

# VIM aliases
alias vimsplit="vim -o"
alias vimvsplit="vim -O"
alias vimsp="vimsplit"
alias vimvsp="vimvsplit"
alias vimtab="vim -p"

# syntax highlight using cat
alias pcat=pygmentize
function pless() {
    pcat "$1" | less -R
}

if [ $MACHINE_OS = "ubuntu" ]; then
    alias pbcopy="xclip -selection clipboard -i"
    alias pbpaste="xclip -selection clipboard -o"
    alias ls="ls --color"
fi

#路径别名 进入相应的路径时只要 cd ~xxx
hash -d download="$HOME/Downloads"
hash -d dropbox="$HOME/Dropbox"
hash -d github="$HOME/github"
hash -d googlecode="$HOME/googlecode"
hash -d tagtoo="$HOME/github_tagtoo/"
hash -d desktop="$HOME/Desktop"

#效果超炫的提示符，如需要禁用，注释下面配置   
function precmd {
    
    local TERMWIDTH
    (( TERMWIDTH = ${COLUMNS} ))

    ###
    # Compose status pr string

    STATUS_LINE=''
    STATUS_LINE_PR=''

    # status
    update_job_num
    update_git_branch
    update_virtualenv_name

    # info
    update_battery_info
    
    ###
    # Truncate the path if it's too long.
    
    PR_FILLBAR=""
    PR_PWDLEN=""
    
    local promptsize=${#${(%):---(%m@%n:%l)()--}}
    local pwdpath=${(%):-%~}

    local pwdsize_unicode="${#pwdpath}"
    local chinesechar_size=$(echo "$pwdpath" | grep -oP "[\x{4e00}-\x{9fff}]" | wc -l)

    # chinese will be treat as 3 times as length of normal charactor
    let "pwdsize = $pwdsize_unicode - $chinesechar_size"
    let "total_occupied=$promptsize+$pwdsize+${#STATUS_LINE}"

    if [[ $total_occupied -gt $TERMWIDTH ]]; then
        ###
        # Tmux will return wrong ${COLUMNS}, I don't know why so I just figure out this solution, shorten the width when detected $TMUX variable
        ###
        #[ "$TMUX" ] && (( TERMWIDTH = $TERMWIDTH - 14 ))
        #PR_FILLBAR="LONG"
        let "PR_PWDLEN=$TERMWIDTH - $total_occupied + $pwdsize"
    else
        
        #[ "$TMUX" ] && (( TERMWIDTH = $TERMWIDTH + 14 ))
        PR_FILLBAR="\${(l.(($TERMWIDTH - $total_occupied))..${PR_HBAR_EMPTY}.)}"
    fi
    
    #echo "total_occupied: $total_occupied"
    #echo "PR_PWDLEN: $PR_PWDLEN"
    
    
}


setopt extended_glob

# hook functions

preexec () {
    if [[ "$TERM" == "screen" ]]; then
    local CMD=${1[(wr)^(*=*|sudo|-*)]}
    echo -n "\ek$CMD\e\\"
    fi
    jobs
}

chpwd () {
    ls
}

setprompt () {
    ###
    # Need this so the prompt will work.

    setopt prompt_subst
    

    ###
    # See if we can use colors.

    autoload colors zsh/terminfo
    if [[ "$terminfo[colors]" -ge 8 ]]; then
    colors
    fi
    for color in RED GREEN YELLOW BLUE MAGENTA CYAN WHITE; do
    eval PR_$color='%{$terminfo[bold]$fg[${(L)color}]%}'
    eval PR_LIGHT_$color='%{$fg[${(L)color}]%}'
    (( count = $count + 1 ))
    done
    PR_NO_COLOUR="%{$terminfo[sgr0]%}"
    
    
    ###
    # See if we can use extended characters to look nicer.
    
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
    
    
    ###
    # Decide if we need to set titlebar text.
    
    case $TERM in
    xterm*)
        PR_TITLEBAR=$'%{\e]0;%(!.-=*[ROOT]*=- | .)%n@%m:%~ | ${COLUMNS}x${LINES} | %y\a%}'
        ;;
    screen)
        PR_TITLEBAR=$'%{\e_screen \005 (\005t) | %(!.-=[ROOT]=- | .)%n@%m:%~ | ${COLUMNS}x${LINES} | %y\e\\%}'
        ;;
    *)
        PR_TITLEBAR=''
        #PR_TITLEBAR=$'%{\e_screen \005 (\005t) | %(!.-=[ROOT]=- | .)%n@%m:%~ | ${COLUMNS}x${LINES} | %y\e\\%}'
        ;;
    esac
    
    
    ###
    # Decide whether to set a screen title
    if [[ "$TERM" == "screen" ]] ; then
      PR_STITLE=$'%{\ekzsh\e\\%}'
    else
      PR_STITLE=''
      #PR_STITLE=$'%{\ekzsh\e\\%}'
    fi

    
    ###
    # Finally, the prompt.

    ## COLOR DEFINITION
    PR_PARENTHESE_COLOR=${PR_NO_COLOUR}
    PR_CORNER_COLOR=${PR_GREEN}
    PR_LINE_COLOR=${PR_LIGHT_GREEN}
    PR_CWD_COLOR=${PR_LIGHT_BLUE}
    PR_DATETIME_COLOR=${PR_GREEN}
    PR_SEPERATOR_COLOR=${PR_NO_COLOUR}

    # root priviledge color
    PR_WITH_ROOT_COLOR=${PR_RED}
    PR_WITHOUT_ROOT_COLOR=${PR_NO_COLOUR}

    # cmd execution color
    PR_SUCCESS_COLOR=${PR_LIGHT_GREEN}
    PR_FAIL_COLOR=${PR_RED}

    ###
    # Settings of prompt
    PR_SEPERATOR=${PR_SEPERATOR_COLOR}\|


    ## Prompts
    
    PROMPT='$PR_SET_CHARSET$PR_STITLE${(e)PR_TITLEBAR}\
$PR_LINE_COLOR$PR_SHIFT_IN$PR_CORNER_COLOR$PR_ULCORNER$PR_LINE_COLOR$PR_HBAR$PR_SHIFT_OUT$PR_PARENTHESE_COLOR(\
$PR_BLUE%(!.%SROOT%s.%n)$PR_RED@%m>$PR_YELLOW%l$STATUS_LINE_PR\
$PR_PARENTHESE_COLOR)$PR_LINE_COLOR$PR_SHIFT_IN$PR_LINE_COLOR${(e)PR_FILLBAR}$PR_LINE_COLOR$PR_SHIFT_OUT$PR_PARENTHESE_COLOR(\
$PR_CWD_COLOR%$PR_PWDLEN<...<%~%<<\
$PR_PARENTHESE_COLOR)$PR_LINE_COLOR$PR_SHIFT_IN$PR_HBAR$PR_CORNER_COLOR$PR_URCORNER$PR_SHIFT_OUT\

$PR_LINE_COLOR$PR_SHIFT_IN$PR_CORNER_COLOR$PR_LLCORNER$PR_LINE_COLOR$PR_HBAR$PR_SHIFT_OUT$PR_PARENTHESE_COLOR(\
%(?.$PR_SUCCESS_COLOR.$PR_FAIL_COLOR)%(?..$?${PR_NO_COLOUR}${PR_SEPERATOR})$PR_YELLOW$$\
$PR_GREEN$PR_SEPERATOR%(!.$PR_WITH_ROOT_COLOR.$PR_WITHOUT_ROOT_COLOR)%#$PR_PARENTHESE_COLOR)\
$PR_LINE_COLOR$PR_SHIFT_IN$PR_HBAR$PR_SHIFT_OUT$PR_NO_COLOUR> '
    
    RPROMPT='$PR_PARENTHESE_COLOR($PR_DATETIME_COLOR%D{%c}$PR_GREEN$PR_NO_COLOUR$PR_SEPERATOR$PR_BATTERY_COLOR$PR_BATTERY_INFO%%$PR_LINE_COLOR$PR_NO_COLOUR$PR_SEPERATOR$PR_CHARGING_STATUS_COLOR$PR_CHARGING_STATUS$PR_PARENTHESE_COLOR)$PR_LINE_COLOR$PR_SHIFT_IN$PR_HBAR$PR_CORNER_COLOR$PR_LRCORNER$PR_LINE_COLOR$PR_SHIFT_OUT$PR_NO_COLOUR'
    
    PS2='$PR_LINE_COLOR$PR_SHIFT_IN$PR_HBAR$PR_SHIFT_OUT\
$PR_SHIFT_IN$PR_HBAR$PR_SHIFT_OUT$PR_PARENTHESE_COLOR(\
$PR_YELLOW%_$PR_PARENTHESE_COLOR)$PR_LINE_COLOR$PR_SHIFT_IN$PR_HBAR$PR_SHIFT_OUT\
$PR_LINE_COLOR$PR_SHIFT_IN$PR_HBAR$PR_SHIFT_OUT$PR_PARENTHESE_COLOR>$PR_NO_COLOUR '

}

add_update_status() {
    # script to add status in one line
    # usage: add_update_status git command $PR_GREEN
    local COLOR_CODE=$3
    local RESET_COLOR_CODE=$PR_NO_COLOUR
    local RESULT_COLOR_CODE=

    local prefix=$1
    local cmd=$2
    local extra_command=$4
    
    # the same reason of CMD_STRING and CMD_STRING_PR
    local seperator=\:
    local color_seperator=${COLOR_CODE}$seperator${COLOR_CODE}

    local execute_result=`eval $cmd 2> /dev/null`

    if [ "$execute_result" ] ; then
        # CMD_STRING and CMD_STRING_PR need to be in the same length, but one with the color code, to avoid length calculation includes color code as strings.
        CMD_STRING="|${prefix}${seperator}${execute_result}"
        CMD_STRING_PR="${PR_PARENTHESE_COLOR}|${COLOR_CODE}${prefix}${color_seperator}$RESULT_COLOR_CODE${execute_result}"
    else
        CMD_STRING=""
        CMD_STRING_PR=""
    fi

    STATUS_LINE=$STATUS_LINE$CMD_STRING
    STATUS_LINE_PR=$STATUS_LINE_PR$CMD_STRING_PR

    $extra_command
}

## Status :: Git Branch

update_git_branch() {
    add_update_status git git_branch ${PR_LIGHT_GREEN}
}

## Status :: Virtual Environment

clean_virtualenv_name() {
    # clean the virtualenv title
    PS1=`echo $PS1 | sed "s/^($(basename $VIRTUAL_ENV 2> /dev/null))//"` 
}

update_virtualenv_name() {
    add_update_status env "/usr/bin/basename $VIRTUAL_ENV" ${PR_RED} clean_virtualenv_name
}

## Status :: Jobs Number

update_job_num() {
    add_update_status job "echo %j" ${PR_BLUE}
}

show_info () {
    autoload colors && colors
    # show path
    #echo "$fg[yellow][Current path]\n$reset_color$PATH"
    # show network info
    #echo "$fg[yellow][Networking]$reset_color"
}

update_battery_info() {
    ## Getting Battery Info

    # Battery info
    #[[ "`pmset -g batt`" =~ '([0-9]+)\%' ]] && PR_BATTERY_INFO=$match[1]
    #[[ "`pmset -g batt`" =~ 'charged|charging|finishing charge|discharging' ]] && PR_CHARGING_STATUS=$MATCH

    # Battery info
    [[ "`cat /sys/class/power_supply/battery/current_now | tr -d "\n"`" =~ '([0-9]+)' ]] && PR_BATTERY_INFO=$match[1]
    PR_BATTERY=$PR_BATTERY."\%"
    PR_CHARGING_STATUS=charged

    # battery color
    PR_BATTERY_COLOR=${PR_RED}
    [[ $PR_BATTERY_INFO -gt "30" ]] && PR_BATTERY_COLOR=${PR_YELLOW}
    [[ $PR_BATTERY_INFO -gt "60" ]] && PR_BATTERY_COLOR=${PR_BLUE}
    [[ $PR_BATTERY_INFO -gt "95" ]] && PR_BATTERY_COLOR=${PR_GREEN}

    [[ $PR_CHARGING_STATUS == "charged" ]] && PR_CHARGING_STATUS_COLOR=${PR_GREEN}
    [[ $PR_CHARGING_STATUS == "charging" ]] && PR_CHARGING_STATUS_COLOR=${PR_YELLOW}
    [[ $PR_CHARGING_STATUS == "discharging" ]] && PR_CHARGING_STATUS_COLOR=${PR_RED}
}

# start prompt
setprompt

# Startup messages
show_info
#task

# added by travis gem
[ -f /Users/littleq/.travis/travis.sh ] && source /Users/littleq/.travis/travis.sh

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

