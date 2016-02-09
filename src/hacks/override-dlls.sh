w_override_dlls()
{
    w_skip_windows w_override_dlls && return

    _W_mode=$1
    case $_W_mode in
    *=*)
        w_die "w_override_dlls: unknown mode $_W_mode.
Usage: 'w_override_dlls mode[,mode] dll ...'." ;;
    disabled)
        _W_mode="" ;;
    esac
    shift
    echo Using $_W_mode override for following DLLs: $@
    cat > "$W_TMP"/override-dll.reg <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\Software\Wine\DllOverrides]
_EOF_
    while test "$1" != ""
    do
        case "$1" in
        comctl32)
           rm -rf "$W_WINDIR_UNIX"/winsxs/manifests/x86_microsoft.windows.common-controls_6595b64144ccf1df_6.0.2600.2982_none_deadbeef.manifest
           ;;
        esac

        if [ "$_W_mode" = default ]
        then
            # To delete a registry key, give an unquoted dash as value
            echo "\"*$1\"=-" >> "$W_TMP"/override-dll.reg
        else
            # Note: if you want to override even DLLs loaded with an absolute
            # path, you need to add an asterisk:
            echo "\"*$1\"=\"$_W_mode\"" >> "$W_TMP"/override-dll.reg
            #echo "\"$1\"=\"$_W_mode\"" >> "$W_TMP"/override-dll.reg
        fi

        shift
    done

    w_try_regedit "$W_TMP_WIN"\\override-dll.reg

    unset _W_mode
}

w_override_no_dlls()
{
    w_skip_windows override && return

    "$WINE" regedit /d 'HKEY_CURRENT_USER\Software\Wine\DllOverrides'
}

