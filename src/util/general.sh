# Ask permission to continue
w_askpermission()
{
    echo "------------------------------------------------------"
    echo "$@"
    echo "------------------------------------------------------"

    if test $W_OPT_UNATTENDED
    then
        _W_timeout="--timeout 5"
    fi

    case $WINETRICKS_GUI in
    zenity) $WINETRICKS_GUI $_W_timeout --question --title=winetricks --text="`echo $@ | sed 's,\\\\,\\\\\\\\,g'`" --no-wrap;;
    kdialog) $WINETRICKS_GUI --title winetricks --warningcontinuecancel "$@" ;;
    none) printf %s "Press Y or N, then Enter: " ; read response ; test "$response" = Y || test "$response" = y;;
    esac

    if test $? -ne 0
    then
        w_die "Operation cancelled, quitting."
        exec false
    fi

    unset _W_timeout
}

# Display info message.  Time out quickly if user doesn't click.
w_info()
{
    echo "------------------------------------------------------"
    echo "$@"
    echo "------------------------------------------------------"

    _W_timeout="--timeout 3"

    case $WINETRICKS_GUI in
    zenity) $WINETRICKS_GUI $_W_timeout --info --title=winetricks --text="`echo $@ | sed 's,\\\\,\\\\\\\\,g'`" --no-wrap;;
    kdialog) $WINETRICKS_GUI --title winetricks --msgbox "$@" ;;
    none) ;;
    esac

    unset _W_timeout
}

# Display warning message to stderr (since it is called inside redirected code)
w_warn()
{
    echo "------------------------------------------------------" >&2
    echo "$@" >&2
    echo "------------------------------------------------------" >&2

    if test $W_OPT_UNATTENDED
    then
        _W_timeout="--timeout 5"
    fi

    case $WINETRICKS_GUI in
    zenity) $WINETRICKS_GUI $_W_timeout --error --title=winetricks --text="`echo $@ | sed 's,\\\\,\\\\\\\\,g'`";;
    kdialog) $WINETRICKS_GUI --title winetricks --error "$@" ;;
    none) ;;
    esac

    unset _W_timeout
}

# Display warning message to stderr (since it is called inside redirected code)
# And give gui user option to cancel (for when used in a loop)
# If user cancels, exit status is 1
w_warn_cancel()
{
    echo "------------------------------------------------------" >&2
    echo "$@" >&2
    echo "------------------------------------------------------" >&2

    if test $W_OPT_UNATTENDED
    then
        _W_timeout="--timeout 5"
    fi

    # Zenity has no cancel button, but will set status to 1 if you click the go-away X
    case $WINETRICKS_GUI in
    zenity) $WINETRICKS_GUI $_W_timeout --error --title=winetricks --text="`echo $@ | sed 's,\\\\,\\\\\\\\,g'`";;
    kdialog) $WINETRICKS_GUI --title winetricks --warningcontinuecancel "$@" ;;
    none) ;;
    esac

    # can't unset, it clears status
}

# Display fatal error message and terminate script
w_die()
{
    w_warn "$@"

    exit 1
}

# Kill all instances of a process in a safe way (Solaris killall kills _everything_)
w_killall()
{
    kill -s KILL `pgrep $1`
}

# Execute with error checking
# Put this in front of any command that might fail
w_try()
{
    # "VAR=foo w_try cmd" fails to put VAR in the environment
    # with some versions of bash if w_try is a shell function?!
    # This is a problem when trying to pass environment variables to e.g. wine.
    # Adding an explicit export here works around it, so add any we use.
    export WINEDLLOVERRIDES
    printf '%s\n' "Executing $*"

    # On Vista, we need to jump through a few hoops to run commands in cygwin.
    # First, .exe's need to have the executable bit set.
    # Second, only cmd can run setup programs (presumably for security).
    # If $1 ends in .exe, we know we're running on real windows, otherwise
    # $1 would be 'wine'.
    case "$1" in
    *.exe)
        chmod +x "$1" || true # don't care if it fails
        cmd /c "$@"
        ;;
    *)
        "$@"
        ;;
    esac
    status=$?
    if test $status -ne 0
    then
        w_die "Note: command '$@' returned status $status.  Aborting."
    fi
}

# Convert a Windows path to a Unix path quickly.
# $1 is an absolute Windows path starting with c:\ or C:/
# with no funny business, so we can use the simplest possible
# algorithm.
winetricks_wintounix()
{
    _W_winp_="$1"
    # Remove drive letter and colon
    _W_winp="${_W_winp_#??}"
    # Prepend the location of drive c
    printf %s "$WINEPREFIX"/dosdevices/c:
    # Change backslashes to slashes
    echo $_W_winp | sed 's,\\,/,g'
}

