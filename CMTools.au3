#Region Header
;===================================================================================================
;
; Title:            CMTools
; Filename:         CMTools.au3
; Description:      Дополнительные команды для Clickermann
; Version:          1.5.0
; Requirement(s):   Autoit 3.3.14.5
; Author(s):        Vint
; Date:             25.10.2021
;
;===================================================================================================
#EndRegion Header

#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
; #AutoIt3Wrapper_UseX64=n  ; Использовать X64 версию AutoIt3_x64 или AUT2EXE_x64
; #AutoIt3Wrapper_Compile_both=y ; Компилировать оба варианта X86 и X64 за раз
#AutoIt3Wrapper_Icon=cmex.ico
#AutoIt3Wrapper_OutFile=CMTools.exe
#AutoIt3Wrapper_OutFile_X64=CMToolsX64.exe 
#AutoIt3Wrapper_OutFile_Type=exe
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_UseUpx=y

#AutoIt3Wrapper_Res_Fileversion=1.5.0
#AutoIt3Wrapper_Res_LegalCopyright=(c)2021 Vint
#AutoIt3Wrapper_Res_Description=additional functionality for Clickermann
#AutoIt3Wrapper_Res_Comment=CMTools
#AutoIt3Wrapper_Res_Language=1049
#AutoIt3Wrapper_Res_requestedExecutionLevel=highestAvailable ; None, asInvoker (как родительский), highestAvailable (наивысшими доступными текущему пользователю) или requireAdministrator (с правами администратора)
#AutoIt3Wrapper_Res_Field=Version|1.5.10
#AutoIt3Wrapper_Res_Field=Build|2021.10.25
#AutoIt3Wrapper_Res_Field=Coded by|Vint
#AutoIt3Wrapper_Res_Field=Compile date|%longdate% %time%
#AutoIt3Wrapper_Res_Field=AutoIt Version|3.3.14.5
; #AutoIt3Wrapper_Res_Field=AutoIt Version|%AutoItVer%
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#Region    **** AutoItSetOption ****
#Au3Stripper_Ignore_Funcs=_MouseWheel_Events
#RequireAdmin
Opt('MustDeclareVars', 1)
Opt('WinWaitDelay', 100)  ; пауза после успешных оконных функций. 250 мс
Opt('TrayIconDebug', 1)
Opt('WinSearchChildren', 1)  ; Поиск окон верхнего уровня и дочерних
;~ Opt('WinTitleMatchMode', 2)  ; 1-начальное, 2-любая подстрока, 3-точное, 4-расширено, -1 to -4=Nocase
#EndRegion **** AutoItSetOption ****

#Region    **** Includes ****
#include-Once
#include <WinAPI.au3>
#include <WinAPIEx.au3>
#include <SendMessage.au3>
#include <Misc.au3>
#include <MouseOnEvent.au3>

#include <WindowsConstants.au3>
#include <Constants.au3>
#include <GUIConstantsEx.au3>
#include <MultiMon.au3>
#include <Array.au3>
#EndRegion **** Includes ****

#Region Global Constants and Variables

Global $CMToolsVersion = '1.5.0'
Global $hGUImain
Global $x1, $y1, $x2, $y2
Global $CM_name = ''
Global $CM_title = ''
Global $fileini = ''
Global $hWndCMM = '', $hWndCM = '', $hWndCMR = '', $iPidCM = '', $versionFullCM = ''
Global $DesktopWidth, $DesktopHeight, $xMin , $yMin, $xMax, $yMax
Global $repeated = False
Global $startBuf
Global $WM_CMCOMMAND
Global $MouseWheelScrollEvent_Tooltip, $MouseMoveEvent_Tooltip
Global $hDLLkernel32

#EndRegion Global Constants and Variables


_Singleton(@ScriptName)  ; запуск только одной копии


_Init()
_WaitCM()
$hDLLkernel32 = DllOpen('kernel32.dll')
_CalculateBuffer()
_MainLoop()

;~ Local $hTimer = TimerInit()
;~ _ColormodeGreyscale_OLD4(750, 426, 849, 525)
;~ _ColormodeGreyscale(750, 426, 849, 525)
;~ _ColormodeGreyscale(0, 0, 3519, 1079) ; 32878.3704 ms  35612.6536 ms
;~ ConsoleWrite('Время выполнения  ' & TimerDiff($hTimer) & ' ms' & @CRLF)
;~ _SendCM(123, 456)


Func _MainLoop()
    Local $Msg, $Code_MY_SETREGION
    $hGUImain = GUICreate('CMTools v' & $CMToolsVersion, 100, 50, 20, 20, $WS_OVERLAPPEDWINDOW + $WS_POPUP)
    GUISetState(@SW_SHOW)
    GUISetState(@SW_MINIMIZE)

    ConsoleWrite('$hGUImain  ' & $hGUImain & @CRLF)
    GUIRegisterMsg($WM_CLOSE, '_WM_CLOSE')
    _RegisterMyCommand()

    While 1
        $Msg = GUIGetMsg()
        Switch $Msg
            Case $GUI_EVENT_CLOSE
                MsgBox(48+4096, 'Внимание!', 'Дополнительный функционал отключен!', 2)
                ExitLoop
            Case Else
                ;ConsoleWrite('$Msg =  ' & $Msg & @CRLF)
        EndSwitch
        If Not WinExists($hWndCM) Then ExitLoop
        Sleep(50)
    WEnd
    GUIDelete()
EndFunc   ;==>_MainLoop

