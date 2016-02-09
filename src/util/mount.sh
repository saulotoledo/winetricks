
# Usage: w_mount "volume name" [filename-to-check [discnum]]
# Some games have two volumes with identical volume names.
# For these, please specify discnum 1 for first disc, discnum 2 for 2nd, etc.,
# else caching can't work.
# FIXME: should take mount option 'unhide' for poorly mastered discs
w_mount()
{
    if test "$3"
    then
        WINETRICKS_IMG="$W_CACHE/$W_PACKAGE/$1-$3.iso"
    else
        WINETRICKS_IMG="$W_CACHE/$W_PACKAGE/$1.iso"
    fi
    mkdir -p "$W_CACHE/$W_PACKAGE"

    if test -f "$WINETRICKS_IMG"
    then
        winetricks_mount_cached_iso
    else
        if test "$WINETRICKS_OPT_KEEPISOS" = 0 || test "$2"
        then
            while true
            do
                winetricks_mount_real_volume "$1"
                if test "$2" = "" || test -f "$W_ISO_MOUNT_ROOT/$2"
                then
                    break
                else
                    w_warn "Wrong disc inserted, $2 not found"
                fi
            done
        fi

        case "$WINETRICKS_OPT_KEEPISOS" in
        1)
            winetricks_cache_iso "$1"
            winetricks_mount_cached_iso
            ;;
        esac
    fi
}

w_umount()
{
    if test "$WINE" = ""
    then
        # Windows
        winetricks_load_vcdmount
        cd "$VCD_DIR"
        w_try vcdmount.exe /u
    else
        echo "Running $WINETRICKS_SUDO umount $W_ISO_MOUNT_ROOT"
        case "$WINETRICKS_SUDO" in
        gksudo)
          # -l lazy unmount in case executable still running
          $WINETRICKS_SUDO "umount -l $W_ISO_MOUNT_ROOT"
          w_try $WINETRICKS_SUDO "rm -rf $W_ISO_MOUNT_ROOT"
          ;;
        *)
          $WINETRICKS_SUDO umount -l $W_ISO_MOUNT_ROOT
          w_try $WINETRICKS_SUDO rm -rf $W_ISO_MOUNT_ROOT
          ;;
        esac
        "$WINE" eject ${W_ISO_MOUNT_LETTER}:
        rm -f "$WINEPREFIX"/dosdevices/${W_ISO_MOUNT_LETTER}:
        rm -f "$WINEPREFIX"/dosdevices/${W_ISO_MOUNT_LETTER}::
    fi
}

