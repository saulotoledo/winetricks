
# Display prefix menu, get which wineprefix the user wants to work with
winetricks_prefixmenu()
{
    case $LANG in
    uk*) _W_msg_title="Winetricks - виберіть wineprefix"
         _W_msg_body='Що Ви хочете зробити?'
         _W_msg_apps='Встановити додаток'
         _W_msg_games='Встановити гру'
         _W_msg_benchmarks='Встановити benchmark'
         _W_msg_default="Вибрати wineprefix за замовчуванням"
         _W_msg_unattended0="Вимкнути автоматичну установку"
         _W_msg_unattended1="Включити автоматичну установку"
         _W_msg_showbroken0="Сховати нестабільні додатки (наприклад з проблемами з DRM)"
         _W_msg_showbroken1="Показати нестабільні додатки (наприклад з проблемами з DRM)"
         _W_msg_help="Переглянути довідку"
         ;;
    zh_CN*)   _W_msg_title="Windows 应用安装向导 - 选择一个 wine 容器"
         _W_msg_body='君欲何为？'
         _W_msg_apps='安装一个 windows 应用'
         _W_msg_games='安装一个游戏'
         _W_msg_benchmarks='安装一个基准测试软件'
         _W_msg_default="选择默认的 wine 容器"
         _W_msg_unattended0="禁用静默安装"
         _W_msg_unattended1="启用静默安装"
         _W_msg_showbroken0="隐藏有问题的程序 (例如那些有数字版权问题)"
         _W_msg_showbroken1="有问题的程序 (例如那些有数字版权问题)"
         _W_msg_help="查看帮助"
         ;;
    zh_TW*|zh_HK*)   _W_msg_title="Windows 應用安裝向導 - 選取一個 wine 容器"
         _W_msg_body='君欲何為？'
         _W_msg_apps='安裝一個 windows 應用'
         _W_msg_games='安裝一個游戲'
         _W_msg_benchmarks='安裝一個基准測試軟體'
         _W_msg_default="選取預設的 wine 容器"
         _W_msg_unattended0="禁用靜默安裝"
         _W_msg_unattended1="啟用靜默安裝"
         _W_msg_showbroken0="隱藏有問題的程式 (例如那些有數字版權問題)"
         _W_msg_showbroken1="有問題的程式 (例如那些有數字版權問題)"
         _W_msg_help="檢視輔助說明"
         ;;
    de*) _W_msg_title="Winetricks - wineprefix auswählen"
         _W_msg_body='Was möchten Sie tun?'
         _W_msg_apps='Eine Programm installieren'
         _W_msg_games='Ein Spiel installieren'
         _W_msg_benchmarks='Ein Benchmark installieren'
         _W_msg_default="Standard wineprefix auswählen"
         _W_msg_unattended0="Automatische Installation deaktivieren"
         _W_msg_unattended1="Automatische Installation aktivieren"
         _W_msg_showbroken0="Defekte Programme nicht anzeigen (z.B. solche mit DRM Problemen)"
         _W_msg_showbroken1="Defekte Programme anzeigen (z.B. solche mit DRM Problemen)"
         _W_msg_help="Hilfe anzeigen"
         ;;
    *)   _W_msg_title="Winetricks - choose a wineprefix"
         _W_msg_body='What do you want to do?'
         _W_msg_apps='Install an app'
         _W_msg_games='Install a game'
         _W_msg_benchmarks='Install a benchmark'
         _W_msg_default="Select the default wineprefix"
         _W_msg_unattended0="Disable silent install"
         _W_msg_unattended1="Enable silent install"
         _W_msg_showbroken0="Hide broken apps (e.g. those with DRM problems)"
         _W_msg_showbroken1="Show broken apps (e.g. those with DRM problems)"
         _W_msg_help="View help"
         ;;
    esac
    case "$W_OPT_UNATTENDED" in
    1) _W_cmd_unattended=attended; _W_msg_unattended="$_W_msg_unattended0" ;;
    *) _W_cmd_unattended=unattended; _W_msg_unattended="$_W_msg_unattended1" ;;
    esac
    case "$W_OPT_SHOWBROKEN" in
    1) _W_cmd_showbroken=hidebroken; _W_msg_showbroken="$_W_msg_showbroken0" ;;
    *) _W_cmd_showbroken=showbroken; _W_msg_showbroken="$_W_msg_showbroken1" ;;
    esac

    case $WINETRICKS_GUI in
    zenity)
        printf %s "zenity \
            --title '$_W_msg_title' \
            --text '$_W_msg_body' \
            --list \
            --radiolist \
            --column '' \
            --column '' \
            --column '' \
            --height $WINETRICKS_MENU_HEIGHT \
            --width $WINETRICKS_MENU_WIDTH \
            --hide-column 2 \
            FALSE help       '$_W_msg_help' \
            FALSE apps       '$_W_msg_apps' \
            FALSE benchmarks '$_W_msg_benchmarks' \
            FALSE games      '$_W_msg_games' \
            TRUE  main       '$_W_msg_default' \
            " \
            > "$WINETRICKS_WORKDIR"/zenity.sh

        if ls -d $W_PREFIXES_ROOT/*/dosdevices > /dev/null 2>&1
        then
            for prefix in "$W_PREFIXES_ROOT"/*/dosdevices
            do
                q="${prefix%%/dosdevices}"
                p="${q##*/}"
                if test -f "$W_PREFIXES_ROOT/$p/wrapper.cfg"
                then
                    _W_msg_name="$p (`winetricks_get_prefix_var name`)"
                else
                    _W_msg_name="$p"
                fi
            case $LANG in 
            zh_CN*) printf %s " FALSE prefix='$p' '选择管理 $_W_msg_name' " ;;
            zh_TW*|zh_HK*) printf %s " FALSE prefix='$p' '選擇管理 $_W_msg_name' " ;;
            de*) printf %s " FALSE prefix='$p' '$_W_msg_name auswählen' " ;;
            *) printf %s " FALSE prefix='$p' 'Select $_W_msg_name' " ;;
            esac
            done >> "$WINETRICKS_WORKDIR"/zenity.sh
        fi
        printf %s " FALSE $_W_cmd_unattended '$_W_msg_unattended'" >> "$WINETRICKS_WORKDIR"/zenity.sh
        printf %s " FALSE $_W_cmd_showbroken '$_W_msg_showbroken'" >> "$WINETRICKS_WORKDIR"/zenity.sh

        sh "$WINETRICKS_WORKDIR"/zenity.sh | tr '|' ' '
        ;;

    kdialog)
        (
        printf %s "kdialog \
            --geometry 600x400+100+100 \
            --title '$_W_msg_title' \
            --separate-output \
            --radiolist '$_W_msg_body' \
            help       '$_W_msg_help'       off \
            games      '$_W_msg_games'      off \
            benchmarks '$_W_msg_benchmarks' off \
            apps       '$_W_msg_apps'       off \
            main       '$_W_msg_default'    on "
        if ls -d "$W_PREFIXES_ROOT"/*/dosdevices > /dev/null 2>&1
        then
            for prefix in "$W_PREFIXES_ROOT"/*/dosdevices
            do
                q="${prefix%%/dosdevices}"
                p="${q##*/}"
                if test -f "$W_PREFIXES_ROOT/$p/wrapper.cfg"
                then
                    _W_msg_name="$p (`winetricks_get_prefix_var name`)"
                else
                    _W_msg_name="$p"
                fi
                printf %s "prefix='$p' 'Select $_W_msg_name' off "
            done
        fi
        ) > "$WINETRICKS_WORKDIR"/kdialog.sh
        sh "$WINETRICKS_WORKDIR"/kdialog.sh
        ;;
    esac
    unset _W_msg_help _W_msg_body _W_msg_title _W_msg_new _W_msg_default _W_msg_name
}