Func _RegisterMyCommand()
    GUIRegisterMsg(0x555, '_COMMAND_555')
    GUIRegisterMsg(0xC400, '_COMMAND_AI_WinGetHandle')
    GUIRegisterMsg(0xC401, '_COMMAND_AI_GetDesktopWindow')
    GUIRegisterMsg(0xC402, '_COMMAND_AI_WinGetProcess')
    GUIRegisterMsg(0xC403, '_COMMAND_AI_WinGetProcessCM')
    GUIRegisterMsg(0xC404, '_COMMAND_AI_WinGetState')
    GUIRegisterMsg(0xC405, '_COMMAND_AI_WinSetOnTop')
    GUIRegisterMsg(0xC406, '_COMMAND_AI_WinSetTrans')
    GUIRegisterMsg(0xC407, '_COMMAND_AI_MouseWheelScrollEvent')
    GUIRegisterMsg(0xC408, '_COMMAND_AI_MouseWheelScrollEventUpDown')
    GUIRegisterMsg(0xC409, '_COMMAND_AI_MouseMoveEvent')
    
    GUIRegisterMsg(0xC420, '_COMMAND_AI_SETREGION')
    GUIRegisterMsg(0xC421, '_COMMAND_AI_GREYSCALE')
    GUIRegisterMsg(0xC422, '_COMMAND_AI_DRAMCONTRAST')

    ; Если регистрировать по имени. CM не может слать имя :-((
    ;$Code_AI_SETREGION = _WinAPI_RegisterWindowMessage('AI_SETREGION')
    ;ConsoleWrite('AI_SETREGION  ' & $Code_AI_SETREGION & @CRLF)
    ;GUIRegisterMsg('AI_SETREGION', '_COMMAND_SETREGION')
EndFunc   ;==>_RegisterMyCommand


#Region    **** COMMANDS function ****

Func _COMMAND_555($hWnd, $iMsg, $iwParam, $ilParam)
    #forceref $hWnd, $iMsg
    Local $hWndFrom, $iIDFrom, $iCode, $iLW, $iHW

    ConsoleWrite('$iMsg ' & $iMsg & @CRLF)
    ConsoleWrite($hWnd & '  ' & _
                Hex(Int($iMsg), 4) & ' (555)  ' & _
                $iwParam & '  ' & _
                $ilParam & _
                @CRLF)
    $hWndFrom = $ilParam
    $iLW = BitAND($iwParam, 0xFFFF) ; младшее слово
    $iHW = BitShift($iwParam, 16) ; старшее слово

    _SendCM(0x555, 1)  ; Ok
    ;Switch $hWndFrom
    ;    Case $hGUImain
    ;        Switch $iCode
    ;            Case 500
    ;                ConsoleWrite('Есть!')
    ;        EndSwitch
    ;EndSwitch
    ; Продолжение обработчика внутренних команд AutoIt3.
    ; Вы также можете завершить, используя строку с выходом из функции.
    ; !!! Но только 'Return' (без значения) без продолжения
    ; обработчика внутренних команд AutoIt3 в дальнейшем !!!
    Return $GUI_RUNDEFMSG
EndFunc   ;==>_COMMAND_555

Func _COMMAND_AI_WinGetHandle($hWnd, $iMsg, $iwParam, $ilParam)
    #forceref $hWnd, $iMsg
    Local $freturn = 0, $ftitle = '', $ftext = ''

    $ftitle = IniRead($fileini, 'window', 'title', '')
    $ftext = IniRead($fileini, 'window', 'text', '')
    If $ftitle <> '' Then
        $freturn = WinGetHandle($ftitle, $ftext)
        If @error or $freturn = '' Then
            $freturn = 0
        Else
            ConsoleWrite('WinGetHandle   hWnd = ' & $freturn & @CRLF)
        EndIf
    EndIf
    _SendCM($freturn, 0xC400)
    ; old ini
    ; IniWrite($fileini, 'main', 'return', $freturn)  ; return
    ; IniWrite($fileini, 'main', 'completion', 1)  ; Ok
EndFunc   ;==>_COMMAND_AI_WinGetHandle

Func _COMMAND_AI_GetDesktopWindow($hWnd, $iMsg, $iwParam, $ilParam)
    #forceref $hWnd, $iMsg
    Local $freturn = 0

    $freturn = _WinAPI_GetDesktopWindow()
    ConsoleWrite('GetDesktopWindow   hWnd = ' & $freturn & @CRLF)
    _SendCM($freturn, 0xC401)
EndFunc   ;==>_COMMAND_AI_GetDesktopWindow

Func _COMMAND_AI_WinGetProcess($hWnd, $iMsg, $iwParam, $ilParam)
    #forceref $hWnd, $iMsg
    Local $freturn = 0, $ftitle = '', $ftext = '', $fhwnd

    $ftitle = IniRead($fileini, 'window', 'title', '')
    $ftext = IniRead($fileini, 'window', 'text', '')
    If $ftitle <> '' Then
        $fhwnd = HWnd(Int($ftitle))
        If Not @error Then
            $ftitle = $fhwnd
        EndIf
        $freturn = WinGetProcess($ftitle, $ftext)
        If @error or $freturn = '' Then
            $freturn = 0
        Else
            ConsoleWrite('WinGetProcess   PID = ' & $freturn & @CRLF)
        EndIf
    EndIf
    _SendCM($freturn, 0xC402)
EndFunc   ;==>_COMMAND_AI_WinGetProcess

Func _COMMAND_AI_WinGetProcessCM($hWnd, $iMsg, $iwParam, $ilParam)
    #forceref $hWnd, $iMsg

    If Not _IsWinCM() Then $iPidCM = 0
    _SendCM($iPidCM, 0xC403)
EndFunc   ;==>_COMMAND_AI_WinGetProcessCM

Func _COMMAND_AI_WinGetState($hWnd, $iMsg, $iwParam, $ilParam)
    #forceref $hWnd, $iMsg
    Local $freturn = 0, $ftitle = '', $ftext = '', $fhwnd
    ;Local $fEXIST, $fSHOW, $fENABLE, $fACTIVE, $fMINIMIZE, $fMAXIMIZE

    $ftitle = IniRead($fileini, 'window', 'title', '')
    $ftext = IniRead($fileini, 'window', 'text', '')
    If $ftitle <> '' Then
        $fhwnd = HWnd(Int($ftitle))
        If Not @error Then
            $ftitle = $fhwnd
        EndIf
        $freturn = WinGetState($ftitle, $ftext)
        If @error or $freturn = '' Then
            $freturn = 0
        Else
            ConsoleWrite('WinGetState   hWnd = ' & $freturn & @CRLF)
            ConsoleWrite('EXIST = ' & BitAND($freturn, 1) & @CRLF)
            ConsoleWrite('SHOW = ' & BitAND($freturn, 2) & @CRLF)
            ConsoleWrite('ENABLE = ' & BitAND($freturn, 4) & @CRLF)
            ConsoleWrite('ACTIVE = ' & BitAND($freturn, 8) & @CRLF)
            ConsoleWrite('MINIMIZE = ' & BitAND($freturn, 16) & @CRLF)
            ConsoleWrite('MAXIMIZE = ' & BitAND($freturn, 32) & @CRLF)
        EndIf
    EndIf
    _SendCM($freturn, 0xC404)
EndFunc   ;==>_COMMAND_AI_WinGetState

Func _COMMAND_AI_WinSetOnTop($hWnd, $iMsg, $iwParam, $ilParam)
    #forceref $hWnd, $iMsg
    Local $fhwnd

    $fhwnd = HWnd($iwParam)
    If Not @error Then
        WinSetOnTop($fhwnd, '', $ilParam)
        _SendCM(0xC405, 1)
    Else
        _SendCM(0xC405, 2)
    EndIf
EndFunc   ;==>_COMMAND_AI_WinSetOnTop

Func _COMMAND_AI_WinSetTrans($hWnd, $iMsg, $iwParam, $ilParam)
    #forceref $hWnd, $iMsg
    Local $fhwnd, $res

    $fhwnd = HWnd($iwParam)
    If Not @error Then
        $res = WinSetTrans($fhwnd, '', $ilParam)
        ConsoleWrite($res & @CRLF)
        _SendCM(0xC406, 1)
    Else
        _SendCM(0xC406, 2)
    EndIf
EndFunc   ;==>_COMMAND_AI_WinSetTrans

Func _COMMAND_AI_MouseWheelScrollEvent($hWnd, $iMsg, $iwParam, $ilParam)
    #forceref $hWnd, $iMsg
    Local $fhwnd = 0, $res, $AI_on_off, $AI_BlockDefProc

    $AI_on_off = BitAND($ilParam, 0xFFFF) ; младшее слово
    $AI_BlockDefProc= BitShift($ilParam, 16) ; старшее слово
    If $iwParam > 0 Then
        $fhwnd = HWnd($iwParam)
    EndIf
    If @error Then
        $fhwnd = 0
    EndIf
    ; ConsoleWrite($AI_on_off & '  ' & $fhwnd & '  ' & $AI_BlockDefProc & @CRLF)

    If $AI_on_off Then
        _MouseSetOnEvent($MOUSE_WHEELSCROLL_EVENT, '_MouseWheelEvents', $fhwnd, $AI_BlockDefProc)
    Else
        _MouseSetOnEvent($MOUSE_WHEELSCROLL_EVENT)
        If $MouseWheelScrollEvent_Tooltip Then
            ToolTip('')
        EndIf
    EndIf
    If Not @error Then
        _SendCM(0xC407, 1)
    Else
        _SendCM(0xC407, 2)
    EndIf
EndFunc   ;==>_COMMAND_AI_MouseWheelScrollEvent

Func _COMMAND_AI_MouseWheelScrollEventUpDown($hWnd, $iMsg, $iwParam, $ilParam)
    #forceref $hWnd, $iMsg
    Local $fhwnd = 0, $res, $AI_on_off, $AI_BlockDefProc

    $AI_on_off = BitAND($ilParam, 0xFFFF) ; младшее слово
    $AI_BlockDefProc= BitShift($ilParam, 16) ; старшее слово
    If $iwParam > 0 Then
        $fhwnd = HWnd($iwParam)
    EndIf
    If @error Then
        $fhwnd = 0
    EndIf
    ; ConsoleWrite($AI_on_off & '  ' & $fhwnd & '  ' & $AI_BlockDefProc & @CRLF)

    If $AI_on_off Then
        _MouseSetOnEvent($MOUSE_WHEELSCROLLUP_EVENT, '_MouseWheelEvents_UpDown', $fhwnd, $AI_BlockDefProc)
        _MouseSetOnEvent($MOUSE_WHEELSCROLLDOWN_EVENT, '_MouseWheelEvents_UpDown', $fhwnd, $AI_BlockDefProc)
    Else
        _MouseSetOnEvent($MOUSE_WHEELSCROLLUP_EVENT)
        _MouseSetOnEvent($MOUSE_WHEELSCROLLDOWN_EVENT)
        If $MouseWheelScrollEvent_Tooltip Then
            ToolTip('')
        EndIf
    EndIf
    If Not @error Then
        _SendCM(0xC408, 1)
    Else
        _SendCM(0xC408, 2)
    EndIf
EndFunc   ;==>_COMMAND_AI_MouseWheelScrollEventUpDown

Func _COMMAND_AI_MouseMoveEvent($hWnd, $iMsg, $iwParam, $ilParam)
    #forceref $hWnd, $iMsg
    Local $fhwnd = 0, $res, $AI_on_off, $AI_BlockDefProc

    $AI_on_off = BitAND($ilParam, 0xFFFF) ; младшее слово
    $AI_BlockDefProc= BitShift($ilParam, 16) ; старшее слово
    If $iwParam > 0 Then
        $fhwnd = HWnd($iwParam)
    EndIf
    If @error Then
        $fhwnd = 0
    EndIf
    ; ConsoleWrite($AI_on_off & '  ' & $fhwnd & '  ' & $AI_BlockDefProc & @CRLF)

    If $AI_on_off Then
        _MouseSetOnEvent($MOUSE_MOVE_EVENT, '_MouseMoveEvents', $fhwnd, $AI_BlockDefProc)
    Else
        _MouseSetOnEvent($MOUSE_MOVE_EVENT)
        If $MouseMoveEvent_Tooltip Then
            ToolTip('')
        EndIf
    EndIf
    If Not @error Then
        _SendCM(0xC409, 1)
    Else
        _SendCM(0xC409, 2)
    EndIf
EndFunc   ;==>_COMMAND_AI_MouseMoveEvent


; ToDo
#CS
ToolTip Создаёт всплывающую подсказку в любом месте экрана
    https://autoit-script.ru/docs/functions/tooltip.htm

WinSetState Показать, скрыть, свернуть, развернуть, или восстановить окно
WinGetClassList Возвращает класс окна
_WinAPI_GetClassName  Возвращает класс окна по hWnd
WinExists
WinClose
WinMenuSelectItem Вызывает пункт меню окна


#include <Sound.au3>
_SoundPlay
_SoundStop

ControlGetHandle Возвращает внутренний указатель элемента
ControlCommand Высылает команду элементу
    https://autoit-script.ru/docs/functions/controlcommand.htm
ControlClick Эмулирует нажатие мыши на указанный элемент интерфейса
    Пример: нажимаем 2-ой экземпляр элемента "Button", содержащий текст "Finish"
    ControlClick("Моё окно", "", "[CLASS:Button; TEXT:Finish; INSTANCE:2]")

ControlSend Выслать строку символов в элемент
ControlDisable Отключает элемент, делая его серым, недоступным
ControlEnable Разблокировывает элемент (делает доступным)
ControlHide Скрыть элемент
ControlShow Отображает ранее скрытый элемент
ControlFocus Устанавливает фокус ввода указанному элементу окна
ControlMove Переместить элемент в пределах окна
ControlGetFocus Возвращает ControlRef# элемента, который имеет фокус ввода в указанном окне
ControlGetPos Возвращает координаты и размер элемента относительно окна
ControlGetText Возвращает текст из элемента
ControlSetText Устанавливает текст в элемент
ControlListView Высылает команду элементу ListView32
#CE



Func _COMMAND_AI_SETREGION($hWnd, $iMsg, $iwParam, $ilParam)
    #forceref $hWnd, $iMsg

    $x1 = BitAND($iwParam, 0xFFFF) ; младшее слово
    $y1 = BitShift($iwParam, 16) ; старшее слово
    $x2 = BitAND($ilParam, 0xFFFF) ; младшее слово
    $y2 = BitShift($ilParam, 16) ; старшее слово
    ;ConsoleWrite('(' & $x1 & ', ' & $y1 & ', ' & $x2 & ', ' & $y2 & ')' & @CRLF)
    ConsoleWrite($hWnd & '  ' & _
                Hex(Int($iMsg), 4) & ' (SETREGION)  ' & _
                $iwParam & '  ' & _
                $ilParam & '    ' & _
                '(' & $x1 & ', ' & $y1 & ', ' & $x2 & ', ' & $y2 & ')' & _
                @CRLF)
    If $x2 < $x1 Or $y2 < $y1 Or _
            $x1 > $xMax Or $x2 > $xMax Or _
            $y1 > $yMax Or $y2 > $yMax Or _
            $x1 < $xMin Or $x2 < $xMin Or _
            $y1 < $yMin Or $y2 < $yMin Then
        ConsoleWrite('Неправильные координаты' & @CRLF)
        _SendCM(0xC420, 2)
        Return
    EndIf
    _SendCM(0xC420, 1)  ; O
EndFunc   ;==>_COMMAND_AI_SETREGION

Func _COMMAND_AI_GREYSCALE($hWnd, $iMsg, $iwParam, $ilParam)
    #forceref $hWnd, $iMsg
    Local $fx1, $fy1, $fx2, $fy2

    $fx1 = BitAND($iwParam, 0xFFFF) ; младшее слово
    $fy1 = BitShift($iwParam, 16) ; старшее слово
    $fx2 = BitAND($ilParam, 0xFFFF)
    $fy2 = BitShift($ilParam, 16)
    ;ConsoleWrite('(' & $fx1 & ', ' & $fy1 & ', ' & $fx2 & ', ' & $fy2 & ')' & @CRLF)
    ConsoleWrite($hWnd & '  ' & _
                Hex(Int($iMsg), 4) & ' (GREYSCALE)  ' & _
                $iwParam & '  ' & _
                $ilParam & '    ' & _
                '(' & $fx1 & ', ' & $fy1 & ', ' & $fx2 & ', ' & $fy2 & ')' & _
                @CRLF)

    If Not _IsWinCM() Or $startBuf = 0 Or _
            $fx2 < $fx1 Or $fy2 < $fy1 Or _
            $fx1 > $xMax Or $fx2 > $xMax Or _
            $fy1 > $yMax Or $fy2 > $yMax Or _
            $fx1 < $xMin Or $fx2 < $xMin Or _
            $fy1 < $yMin Or $fy2 < $yMin Then
        ConsoleWrite('Неправильные координаты' & @CRLF)
        _SendCM(0xC421, 2)
        Return
    EndIf

    _ColormodeGreyscale($fx1, $fy1, $fx2, $fy2)
    If @error Then
        _SendCM(0xC421, 2)
        Return
    EndIf
    _SendCM(0xC421, 1)  ; Ok
EndFunc   ;==>_COMMAND_AI_GREYSCALE

Func _COMMAND_AI_DRAMCONTRAST($hWnd, $iMsg, $iwParam, $ilParam)
    #forceref $hWnd, $iMsg
    Local $mid_contr = BitAND($iwParam, 0xFFFFFFFF), $k_contr = BitAND($ilParam, 0xFFFFFFFF)

    ConsoleWrite($hWnd & '  ' & _
                Hex(Int($iMsg), 4) & ' (DRAMCONTRAST)  ' & _
                $iwParam & '  ' & _
                $ilParam & '    ' & _
                'mid_contr = ' & $mid_contr & ',    k_contr = ' & $k_contr & _
                @CRLF)

    If Not _IsWinCM() Or $startBuf = 0 Or _
            $x2 < $x1 Or $y2 < $y1 Or _
            $x1 > $xMax Or $x2 > $xMax Or _
            $y1 > $yMax Or $y2 > $yMax Or _
            $x1 < $xMin Or $x2 < $xMin Or _
            $y1 < $yMin Or $y2 < $yMin Then
        ConsoleWrite('Неправильные координаты' & @CRLF)
        _SendCM(0xC422, 2)
        Return
    EndIf

    _ColormodeDramContrast($x1, $y1, $x2, $y2, $mid_contr, $k_contr)
    If @error Then
        _SendCM(0xC422, 2)
        Return
    EndIf
    _SendCM(0xC422, 1)  ; Ok
EndFunc   ;==>_COMMAND_AI_DRAMCONTRAST

#EndRegion **** COMMANDS function ****


Func _Init()
    If @Compiled Then
        FileInstall('CMTools\settings_cme_default.ini', @ScriptDir & '\settings_cme.ini', 0)
        FileInstall('CMTools\logger.cms', @ScriptDir & '\logger.cms', 0)
        FileInstall('CMTools\CMTools_CMS.cms', @ScriptDir & '\CMTools_CMS.cms', 0)

        $fileini = @ScriptDir & '\settings_cme.ini'
    Else
        $fileini = @ScriptDir & '\CMTools\settings_cme.ini'
    EndIf
    _CheckINI()
    $CM_name = IniRead($fileini, 'clickermann', 'program_name', 'Clickermann')
    $CM_title = '[TITLE:' & $CM_name & '; W:310; H:194]'

    $WM_CMCOMMAND = Int(IniRead($fileini, 'clickermann', 'wm_cmcommand', 1024))

    $MouseWheelScrollEvent_Tooltip = Int(IniRead($fileini, 'other', 'MouseWheelScrollEvent_Tooltip', 0))
    $MouseMoveEvent_Tooltip = Int(IniRead($fileini, 'other', 'MouseMoveEvent_Tooltip', 0))
    _DefinitionMonitors()
EndFunc   ;==>_Init

Func _CheckINI()
    Local $temp
    $temp = IniRead($fileini, 'clickermann', 'program_name', 0)
    If @error Then
        MsgBox(4096, '', 'Произошла ошибка, отсутствует или повреждён файл settings_cme.ini', 2)
        ; FileInstall('CMTools\settings_cme_default.ini', @ScriptDir & '\settings_cme.ini', 1)
        Sleep(500)
        Exit
    EndIf
EndFunc   ;==>_CheckINI

Func _DefinitionMonitors()
    Local $Desktop, $sDataMonitor
    If $__MonitorList[0][0] == 0 Then
        _GetMonitors()
        ; Local $aDesk = WinGetPos('Program Manager')
        ; $DesktopWidth = $aDesk[2], $DesktopHeight = $aDesk[3]
        ; $xMax = $DesktopWidth - 1, $yMax = $DesktopHeight - 1
        $DesktopWidth = $__MonitorList[0][5]
        $DesktopHeight = $__MonitorList[0][6]
        $xMin = $__MonitorList[0][1]
        $yMin = $__MonitorList[0][2]
        $xMax = $__MonitorList[0][3] - 1
        $yMax = $__MonitorList[0][4] - 1

        ConsoleWrite('Desktop' & @CRLF)
        ConsoleWrite('    Min ' & $xMin & 'x' & $yMin & @CRLF)
        ConsoleWrite('    Max ' & $xMax & 'x' & $yMax & @CRLF)
        ConsoleWrite('    Width/Height ' & $DesktopWidth & 'x' & $DesktopHeight & @CRLF)

        For $mon = 1 To 4
            IniDelete($fileini, 'main' , 'monitor_' & $mon)
        Next

        $Desktop = ''
        For $i = 0 To 6
            if $i > 0 Then $Desktop &= ':'
            $Desktop &= $__MonitorList[0][$i]
        Next
        IniWrite($fileini, 'main', 'desktop', $Desktop)

        For $mon = 1 To $__MonitorList[0][0]
            $sDataMonitor = ''
            For $i = 0 To 6
                if $i > 0 Then $sDataMonitor &= ':'
                $sDataMonitor &= $__MonitorList[$mon][$i]
            Next
            IniWrite($fileini, 'main', 'monitor_' & $mon, $sDataMonitor)
        Next
        ; _ArrayDisplay($__MonitorList, 'Monitors', Default, Default, '|', 'hMonitor|left|top|right|bottom|width|height')
    EndIf
EndFunc   ;==>_DefinitionMonitors

Func _WaitCM()
    $hWndCM = WinWait($CM_title, '', 3)
    $repeated = False
    If Not _IsWinCM() Then
        MsgBox(16+4096, 'Внимание!', 'Окно Clickermann не найдено.' & @CRLF & 'Дополнительный функционал не подключен!', 3)
        SetError(1)
        Exit
    EndIf
EndFunc   ;==>WaitCM

Func _IsWinCM()
    $hWndCMM = _GetWin('базовое', '[CLASS:TApplication; TITLE:' & $CM_name & '; W:0; H:0]')
    $hWndCM = _GetWin('главное', $CM_title)
    If $hWndCMM And $hWndCM Then
        if Not $repeated Then
            $hWndCMR = _GetWin('редактора', '[TITLE:Редактор -]')
            ;_WinAPI_GetWindowThreadProcessId($hWndCM, $iPidCM2)

            $iPidCM = WinGetProcess($hWndCM)
            ; ConsoleWrite('Идентификатор PID ' & $iPidCM & @CRLF)

            _GetVersionCM()
        EndIf
        $repeated = True
        return True
    Else
        $hWndCMM = ''
        $hWndCM = ''
        $hWndCMR = ''
        $iPidCM = ''
        return False
    EndIf
EndFunc   ;==>_IsWinCM

Func _GetVersionCM()
    ; Local $versionCMself = IniRead($fileini, 'clickermann', 'versionCM', '')  ; '4.13.014'
    Local $pathFileCM = _WinAPI_GetProcessFileName($iPidCM)
    ; Local $pathFileCM = _WinAPI_GetWindowFileName($hWndCMM)
    Local $FileSize = FileGetSize($pathFileCM)
    Local $FileVersion = FileGetVersion($pathFileCM)

    Switch $FileSize
        Case 1773568
            $versionFullCM = '4.13.014x32'
        Case 2554368
            $versionFullCM = '4.13.014x64'
        Case 2002432
            $versionFullCM = '4.14.003bx32'
        Case Else
            $versionFullCM = ''
    EndSwitch
    IniWrite($fileini, 'clickermann', 'versionCMfull', $versionFullCM)

    ; ConsoleWrite($pathFileCM & @CRLF)
    ; ConsoleWrite('Размер файла в байтах ' & $FileSize & @CRLF)  ;2554368
    ; ConsoleWrite('Version ' & $FileVersion & @CRLF)  ;4.13.0.0
    ConsoleWrite('Version Full CM ' & $versionFullCM & @CRLF & @CRLF)
EndFunc   ;==>_GetVersionCM

Func _WM_CLOSE($hWnd, $iMsg, $iwParam, $ilParam)
    GUIDelete($hGUImain)
    DllClose($hDLLkernel32)
    Exit
EndFunc   ;==>_WM_CLOSE

Func _GetWin($type, $data)
    Local $hWndt = WinGetHandle($data), $text
    if Not $repeated Then
        If $hWndt Then
            $text = 'окно ' & $type & ' существует  ' & $hWndt & @CRLF
        Else
            $text = 'окно ' & $type & ' НЕ существует' & @CRLF
        EndIf
        ConsoleWrite($text)
    EndIf
    Return $hWndt
EndFunc   ;==>_GetWin

Func _SendCM($wParam, $lParam)
    ; Ответы
    ; (код_команды, команда)
    ; (1, 1) - Ok, команда выполнена успешно
    ; (2, 1) - Error, команда выполнена неудачно
    _SendMessage($hWndCM, $WM_CMCOMMAND, $wParam, $lParam)
    If @error Then
        MsgBox(4096, '_SendCM', '_SendMessage Error: ' & @error)
        Exit
    EndIf
EndFunc   ;==>_SendCM

Func _OpenProcess($ah_Handle, $iAccess, $fInherit, $iProcessID)
    Local $aResult = DllCall($ah_Handle, 'handle', 'OpenProcess', 'dword', $iAccess, 'bool', $fInherit, 'dword', $iProcessID)
    If @error Then Return SetError(@error, @extended, 0)
    If $aResult[0] Then Return $aResult[0]
    Return 0
EndFunc   ;==>_OpenProcess

Func _CalculateBuffer()
    Local $hProcess
    Local $pointer
    Local $lenPxl, $lenXBite, $tagSTRUCT, $tClrStruct, $pClrStruct
    Local $tBf = DllStructCreate('DWORD')
    Local $iAddressCM, $offset

    ;$hProcess = _WinAPI_OpenProcess($PROCESS_ALL_ACCESS, 0, $iPidCM)
    $hProcess = _OpenProcess($hDLLkernel32, $PROCESS_ALL_ACCESS, 0, $iPidCM)
    If Not $hProcess Then
        ConsoleWrite('Не удалось открыть память тестовой программы' & @CRLF)
        SetError(1)
        Return
    EndIf

    If $versionFullCM = '4.13.014x32' Then
        $iAddressCM = 0x00655BB8
        $offset = 0x1C

        #cs
        iAddressCM  00655BB8
        pointer  034CFCC0
        startBuf  057B0000
        Screen 1 line  0662D100
        color  FFFA0000   RGB  250  0  0
        #ce

        ConsoleWrite('iAddressCM  ' & Hex($iAddressCM, 8) & @CRLF)

        ; Читаем адрес начала буфера в указателе
        DllCall($hDLLkernel32, 'bool', 'ReadProcessMemory', 'handle', $hProcess, _
                'ptr', $iAddressCM, 'ptr', DllStructGetPtr($tBf), 'ulong_ptr', 4, 'ulong_ptr*', 0)
        $pointer = DllStructGetData($tBf, 1)
        ConsoleWrite('pointer  ' & Hex($pointer, 8) & @CRLF)  ; 034CFCC0

        DllCall($hDLLkernel32, 'bool', 'ReadProcessMemory', 'handle', $hProcess, _
                'ptr', $pointer + $offset, 'ptr', DllStructGetPtr($tBf), 'ulong_ptr', 4, 'ulong_ptr*', 0)
        $startBuf = DllStructGetData($tBf, 1)
        ConsoleWrite('startBuf  ' & Hex($startBuf, 8) & @CRLF)  ; 057B0000
    ElseIf $versionFullCM = '4.13.014x64' Then
        $iAddressCM = 0x007CC6F0
        $offset = 0x24

        #cs
        iAddressCM  007CC6F0
        pointer  0298D730
        startBuf  05130000
        Screen 1 line  05FAD100
        color  FFFA0000   RGB  250  0  0
        #ce

        ConsoleWrite('iAddressCM  ' & Hex($iAddressCM, 8) & @CRLF)

        ; Читаем адрес начала буфера в указателе
        DllCall($hDLLkernel32, 'bool', 'ReadProcessMemory', 'handle', $hProcess, _
                'ptr', $iAddressCM, 'ptr', DllStructGetPtr($tBf), 'ulong_ptr', 4, 'ulong_ptr*', 0)
        $pointer = DllStructGetData($tBf, 1)
        ConsoleWrite('pointer  ' & Hex($pointer, 8) & @CRLF)  ; 0298D730

        DllCall($hDLLkernel32, 'bool', 'ReadProcessMemory', 'handle', $hProcess, _
                'ptr', $pointer + $offset, 'ptr', DllStructGetPtr($tBf), 'ulong_ptr', 4, 'ulong_ptr*', 0)
        $startBuf = DllStructGetData($tBf, 1)
        ConsoleWrite('startBuf  ' & Hex($startBuf, 8) & @CRLF)  ; 05130000
    ElseIf $versionFullCM = '4.14.003bx32' Then
        $iAddressCM = 0x0065FC20
        $offset = 0x1C

        #cs
        iAddressCM  0065FC20
        pointer  0296FCC0
        startBuf  05090000
        Screen 1 line  0662D100
        color  FFFA0000   RGB  250  0  0
        #ce

        ConsoleWrite('iAddressCM  ' & Hex($iAddressCM, 8) & @CRLF)

        ; Читаем адрес начала буфера в указателе
        DllCall($hDLLkernel32, 'bool', 'ReadProcessMemory', 'handle', $hProcess, _
                'ptr', $iAddressCM, 'ptr', DllStructGetPtr($tBf), 'ulong_ptr', 4, 'ulong_ptr*', 0)
        $pointer = DllStructGetData($tBf, 1)
        ConsoleWrite('pointer  ' & Hex($pointer, 8) & @CRLF)  ; 0296FCC0

        DllCall($hDLLkernel32, 'bool', 'ReadProcessMemory', 'handle', $hProcess, _
                'ptr', $pointer + $offset, 'ptr', DllStructGetPtr($tBf), 'ulong_ptr', 4, 'ulong_ptr*', 0)
        $startBuf = DllStructGetData($tBf, 1)
        ConsoleWrite('startBuf  ' & Hex($startBuf, 8) & @CRLF)  ; 05090000
    Else
        $startBuf = 0
    EndIf

    If ProcessExists($iPidCM) Then
        DllCall($hDLLkernel32, 'bool', 'CloseHandle', 'handle', $hProcess)
    EndIf
EndFunc   ;==>_CalculateBuffer



#Region    **** Realization  function ****

Func _MouseMoveEvents($iEvent)
    _SendCM(1, 0xC409)
    If $MouseMoveEvent_Tooltip Then
        ToolTip('Перемещение мыши', Default, Default, 'MouseMove', 1)
    EndIf
EndFunc

Func _MouseWheelEvents($iEvent)
    _SendCM(1, 0xC407)
    If $MouseWheelScrollEvent_Tooltip Then
        ToolTip('Прокручивание колёсика', Default, Default, 'MouseWheel', 1)
    EndIf
EndFunc

Func _MouseWheelEvents_UpDown($iEvent)
    Switch $iEvent
        Case $MOUSE_WHEELSCROLLUP_EVENT
            _SendCM(2, 0xC408)
            If $MouseWheelScrollEvent_Tooltip Then
                ToolTip('Прокручивание колёсика ВВЕРХ', Default, Default, 'Up', 1)
            EndIf
        Case $MOUSE_WHEELSCROLLDOWN_EVENT
            _SendCM(3, 0xC408)
            If $MouseWheelScrollEvent_Tooltip Then
                ToolTip('Прокручивание колёсика ВНИЗ', Default, Default, 'Down', 1)
            EndIf
    EndSwitch
    ;Return $MOE_BLOCKDEFPROC ;Block
EndFunc

Func _ToggleMonitor($hwnd, $OnOff)
    Local Const $WM_SYSCOMMAND = 274
    Local Const $SC_MONITORPOWER = 61808
    _SendMessage($hWnd, $WM_SYSCOMMAND, $SC_MONITORPOWER, $OnOff)
    If @error Then
        MsgBox(4096, '_ToggleMonitor', '_SendMessage Error: ' & @error)
        Exit
    EndIf
EndFunc   ;==>_ToggleMonitor

Func _ColormodeGreyscale($fx1, $fy1, $fx2, $fy2)
    Local $hProcess
    Local $lenPxl, $lenXBite, $tagSTRUCT, $tClrStruct, $pClrStruct
    Local $yFull, $addrWrStruct
    Local $color, $R, $G, $B, $A
    Local $gray_canal
    Local $bFullScreen = False
    Local $lenXPxl = $fx2 - $fx1 + 1, $lenYPxl = $fy2 - $fy1 + 1
    Local $startBufRd = $startBuf + _
                (($DesktopWidth * ($yMax - $fy2)) * 4) + _
                ($fx1 * 4)

    ; Local $hTimer = TimerInit()
    $hProcess = _OpenProcess($hDLLkernel32, $PROCESS_ALL_ACCESS, 0, $iPidCM)
    If Not $hProcess Then
        ConsoleWrite('Не удалось открыть память тестовой программы' & @CRLF)
        SetError(1)
        Return
    EndIf

    $lenPxl = (($lenYPxl - 1) * $DesktopWidth) + $lenXPxl
    $lenXBite = $lenPxl * 4
    $tagSTRUCT = 'DWORD[' & $lenPxl &']'
    $tClrStruct = DllStructCreate($tagSTRUCT)
    $pClrStruct = DllStructGetPtr($tClrStruct)
    DllCall($hDLLkernel32, 'bool', 'ReadProcessMemory', 'handle', $hProcess, _
            'ptr', $startBufRd, 'ptr', $pClrStruct, 'ulong_ptr', $lenXBite, 'ulong_ptr*', 0)

    If $fx1 = $xMin And $fy1 = $yMin And $fx2 = $xMax And $fy2 = $yMax Then $bFullScreen = True
    If $bFullScreen Then
        ; ConsoleWrite('Весь экран' & @CRLF)
        For $x = 1 To $lenPxl
            $color = DllStructGetData($tClrStruct, 1, $x)
            $B = BitAND($color, 0xFF)
            $G = BitAND(BitShift($color, 8), 0xFF)
            $R = BitAND(BitShift($color, 16), 0xFF)
            ;ConsoleWrite('color  ' & $color & '   RGB  ' & _
            ;            $R & '  ' & $G & '  ' & $B & '  ' & @CRLF)

            #Region    ************ Обработка Greyscale ************
            $gray_canal = Int(0.299*$R + 0.587*$G + 0.114*$B)
            $color = 0xFF*0x1000000 + $gray_canal*0x10000 + $gray_canal*0x100 + $gray_canal
            #EndRegion ************ Обработка Greyscale ************

            DllStructSetData($tClrStruct, 1, $color, $x)
        Next
    Else
        ; ConsoleWrite('Построчно' & @CRLF)
        For $y = 0 To $lenYPxl - 1
            $yFull = $y * $DesktopWidth
            For $x = 0 To $lenXPxl - 1
                $addrWrStruct = $yFull + $x + 1
                $color = DllStructGetData($tClrStruct, 1, $addrWrStruct)
                $B = BitAND($color, 0xFF)
                $G = BitAND(BitShift($color, 8), 0xFF)
                $R = BitAND(BitShift($color, 16), 0xFF)
                ;ConsoleWrite('color  ' & $color & '   RGB  ' & _
                ;            $R & '  ' & $G & '  ' & $B & '  ' & @CRLF)

                #Region    ************ Обработка ************
                $gray_canal = Int(0.299*$R + 0.587*$G + 0.114*$B)
                $color = 0xFF*0x1000000 + $gray_canal*0x10000 + $gray_canal*0x100 + $gray_canal
                #EndRegion ************ Обработка ************

                DllStructSetData($tClrStruct, 1, $color, $addrWrStruct)
            Next
        Next
    EndIf
    DllCall($hDLLkernel32, 'bool', 'WriteProcessMemory', 'handle', $hProcess, _
            'ptr', $startBufRd, 'ptr', $pClrStruct, 'ulong_ptr', $lenXBite, 'ulong_ptr*', 0)

    If ProcessExists($iPidCM) Then
        DllCall($hDLLkernel32, 'bool', 'CloseHandle', 'handle', $hProcess)
    EndIf
    ; ConsoleWrite('Время выполнения  ' & TimerDiff($hTimer) & ' ms' & @CRLF)
EndFunc   ;==>_ColormodeGreyscale_5

Func _ColormodeDramContrast($fx1, $fy1, $fx2, $fy2, $fmid_contr, $fk_contr)
    Local $hProcess
    Local $lenPxl, $lenXBite, $tagSTRUCT, $tClrStruct, $pClrStruct
    Local $yFull, $addrWrStruct
    Local $color, $R, $G, $B, $A
    Local $bFullScreen = False
    Local $lenXPxl = $fx2 - $fx1 + 1, $lenYPxl = $fy2 - $fy1 + 1
    Local $startBufRd = $startBuf + _
                (($DesktopWidth * ($yMax - $fy2)) * 4) + _
                ($fx1 * 4)

    ;Local $hTimer = TimerInit()
    $hProcess = _OpenProcess($hDLLkernel32, $PROCESS_ALL_ACCESS, 0, $iPidCM)
    If Not $hProcess Then
        ConsoleWrite('Не удалось открыть память тестовой программы' & @CRLF)
        SetError(1)
        Return
    EndIf

    ConsoleWrite('(' & $fx1 & ', ' & $fy1 & ', ' & $fx2 & ', ' & $fy2 & ')   ' & _
                'mid_contr = ' & $fmid_contr & ',  k_contr = ' & $fk_contr & @CRLF)

    $lenPxl = (($lenYPxl - 1) * $DesktopWidth) + $lenXPxl
    $lenXBite = $lenPxl * 4
    $tagSTRUCT = 'DWORD[' & $lenPxl &']'
    $tClrStruct = DllStructCreate($tagSTRUCT)
    $pClrStruct = DllStructGetPtr($tClrStruct)
    DllCall($hDLLkernel32, 'bool', 'ReadProcessMemory', 'handle', $hProcess, _
            'ptr', $startBufRd, 'ptr', $pClrStruct, 'ulong_ptr', $lenXBite, 'ulong_ptr*', 0)

    If $fx1 = $xMin And $fy1 = $yMin And $fx2 = $xMax And $fy2 = $yMax Then $bFullScreen = True
    If $bFullScreen Then
        ; ConsoleWrite('Весь экран' & @CRLF)
        For $x = 1 To $lenPxl
            $color = DllStructGetData($tClrStruct, 1, $x)
            $B = BitAND($color, 0xFF)
            $G = BitAND(BitShift($color, 8), 0xFF)
            $R = BitAND(BitShift($color, 16), 0xFF)
            ;ConsoleWrite('color  ' & $color & '   RGB  ' & _
            ;            $R & '  ' & $G & '  ' & $B & '  ' & @CRLF)

            #Region    ************ Обработка DramContrast ************
            If (($R + $G + $B) / 3) > $fmid_contr Then
                $R = $R + $fk_contr
                $G = $G + $fk_contr
                $B = $B + $fk_contr
                If $R < $fmid_contr Then
                    $R = $fmid_contr
                EndIf
                If $G < $fmid_contr Then
                    $G = $fmid_contr
                EndIf
                If $B < $fmid_contr Then
                    $B = $fmid_contr
                EndIf
                If $R > 255 Then
                    $R = 255
                EndIf
                If $G > 255 Then
                    $G = 255
                EndIf
                If $B > 255 Then
                    $B = 255
                EndIf
            Else
                $R = $R - $fk_contr
                $G = $G - $fk_contr
                $B = $B - $fk_contr
                If $R > $fmid_contr Then
                    $R = $fmid_contr
                EndIf
                If $G > $fmid_contr Then
                    $G = $fmid_contr
                EndIf
                If $B > $fmid_contr Then
                    $B = $fmid_contr
                EndIf
                If $R < 0 Then
                    $R = 0
                EndIf
                If $G < 0 Then
                    $G = 0
                EndIf
                If $B < 0 Then
                    $B = 0
                EndIf
            EndIf
            $color = 0xFF*0x1000000 + $R*0x10000 + $G*0x100 + $B
            #EndRegion ************ Обработка DramContrast ************

            DllStructSetData($tClrStruct, 1, $color, $x)
        Next
    Else
        ; ConsoleWrite('Построчно' & @CRLF)
        For $y = 0 To $lenYPxl - 1
            $yFull = $y * $DesktopWidth
            For $x = 0 To $lenXPxl - 1
                $addrWrStruct = $yFull + $x + 1
                $color = DllStructGetData($tClrStruct, 1, $addrWrStruct)
                $B = BitAND($color, 0xFF)
                $G = BitAND(BitShift($color, 8), 0xFF)
                $R = BitAND(BitShift($color, 16), 0xFF)
                ;ConsoleWrite('color  ' & $color & '   RGB  ' & _
                ;            $R & '  ' & $G & '  ' & $B & '  ' & @CRLF)

                #Region    ************ Обработка ************
                If (($R + $G + $B) / 3) > $fmid_contr Then
                    $R = $R + $fk_contr
                    $G = $G + $fk_contr
                    $B = $B + $fk_contr
                    If $R < $fmid_contr Then
                        $R = $fmid_contr
                    EndIf
                    If $G < $fmid_contr Then
                        $G = $fmid_contr
                    EndIf
                    If $B < $fmid_contr Then
                        $B = $fmid_contr
                    EndIf
                    If $R > 255 Then
                        $R = 255
                    EndIf
                    If $G > 255 Then
                        $G = 255
                    EndIf
                    If $B > 255 Then
                        $B = 255
                    EndIf
                Else
                    $R = $R - $fk_contr
                    $G = $G - $fk_contr
                    $B = $B - $fk_contr
                    If $R > $fmid_contr Then
                        $R = $fmid_contr
                    EndIf
                    If $G > $fmid_contr Then
                        $G = $fmid_contr
                    EndIf
                    If $B > $fmid_contr Then
                        $B = $fmid_contr
                    EndIf
                    If $R < 0 Then
                        $R = 0
                    EndIf
                    If $G < 0 Then
                        $G = 0
                    EndIf
                    If $B < 0 Then
                        $B = 0
                    EndIf
                EndIf
                $color = 0xFF*0x1000000 + $R*0x10000 + $G*0x100 + $B
                #EndRegion ************ Обработка ************

                DllStructSetData($tClrStruct, 1, $color, $addrWrStruct)
            Next
        Next
    EndIf
    DllCall($hDLLkernel32, 'bool', 'WriteProcessMemory', 'handle', $hProcess, _
            'ptr', $startBufRd, 'ptr', $pClrStruct, 'ulong_ptr', $lenXBite, 'ulong_ptr*', 0)

    If ProcessExists($iPidCM) Then
        DllCall($hDLLkernel32, 'bool', 'CloseHandle', 'handle', $hProcess)
    EndIf
    ;ConsoleWrite('Время выполнения  ' & TimerDiff($hTimer) & ' ms' & @CRLF)
EndFunc   ;==>_ColormodeDramContrast

#EndRegion **** Realization  function ****


; ≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡

;~ WM_User = 0x400 (1024)
;~ Стандартные сообщения до WM_User-1.     от              0   до  0x03FF (1023)
;~ Локальные сообщения от WM_User          от  0x0400  (1024)  до  0x7FFF (32767)
;~ Глобальные сообщения                    от  0xC000 (49152)  до  0xFFFF (65535)


;ExitLoop(1)
;Binary('0x' & '4D5A00000000')

;~ $hControl = ControlGetHandle($hWnd, '', '[CLASS:Button; TEXT:OK]')
;~ ControlClick($hWnd, '', $hControl, 'main')

