
# Turn off news, overlays, and friend interaction in steam
# Run from inside c:\Program Files\Steam
w_steam_safemode()
{
    cat > "$W_TMP/steamconfig.pl" <<"_EOF_"
#!/usr/bin/env perl
# Parse steam's localconfig.vcf, add settings to it, and write it out again
# The file is a recursive dictionary
#
# FILE :== CONTAINER
#
# VALUE :== "name" "value" NEWLINE
#
# CONTAINER :== "name" NEWLINE "{" NEWLINE ( VALUE | CONTAINER ) * "}" NEWLINE
#
# We load it into a recursive hash.

use strict;
use warnings;

sub read_into_container{
    my( $pcontainer ) = @_;

    $_ = <FILE> || w_die "Can't read first line of container";
    /{/ || w_die "First line of container was not {";
    while (<FILE>) {
       chomp;
       if (/"([^"]*)"\s*"([^"]*)"$/) {
           ${$pcontainer}{$1} = $2;
       } elsif (/"([^"]*)"$/) {
           my( %newcon, $name );
           $name = $1;
           read_into_container(\%newcon);
           ${$pcontainer}{$name} = \%newcon;
        } elsif (/}/) {
           return;
        } else {
           w_die "huh?";
        }
    }
}

sub dump_container{
    my( $pcontainer, $indent ) = @_;
    foreach (sort(keys(%{$pcontainer}))) {
        my( $val ) = ${$pcontainer}{$_};
        if (ref $val eq 'HASH') {
            print "${indent}\"$_\"\n";
            print "${indent}{\n";
            dump_container($val, "$indent\t");
            print "${indent}}\n";
        } else {
            print "${indent}\"${_}\"\t\t\"$val\"\n";
        }
    }
}

# Disable anything unsafe or annoying
sub disable_notifications{
    my( $pcontainer ) = @_;
    ${$pcontainer}{"friends"}{"PersonaStateDesired"} = "1";
    ${$pcontainer}{"friends"}{"Notifications_ShowIngame"} = "0";
    ${$pcontainer}{"friends"}{"Sounds_PlayIngame"} = "0";
    ${$pcontainer}{"friends"}{"Notifications_ShowOnline"} = "0";
    ${$pcontainer}{"friends"}{"Sounds_PlayOnline"} = "0";
    ${$pcontainer}{"friends"}{"Notifications_ShowMessage"} = "0";
    ${$pcontainer}{"friends"}{"Sounds_PlayMessage"} = "0";
    ${$pcontainer}{"friends"}{"AutoSignIntoFriends"} = "0";
    ${$pcontainer}{"News"}{"NotifyAvailableGames"} = "0";
    ${$pcontainer}{"system"}{"EnableGameOverlay"} = "0";
}

# Read the file
my(%top);
open FILE, $ARGV[0] || w_die "can't open ".$ARGV[0];
my($line);
$line = <FILE> || w_die "Could not read first line from ".$ARGV[0];
$line =~ /"UserLocalConfigStore"/ || w_die "this is not a localconfig.vdf file";
read_into_container(\%top);

# Modify it
disable_notifications(\%top);

# Write modified file
print "\"UserLocalConfigStore\"\n";
print "{\n";
dump_container(\%top, "\t");
print "}\n";
_EOF_