w_override_all_dlls()
{
    # Disable all known native Microsoft DLLs in favor of Wine's builtin ones
    # Generated with
    # find ~/wine-git/dlls -maxdepth 1 -type d -print | sed 's,.*/,,' | sort | fmt -50 | sed 's/$/ \\/'
    # Last updated: 2015-09-28
    w_override_dlls builtin \
        acledit aclui activeds actxprxy adsiid advapi32 \
        advpack amstream api-ms-win-core-com-l1-1-0 \
        api-ms-win-core-console-l1-1-0 \
        api-ms-win-core-datetime-l1-1-0 \
        api-ms-win-core-datetime-l1-1-1 \
        api-ms-win-core-debug-l1-1-0 \
        api-ms-win-core-debug-l1-1-1 \
        api-ms-win-core-errorhandling-l1-1-0 \
        api-ms-win-core-errorhandling-l1-1-1 \
        api-ms-win-core-errorhandling-l1-1-2 \
        api-ms-win-core-fibers-l1-1-0 \
        api-ms-win-core-fibers-l1-1-1 \
        api-ms-win-core-file-l1-1-0 \
        api-ms-win-core-file-l1-2-0 \
        api-ms-win-core-file-l2-1-0 \
        api-ms-win-core-file-l2-1-1 \
        api-ms-win-core-handle-l1-1-0 \
        api-ms-win-core-heap-l1-1-0 \
        api-ms-win-core-heap-l1-2-0 \
        api-ms-win-core-heap-obsolete-l1-1-0 \
        api-ms-win-core-interlocked-l1-1-0 \
        api-ms-win-core-interlocked-l1-2-0 \
        api-ms-win-core-io-l1-1-1 \
        api-ms-win-core-kernel32-legacy-l1-1-0 \
        api-ms-win-core-libraryloader-l1-1-0 \
        api-ms-win-core-libraryloader-l1-1-1 \
        api-ms-win-core-localization-l1-2-0 \
        api-ms-win-core-localization-l1-2-1 \
        api-ms-win-core-localization-obsolete-l1-1-0 \
        api-ms-win-core-localregistry-l1-1-0 \
        api-ms-win-core-memory-l1-1-0 \
        api-ms-win-core-memory-l1-1-1 \
        api-ms-win-core-misc-l1-1-0 \
        api-ms-win-core-namedpipe-l1-1-0 \
        api-ms-win-core-namedpipe-l1-2-0 \
        api-ms-win-core-processenvironment-l1-1-0 \
        api-ms-win-core-processenvironment-l1-2-0 \
        api-ms-win-core-processthreads-l1-1-0 \
        api-ms-win-core-processthreads-l1-1-1 \
        api-ms-win-core-processthreads-l1-1-2 \
        api-ms-win-core-profile-l1-1-0 \
        api-ms-win-core-psapi-l1-1-0 \
        api-ms-win-core-registry-l1-1-0 \
        api-ms-win-core-rtlsupport-l1-1-0 \
        api-ms-win-core-rtlsupport-l1-2-0 \
        api-ms-win-core-shlwapi-legacy-l1-1-0 \
        api-ms-win-core-string-l1-1-0 \
        api-ms-win-core-synch-l1-1-0 \
        api-ms-win-core-synch-l1-2-0 \
        api-ms-win-core-sysinfo-l1-1-0 \
        api-ms-win-core-sysinfo-l1-2-0 \
        api-ms-win-core-sysinfo-l1-2-1 \
        api-ms-win-core-threadpool-legacy-l1-1-0 \
        api-ms-win-core-timezone-l1-1-0 \
        api-ms-win-core-url-l1-1-0 \
        api-ms-win-core-util-l1-1-0 \
        api-ms-win-core-winrt-error-l1-1-0 \
        api-ms-win-core-winrt-error-l1-1-1 \
        api-ms-win-core-winrt-l1-1-0 \
        api-ms-win-core-winrt-string-l1-1-0 \
        api-ms-win-core-xstate-l2-1-0 \
        api-ms-win-crt-conio-l1-1-0 \
        api-ms-win-crt-convert-l1-1-0 \
        api-ms-win-crt-environment-l1-1-0 \
        api-ms-win-crt-filesystem-l1-1-0 \
        api-ms-win-crt-heap-l1-1-0 \
        api-ms-win-crt-locale-l1-1-0 \
        api-ms-win-crt-math-l1-1-0 \
        api-ms-win-crt-multibyte-l1-1-0 \
        api-ms-win-crt-private-l1-1-0 \
        api-ms-win-crt-process-l1-1-0 \
        api-ms-win-crt-runtime-l1-1-0 \
        api-ms-win-crt-stdio-l1-1-0 \
        api-ms-win-crt-string-l1-1-0 \
        api-ms-win-crt-time-l1-1-0 \
        api-ms-win-crt-utility-l1-1-0 \
        api-ms-win-downlevel-advapi32-l1-1-0 \
        api-ms-win-downlevel-advapi32-l2-1-0 \
        api-ms-win-downlevel-normaliz-l1-1-0 \
        api-ms-win-downlevel-ole32-l1-1-0 \
        api-ms-win-downlevel-shell32-l1-1-0 \
        api-ms-win-downlevel-shlwapi-l1-1-0 \
        api-ms-win-downlevel-shlwapi-l2-1-0 \
        api-ms-win-downlevel-user32-l1-1-0 \
        api-ms-win-downlevel-version-l1-1-0 \
        api-ms-win-eventing-provider-l1-1-0 \
        api-ms-win-ntuser-dc-access-l1-1-0 \
        api-ms-win-security-base-l1-1-0 \
        api-ms-win-security-base-l1-2-0 \
        api-ms-win-security-sddl-l1-1-0 \
        api-ms-win-service-core-l1-1-1 \
        api-ms-win-service-management-l1-1-0 \
        api-ms-win-service-winsvc-l1-2-0 apphelp \
        appwiz.cpl atl atl100 atl110 atl80 atl90 authz \
        avicap32 avifil32 avifile.dll16 avrt bcrypt \
        browseui cabinet capi2032 cards cfgmgr32 clusapi \
        combase comcat comctl32 comdlg32 commdlg.dll16 \
        comm.drv16 compobj.dll16 compstui comsvcs connect \
        credui crtdll crypt32 cryptdlg cryptdll cryptext \
        cryptnet cryptui ctapi32 ctl3d32 ctl3d.dll16 \
        ctl3dv2.dll16 d2d1 d3d10 d3d10_1 d3d10core \
        d3d11 d3d8 d3d9 d3dcompiler_33 d3dcompiler_34 \
        d3dcompiler_35 d3dcompiler_36 d3dcompiler_37 \
        d3dcompiler_38 d3dcompiler_39 d3dcompiler_40 \
        d3dcompiler_41 d3dcompiler_42 d3dcompiler_43 \
        d3dcompiler_46 d3dcompiler_47 d3dim d3drm \
        d3dx10_33 d3dx10_34 d3dx10_35 d3dx10_36 d3dx10_37 \
        d3dx10_38 d3dx10_39 d3dx10_40 d3dx10_41 d3dx10_42 \
        d3dx10_43 d3dx11_42 d3dx11_43 d3dx9_24 d3dx9_25 \
        d3dx9_26 d3dx9_27 d3dx9_28 d3dx9_29 d3dx9_30 \
        d3dx9_31 d3dx9_32 d3dx9_33 d3dx9_34 d3dx9_35 \
        d3dx9_36 d3dx9_37 d3dx9_38 d3dx9_39 d3dx9_40 \
        d3dx9_41 d3dx9_42 d3dx9_43 d3dxof davclnt \
        dbgeng dbghelp dciman32 ddeml.dll16 ddraw \
        ddrawex devenum dhcpcsvc difxapi dinput \
        dinput8 dispdib.dll16 dispex display.drv16 \
        dlls dmband dmcompos dmime dmloader dmscript \
        dmstyle dmsynth dmusic dmusic32 dnsapi dplay \
        dplayx dpnaddr dpnet dpnhpast dpnlobby dpvoice \
        dpwsockx drmclien dsound dssenh dswave dwmapi \
        dwrite dxdiagn dxerr8 dxerr9 dxgi dxguid dxva2 \
        evr explorerframe ext-ms-win-gdi-devcaps-l1-1-0 \
        faultrep fltlib fntcache fontsub fusion fwpuclnt \
        gameux gdi32 gdi.exe16 gdiplus glu32 gphoto2.ds \
        gpkcsp hal hhctrl.ocx hid hidclass.sys hlink \
        hnetcfg httpapi iccvid icmp ieframe ifsmgr.vxd \
        imaadp32.acm imagehlp imm32 imm.dll16 inetcomm \
        inetcpl.cpl inetmib1 infosoft initpki inkobj \
        inseng iphlpapi itircl itss joy.cpl jscript \
        jsproxy kernel32 keyboard.drv16 krnl386.exe16 \
        ksuser ktmw32 loadperf localspl localui lz32 \
        lzexpand.dll16 mapi32 mapistub mciavi32 mcicda \
        mciqtz32 mciseq mciwave mf mfplat mfreadwrite \
        mgmtapi midimap mlang mmcndmgr mmdevapi \
        mmdevldr.vxd mmsystem.dll16 monodebg.vxd \
        mountmgr.sys mouse.drv16 mpr mprapi msacm32 \
        msacm32.drv msacm.dll16 msadp32.acm msasn1 \
        mscat32 mscms mscoree msctf msctfp msdaps \
        msdmo msftedit msg711.acm msgsm32.acm mshtml \
        mshtml.tlb msi msident msimg32 msimsg msimtf \
        msisip msisys.ocx msls31 msnet32 mspatcha msrle32 \
        msscript.ocx mssign32 mssip32 mstask msvcirt \
        msvcm80 msvcm90 msvcp100 msvcp110 msvcp120 \
        msvcp120_app msvcp60 msvcp70 msvcp71 msvcp80 \
        msvcp90 msvcr100 msvcr110 msvcr120 msvcr120_app \
        msvcr70 msvcr71 msvcr80 msvcr90 msvcrt msvcrt20 \
        msvcrt40 msvcrtd msvfw32 msvidc32 msvideo.dll16 \
        mswsock msxml msxml2 msxml3 msxml4 msxml6 \
        nddeapi ndis.sys netapi32 netcfgx netprofm \
        newdev normaliz npmshtml npptools ntdll ntdsapi \
        ntoskrnl.exe ntprint objsel odbc32 odbccp32 \
        odbccu32 ole2conv.dll16 ole2disp.dll16 ole2.dll16 \
        ole2nls.dll16 ole2prox.dll16 ole2thk.dll16 \
        ole32 oleacc oleaut32 olecli32 olecli.dll16 \
        oledb32 oledlg olepro32 olesvr32 olesvr.dll16 \
        olethk32 openal32 opencl opengl32 packager pdh \
        photometadatahandler pidgen powrprof printui \
        prntvpt propsys psapi pstorec qcap qedit qmgr \
        qmgrprxy quartz query rasapi16.dll16 rasapi32 \
        rasdlg regapi resutils riched20 riched32 \
        rpcrt4 rsabase rsaenh rstrtmgr rtutils \
        samlib sane.ds scarddlg sccbase schannel \
        schedsvc scrrun scsiport.sys secur32 security \
        sensapi serialui setupapi setupx.dll16 sfc \
        sfc_os shdoclc shdocvw shell32 shell.dll16 \
        shfolder shlwapi slbcsp slc snmpapi softpub \
        sound.drv16 spoolss stdole2.tlb stdole32.tlb \
        sti storage.dll16 stress.dll16 strmbase strmiids \
        svrapi sxs system.drv16 t2embed tapi32 taskschd \
        toolhelp.dll16 traffic twain_32 twain.dll16 \
        typelib.dll16 ucrtbase unicows updspapi url \
        urlmon usbd.sys user32 userenv user.exe16 usp10 \
        uuid uxtheme vbscript vcomp vcomp100 vcomp110 \
        vcomp90 vdhcp.vxd vdmdbg ver.dll16 version \
        vmm.vxd vnbt.vxd vnetbios.vxd vssapi vtdapi.vxd \
        vwin32.vxd w32skrnl w32sys.dll16 wbemdisp \
        wbemprox webservices wer wevtapi wiaservc \
        win32s16.dll16 win87em.dll16 winaspi.dll16 \
        windebug.dll16 windowscodecs windowscodecsext \
        winealsa.drv winecoreaudio.drv winecrt0 wined3d \
        winegstreamer winejoystick.drv winemac.drv \
        winemapi winemp3.acm wineoss.drv wineps16.drv16 \
        wineps.drv wineqtdecoder winex11.drv wing32 \
        wing.dll16 winhttp wininet winmm winnls32 \
        winnls.dll16 winscard winsock.dll16 winspool.drv \
        winsta wintab32 wintab.dll16 wintrust wlanapi \
        wldap32 wmi wmiutils wmp wmvcore wnaspi32 wow32 \
        wpcap ws2_32 wshom.ocx wsnmp32 wsock32 wtsapi32 \
        wuapi wuaueng x3daudio1_1 x3daudio1_2 x3daudio1_3 \
        x3daudio1_4 x3daudio1_5 x3daudio1_6 x3daudio1_7 \
        xapofx1_1 xapofx1_3 xapofx1_4 xapofx1_5 xaudio2_7 \
        xaudio2_8 xinput1_1 xinput1_2 xinput1_3 xinput1_4 \
        xinput9_1_0 xmllite xolehlp xpsprint xpssvcs \

        # blank line so you don't have to remove the extra trailing \
}

