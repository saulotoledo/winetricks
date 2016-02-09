#---- Private Functions ----

winetricks_get_sha1sum_prog() {
    # Mac folks tend to not have sha1sum, but we can make do with openssl
    if [ -x "`which sha1sum 2>/dev/null`" ]
    then
        WINETRICKS_SHA1SUM="sha1sum"
    elif [ -x "`which openssl 2>/dev/null`" ]
    then
        WINETRICKS_SHA1SUM="openssl dgst -sha1"
    else
        w_die "No sha1sum utility available."
    fi
}

winetricks_print_version() {
    # normally done by winetricks_init, but we don't want to set up the WINEPREFIX
    # just to get the winetricks version:
    winetricks_get_sha1sum_prog

    w_get_sha1sum $0
    echo "$WINETRICKS_VERSION - sha1sum: $_W_gotsum"
}

# Run a small wine command for internal use
# Handy place to put small workarounds
winetricks_early_wine()
{
    # The sed works around http://bugs.winehq.org/show_bug.cgi?id=25838
    # which unfortunately got released in wine-1.3.12
    # We would like to use DISPLAY= to prevent virtual desktops from
    # popping up, but that causes autohotkey's tray icon to not show up.
    # We used to use WINEDLLOVERRIDES=mshtml= here to suppress the gecko
    # autoinstall, but that yielded wineprefixes that *never* autoinstalled
    # gecko (winezeug bug 223).
    # The tr removes carriage returns so expanded variables don't have crud on the end
    # The grep works around using new wineprefixes with old wine
    WINEDEBUG=-all "$WINE" "$@" 2> "$W_TMP_EARLY"/early_wine.err.txt | ( sed 's/.*1h.=//' | tr -d '\r' | grep -v "Module not found" || true)
}

winetricks_detect_gui()
{
    if test -x "`which zenity 2>/dev/null`"
    then
        WINETRICKS_GUI=zenity

        WINETRICKS_MENU_HEIGHT=500
        WINETRICKS_MENU_WIDTH=1010
    elif test -x "`which kdialog 2>/dev/null`"
    then
        echo "Zenity not found!  Using kdialog as poor substitute."
        WINETRICKS_GUI=kdialog
    else
        echo "No arguments given, so tried to start GUI, but zenity not found."
        echo "Please install zenity if you want a graphical interface, or "
        echo "run with --help for more options."
        exit 1
    fi
}

# Detect which sudo to use
winetricks_detect_sudo()
{
    WINETRICKS_SUDO=sudo
    if test "$WINETRICKS_GUI" = "none"
    then
        return
    fi
    if test x"$DISPLAY" != x""
    then
        if test -x "`which gksudo 2>/dev/null`"
        then
            WINETRICKS_SUDO=gksudo
        elif test -x "`which kdesudo 2>/dev/null`"
        then
            WINETRICKS_SUDO=kdesudo
        # fall back to the su versions if sudo isn't available (Fedora, etc.):
        elif test -x "`which gksu 2>/dev/null`"
        then
            WINETRICKS_SUDO=gksu
        elif test -x "`which kdesu 2>/dev/null`"
        then
            WINETRICKS_SUDO=kdesu
        fi
    fi
}

winetricks_get_prefix_var()
{
    (
        . "$W_PREFIXES_ROOT/$p/wrapper.cfg"
        # The cryptic sed is there to turn ' into '\''
        eval echo \$ww_$1 | sed "s/'/'\\\''/"
    )
}

