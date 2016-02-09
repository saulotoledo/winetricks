
# Has to be set in a few places...
w_set_winver()
{
    w_skip_windows w_set_winver && return
    # FIXME: This should really be done with winecfg, but it has no CLI options.

    # First, delete any lingering version info, otherwise it may conflict:
    (
    "$WINE" reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion" /v SubVersionNumber /f || true
    "$WINE" reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion" /v VersionNumber /f || true
    "$WINE" reg delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion" /v CSDVersion /f || true
    "$WINE" reg delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion" /v CurrentBuildNumber /f || true
    "$WINE" reg delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion" /v CurrentVersion /f || true
    "$WINE" reg delete "HKLM\System\CurrentControlSet\Control\ProductOptions" /v ProductType /f || true
    "$WINE" reg delete "HKLM\System\CurrentControlSet\Control\ServiceCurrent" /v OS /f || true
    "$WINE" reg delete "HKLM\System\CurrentControlSet\Control\Windows" /v CSDVersion /f || true
    "$WINE" reg delete "HKCU\Software\Wine" /v Version /f || true
    "$WINE" reg delete "HKLM\\System\\CurrentControlSet\\Control\\ProductOptions" /v ProductType /f || true
    ) > /dev/null 2>&1

    case $1 in
    win31)
        echo "Setting Windows version to $1"
        cat > "$W_TMP"/set-winver.reg <<_EOF_
REGEDIT4

[HKEY_USERS\S-1-5-4\Software\Wine]
"Version"="win31"

_EOF_

        w_try_regedit "$W_TMP_WIN"\\set-winver.reg
        return
        ;;
    win95)
        # This key is only used for win 95/98:

        echo "Setting Windows version to $1"
        cat > "$W_TMP"/set-winver.reg <<_EOF_
REGEDIT4

[HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion]
"ProductName"="Microsoft Windows 95"
"SubVersionNumber"=""
"VersionNumber"="4.0.950"

_EOF_
        w_try_regedit "$W_TMP_WIN"\\set-winver.reg
        return
        ;;
    win98)
        # This key is only used for win 95/98:

        echo "Setting Windows version to $1"
        cat > "$W_TMP"/set-winver.reg <<_EOF_
REGEDIT4

[HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion]
"ProductName"="Microsoft Windows 98"
"SubVersionNumber"=" A "
"VersionNumber"="4.10.2222"

_EOF_
        w_try_regedit "$W_TMP_WIN"\\set-winver.reg
        return
        ;;
    nt40)
        # Similar to modern version, but sets two extra keys:

        echo "Setting Windows version to $1"
        cat > "$W_TMP"/set-winver.reg <<_EOF_
REGEDIT4

[HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion]
"CSDVersion"="Service Pack 6a"
"CurrentBuildNumber"="1381"
"CurrentVersion"="4.0"

[HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\ProductOptions]
"ProductType"="WinNT"

[HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\ServiceCurrent]
"OS"="Windows_NT"

[HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Windows]
"CSDVersion"=dword:00000600

_EOF_
        w_try_regedit "$W_TMP_WIN"\\set-winver.reg
        return
        ;;
    win2k)
        csdversion="Service Pack 4"
        currentbuildnumber="2195"
        currentversion="5.0"
        csdversion_hex=dword:00000400
        ;;
    winxp)
        csdversion="Service Pack 3"
        currentbuildnumber="2600"
        currentversion="5.1"
        csdversion_hex=dword:00000300
        ;;
    win2k3)
        csdversion="Service Pack 2"
        currentbuildnumber="3790"
        currentversion="5.2"
        csdversion_hex=dword:00000200
        "$WINE" reg add "HKLM\\System\\CurrentControlSet\\Control\\ProductOptions" /v ProductType /d "ServerNT" /f
        ;;
    vista)
        csdversion="Service Pack 2"
        currentbuildnumber="6002"
        currentversion="6.0"
        csdversion_hex=dword:00000200
        "$WINE" reg add "HKLM\\System\\CurrentControlSet\\Control\\ProductOptions" /v ProductType /d "WinNT" /f
        ;;
    win7)
        csdversion="Service Pack 1"
        currentbuildnumber="7601"
        currentversion="6.1"
        csdversion_hex=dword:00000100
        "$WINE" reg add "HKLM\\System\\CurrentControlSet\\Control\\ProductOptions" /v ProductType /d "WinNT" /f
        ;;
    *)
        w_die "Invalid Windows version given."
        ;;
    esac

    echo "Setting Windows version to $1"
    cat > "$W_TMP"/set-winver.reg <<_EOF_
REGEDIT4

[HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion]
"CSDVersion"="$csdversion"
"CurrentBuildNumber"="$currentbuildnumber"
"CurrentVersion"="$currentversion"

[HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Windows]
"CSDVersion"=$csdversion_hex

_EOF_
    w_try_regedit "$W_TMP_WIN"\\set-winver.reg
}

w_unset_winver()
{
    w_set_winver winxp
}

