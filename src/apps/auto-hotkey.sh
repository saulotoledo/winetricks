
w_ahk_do()
{
    if ! test -f "$W_CACHE/ahk/AutoHotkey.exe"
    then
        W_BROWSERAGENT=1 \
        w_download_to ahk http://www.autohotkey.com/download/AutoHotkey104805.zip b3981b13fbc45823131f69d125992d6330212f27
        w_try_unzip "$W_CACHE/ahk" "$W_CACHE/ahk/AutoHotkey104805.zip" AutoHotkey.exe AU3_Spy.exe
        chmod +x "$W_CACHE/ahk/AutoHotkey.exe"
    fi

    _W_CR=`printf \\\\r`
    cat <<_EOF_ | sed "s/\$/$_W_CR/" > "$W_TMP"/tmp.ahk
w_opt_unattended = ${W_OPT_UNATTENDED:-0}
$@
_EOF_
    w_try "$WINE" "$W_CACHE_WIN\\ahk\\AutoHotkey.exe" "$W_TMP_WIN"\\tmp.ahk
    unset _W_CR
}

