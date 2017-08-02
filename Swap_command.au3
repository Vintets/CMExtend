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
    GUIRegisterMsg(0xC400, '_COMMAND_GET_PIDCM')
    GUIRegisterMsg(0xC401, '_COMMAND_SETREGION')
    GUIRegisterMsg(0xC402, '_COMMAND_GREYSCALE')

    ; Если регистрировать по имени. CM не может слать имя :-((
    ;$Code_MY_SETREGION = _WinAPI_RegisterWindowMessage('MY_SETREGION')
    ;ConsoleWrite('MY_SETREGION  ' & $Code_MY_SETREGION & @CRLF)
    ;GUIRegisterMsg('MY_SETREGION', '_COMMAND_SETREGION')
EndFunc   ;==>_RegisterMyCommand

Func _COMMAND_555($hWnd, $iMsg, $iwParam, $ilParam)
    #forceref $hWnd, $iMsg
    Local $hWndFrom, $iIDFrom, $iCode

    ConsoleWrite($hWnd & '  ' & Hex(Int($iMsg), 4) & '  ' & $iwParam & '  ' & $ilParam & @CRLF)
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

Func _COMMAND_GET_PIDCM($hWnd, $iMsg, $iwParam, $ilParam)
    #forceref $hWnd, $iMsg

    ConsoleWrite($hWnd & '  ' & _
                Hex(Int($iMsg), 4) & ' (GET_PIDCM)  ' & _
                $iwParam & '  ' & _
                $ilParam & _
                @CRLF)
    _IsWinCM()
    IniWrite($fileini, 'clickermann', 'CMPID', $iPidCM)  ; Записываем в ini $iPidCM
    IniWrite($fileini, 'clickermann', 'completion', 1)  ; Ok
EndFunc   ;==>_COMMAND_GET_PIDCM

Func _COMMAND_SETREGION($hWnd, $iMsg, $iwParam, $ilParam)
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
EndFunc   ;==>_COMMAND_SETREGION

Func _COMMAND_GREYSCALE($hWnd, $iMsg, $iwParam, $ilParam)
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
EndFunc   ;==>_COMMAND_GREYSCALE

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