# Present app $1 with the Windows personality $2
w_set_app_winver()
{
    w_skip_windows w_set_app_winver && return

    _W_app="$1"
    _W_version="$2"
    echo "Setting $_W_app to $_W_version mode"
    (
    echo REGEDIT4
    echo ""
    echo "[HKEY_CURRENT_USER\\Software\\Wine\\AppDefaults\\$_W_app]"
    echo "\"Version\"=\"$_W_version\""
    ) > "$W_TMP"/set-winver.reg

    w_try_regedit "$W_TMP_WIN"\\set-winver.reg
    rm "$W_TMP"/set-winver.reg
    unset _W_app
}

# Usage: w_wine_version OP VALUE
# All the integer comparison operators of 'test' are supported, since 'test' does the work.
# Example:
#  if w_wine_version -gt 1.3.2
#  then
#      ...
#  fi
w_wine_version()
{
    # Parse major/minor/micro/nano fields of VALUE.  Ignore nano.  Abort if major is not 1.
    case $2 in
    0*|1.0|1.0.*) w_die "bug: $2 is before 1.1, we don't bother with bugs fixed that long ago" ;;
    1.1.*) _W_minor=1; _W_micro=`echo $2 | sed 's/.*\.//'`;;
    1.2) _W_minor=2; _W_micro=0;;
    1.2.*) _W_minor=2; _W_micro=`echo $2 | sed 's/.*\.//'`;;
    1.3.*) _W_minor=3; _W_micro=`echo $2 | sed 's/.*\.//'`;;
    1.4) _W_minor=4; _W_micro=0;;
    1.4.*) _W_minor=4; _W_micro=`echo $2 | sed 's/.*\.//'`;;
    1.5.*) _W_minor=5; _W_micro=`echo $2 | sed 's/.*\.//'`;;
    1.6|1.6-rc*) _W_minor=6; _W_micro=0;;
    1.6.*) _W_minor=6; _W_micro=`echo $2 | sed 's/.*\.//'`;;
    1.7.*) _W_minor=7; _W_micro=`echo $2 | sed 's/.*\.//'`;;
    1.8.*) _W_minor=8; _W_micro=`echo $2 | sed 's/.*\.//'`;;
    *) w_die "bug: unrecognized version $2";;
    esac

    # Comparing current wine version 1.$WINETRICKS_WINE_MINOR.$WINETRICKS_WINE_MICRO against 1.$_W_minor.$_W_micro
    if test $WINETRICKS_WINE_MINOR = $_W_minor
    then
        test $WINETRICKS_WINE_MICRO $1 $_W_micro || return 1
    else
        test $WINETRICKS_WINE_MINOR $1 $_W_minor || return 1
    fi
}

# Built-in self test for w_wine_version
#echo Verify that version 1.3.4 is equal to itself
#WINETRICKS_WINE_MINOR=3 WINETRICKS_WINE_MICRO=4 w_wine_version -eq 1.3.4 || w_die "fail test case wine-1.3.4 = 1.3.4"
#echo Verify that version 1.3.4 is greater than 1.2
#WINETRICKS_WINE_MINOR=3 WINETRICKS_WINE_MICRO=4 w_wine_version -gt 1.2 || w_die "fail test case wine-1.3.4 > wine-1.2"
#echo Verify that version 1.6 is greater than 1.2
#WINETRICKS_WINE_MINOR=6 WINETRICKS_WINE_MICRO=0 w_wine_version -gt 1.2 || w_die "fail test case wine-1.6 > wine-1.2"

# Usage: w_wine_version_in range ...
# True if wine version in any of the given ranges
# 'range' can be
#    val1,   (for >= val1)
#    ,val2   (for <= val2)
#    val1,val2 (for >= val1 && <= val2)
w_wine_version_in()
{
   for _W_range
   do
     _W_val1=`echo $_W_range | sed 's/,.*//'`
     _W_val2=`echo $_W_range | sed 's/.*,//'`

     # If in this range, return true
     case $_W_range in
     ,*)                                  w_wine_version   -le "$_W_val2" && unset _W_range _W_val1 _W_val2 && return 0;;
     *,) w_wine_version -ge "$_W_val1"                                    && unset _W_range _W_val1 _W_val2 && return 0;;
     *)  w_wine_version -ge "$_W_val1" && w_wine_version   -le "$_W_val2" && unset _W_range _W_val1 _W_val2 && return 0;;
     esac
   done
   unset _W_range _W_val1 _W_val2
   return 1
}

# Built-in self test for w_wine_version_in
#w_wine_version_in_test()
#{
#    WINETRICKS_WINE_MINOR=$1 WINETRICKS_WINE_MICRO=$2 w_wine_version_in $3 $4 $5 $6 || w_die "fail test case wine-1.$1.$2 in $3 $4 $5 $6"
#}
#w_wine_version_not_in_test()
#{
#    WINETRICKS_WINE_MINOR=$1 WINETRICKS_WINE_MICRO=$2 w_wine_version_in $3 $4 $5 $6 && w_die "fail test case wine-1.$1.$2 in $3 $4 $5 $6"
#}
#echo Verify that version 1.2.0 is in the range 1.2,
#w_wine_version_in_test 2 0  1.2,
#echo Verify that version 1.3.4 is in the range 1.2,
#w_wine_version_in_test 3 4  1.2,
#echo Verify that version 1.3 is not in the range ,1.2
#w_wine_version_not_in_test 3 0  ,1.2
#echo Verify that version 1.6-rc1 is in the range 1.2,
#w_wine_version_in_test 6 0  1.2,
#echo test passed

