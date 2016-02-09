# Download a file
# Usage: w_download_to packagename url [sha1sum [filename [cookie jar]]]
# Caches downloads in winetrickscache/$packagename
w_download_to()
{
    _W_packagename="$1"
    _W_url="$2"
    _W_sum="$3"
    _W_file="$4"
    _W_cookiejar="$5"

    case $_W_packagename in
    .) w_die "bug: please do not download packages to top of cache" ;;
    esac

    if echo "$_W_url" | grep ' '
    then
        w_die "bug: please use %20 instead of literal spaces in urls, curl rejects spaces, and they make life harder for linkcheck.sh"
    fi
    if [ "$_W_file"x = ""x ]
    then
        _W_file=`basename "$_W_url"`
    fi
    _W_cache="$W_CACHE/$_W_packagename"

    if test ! -d "$_W_cache"
    then
        w_try mkdir -p "$_W_cache"
    fi

    # Try download twice
    checksum_ok=""
    tries=0
    while test $tries -lt 2
    do
        tries=`expr $tries + 1`

        if test -s "$_W_cache/$_W_file"
        then
            if test "$3"
            then
                if test $tries = 1
                then
                    # The cache was full.  If the file is larger than 500MB,
                    # don't checksum it, that just annoys the user.
                    if test `du -k "$_W_cache/$_W_file" | cut -f1` -gt 500000
                    then
                        checksum_ok=1
                        break
                    fi
                fi
                # If checksum matches, declare success and exit loop
                w_get_sha1sum "$_W_cache/$_W_file"
                if [ "$_W_gotsum"x = "$3"x ]
                then
                    checksum_ok=1
                    break
                fi
                if test ! "$WINETRICKS_CONTINUE_DOWNLOAD"
                then
                    w_warn "Checksum for $_W_cache/$_W_file did not match, retrying download"
                    mv -f "$_W_cache/$_W_file" "$_W_cache/$_W_file".bak
                fi
            else
                # file exists, no checksum known, declare success and exit loop
                break
            fi
        elif test -f "$_W_cache/$_W_file"
        then
            # zero length file, just delete before retrying
            rm "$_W_cache/$_W_file"
        fi

        _W_dl_olddir=`pwd`
        cd "$_W_cache"
        # Mac folks tend to have curl rather than wget
        # On Mac, 'which' doesn't return good exit status
        # Need to jam in --header "Accept-Encoding: gzip,deflate" else
        # redhat.com decompresses liberation-fonts.tar.gz!
        # Note: this causes other sites to compress downloads, hence
        # the kludge further down.  See http://code.google.com/p/winezeug/issues/detail?id=77
        echo Downloading $_W_url to $_W_cache

        # For sites that prefer mozilla in the useragent, set W_BROWSERAGENT=1
        case "$W_BROWSERAGENT" in
        1) _W_agent="Mozilla/5.0 (compatible; Konqueror/2.1.1; X11)" ;;
        *) _W_agent= ;;
        esac

        if [ -x "`which aria2c 2>/dev/null`" ]
        then
            # Basic aria2c support.
            aria2c -c -d "$_W_cache" -o "$_W_file" "$_W_url"
        elif [ -x "`which wget 2>/dev/null`" ]
        then
           # Use -nd to insulate ourselves from people who set -x in WGETRC
           # [*] --retry-connrefused works around the broken sf.net mirroring
           # system when downloading corefonts
           # [*] --read-timeout is useful on the adobe server that doesn't
           # close the connection unless you tell it to (control-C or closing
           # the socket)
           winetricks_wget_progress \
               -O "$_W_file" -nd \
               -c --read-timeout=300 --retry-connrefused \
               --header "Accept-Encoding: gzip,deflate" \
               ${_W_cookiejar:+--load-cookies "$_W_cookiejar"} \
               ${_W_agent:+--user-agent="$_W_agent"} \
               "$_W_url"
        elif [ -x "`which curl 2>/dev/null`" ]
        then
           # curl doesn't get filename from the location given by the server!
           # fortunately, we know it
           curl -L -o "$_W_file" -C - \
               --header "Accept-Encoding: gzip,deflate" \
               ${_W_cookiejar:+--cookie "$_W_cookiejar"} \
               ${_W_agent:+--user-agent "$_W_agent"} \
               "$_W_url"
        else
            w_die "Please install wget or aria2c (or, if those aren't available, curl)"
        fi
        if test $? != 0
        then
            test -f "$_W_file" && rm "$_W_file"
            w_die "Downloading $_W_url failed"
        fi
        # Need to decompress .exe's that are compressed, else cygwin fails
        # Also affects ttf files on github
        _W_filetype=`which file 2>/dev/null`
        case $_W_filetype-$_W_file in
        /*-*.exe|/*-*.ttf|/*-*.zip)
            case `file "$_W_file"` in
            *:*gzip*) mv "$_W_file" "$_W_file.gz"; gunzip < "$_W_file.gz" > "$_W_file";;
            esac
        esac

        # On cygwin, .exe's must be marked +x
        case "$_W_file" in
        *.exe) chmod +x "$_W_file" ;;
        esac

        cd "$_W_dl_olddir"
        unset _W_dl_olddir
    done

    if test "$3" && test ! "$checksum_ok"
    then
        w_verify_sha1sum $3  "$_W_cache/$_W_file"
    fi
}

# Download a file
# Usage: w_download url [sha1sum [filename [cookie jar]]]
# Caches downloads in winetrickscache/$W_PACKAGE
w_download()
{
    w_download_to $W_PACKAGE "$@"
}

# Download one or more files via bittorrent
# Usage: w_download_torrent [foo.torrent]
# Caches downloads in $W_CACHE/$W_PACKAGE, torrent files are assumed to be there
# If no foo.torrent is given, will add ALL .torrent files in $W_CACHE/$W_PACKAGE
w_download_torrent()
{
    # FIXME: figure out how to extract the filename from the .torrent file
    # so callers don't need to check if the files are already downloaded.

    w_call utorrent

    UT_WINPATH="$W_CACHE_WIN\\$W_PACKAGE"
    cd "$W_CACHE/$W_PACKAGE"

    if [ "$2"x != ""x ] # foo.torrent parameter supplied
    then
        w_try "$WINE" utorrent "/DIRECTORY" "$UT_WINPATH" "$UT_WINPATH\\$2" &
    else # grab all torrents
        for torrent in `ls *.torrent`
        do
            w_try "$WINE" utorrent "/DIRECTORY" "$UT_WINPATH" "$UT_WINPATH\\$torrent" &
        done
    fi

    # Start uTorrent, have it wait until all downloads are finished
    w_ahk_do "
        SetTitleMatchMode, 2
        winwait, Torrent
        Loop
        {
            sleep 6000
            ifwinexist, Torrent, default
            {
                ;should uTorrent be the default torrent app?
                controlclick, Button1, Torrent, default  ; yes
                continue
            }
            ifwinexist, Torrent, already
            {
                ;torrent already registered, fine
                controlclick, Button1, Torrent, default  ; yes
                continue
            }
            ifwinexist, Torrent, Bandwidth
            {
                ;Cancels bandwidth test on first run of uTorrent
                controlclick, Button5, Torrent, Bandwidth
                continue
            }
            ifwinexist, Torrent, version
            {
                ;Decline upgrade to newer version
                controlclick, Button3, Torrent, version
                controlclick, Button2, Torrent, version
                continue
            }
            break
        }
        ;Sets parameter to close uTorrent once all downloads are complete
        winactivate, Torrent 2.0
        send !o
        send a{Down}{Enter}
        winwaitclose, Torrent 2.0
    "
}

w_download_manual_to()
{
    _W_packagename="$1"
    _W_url="$2"
    _W_file="$3"
    _W_sha1sum="$4"

    case "$media" in
    "download")
        w_info "FAIL: bug: media type is download, but w_download_manual was called.  Programmer, please change verb's media type to manual_download."
        ;;
    esac

    case $LANG in
    da*) _W_dlmsg="Hent venligst filen $_W_file fra $_W_url og placér den i $W_CACHE/$_W_packagename, kør derefter dette skript.";;
    de*) _W_dlmsg="Bitte laden Sie $_W_file von $_W_url runter, stellen Sie's in $W_CACHE/$_W_packagename, dann wiederholen Sie dieses Kommando.";;
    pl*) _W_dlmsg="Proszę pobrać plik $_W_file z $_W_url, następnie umieścić go w $W_CACHE/$_W_packagename, a na końcu uruchomić ponownie ten skrypt.";;
    uk*) _W_dlmsg="Будь ласка, звантажте $_W_file з $_W_url, розташуйте в $W_CACHE/$_W_packagename, потім запустіть скрипт знову.";;
    zh_CN*) _W_dlmsg="请从 $_W_url 下载 $_W_file，并置放于 $W_CACHE/$_W_packagename, 然后重新运行 winetricks.";;
    zh_TW*|zh_HK*) _W_dlmsg="請從 $_W_url 下載 $_W_file，并置放於 $W_CACHE/$_W_packagename, 然后重新執行 winetricks.";;
    *) _W_dlmsg="Please download $_W_file from $_W_url, place it in $W_CACHE/$_W_packagename, then re-run this script.";;
    esac

    if ! test -f "$W_CACHE/$_W_packagename/$_W_file"
    then
        mkdir -p "$W_CACHE/$_W_packagename"
        w_open_folder "$W_CACHE/$_W_packagename"
        w_open_webpage "$_W_url"
        sleep 3   # give some time for browser to open
        w_die "$_W_dlmsg"
        # FIXME: wait in loop until file is finished?
    fi
    # FIXME: verify $sha1sum of $file
    unset _W_url _W_file _W_sha1sum _W_dlmsg
}

w_download_manual()
{
    w_download_manual_to $W_PACKAGE "$@"
}

