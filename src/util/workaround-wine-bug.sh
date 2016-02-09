# Usage: workaround_wine_bug bugnumber [message] [good-wine-version-range ...]
# Returns true and outputs given msg if the workaround needs to be applied.
# For debugging: if you want to skip a bug's workaround, put the bug number in
# the environment variable WINETRICKS_BLACKLIST to disable it.
w_workaround_wine_bug()
{
    if test "$WINE" = ""
    then
        echo No need to work around wine bug $1 on windows
        return 1
    fi
    case "$2" in
    [0-9]*) w_die "bug: want message in w_workaround_wine_bug arg 2, got $2" ;;
    "") _W_msg="";;
    *)  _W_msg="-- $2";;
    esac

    if test "$3" && w_wine_version_in $3 $4 $5 $6
    then
        echo Current wine does not have wine bug $1, so not applying workaround
        return 1
    fi

    case $1 in
    "$WINETRICKS_BLACKLIST")
        echo wine bug $1 workaround blacklisted, skipping
        return 1
        ;;
    esac
    case $LANG in
    da*) w_warn "Arbejder uden om wine-fejl ${1} $_W_msg" ;;
    de*) w_warn "Wine-Fehler ${1} wird umgegangen $_W_msg" ;;
    pl*) w_warn "Obchodzenie błędu w wine ${1} $_W_msg" ;;
    uk*) w_warn "Обхід помилки ${1} $_W_msg" ;;
    zh_CN*)   w_warn "绕过 wine bug ${1} $_W_msg" ;;
    zh_TW*|zh_HK*)   w_warn "繞過 wine bug ${1} $_W_msg" ;;
    *)   w_warn "Working around wine bug ${1} $_W_msg" ;;
    esac
    winetricks_stats_log_command w_workaround_wine_bug-$1
    return 0
}

