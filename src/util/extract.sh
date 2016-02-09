
w_try_7z()
{
    # $1 - directory to extract to
    # $2 - file to extract
    # Not always installed, use Windows 7-zip as a fallback:
    if test -x "`which 7z 2>/dev/null`"
    then
        w_try 7z x "$2" -o"$1"
    else
        w_warn "Cannot find 7z.  Using Windows 7-zip instead. (You can avoid this by installing 7z, e.g. 'sudo apt-get install p7zip-full' or 'sudo yum install p7zip p7zip-plugins')."
        WINETRICKS_OPT_SHAREDPREFIX=1 w_call 7zip
        # errors out if there is a space between -o and path
        w_try "$WINE" "$W_PROGRAMS_X86_WIN\\7-Zip\\7z.exe" x "`w_pathconv -w $2`" -o"`w_pathconv -w $1`"
    fi
}

w_try_cabextract()
{
    # Not always installed, but shouldn't be fatal unless it's being used
    if test ! -x "`which cabextract 2>/dev/null`"
    then
        w_die "Cannot find cabextract.  Please install it (e.g. 'sudo apt-get install cabextract' or 'sudo yum install cabextract')."
    fi

    w_try cabextract -q "$@"
}


w_try_unrar()
{
    # $1 - zipfile to extract (keeping internal paths, in cwd)

    # Not always installed, use Windows 7-zip as a fallback:
    if test -x "`which unrar 2>/dev/null`"
    then
        w_try unrar x "$@"
    else
        w_warn "Cannot find unrar.  Using Windows 7-zip instead. (You can avoid this by installing unrar, e.g. 'sudo apt-get install unrar' or 'sudo yum install unrar')."
        WINETRICKS_OPT_SHAREDPREFIX=1 w_call 7zip
        w_try "$WINE" "$W_PROGRAMS_X86_WIN\\7-Zip\\7z.exe" x "`w_pathconv -w $1`"
    fi
}

w_try_unzip()
{
    # $1 - directory to extract to
    # $2 - zipfile to extract
    # $3 .. $n - files to extract from the archive

    destdir="$1"
    zipfile="$2"
    shift 2

    # Not always installed, use Windows 7-zip as a fallback:
    if test -x "`which unzip 2>/dev/null`"
    then
        # FreeBSD ships unzip, but it doesn't support self compressed executables
        # If it fails ,fall back to 7-zip:
        unzip -o -q -d"$destdir" "$zipfile" "$@"
        ret=$?
        case $ret in
            0) return ;;
            1|*) w_warn "Unzip failed, trying Windows 7-zip instead." ;;
        esac
    else
        w_warn "Cannot find unzip.  Using Windows 7-zip instead. (You can avoid this by installing unzip, e.g. 'sudo apt-get install unzip' or 'sudo yum install unzip')."
    fi

    WINETRICKS_OPT_SHAREDPREFIX=1 w_call 7zip
    # errors out if there is a space between -o and path
    w_try "$WINE" "$W_PROGRAMS_X86_WIN\\7-Zip\\7z.exe" x "`w_pathconv -w $zipfile`" -o"`w_pathconv -w $destdir`" "$@"
}
