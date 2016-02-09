
w_try_msiexec64()
{
    if test "$W_ARCH" != "win64"
    then
        w_die "bug: 64-bit msiexec called from a $W_ARCH prefix."
    fi

    w_try "$WINE" start /wait "$W_SYSTEM64_DLLS_WIN32/msiexec.exe" $W_UNATTENDED_SLASH_Q "$@"
}

w_try_regedit()
{
    # on windows, doesn't work without cmd /c
    case "$OS" in
    "Windows_NT") cmdc="cmd /c";;
    *) unset cmdc ;;
    esac

    w_try winetricks_early_wine $cmdc regedit $W_UNATTENDED_SLASH_S "$@"
}

w_try_regsvr()
{
    w_try "$WINE" regsvr32 $W_UNATTENDED_SLASH_S $@
}

w_read_key()
{
    if test ! "$W_OPT_UNATTENDED"
    then
        W_KEY=dummy_to_make_autohotkey_happy
        return 0
    fi

    mkdir -p "$W_CACHE/$W_PACKAGE"

    # backwards compatible location
    # Auth doesn't belong in cache, since restoring it requires user input
    _W_keyfile="$W_CACHE/$W_PACKAGE/key.txt"
    if ! test -f "$_W_keyfile"
    then
        _W_keyfile="$WINETRICKS_AUTH/$W_PACKAGE/key.txt"
    fi
    if ! test -f "$_W_keyfile"
    then
        # read key from user
        case $LANG in
        da*) _W_keymsg="Angiv venligst registrerings-nøglen for pakken '$_PACKAGE'"
            _W_nokeymsg="Ingen nøgle angivet"
            ;;
        de*) _W_keymsg="Bitte einen Key für Paket '$W_PACKAGE' eingeben"
            _W_nokeymsg="Keinen Key eingegeben?"
            ;;
        pl*) _W_keymsg="Proszę podać klucz dla programu '$W_PACKAGE'"
            _W_nokeymsg="Nie podano klucza"
            ;;
        uk*) _W_keymsg="Будь ласка, введіть ключ для додатка '$W_PACKAGE'"
            _W_nokeymsg="Ключ не надано"
            ;;
        zh_CN*)  _W_keymsg="按任意键为 '$W_PACKAGE'"
            _W_nokeymsg="No key given"
            ;;
        zh_TW*|zh_HK*)  _W_keymsg="按任意鍵為 '$W_PACKAGE'"
            _W_nokeymsg="No key given"
            ;;
        *)  _W_keymsg="Please enter the key for app '$W_PACKAGE'"
            _W_nokeymsg="No key given"
            ;;
        esac
        case $WINETRICKS_GUI in
        *zenity) W_KEY=`zenity --entry --text "$_W_keymsg"` ;;
        *kdialog) W_KEY=`kdialog --inputbox "$_W_keymsg"` ;;
        *xmessage) w_die "sorry, can't read key from gui with xmessage" ;;
        none) printf %s "$_W_keymsg": ; read W_KEY ;;
        esac
        if test "$W_KEY" = ""
        then
            w_die "$_W_nokeymsg"
        fi
        echo "$W_KEY" > "$_W_keyfile"
    fi
    W_RAW_KEY=`cat "$_W_keyfile"`
    W_KEY=`echo $W_RAW_KEY | tr -d '[:blank:][=-=]'`
    unset _W_keyfile _W_keymsg _W_nokeymsg
}


w_dotnet_verify()
{
    case $1 in
        dotnet11) version="1.1" ;;
        dotnet11sp1) version="1.1 SP1" ;;
        dotnet20) version="2.0" ;;
        dotnet20sp1) version="2.0 SP1" ;;
        dotnet20sp2) version="2.0 SP2" ;;
        dotnet30) version="3.0" ;;
        dotnet30sp1) version="3.0 SP1" ;;
        dotnet35) version="3.5" ;;
        dotnet35sp1) version="3.5 SP1" ;;
        dotnet40) version="4 Client" ;;
        dotnet45) version="4.5" ;;
        dotnet452) version="4.5.2" ;;
        *) echo error ; exit 1 ;;
    esac
            w_call dotnet_verifier
            # FIXME: The logfile may be useful somewhere (or at least print the location)
            w_ahk_do "
                SetTitleMatchMode, 2
                ; FIXME; this only works the first time? Check if it's already verified somehow..
                run, netfx_setupverifier.exe /q:a /c:"setupverifier2.exe"
                winwait, Verification Utility
                ControlClick, Button1
                Control, ChooseString, NET Framework $version, ComboBox1
                ControlClick, Button1 ; Verify
                loop, 60
                {
                    sleep 1000
                    process, exist, setupverifier2.exe
                    dn_pid=%ErrorLevel%
                    if dn_pid = 0
                    {
                        break
                    }
                    ifWinExist, Verification Utility, Product verification failed
                    {
                        process, close, setupverifier2.exe
                        exit 1
                    }
                    ifWinExist, Verification Utility, Product verification succeeded
                    {
                        process, close, setupverifier2.exe
                        break
                    }
                }
            "
            dn_status=$?
}