# Display main menu, get which submenu the user wants
winetricks_mainmenu()
{
    case $LANG in
    da*) _W_msg_title='Vælg en pakke-kategori'
         _W_msg_body='Hvad ønsker du at gøre?'
         _W_msg_dlls="Install a Windows DLL"
         _W_msg_fonts='Install a font'
         _W_msg_settings='Change Wine settings'
         _W_msg_winecfg='Run winecfg'
         _W_msg_regedit='Run regedit'
         _W_msg_taskmgr='Run taskmgr'
         _W_msg_uninstaller='Run uninstaller'
         _W_msg_shell='Run a commandline shell (for debugging)'
         _W_msg_folder='Browse files'
         _W_msg_annihilate="Delete ALL DATA AND APPLICATIONS INSIDE THIS WINEPREFIX"
         ;;
    de*) _W_msg_title='Pakettyp auswählen'
         _W_msg_body='Was möchten Sie tun?'
         _W_msg_dlls="Windows-DLL installieren"
         _W_msg_fonts='Schriftart installieren'
         _W_msg_settings='Wine Einstellungen ändern'
         _W_msg_winecfg='winecfg starten'
         _W_msg_regedit='regedit starten'
         _W_msg_taskmgr='taskmgr starten'
         _W_msg_uninstaller='uninstaller starten'
         _W_msg_shell='Eine Kommandozeile zum debuggen starten'
         _W_msg_folder='Ordner durchsuchen'
         _W_msg_annihilate="ALLE DATEIEN UND PROGRAMME IN DIESEM WINEPREFIX Löschen"
         ;;
    pl*) _W_msg_title="Winetricks - obecny prefiks to \"$WINEPREFIX\""
         _W_msg_body='What would you like to do to this wineprefix?'
         _W_msg_dlls="Zainstaluj Windowsową bibliotekę DLL lub komponent"
         _W_msg_fonts='Zainstaluj czcionkę'
         _W_msg_settings='Zmień ustawienia'
         _W_msg_winecfg='Uruchom winecfg'
         _W_msg_regedit='Uruchom regedit'
         _W_msg_taskmgr='Uruchom taskmgr'
         _W_msg_uninstaller='Run uninstaller'
         _W_msg_shell='Uruchom powłokę wiersza poleceń (dla debugowania)'
         _W_msg_folder='Przeglądaj pliki'
         _W_msg_annihilate="Usuń WSZYSTKIE DANE I APLIKACJE WEWNĄTRZ TEGO WINEPREFIXA"
         ;;
    uk*) _W_msg_title="Winetricks - поточний prefix \"$WINEPREFIX\""
         _W_msg_body='Що Ви хочете зробити для цього wineprefix?'
         _W_msg_dlls="Встановити Windows DLL чи компонент(и)"
         _W_msg_fonts='Встановити шрифт'
         _W_msg_settings='Змінити налаштування'
         _W_msg_winecfg='Запустити winecfg'
         _W_msg_regedit='Запустити regedit'
         _W_msg_taskmgr='Запустити taskmgr'
         _W_msg_uninstaller='Run uninstaller'
         _W_msg_shell='Запуск командної оболонки (для налагодження)'
         _W_msg_folder='Перегляд файлів'
         _W_msg_annihilate="Видалити УСІ ДАНІ ТА ПРОГРАМИ З ЦЬОГО WINEPREFIX"
         ;;
    zh_CN*)   _W_msg_title="Windows 应用安装向导 - 当前容器路径是 \"$WINEPREFIX\""
         _W_msg_body='管理当前容器'
         _W_msg_dlls="安装 Windows DLL 或组件"
         _W_msg_fonts='安装字体'
         _W_msg_settings='修改设置'
         _W_msg_winecfg='运行 winecfg'
         _W_msg_regedit='运行注册表'
         _W_msg_taskmgr='运行任务管理器'
         _W_msg_uninstaller='运行卸载程序'
         _W_msg_shell='运行命令提示窗口 (作为调试)'
         _W_msg_folder='浏览容器中的文件'
         _W_msg_annihilate="删除当前容器所有相关文件，包括启动器，完全卸载"
         ;;
    zh_TW*|zh_HK*)   _W_msg_title="Windows 應用裝載向導 - 目前容器路徑是 \"$WINEPREFIX\""
         _W_msg_body='管理目前容器'
         _W_msg_dlls="裝載 Windows DLL 或套件"
         _W_msg_fonts='裝載字型'
         _W_msg_settings='修改設定'
         _W_msg_winecfg='執行 winecfg'
         _W_msg_regedit='執行註冊表'
         _W_msg_taskmgr='執行工作管理者'
         _W_msg_uninstaller='執行反安裝程式'
         _W_msg_shell='執行指令輔助說明視窗 (作為除錯)'
         _W_msg_folder='瀏覽容器中的檔案'
         _W_msg_annihilate="移除目前容器所有相依檔案，包括啟動器，完全卸載"
         ;;
    *)   _W_msg_title="Winetricks - current prefix is \"$WINEPREFIX\""
         _W_msg_body='What would you like to do to this wineprefix?'
         _W_msg_dlls="Install a Windows DLL or component"
         _W_msg_fonts='Install a font'
         _W_msg_settings='Change settings'
         _W_msg_winecfg='Run winecfg'
         _W_msg_regedit='Run regedit'
         _W_msg_taskmgr='Run taskmgr'
         _W_msg_uninstaller='Run uninstaller'
         _W_msg_shell='Run a commandline shell (for debugging)'
         _W_msg_folder='Browse files'
         _W_msg_annihilate="Delete ALL DATA AND APPLICATIONS INSIDE THIS WINEPREFIX"
         ;;
    esac

    case $WINETRICKS_GUI in
    zenity)
        (
          printf %s "zenity \
            --title '$_W_msg_title' \
            --text '$_W_msg_body' \
            --list \
            --radiolist \
            --column '' \
            --column '' \
            --column '' \
            --height $WINETRICKS_MENU_HEIGHT \
            --width $WINETRICKS_MENU_WIDTH \
            --hide-column 2 \
            FALSE dlls        '$_W_msg_dlls' \
            FALSE fonts       '$_W_msg_fonts' \
            FALSE settings    '$_W_msg_settings' \
            FALSE winecfg     '$_W_msg_winecfg' \
            FALSE regedit     '$_W_msg_regedit' \
            FALSE taskmgr     '$_W_msg_taskmgr' \
            FALSE uninstaller '$_W_msg_uninstaller' \
            FALSE shell       '$_W_msg_shell' \
            FALSE folder      '$_W_msg_folder' \
            FALSE annihilate  '$_W_msg_annihilate' \
         "
         ) > "$WINETRICKS_WORKDIR"/zenity.sh
        sh "$WINETRICKS_WORKDIR"/zenity.sh | tr '|' ' '
        ;;

    kdialog)
        $WINETRICKS_GUI --geometry 600x400+100+100 \
                --title "$_W_msg_title" \
                --separate-output \
                --radiolist \
                "$_W_msg_body"\
                dlls        "$_W_msg_dlls" off \
                fonts       "$_W_msg_fonts" off \
                settings    "$_W_msg_settings" off \
                winecfg     "$_W_msg_winecfg" off \
                regedit     "$_W_msg_regedit" off \
                taskmgr     "$_W_msg_taskmgr" off \
                uninstaller "$_W_msg_uninstaller" off \
                shell       "$_W_msg_shell" off \
                folder      "$_W_msg_folder" off \
                annihilate  "$_W_msg_annihilate" off \
                $_W_cmd_unattended "$_W_msg_unattended" off \

        ;;
    esac
    unset _W_msg_body _W_msg_title _W_msg_apps _W_msg_benchmarks _W_msg_dlls _W_msg_games _W_msg_settings
}

