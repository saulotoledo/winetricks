# Function for verbs to register themselves so they show up in the menu.
# Example:
# w_metadata wog games \
#   title="World of Goo Demo" \
#   pub="2D Boy" \
#   year="2008" \
#   media="download" \
#   file1="WorldOfGooDemo.1.0.exe"

w_metadata()
{
    case $WINETRICKS_OPT_VERBOSE in
        2) set -x ;;
        *) set +x ;;
    esac

    if test "$installed_exe1" || test "$installed_file1" || test "$publisher" || test "$year"
    then
        w_die "bug: stray metadata tags set: somebody forgot a backslash in a w_metadata somewhere.  Run with sh -x to see where."
    fi
    if winetricks_metadata_exists $1
    then
        w_die "bug: a verb named $1 already exists."
    fi

    _W_md_cmd="$1"
    _W_category=$2
    file="$WINETRICKS_METADATA/$_W_category/$1.vars"
    shift
    shift
    # Echo arguments to file, with double quotes around the values.
    # Used to use perl here, but that was too slow on cygwin.
    for arg
    do
        case "$arg" in
        installed_exe1=/*)
            w_die "bug: w_metadata $_W_md_cmd has a unix path for installed_exe1, should be a windows path";;
        installed_file1=/*)
            w_die "bug: w_metadata $_W_md_cmd has a unix path for installed_file1, should be a windows path";;
        media=download_manual)
            w_die "bug: verb $_W_md_cmd has media=download_manual, should be manual_download" ;;
        esac
        # Use longest match when stripping value,
        # and shortest match when stripping name,
        # so descriptions can have embedded equals signs
        # FIXME: backslashes get interpreted here.  This screws up
        # installed_file1 fairly often.  Fortunately, we can use forward
        # slashes in that variable instead of backslashes.
        echo ${arg%%=*}=\"${arg#*=}\"
    done > "$file"
    echo category='"'$_W_category'"' >> "$file"
    # If the problem described above happens, you'd see errors like this:
    # /tmp/w.dank.4650/metadata/dlls/comctl32.vars: 6: Syntax error: Unterminated quoted string
    # so check for lines that aren't properly quoted.

    # Do sanity check unless running on cygwin, where it's way too slow.
    case "$OS" in
    "Windows_NT")
        ;;
    *)
        if grep '[^"]$' "$file"
        then
            w_die "bug: w_metadata $_W_md_cmd corrupt, might need forward slashes?"
        fi
        ;;
    esac
    unset _W_md_cmd

    # Restore verbosity:
    case $WINETRICKS_OPT_VERBOSE in
        1|2) set -x ;;
        *) set +x ;;
    esac
}

# Function for verbs to register their main executable [or, if name is given,
# other executables]
# Example:
#   w_declare_exe "$W_PROGRAMS_X86_WIN\\WorldOfGooDemo" WorldOfGoo.exe [name]
w_declare_exe()
{
    _W_dir="$1"
    _W_exe="$2"
    if test "$3"
    then
        _W_name="$3"
    else
        _W_name="$W_PACKAGE"
    fi
    cat > "$W_DRIVE_C/run-$_W_name.bat" <<__EOF__
${W_PROGRAMS_DRIVE}:
cd "$_W_dir"
$_W_exe %*
__EOF__
    unset _W_dir _W_exe _W_name
}

# Checks that a conflicting verb is not already installed in the prefix
# Usage: w_conflicts verb_to_install conflicts
w_conflicts()
{
    for x in $2
    do
        if grep -qw "$x" "$WINEPREFIX/winetricks.log"
        then
            w_die "error: $1 conflicts with $x, which is already installed."
        fi
    done
}

# Call a verb, don't let it affect environment
# Hope that subshell passes through exit status
# Usage: w_do_call foo [bar]       (calls load_foo bar)
# Or: w_do_call foo=bar            (also calls load_foo bar)
# Or: w_do_call foo                (calls load_foo)
w_do_call()
{
    (
        # Hack..
        if test $cmd = vd
        then
            load_vd $arg
            _W_status=$?
            test "$W_OPT_NOCLEAN" = 1 || rm -rf "$W_TMP"
            mkdir -p "$W_TMP"
            return $_W_status
        fi

        case $1 in
        *=*) arg=`echo $1 | sed 's/.*=//'`; cmd=`echo $1 | sed 's/=.*//'`;;
        *) cmd=$1; arg=$2 ;;
        esac

        # Kludge: use Temp instead of temp to avoid \t expansion in w_try
        # but use temp in unix path because that's what wine creates, and having both temp and Temp
        # causes confusion (e.g. makes vc2005trial fail)
        # FIXME: W_TMP is also set in winetricks_set_wineprefix, can we avoid the duplication?
        W_TMP="$W_DRIVE_C/windows/temp/_$1"
        W_TMP_WIN="C:\\windows\\Temp\\_$1"
        test "$W_OPT_NOCLEAN" = 1 || rm -rf "$W_TMP"
        mkdir -p "$W_TMP"

        # Unset all known used metadata values, in case this is a nested call
        unset conflicts installed_file1 installed_exe1

        if winetricks_metadata_exists $1
        then
            . "$WINETRICKS_METADATA"/*/$1.vars
        elif winetricks_metadata_exists $cmd
        then
            . "$WINETRICKS_METADATA"/*/$cmd.vars
        elif test $cmd = native || test $cmd = disabled || test $cmd = builtin || test $cmd = default
        then
            # ugly special case - can't have metadata for these verbs until we allow arbitrary parameters
            w_override_dlls $cmd $arg
            _W_status=$?
            test "$W_OPT_NOCLEAN" = 1 || rm -rf "$W_TMP"
            mkdir -p "$W_TMP"
            return $_W_status
        else
            w_die "No such verb $1"
        fi

        # If needed, set the app's wineprefix
        case "$OS" in
        Windows_NT)
            ;;
        *)
            case "$category"-"$WINETRICKS_OPT_SHAREDPREFIX" in
            apps-0|benchmarks-0|games-0)
                winetricks_set_wineprefix "$cmd"
                # If it's a new wineprefix, give it metadata
                if test ! -f "$WINEPREFIX"/wrapper.cfg
                then
                    echo ww_name=\"$title\" > "$WINEPREFIX"/wrapper.cfg
                fi
                ;;
            esac
            ;;
        esac

        test "$W_OPT_NOCLEAN" = 1 || rm -rf "$W_TMP"
        mkdir -p "$W_TMP"

        # Don't install if already installed
        if test "$WINETRICKS_FORCE" != 1 && winetricks_is_installed $1
        then
            echo "$1 already installed, skipping"
            return 0
        fi

        # Don't install if a conflicting verb is already installed:
        if test "$WINETRICKS_FORCE" != 1 && test "$conflicts" && test -f "$WINEPREFIX/winetricks.log"
        then
            for x in $conflicts
            do
                w_conflicts $1 $x
            done
        fi

        # We'd like to get rid of W_PACKAGE, but for now, just set it as late as possible.
        W_PACKAGE=$1
        w_try load_$cmd $arg
        winetricks_stats_log_command $*

        # User-specific postinstall hook.
        # Source it so the script can call w_download() if needed.
        postfile="$WINETRICKS_POST/$1/$1-postinstall.sh"
        if test -f "$postfile"
        then
            chmod +x "$postfile"
            . "$postfile"
        fi

        # Verify install
        if test "$installed_exe1" || test "$installed_file1"
        then
            if ! winetricks_is_installed $1
            then
                w_die "$1 install completed, but installed file $_W_file_unix not found"
            fi
        fi

        # If the user specified --verify, also run gui tests:
        if test "$WINETRICKS_VERIFY" = 1 && type verify_$cmd 2> /dev/null
        then
            w_try verify_$cmd
        fi

        # Clean up after this verb
        test "$W_OPT_NOCLEAN" = 1 || rm -rf "$W_TMP"
        mkdir -p "$W_TMP"

        # Calling subshell must explicitly propagate error code with exit $?
    ) || exit $?
}


# If you want to check exit status yourself, use w_do_call
w_call()
{
    w_try w_do_call $@
}

