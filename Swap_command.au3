#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <Constants.au3>
#include <WindowsConstants.au3>
#include <WinAPI.au3>

Global $hGUImain
Global $x1, $y1, $x2, $y2
Global $hWndCMM = '', $hWndCM = '', $hWndCMR = '', $iPidCM = ''
Global $fileini = @ScriptDir & '\settings_cme.ini'
Global $Available = False

_IsWinCM()
Example1()

Func Example1()
    Local $Msg, $Code_MY_SETREGION
    $hGUImain = GUICreate('Мой GUI', 100, 50, 20, 20, $WS_OVERLAPPEDWINDOW + $WS_POPUP)
    GUISetState(@SW_SHOW)
    GUISetState(@SW_MINIMIZE)

    ConsoleWrite('$hGUImain  ' & $hGUImain & @CRLF)
    GUIRegisterMsg($WM_CLOSE, '_WM_CLOSE')
    _RegisterMyCommand()

    While 1
        $Msg = GUIGetMsg()
        Switch $Msg
            Case $GUI_EVENT_CLOSE
                ExitLoop
            Case Else
                ;ConsoleWrite('$Msg =  ' & $Msg & @CRLF)
        EndSwitch
        Sleep(50)
    WEnd
    GUIDelete()
EndFunc   ;==>Example1

