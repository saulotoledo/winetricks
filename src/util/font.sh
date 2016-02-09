w_register_font()
{
    file=$1
    shift
    font=$1

    case "$file" in
    *.TTF|*.ttf) font="$font (TrueType)";;
    esac

    # Kludge: use _r to avoid \r expansion in w_try
    cat > "$W_TMP"/_register-font.reg <<_EOF_
REGEDIT4

[HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Fonts]
"$font"="$file"
_EOF_
    # too verbose
    w_try_regedit "$W_TMP_WIN"\\_register-font.reg
    cp "$W_TMP"/*.reg "$W_TMP_EARLY"/_reg$$.reg

    # Wine also updates the win9x fonts key, so let's do that, too
    cat > "$W_TMP"/_register-font.reg <<_EOF_
REGEDIT4

[HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Fonts]
"$font"="$file"
_EOF_
    w_try_regedit "$W_TMP_WIN"\\_register-font.reg
    cp "$W_TMP"/*.reg "$W_TMP_EARLY"/_reg$$-2.reg
}

w_register_font_replacement()
{
    _W_alias=$1
    shift
    _W_font=$1
    # Kludge: use _r to avoid \r expansion in w_try
    cat > "$W_TMP"/_register-font-replacements.reg <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\Software\Wine\Fonts\Replacements]
"$_W_alias"="$_W_font"
_EOF_
    w_try_regedit "$W_TMP_WIN"\\_register-font-replacements.reg
    unset _W_alias _W_font
}