# Convert between Unix path and Windows path
# Usage is lowest common denominator of cygpath/winepath
# so -u to convert to unix, and -w to convert to windows
w_pathconv()
{
    case "$OS" in
     "Windows_NT")
        # for some reason, cygpath turns some spaces into newlines?!
        cygpath "$@" | tr '\012' '\040' | sed 's/ $//'
        ;;
     *)
        case "$@" in
        -u?c:\\*|-u?C:\\*|-u?c:/*|-u?C:/*) winetricks_wintounix "$2" ;;
        *) winetricks_early_wine winepath "$@" ;;
        esac
        ;;
    esac
}

# Expand an environment variable and print it to stdout
w_expand_env()
{
    winetricks_early_wine cmd.exe /c echo "%$1%"
}

# get sha1sum string and set $_W_gotsum to it
w_get_sha1sum()
{
    local _W_file="$1"
    _W_gotsum=`$WINETRICKS_SHA1SUM < "$_W_file" | sed 's/(stdin)= //;s/ .*//'`
}

# verify an sha1sum
w_verify_sha1sum()
{
    _W_vs_wantsum=$1
    _W_vs_file=$2

    w_get_sha1sum "$_W_vs_file"
    if [ "$_W_gotsum"x != "$_W_vs_wantsum"x ]
    then
        w_die "sha1sum mismatch!  Rename $_W_vs_file and try again."
    fi
    unset _W_vs_wantsum _W_vs_file _W_gotsum
}

# wget outputs progress messages that look like this:
#      0K .......... .......... .......... .......... ..........  0%  823K 40s
# This function replaces each such line with the pair of lines
# 0%
# # Downloading... 823K (40s)
# It uses minimal buffering, so each line is output immediately
# and the user can watch progress as it happens.

winetricks_parse_wget_progress()
{
    # Parse a percentage, a size, and a time into $1, $2 and $3
    # then use them to create the output line.
    perl -p -e \
       '$| = 1; s/^.* +([0-9]+%) +([0-9,.]+[GMKB]) +([0-9hms,.]+).*$/\1\n# Downloading... \2 (\3)/'
}

# Execute wget, and if in gui mode, also show a graphical progress bar
winetricks_wget_progress()
{
    case $WINETRICKS_GUI in
    zenity)
        # Usa a subshell so if the user clicks 'Cancel',
        # the --auto-kill kills the subshell, not the current shell
        (
            wget "$@" 2>&1 |
            winetricks_parse_wget_progress | \
            $WINETRICKS_GUI --progress --width 400 --title="$_W_file" --auto-kill --auto-close
        )
        err=$?
        if test $err -gt 128
        then
            # 129 is 'killed by SIGHUP'
            # Sadly, --auto-kill only applies to parent process,
            # which was the subshell, not all the elements of the pipeline...
            # have to go find and kill the wget.
            # If we ran wget in the background, we could kill it more directly, perhaps...
            if pid=`ps augxw | grep ."$_W_file" | grep -v grep | awk '{print $2}'`
            then
                echo User aborted download, killing wget
                kill $pid
            fi
        fi
        return $err
        ;;
    *) wget "$@" ;;
    esac
}

# Open a web browser for the user to the given page
# Usage: w_open_webpage url
w_open_webpage()
{
    # See http://www.dwheeler.com/essays/open-files-urls.html
    for _W_cmd in xdg-open sdtwebclient cygstart open firefox true
    do
        _W_cmdpath=`which $_W_cmd`
        if test -n "$_W_cmdpath"
        then
            break
        fi
    done
    $_W_cmd "$1" &
    unset _W_cmd _W_cmdpath
}

# Open a folder for the user in the specified directory
# Usage: w_open_folder directory
w_open_folder()
{
    for _W_cmd in xdg-open open cygstart true
    do
        _W_cmdpath=`which $_W_cmd`
        if test -n "$_W_cmdpath"
        then
            break
        fi
    done
    $_W_cmd "$1" &
    unset _W_cmd _W_cmdpath
}

w_question()
{
    case $WINETRICKS_GUI in
    *zenity) $WINETRICKS_GUI --entry --text "$1" ;;
    *kdialog) $WINETRICKS_GUI --inputbox "$1" ;;
    *xmessage) w_die "sorry, can't ask question with xmessage" ;;
    none) echo -n "$1" >&2 ; read W_ANSWER ; echo $W_ANSWER; unset W_ANSWER;;
    esac
}

w_append_path()
{
    # Prepend $1 to the windows path in the registry.
    # Use printf %s to avoid interpreting backslashes.
    _W_NEW_PATH="`printf %s $1| sed 's,\\\\,\\\\\\\\,g'`"
    _W_WIN_PATH="`w_expand_env PATH | sed 's,\\\\,\\\\\\\\,g'`"

    sed 's/$/\r/' > "$W_TMP"/path.reg <<_EOF_
REGEDIT4

[HKEY_LOCAL_MACHINE\\System\\CurrentControlSet\\Control\\Session Manager\\Environment]
"PATH"="$_W_NEW_PATH;$_W_WIN_PATH"
_EOF_

    w_try_regedit "$W_TMP_WIN"\\path.reg
    rm -f "$W_TMP"/path.reg
    unset _W_NEW_PATH _W_WIN_PATH
}