w_override_app_dlls()
{
    w_skip_windows w_override_app_dlls && return

    _W_app=$1
    shift
    _W_mode=$1
    shift

    # Fixme: handle comma-separated list of modes
    case $_W_mode in
    b|builtin) _W_mode=builtin ;;
    n|native) _W_mode=native ;;
    default) _W_mode=default ;;
    d|disabled)
        _W_mode="" ;;
    *)
        w_die "w_override_app_dlls: unknown mode $_W_mode.  (want native, builtin, default, or disabled)
Usage: 'w_override_app_dlls app mode dll ...'." ;;
    esac

    echo Using $_W_mode override for following DLLs when running $_W_app: $@
    (
    echo REGEDIT4
    echo ""
    echo "[HKEY_CURRENT_USER\\Software\\Wine\\AppDefaults\\$_W_app\\DllOverrides]"
    ) > "$W_TMP"/override-dll.reg

    while test "$1" != ""
    do
        case "$1" in
        comctl32)
           rm -rf "$W_WINDIR_UNIX"/winsxs/manifests/x86_microsoft.windows.common-controls_6595b64144ccf1df_6.0.2600.2982_none_deadbeef.manifest
           ;;
        esac
        if [ "$_W_mode" = default ]
        then
            # To delete a registry key, give an unquoted dash as value
            echo "\"*$1\"=-" >> "$W_TMP"/override-dll.reg
        else
            # Note: if you want to override even DLLs loaded with an absolute
            # path, you need to add an asterisk:
            echo "\"*$1\"=\"$_W_mode\"" >> "$W_TMP"/override-dll.reg
            #echo "\"$1\"=\"$_W_mode\"" >> "$W_TMP"/override-dll.reg
        fi
        shift
    done

    w_try_regedit "$W_TMP_WIN"\\override-dll.reg
    rm "$W_TMP"/override-dll.reg
    unset _W_app _W_mode
}