for file in userdata/*/config/localconfig.vdf
do
    cp "$file" "$file.old"
    perl "$W_TMP"/steamconfig.pl "$file.old" > "$file"
done
}

# Reads steam username and password from environment, cache, or user
# If had to ask user, cache answer.
w_steam_getid()
{
    #TODO: Translate
    _W_steamidmsg="Please enter your Steam login ID (not email)"
    _W_steampasswordmsg="Please enter your Steam password"

    if test ! "$W_STEAM_ID"
    then
        if test -f "$W_CACHE"/steam_userid.txt
        then
            W_STEAM_ID=`cat "$W_CACHE"/steam_userid.txt`
        else
            W_STEAM_ID=`w_question "$_W_steamidmsg"`
            echo "$W_STEAM_ID" > "$W_CACHE"/steam_userid.txt
            chmod 600 "$W_CACHE"/steam_userid.txt
        fi
    fi
    if test ! "$W_STEAM_PASSWORD"
    then
        if test -f "$W_CACHE"/steam_password.txt
        then
            W_STEAM_PASSWORD=`cat "$W_CACHE"/steam_password.txt`
        else
            W_STEAM_PASSWORD=`w_question "$_W_steampasswordmsg"`
            echo "$W_STEAM_PASSWORD" > "$W_CACHE"/steam_password.txt
            chmod 600 "$W_CACHE"/steam_password.txt
        fi
    fi
}

# Usage:
# w_steam_install_game steamidnum windowtitle
w_steam_install_game()
{
    _W_steamid=$1
    _W_steamtitle="$2"

    w_steam_getid

    # Install the steam runtime
    WINETRICKS_OPT_SHAREDPREFIX=1 w_call steam

    # Steam puts up a bunch of windows.  Here's the sequence:
    # "Steam - Updating" - wait for it to close.  May appear twice in a row.
    # "Steam - Login" - wait for it to close (credentials already given on cmdline)
    # "Steam" (small window) - connecting, wait for it to close
    # "Steam" (large window) - the main window
    # "Steam - Updates News" - close it forcefully
    # "Install - $title" - send enter, click a couple checkboxes, send enter again
    # "Updating $title" - small download progress dialog
    # "Steam - Ready" game install done.  (Only comes up if main window not up.)

    cd "$W_PROGRAMS_X86_UNIX/Steam"
    w_ahk_do "
        SetTitleMatchMode 2
        SetWinDelay 500
        ; Run steam once until it finishes its initial update.
        ; For me, this exits at 26%.
        run steam.exe -applaunch $_W_steamid -login $W_STEAM_ID $W_STEAM_PASSWORD
        Loop
        {
            ifWinExist, Steam - Updating
            {
                winwaitclose, Steam
                process close, Steam.exe
                sleep 1000
                ; Run a second time; let it finish updating, then kill it.
                run steam.exe
                winwait Steam - Updating
                winwaitclose
                process close, Steam.exe
                ; Run a third time, have it log in, wait until it has finished connecting
                run steam.exe -applaunch $_W_steamid -login $W_STEAM_ID $W_STEAM_PASSWORD
            }
            ifWinExist, Steam Login
            {
                break
            }
            sleep 500
        }
        ; wait for login window to close
        winwaitclose

        winwait Steam  ; wait for small <<connecting>> window
        winwaitclose
    "

if [ "$STEAM_DVD" = "TRUE" ]
then
    w_ahk_do "
        ; Run a fourth time, have it install the app.
        run steam.exe -install ${W_ISO_MOUNT_LETTER}:\\
    "
else
    w_ahk_do "
        ; Run a fourth time, have it install the app.
        run steam.exe -applaunch $_W_steamid
    "
fi

    w_ahk_do "
        winwait Install - $_W_steamtitle
        if ( w_opt_unattended > 0 ) {
            send {enter}          ; next (for 1st of 3 pages of install dialog)
            sleep 1000
            click 32, 91          ; uncheck create menu item?
            click 32, 119         ; check create desktop icon?
            send {enter}          ; next (for 2nd of 3 pages of install dialog)
            ; dismiss any news dialogs, and click 'next' on third page of install dialog
            loop
            {
                sleep 1000
                ifwinexist Steam - Updates News
                {
                    winclose
                    continue
                }
                ifwinexist Install - $_W_steamtitle
                {
                    winactivate
                    send {enter}      ; next (for 3rd of 3 pages of install dialog)
                }
                ifwinnotexist Install - $_W_steamtitle
                {
                    sleep 1000
                    ifwinnotexist Install - $_W_steamtitle
                        break
                }
            }
        }
    "

if [ "$STEAM_DVD" = "TRUE" ]
then
    # Wait for install to finish
    while true
    do
        grep "SetHasAllLocalContent(true) called for $_W_steamid" "$W_PROGRAMS_X86_UNIX/Steam/logs/download_log.txt" && break
        sleep 5
    done
fi

    w_ahk_do "
        ; For DVD's: theoretically, it should be installed now, but most games want to download updates. Do that now.
        ; For regular downloads: relaunch to coax steam into showing its nice small download progress dialog
        process close, Steam.exe
        run steam.exe -login $W_STEAM_ID $W_STEAM_PASSWORD -applaunch $_W_steamid
        winwait Ready -
        process close, Steam.exe
    "

    # Not all users need this disabled, but let's play it safe for now
    if w_workaround_wine_bug 22053 "Disabling ingame notifications to prevent game crashes on some machines."
    then
        w_steam_safemode
    fi

    w_declare_exe "$W_PROGRAMS_X86_WIN\\Steam" "steam.exe -login $W_STEAM_ID $W_STEAM_PASSWORD -applaunch $_W_steamid"

    myexec="Exec=env WINEPREFIX=\"$WINEPREFIX\" wine cmd /c 'C:\\\\\\\\Run-$W_PACKAGE.bat'"
    mymenu="$XDG_DATA_HOME/applications/wine/Programs/Steam/$_W_steamtitle.desktop"
    if test -f "$mymenu" && w_workaround_wine_bug 26487 "Fixing system menu"
    then
        sed -i "s,Exec=.*,$myexec," "$mymenu"
    else
        w_warn "bug: could not find system menu entry $_W_steamtitle"
    fi

    unset _W_steamid _W_steamtitle
}