Func _RegisterMyCommand()
    GUIRegisterMsg(0x555, '_COMMAND_555')
    GUIRegisterMsg(0xC400, '_COMMAND_AI_WinGetHandle')
    GUIRegisterMsg(0xC401, '_COMMAND_AI_GetDesktopWindow')
    GUIRegisterMsg(0xC402, '_COMMAND_AI_WinGetProcess')
    GUIRegisterMsg(0xC403, '_COMMAND_AI_WinGetProcessCM')
    GUIRegisterMsg(0xC404, '_COMMAND_AI_WinGetState')
    GUIRegisterMsg(0xC407, '_COMMAND_AI_WinSetOnTop')
    GUIRegisterMsg(0xC408, '_COMMAND_AI_WinSetTrans')
    
    GUIRegisterMsg(0xC450, '_COMMAND_AI_SETREGION')
    GUIRegisterMsg(0xC451, '_COMMAND_AI_GREYSCALE')

    ; Если регистрировать по имени. CM не может слать имя :-((
    ;$Code_AI_SETREGION = _WinAPI_RegisterWindowMessage('AI_SETREGION')
    ;ConsoleWrite('AI_SETREGION  ' & $Code_AI_SETREGION & @CRLF)
    ;GUIRegisterMsg('AI_SETREGION', '_COMMAND_SETREGION')
EndFunc   ;==>_RegisterMyCommand

Func _COMMAND_555($hWnd, $iMsg, $iwParam, $ilParam)
    #forceref $hWnd, $iMsg
    Local $hWndFrom, $iIDFrom, $iCode

    ConsoleWrite($hWnd & '  ' & _
                Hex(Int($iMsg), 4) & ' (555)  ' & _
                $iwParam & '  ' & _
                $ilParam & _
                @CRLF)
    $hWndFrom = $ilParam
    $iLW = BitAND($iwParam, 0xFFFF) ; младшее слово
    $iHW = BitShift($iwParam, 16) ; старшее слово

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
    Local $freturn = -1, $ftitle = '', $ftext = ''

    $ftitle = IniRead($fileini, 'clickermann', 'title', '')
    $ftext = IniRead($fileini, 'clickermann', 'text', '')
    If $ftitle <> '' Then
        $freturn = WinGetHandle($ftitle, $ftext)
        If @error or $freturn = '' Then
            $freturn = -1
        Else
            ConsoleWrite('WinGetHandle   hWnd = ' & $freturn & @CRLF)
        EndIf
    EndIf
    IniWrite($fileini, 'clickermann', 'return', $freturn)  ; return
    IniWrite($fileini, 'clickermann', 'completion', 1)  ; Ok
EndFunc   ;==>_COMMAND_AI_WinGetHandle

Func _COMMAND_AI_GetDesktopWindow($hWnd, $iMsg, $iwParam, $ilParam)
    #forceref $hWnd, $iMsg
    Local $freturn = -1

    $freturn = _WinAPI_GetDesktopWindow()
    ConsoleWrite('GetDesktopWindow   hWnd = ' & $freturn & @CRLF)
    IniWrite($fileini, 'clickermann', 'return', $freturn)  ; return
    IniWrite($fileini, 'clickermann', 'completion', 1)  ; Ok
EndFunc   ;==>_COMMAND_AI_GetDesktopWindow

Func _COMMAND_AI_WinGetProcess($hWnd, $iMsg, $iwParam, $ilParam)
    #forceref $hWnd, $iMsg
    Local $freturn = -1, $ftitle = '', $ftext = '', $fhwnd

    $ftitle = IniRead($fileini, 'clickermann', 'title', '')
    $ftext = IniRead($fileini, 'clickermann', 'text', '')
    If $ftitle <> '' Then
        $fhwnd = HWnd(Int($ftitle))
        If Not @error Then
            $ftitle = $fhwnd
        EndIf
        $freturn = WinGetProcess($ftitle, $ftext)
        If @error or $freturn = '' Then
            $freturn = -1
        Else
            ConsoleWrite('WinGetProcess   PID = ' & $freturn & @CRLF)
        EndIf
    EndIf
    IniWrite($fileini, 'clickermann', 'return', $freturn)  ; return
    IniWrite($fileini, 'clickermann', 'completion', 1)  ; Ok
EndFunc   ;==>_COMMAND_AI_WinGetProcess

Func _COMMAND_AI_WinGetProcessCM($hWnd, $iMsg, $iwParam, $ilParam)
    #forceref $hWnd, $iMsg

    _IsWinCM()
    IniWrite($fileini, 'clickermann', 'return', $iPidCM)  ; return
    IniWrite($fileini, 'clickermann', 'completion', 1)  ; Ok
EndFunc   ;==>_COMMAND_AI_WinGetProcessCM

Func _COMMAND_AI_WinGetState($hWnd, $iMsg, $iwParam, $ilParam)
    #forceref $hWnd, $iMsg
    Local $freturn = -1, $ftitle = '', $ftext = '', $fhwnd
    ;Local $fEXIST, $fSHOW, $fENABLE, $fACTIVE, $fMINIMIZE, $fMAXIMIZE

    $ftitle = IniRead($fileini, 'clickermann', 'title', '')
    $ftext = IniRead($fileini, 'clickermann', 'text', '')
    If $ftitle <> '' Then
        $fhwnd = HWnd(Int($ftitle))
        If Not @error Then
            $ftitle = $fhwnd
        EndIf
        $freturn = WinGetState($ftitle, $ftext)
        If @error or $freturn = '' Then
            $freturn = -1
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
    IniWrite($fileini, 'clickermann', 'return', $freturn)  ; return
    IniWrite($fileini, 'clickermann', 'completion', 1)  ; Ok
EndFunc   ;==>_COMMAND_AI_WinGetState

Func _COMMAND_AI_WinSetOnTop($hWnd, $iMsg, $iwParam, $ilParam)
    #forceref $hWnd, $iMsg
    Local $fhwnd

    $fhwnd = HWnd($iwParam)
    If Not @error Then
        WinSetOnTop($fhwnd, '', $ilParam)
    EndIf
EndFunc   ;==>_COMMAND_AI_WinSetOnTop

Func _COMMAND_AI_WinSetTrans($hWnd, $iMsg, $iwParam, $ilParam)
    #forceref $hWnd, $iMsg
    Local $fhwnd

    $fhwnd = HWnd($iwParam)
    If Not @error Then
        $res = WinSetTrans($fhwnd, '', $ilParam)
        ConsoleWrite($res & @CRLF)
    EndIf
EndFunc   ;==>_COMMAND_AI_WinSetTrans




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
;~     _COLORMODE_GREYSCALE($fx1, $fy1, $fx2, $fy2)
    IniWrite($fileini, 'clickermann', 'completion', 1)  ; Ok
EndFunc   ;==>_COMMAND_AI_GREYSCALE

Func _WM_CLOSE($hWnd, $iMsg, $iwParam, $ilParam)
    GUIDelete($hGUImain)
    Exit
EndFunc   ;==>_WM_CLOSE

Func _IsWinCM()
    ;$hWndCMM = _GetWin('базовое', '[CLASS:TApplication; TITLE:Clickermann -]')
    $hWndCM = _GetWin('главное', '[TITLE:Clickermann -]')
    $hWndCMR = _GetWin('редактора', '[CLASS:TfrmEdit; TITLE:Редактор -]')

    $iPidCM = WinGetProcess($hWndCM)
    ;_WinAPI_GetWindowThreadProcessId ($hWndCM, $iPidCM2)
    If $hWndCM <> '' Then
        $Available = True
        ConsoleWrite('Идентификатор PID ' & $iPidCM & @CRLF)
    Else
        $Available = False
    EndIf
EndFunc   ;==>_IsWinCM

Func _GetWin($type, $data)
    Local $hWndt = WinGetHandle($data), $text
    If $hWndt <> '' Then
        $text = 'окно ' & $type & ' существует  ' & $hWndt & @CRLF
    Else
        $text = 'окно ' & $type & ' НЕ существует' & @CRLF
    EndIf
    ConsoleWrite($text)
    Return $hWndt
EndFunc   ;==>_GetWin

;~ WM_User = 0x400 (1024)
;~ Стандартные сообщения до WM_User-1.     от              0   до  0x03FF (1023)
;~ Локальные сообщения от WM_User          от  0x0400  (1024)  до  0x7FFF (32767)
;~ Глобальные сообщения                    от  0xC000 (49152)  до  0xFFFF (65535)


