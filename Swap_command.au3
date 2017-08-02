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
    $hGUImain = GUICreate('��� GUI', 100, 50, 20, 20, $WS_OVERLAPPEDWINDOW + $WS_POPUP)
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

    ; ���� �������������� �� �����. CM �� ����� ����� ��� :-((
    ;$Code_MY_SETREGION = _WinAPI_RegisterWindowMessage('MY_SETREGION')
    ;ConsoleWrite('MY_SETREGION  ' & $Code_MY_SETREGION & @CRLF)
    ;GUIRegisterMsg('MY_SETREGION', '_COMMAND_SETREGION')
EndFunc   ;==>_RegisterMyCommand

Func _COMMAND_555($hWnd, $iMsg, $iwParam, $ilParam)
    #forceref $hWnd, $iMsg
    Local $hWndFrom, $iIDFrom, $iCode

    ConsoleWrite($hWnd & '  ' & Hex(Int($iMsg), 4) & '  ' & $iwParam & '  ' & $ilParam & @CRLF)
    $hWndFrom = $ilParam
    $iLW = BitAND($iwParam, 0xFFFF) ; ������� �����
    $iHW = BitShift($iwParam, 16) ; ������� �����

    ;Switch $hWndFrom
    ;    Case $hGUImain
    ;        Switch $iCode
    ;            Case 500
    ;                ConsoleWrite('����!')
    ;        EndSwitch
    ;EndSwitch
    ; ����������� ����������� ���������� ������ AutoIt3.
    ; �� ����� ������ ���������, ��������� ������ � ������� �� �������.
    ; !!! �� ������ 'Return' (��� ��������) ��� �����������
    ; ����������� ���������� ������ AutoIt3 � ���������� !!!
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
    IniWrite($fileini, 'clickermann', 'CMPID', $iPidCM)  ; ���������� � ini $iPidCM
    IniWrite($fileini, 'clickermann', 'completion', 1)  ; Ok
EndFunc   ;==>_COMMAND_GET_PIDCM

Func _COMMAND_SETREGION($hWnd, $iMsg, $iwParam, $ilParam)
    #forceref $hWnd, $iMsg

    $x1 = BitAND($iwParam, 0xFFFF) ; ������� �����
    $y1 = BitShift($iwParam, 16) ; ������� �����
    $x2 = BitAND($ilParam, 0xFFFF) ; ������� �����
    $y2 = BitShift($ilParam, 16) ; ������� �����
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

    $fx1 = BitAND($iwParam, 0xFFFF) ; ������� �����
    $fy1 = BitShift($iwParam, 16) ; ������� �����
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
    ;$hWndCMM = _GetWin('�������', '[CLASS:TApplication; TITLE:Clickermann -]')
    $hWndCM = _GetWin('�������', '[TITLE:Clickermann -]')
    $hWndCMR = _GetWin('���������', '[CLASS:TfrmEdit; TITLE:�������� -]')

    $iPidCM = WinGetProcess($hWndCM)
    ;_WinAPI_GetWindowThreadProcessId ($hWndCM, $iPidCM2)
    If $hWndCM <> '' Then
        $Available = True
        ConsoleWrite('������������� PID ' & $iPidCM & @CRLF)
    Else
        $Available = False
    EndIf
EndFunc   ;==>_IsWinCM

Func _GetWin($type, $data)
    Local $hWndt = WinGetHandle($data), $text
    If $hWndt <> '' Then
        $text = '���� ' & $type & ' ����������  ' & $hWndt & @CRLF
    Else
        $text = '���� ' & $type & ' �� ����������' & @CRLF
    EndIf
    ConsoleWrite($text)
    Return $hWndt
EndFunc   ;==>_GetWin

;~ WM_User = 0x400 (1024)
;~ ����������� ��������� �� WM_User-1.     ��              0   ��  0x03FF (1023)
;~ ��������� ��������� �� WM_User          ��  0x0400  (1024)  ��  0x7FFF (32767)
;~ ���������� ���������                    ��  0xC000 (49152)  ��  0xFFFF (65535)


