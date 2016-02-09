
#----------------------------------------------------------------

# Generic GOG.com installer
# Usage: game_id game_title [other_files,size [reader_control [run_command [download_id [install_dir [installer_size_and_sha1]]]]]]
# game_id
#     Used for main installer name and download url.
# game_title
#     Used for AutoHotKey and installation path in bat script.
# other_files
#     Extra installer files, in one string, space-separated.
# reader_control
#     If set, the control id of the configuration panel checkbox controling
#     Adobe Reader installation.
#     Some games don't have it, some games do with different ids.
# run_command
#     Used for bat script, relative to installation path.
# download_id
#     For games which download url doesn't match their game_id
# install_dir
#     If different from game_title
# installer_size_and_sha1
#     exe file SHA1.
winetricks_load_gog()
{
    game_id="$1"
    game_title="$2"
    other_files="$3"
    reader_control="$4"
    run_command="$5"
    download_id="$6"
    install_dir="$7"
    installer_size_and_sha1="$8"

    if [ "$download_id"x = ""x ]
    then
        download_id="$game_id"
    fi
    if [ "$install_dir"x = ""x ]
    then
        install_dir="$game_title"
    fi

    installer_path="$W_CACHE/$W_PACKAGE"
    mkdir -p "$installer_path"
    installer="setup_$game_id.exe"

    if test "$installer_size_and_sha1"x = ""x
    then
        files="$installer $other_files"
    else
        files="$installer,$installer_size_and_sha1 $other_files"
    fi

    file_id=0
    for file_and_size_and_sha1 in $files
    do
        case "$file_and_size_and_sha1" in
        *,*,*)
            sha1sum=`echo $file_and_size_and_sha1 | sed "s/.*,//"`
            minsize=`echo $file_and_size_and_sha1 | sed 's/[^,]*,\([^,]*\),.*/\1/'`
            file=`echo $file_and_size_and_sha1 | sed 's/,.*//'`
            ;;
        *,*)
            sha1sum=""
            minsize=`echo $file_and_size_and_sha1 | sed 's/.*,//'`
            file=`echo $file_and_size_and_sha1 | sed 's/,.*//'`
            ;;
        *)
            sha1sum=""
            minsize=1
            file=$file_and_size_and_sha1
            ;;
        esac
        file_path="$installer_path/$file"
        if ! test -s "$file_path" || test `stat -Lc%s "$file_path"` -lt $minsize
        then
            # FIXME: bring back automated download
            w_info "You have to be logged in to gog, and you have to own the game, for the following URL to work.  Otherwise it gets a 404."
            w_download_manual "https://www.gog.com/en/download/game/$download_id/$file_id" "$file"
            check_sha1=1
            filesize=`stat -Lc%s "$file_path"`
            if test $minsize -gt 1 && test $filesize -ne $minsize
            then
                check_sha1=""
                w_warn "Expected file size $minsize, please report new size $filesize."
            fi
            if test "$check_sha1" != "" && test "$sha1sum"x != ""x
            then
                w_verify_sha1sum "$sha1sum" "$file_path"
            fi
        fi
        file_id=`expr $file_id + 1`
    done

    cd "$installer_path"
    w_ahk_do "
        run $installer
        WinWait, Setup - $game_title, Start installation
        ControlGet, checkbox_state, Checked,, TCheckBox1 ; EULA
        if (checkbox_state != 1) {
            ControlClick, TCheckBox1
        }
        if (\"$reader_control\") {
            ControlClick, TMCoPShadowButton1 ; Options
            Loop, 10
            {
                ControlGet, visible, Visible,, $reader_control
                if (visible)
                {
                    break
                }
                Sleep, 1000
            }
            ControlGet, checkbox_state, Checked,, $reader_control ; Unckeck Adobe/Foxit Reader
            if (checkbox_state != 0) {
                ControlClick, $reader_control
            }
        }
        ControlClick, TMCoPShadowButton2 ; Start Installation
        WinWait, Setup - $game_title, Exit Installer
        ControlClick, TMCoPShadowButton1 ; Exit Installer
        "

    if test "$run_command"x != ""x
    then
        w_declare_exe "$W_PROGRAMS_X86_WIN\\GOG.com\\$install_dir" "$run_command"
    fi
}