winetricks_settings_menu()
{
    # FIXME: these translations should really be centralized/reused:
    case $LANG in
    da*) _W_msg_title='Vælg en pakke'
         _W_msg_body='Which settings would you like to change?'
         ;;
    de*) _W_msg_title="Winetricks - Aktueller Prefix ist \"$WINEPREFIX\""
         _W_msg_body='Welche Einstellungen möchten Sie ändern?'
         ;;
    pl*) _W_msg_title="Winetricks - obecny prefiks to \"$WINEPREFIX\""
         _W_msg_body='Which settings would you like to change?'
         ;;
    uk*) _W_msg_title="Winetricks - поточний prefix \"$WINEPREFIX\""
         _W_msg_body='Які налаштування Ви хочете змінити?'
         ;;
    zh_CN*)   _W_msg_title="Windows 应用安装向导 - 当前容器路径是 \"$WINEPREFIX\""
         _W_msg_body='君欲更改哪项设置？'
         ;;
    zh_TW*|zh_HK*)   _W_msg_title="Windows 應用裝載向導 - 目前容器路徑是 \"$WINEPREFIX\""
         _W_msg_body='君欲變更哪項設定？'
         ;;
    *)   _W_msg_title="Winetricks - current prefix is \"$WINEPREFIX\""
         _W_msg_body='Which settings would you like to change?'
         ;;
    esac

    case $WINETRICKS_GUI in
    zenity)
        case $LANG in
        da*) printf %s "zenity \
                --title '$_W_msg_title' \
                --text '$_W_msg_body' \
                --list \
                --checklist \
                --column '' \
                --column Pakke \
                --column Navn \
                --height $WINETRICKS_MENU_HEIGHT \
                --width $WINETRICKS_MENU_WIDTH \
                "
            ;;
        de*) printf %s "zenity \
                --title '$_W_msg_title' \
                --text '$_W_msg_body' \
                --list \
                --checklist \
                --column '' \
                --column Einstellung \
                --column Name \
                --height $WINETRICKS_MENU_HEIGHT \
                --width $WINETRICKS_MENU_WIDTH \
                "
            ;;
        pl*) printf %s "zenity \
                --title '$_W_msg_title' \
                --text '$_W_msg_body' \
                --list \
                --checklist \
                --column '' \
                --column Ustawienie \
                --column Nazwa \
                --height $WINETRICKS_MENU_HEIGHT \
                --width $WINETRICKS_MENU_WIDTH \
                "
            ;;
        uk*) printf %s "zenity \
                --title '$_W_msg_title' \
                --text '$_W_msg_body' \
                --list \
                --checklist \
                --column '' \
                --column Установка \
                --column Назва \
                --height $WINETRICKS_MENU_HEIGHT \
                --width $WINETRICKS_MENU_WIDTH \
                "
            ;;
        zh_CN*) printf %s "zenity \
                --title '$_W_msg_title' \
                --text '$_W_msg_body' \
                --list \
                --checklist \
                --column '' \
                --column 设置 \
                --column 标题 \
                --height $WINETRICKS_MENU_HEIGHT \
                --width $WINETRICKS_MENU_WIDTH \
                "
            ;;
        zh_TW*|zh_HK*) printf %s "zenity \
                --title '$_W_msg_title' \
                --text '$_W_msg_body' \
                --list \
                --checklist \
                --column '' \
                --column 設定 \
                --column 標題 \
                --height $WINETRICKS_MENU_HEIGHT \
                --width $WINETRICKS_MENU_WIDTH \
                "
            ;;
        *) printf %s "zenity \
                --title '$_W_msg_title' \
                --text '$_W_msg_body' \
                --list \
                --checklist \
                --column '' \
                --column Setting \
                --column Title \
                --height $WINETRICKS_MENU_HEIGHT \
                --width $WINETRICKS_MENU_WIDTH \
                "
            ;;
        esac > "$WINETRICKS_WORKDIR"/zenity.sh

        for metadatafile in "$WINETRICKS_METADATA"/$WINETRICKS_CURMENU/*.vars
        do
            code=`winetricks_metadata_basename "$metadatafile"`
            (
            title='?'
            author='?'
            . "$metadatafile"
          # Begin 'title' strings localization code
            case $LANG in
            uk*) case "$title_uk" in
                 "") ;;
                 *) title="$title_uk";;
                 esac
            esac
          # End of code
            printf "%s %s %s %s" " " FALSE \
                    $code \
                    "\"$title\""
            )
        done >> "$WINETRICKS_WORKDIR"/zenity.sh

        sh "$WINETRICKS_WORKDIR"/zenity.sh | tr '|' ' '
        ;;

    kdialog)
        (
        printf %s "kdialog --geometry 600x400+100+100 --title '$_W_msg_title' --separate-output --checklist '$_W_msg_body' "
        winetricks_list_all | sed 's/\([^ ]*\)  *\(.*\)/\1 "\1 - \2" off /' | tr '\012' ' '
        ) > "$WINETRICKS_WORKDIR"/kdialog.sh
        sh "$WINETRICKS_WORKDIR"/kdialog.sh
        ;;
    esac

    unset _W_msg_body _W_msg_title
}

# Display the current menu, output list of verbs to execute to stdout
winetricks_showmenu()
{
    case $LANG in
    da*) _W_msg_title='Vælg en pakke'
         _W_msg_body='Vilken pakke vil du installere?'
         _W_cached="cached"
         ;;
    de*) _W_msg_title="Winetricks - Aktueller Prefix ist \"$WINEPREFIX\""
         _W_msg_body='Welche Paket(e) möchten Sie installieren?'
         _W_cached="gecached"
         ;;
    pl*) _W_msg_title="Winetricks - obecny prefiks to \"$WINEPREFIX\""
         _W_msg_body='Które paczki chesz zainstalować?'
         _W_cached="zarchiwizowane"
         ;;
    uk*) _W_msg_title="Winetricks - поточний prefix \"$WINEPREFIX\""
         _W_msg_body='Які пакунки Ви хочете встановити?'
         _W_cached="кешовано"
         ;;
    zh_CN*)   _W_msg_title="Windows 应用安装向导 - 当前容器路径是 \"$WINEPREFIX\""
         _W_msg_body='君欲安装何种应用？'
         _W_cached="已缓存"
         ;;
    zh_TW*|zh_HK*)   _W_msg_title="Windows 應用裝載向導 - 目前容器路徑是 \"$WINEPREFIX\""
         _W_msg_body='君欲裝載何種應用？'
         _W_cached="已緩存"
         ;;
    *)   _W_msg_title="Winetricks - current prefix is \"$WINEPREFIX\""
         _W_msg_body='Which package(s) would you like to install?'
         _W_cached="cached"
         ;;
    esac


    case $WINETRICKS_GUI in
    zenity)
        case $LANG in
        da*) printf %s "zenity \
                --title '$_W_msg_title' \
                --text '$_W_msg_body' \
                --list \
                --checklist \
                --column '' \
                --column Pakke \
                --column Navn \
                --column Udgiver \
                --column År \
                --column Medie \
                --column Status \
                --column 'Size (MB)' \
                --column 'Time (sec)' \
                --height $WINETRICKS_MENU_HEIGHT \
                --width $WINETRICKS_MENU_WIDTH \
                "
            ;;
        de*) printf %s "zenity \
                --title '$_W_msg_title' \
                --text '$_W_msg_body' \
                --list \
                --checklist \
                --column '' \
                --column Paket \
                --column Name \
                --column Herausgeber \
                --column Jahr \
                --column Media \
                --column Status \
                --column 'Größe (MB)' \
                --column 'Zeit (sec)' \
                --height $WINETRICKS_MENU_HEIGHT \
                --width $WINETRICKS_MENU_WIDTH \
                "
             ;;
        pl*) printf %s "zenity \
                --title '$_W_msg_title' \
                --text '$_W_msg_body' \
                --list \
                --checklist \
                --column '' \
                --column Paczka \
                --column Nazwa \
                --column Wydawca \
                --column Rok \
                --column Media \
                --column Status \
                --column 'Rozmiar (MB)' \
                --column 'Czas (sek)' \
                --height $WINETRICKS_MENU_HEIGHT \
                --width $WINETRICKS_MENU_WIDTH \
                "
             ;;
        uk*) printf %s "zenity \
                --title '$_W_msg_title' \
                --text '$_W_msg_body' \
                --list \
                --checklist \
                --column '' \
                --column Пакунок \
                --column Назва \
                --column Видавець \
                --column Рік \
                --column Медіа \
                --column Статус \
                --column 'Розмір (МБ)' \
                --column 'Час (сек)' \
                --height $WINETRICKS_MENU_HEIGHT \
                --width $WINETRICKS_MENU_WIDTH \
                "
             ;;
        zh_CN*) printf %s "zenity \
                --title '$_W_msg_title' \
                --text '$_W_msg_body' \
                --list \
                --checklist \
                --column '' \
                --column 包名 \
                --column 软件名 \
                --column 发行商 \
                --column 发行年 \
                --column 媒介 \
                --column 状态 \
                --column '文件大小 (MB)' \
                --column '时间 (秒)' \
                --height $WINETRICKS_MENU_HEIGHT \
                --width $WINETRICKS_MENU_WIDTH \
                "
             ;;
        zh_TW*|zh_HK*) printf %s "zenity \
                --title '$_W_msg_title' \
                --text '$_W_msg_body' \
                --list \
                --checklist \
                --column '' \
                --column 包名 \
                --column 軟體名 \
                --column 發行商 \
                --column 發行年 \
                --column 媒介 \
                --column 狀態 \
                --column '檔案大小 (MB)' \
                --column '時間 (秒)' \
                --height $WINETRICKS_MENU_HEIGHT \
                --width $WINETRICKS_MENU_WIDTH \
                "
             ;;
        *) printf %s "zenity \
                --title '$_W_msg_title' \
                --text '$_W_msg_body' \
                --list \
                --checklist \
                --column '' \
                --column Package \
                --column Title \
                --column Publisher \
                --column Year \
                --column Media \
                --column Status \
                --column 'Size (MB)' \
                --column 'Time (sec)' \
                --height $WINETRICKS_MENU_HEIGHT \
                --width $WINETRICKS_MENU_WIDTH \
                "
             ;;
        esac > "$WINETRICKS_WORKDIR"/zenity.sh

        > "$WINETRICKS_WORKDIR"/installed.txt
        for metadatafile in "$WINETRICKS_METADATA"/$WINETRICKS_CURMENU/*.vars
        do
            code=`winetricks_metadata_basename "$metadatafile"`
            (
            title='?'
            author='?'
            . "$metadatafile"
            if test "$W_OPT_SHOWBROKEN" = 1 || test "$wine_showstoppers" = ""
            then
                # Compute cached and downloadable flags
                flags=""
                winetricks_is_cached $code && flags="$_W_cached"
                installed=FALSE
                if winetricks_is_installed $code
                then
                    installed=TRUE
                    echo $code >> "$WINETRICKS_WORKDIR"/installed.txt
                fi
                printf %s " $installed \
                    $code \
                    \"$title\" \
                    \"$publisher\" \
                    \"$year\" \
                    \"$media\" \
                    \"$flags\" \
                    \"$size_MB\" \
                    \"$time_sec\" \
                "
            fi
            )
        done >> "$WINETRICKS_WORKDIR"/zenity.sh

        # Filter out any verb that's already installed
        sh "$WINETRICKS_WORKDIR"/zenity.sh |
            tr '|' '\012' |
            fgrep -v -x -f "$WINETRICKS_WORKDIR"/installed.txt |
            tr '\012' ' '
        ;;

    kdialog)
        (
        printf %s "kdialog --geometry 600x400+100+100 --title '$_W_msg_title' --separate-output --checklist '$_W_msg_body' "
        winetricks_list_all | sed 's/\([^ ]*\)  *\(.*\)/\1 "\1 - \2" off /' | tr '\012' ' '
        ) > "$WINETRICKS_WORKDIR"/kdialog.sh
        sh "$WINETRICKS_WORKDIR"/kdialog.sh
        ;;
    esac

    unset _W_msg_body _W_msg_title
}
