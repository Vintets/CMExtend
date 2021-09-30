#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=cmex.ico
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_Res_Comment=Swap_command
#AutoIt3Wrapper_Res_Fileversion=0.0.9
#AutoIt3Wrapper_Res_LegalCopyright=Vint
#AutoIt3Wrapper_Res_Language=1049
#AutoIt3Wrapper_Res_requestedExecutionLevel=None
#AutoIt3Wrapper_Res_Field=Version|0.0.9
#AutoIt3Wrapper_Res_Field=Build|2021.09.30
#AutoIt3Wrapper_Res_Field=Coded by|Vint
#AutoIt3Wrapper_Res_Field=Compile date|%longdate% %time%
#AutoIt3Wrapper_Res_Field=AutoIt Version|%AutoItVer%
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

;===============================================================================
;
; Description:      Swap_command
; Version:          0.0.9
; Requirement(s):   Autoit 3.3.14.5
; Author(s):        Vint
;
;===============================================================================

#Region    ************ Includes ************
#include <WinAPI.au3>
#include <SendMessage.au3>

#include <WindowsConstants.au3>
#include <Constants.au3>
#include <GUIConstantsEx.au3>
#EndRegion ************ Includes ************

#RequireAdmin

Global $CMExtendVersion = '0.0.9'
Global $hGUImain
Global $x1, $y1, $x2, $y2
Global $CM_name = ''
Global $hWndCMM = '', $hWndCM = '', $hWndCMR = '', $iPidCM = ''
Global $fileini = @ScriptDir & '\settings_cme.ini'
Global $repeated = False
Global $iAddressCM = 0x004E20FC
Global $WM_CMCOMMAND = 1024
Global $CM_title = ''



CreateCMTitle()
_WaitCM()
_MainLoop()

;~ Local $hTimer = TimerInit()
;~ _COLORMODE_GREYSCALE_OLD4(750, 426, 849, 525)
;~ _COLORMODE_GREYSCALE(750, 426, 849, 525)
;~ ConsoleWrite('Время выполнения  ' & TimerDiff($hTimer) & ' ms' & @CRLF)
;~ _SendCM(123, 456)

Func CreateCMTitle()
    $CM_name = IniRead($fileini, 'clickermann', 'program_name', 'Clickermann')
    $CM_title = '[TITLE:' & $CM_name & '; W:310; H:194]'
EndFunc   ;==>_MainLoop

Func _MainLoop()
    Local $Msg, $Code_MY_SETREGION
    $hGUImain = GUICreate('CMExtend v' & $CMExtendVersion, 100, 50, 20, 20, $WS_OVERLAPPEDWINDOW + $WS_POPUP)
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
    GUIRegisterMsg(0xC407, '_COMMAND_AI_WinSetOnTop')
    GUIRegisterMsg(0xC408, '_COMMAND_AI_WinSetTrans')
    ; GUIRegisterMsg(0xC409, '_COMMAND_AI_Win777')
    
    GUIRegisterMsg(0xC450, '_COMMAND_AI_SETREGION')
    GUIRegisterMsg(0xC451, '_COMMAND_AI_GREYSCALE')
    GUIRegisterMsg(0xC452, '_COMMAND_AI_DRAMCONTRAST')

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
    _COLORMODE_GREYSCALE($fx1, $fy1, $fx2, $fy2)
    IniWrite($fileini, 'clickermann', 'completion', 1)  ; Ok
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
    _COLORMODE_DRAMCONTRAST($x1, $y1, $x2, $y2, $mid_contr, $k_contr)
    IniWrite($fileini, 'clickermann', 'completion', 1)  ; Ok
EndFunc   ;==>_COMMAND_AI_DRAMCONTRAST

Func _WM_CLOSE($hWnd, $iMsg, $iwParam, $ilParam)
    GUIDelete($hGUImain)
    Exit
EndFunc   ;==>_WM_CLOSE

Func _WaitCM()
    $hWndCM = WinWait($CM_title, '', 3)
    If Not _IsWinCM() Then
        MsgBox(16+4096, 'Внимание!', 'Окно Clickermann не найдено.' & @CRLF & 'Дополнительный функционал не подключен!', 3)
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
        EndIf
        $repeated = True
        return True
    Else
        Global $hWndCMM = '', $hWndCM = '', $hWndCMR = '', $iPidCM = ''
        return False
    EndIf
EndFunc   ;==>_IsWinCM

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

Func _OpenProcess($ah_Handle, $iAccess, $fInherit, $iProcessID)
    Local $aResult = DllCall($ah_Handle, 'handle', 'OpenProcess', 'dword', $iAccess, 'bool', $fInherit, 'dword', $iProcessID)
    If @error Then Return SetError(@error, @extended, 0)
    If $aResult[0] Then Return $aResult[0]
    Return 0
EndFunc   ;==>_OpenProcess



Func _COLORMODE_GREYSCALE_OLD1($fx1, $fy1, $fx2, $fy2)
    Local $iRead, $iWrite, $startbuf, $startBufRd, $addrRd
    Local $color=0, $R, $G, $B
    Local $lenstrX = $fx2 - $fx1
    Local $tBf = DllStructCreate('DWORD')
    Local $tClrStruct = DllStructCreate('DWORD')

    ;Local $hTimer = TimerInit()
    If $fx1 > @DesktopWidth Or $fx2 > @DesktopWidth Or $fy1 > @DesktopHeight Or $fy2 > @DesktopHeight Then
        ConsoleWrite('Неправильные координаты' & @CRLF)
        Return
    EndIf
    If Not _IsWinCM() Then Return

    $hProcess = _WinAPI_OpenProcess($PROCESS_ALL_ACCESS, 0, $iPidCM)
    If Not $hProcess Then
        ConsoleWrite('Не удалось открыть память тестовой программы' & @CRLF)
        ;MsgBox(16+4096, 'Ошибка', 'Не удалось открыть память тестовой программы')
        Return
    EndIf

    ; Читаем адрес начала буфера в указателе
    _WinAPI_ReadProcessMemory($hProcess, $iAddressCM, DllStructGetPtr($tBf), 4, $iRead)
    $startbuf = DllStructGetData($tBf, 1)
    ConsoleWrite('startbuf  ' & $startbuf & @CRLF)

    $startBufRd = $startbuf + ($fy1 * @DesktopWidth * 4) + ($fx1*4)
    For $y = 0 To $fy2 - $fy1
        ;$startBufRd = $startbuf + (($fy1+$y) * @DesktopWidth * 4) + ($fx1*4)
        For $x = 0 To $lenstrX
            $addrRd = $startBufRd + $x*4
            _WinAPI_ReadProcessMemory($hProcess, $addrRd, DllStructGetPtr($tClrStruct), 4, $iRead)
            $color = DllStructGetData($tClrStruct, 1)
            $B = BitAND($color, 0xFF)
            $G = BitAND(BitShift($color, 8), 0xFF)
            $R = BitAND(BitShift($color, 16), 0xFF)
;~             $G = BitShift(BitAND($color, 0xFF00), 8)
;~             $R = BitShift(BitAND($color, 0xFF0000), 16)
            ;ConsoleWrite('color  ' & $color & '   RGB  ' & _
            ;            $R & '  ' & $G & '  ' & $B & '  ' & @CRLF)
            $gray_canal = Int(0.299*$R + 0.587*$G + 0.114*$B)
            $color = $gray_canal*65536 + $gray_canal*256 + $gray_canal
            ;$color = BitShift($gray_canal, -16) + BitShift($gray_canal, -8) + $gray_canal
            DllStructSetData($tClrStruct, 1, $color)
            _WinAPI_WriteProcessMemory($hProcess, $addrRd, DllStructGetPtr($tClrStruct), 4, $iWrite)
            ;ConsoleWrite('$gray  ' & $color & '  ' & $gray_canal & @CRLF)
            ;$startBufRd += 3
        Next
        $startBufRd += @DesktopWidth * 4
    Next

    If ProcessExists($iPidCM) Then
        _WinAPI_CloseHandle($hProcess); Открытый процесс необходимо закрывать
    EndIf
    ;ConsoleWrite('Время выполнения  ' & TimerDiff($hTimer) & ' ms' & @CRLF)
EndFunc   ;==>_COLORMODE_GREYSCALE_OLD1

Func _COLORMODE_GREYSCALE_OLD2($fx1, $fy1, $fx2, $fy2)
    Local $hProcess
    Local $iRead, $iWrite, $startbuf, $startBufRd
    Local $color, $R, $G, $B, $A
    Local Const $lenXBite = ($fx2 - $fx1 + 1) * 4
    Local Const $tagSTRUCT = 'byte[' & $lenXBite &']'
    Local $tClrStruct = DllStructCreate($tagSTRUCT)
    Local $tBf = DllStructCreate('DWORD')

    ;Local $hTimer = TimerInit()
    If $fx1 > @DesktopWidth Or $fx2 > @DesktopWidth Or $fy1 > @DesktopHeight Or $fy2 > @DesktopHeight Then
        ConsoleWrite('Неправильные координаты' & @CRLF)
        Return
    EndIf
    If Not _IsWinCM() Then Return

    $hProcess = _WinAPI_OpenProcess($PROCESS_ALL_ACCESS, 0, $iPidCM)
    If Not $hProcess Then
        ConsoleWrite('Не удалось открыть память тестовой программы' & @CRLF)
        ;MsgBox(16+4096, 'Ошибка', 'Не удалось открыть память тестовой программы')
        Return
    EndIf

    ; Читаем адрес начала буфера в указателе
    _WinAPI_ReadProcessMemory($hProcess, $iAddressCM, DllStructGetPtr($tBf), 4, $iRead)
    $startbuf = DllStructGetData($tBf, 1)
    ;ConsoleWrite('startbuf  ' & $startbuf & @CRLF)

    $startBufRd = $startbuf + ($fy1 * @DesktopWidth * 4) + ($fx1*4)
    For $y = 0 To $fy2 - $fy1
        _WinAPI_ReadProcessMemory($hProcess, $startBufRd, DllStructGetPtr($tClrStruct), $lenXBite, $iRead)

        For $x = 1 To $lenXBite Step 4
            $B = DllStructGetData($tClrStruct, 1, $x)
            $G = DllStructGetData($tClrStruct, 1, $x+1)
            $R = DllStructGetData($tClrStruct, 1, $x+2)
            ;$A = DllStructGetData($tClrStruct, 1, $x+3)
            ;ConsoleWrite(DllStructGetSize($tClrStruct) &'  Read  ' & $iRead & ' B,   ' & _
            ;            'RGBA  ' & _
            ;            $R & '  ' & $G & '  ' & $B & '  ' & $A & @CRLF)
            $gray_canal = Int(0.299*$R + 0.587*$G + 0.114*$B)
            DllStructSetData($tClrStruct, 1, $gray_canal, $x)
            DllStructSetData($tClrStruct, 1, $gray_canal, $x+1)
            DllStructSetData($tClrStruct, 1, $gray_canal, $x+2)
        Next
        _WinAPI_WriteProcessMemory($hProcess, $startBufRd, DllStructGetPtr($tClrStruct), $lenXBite, $iWrite)
        ;ConsoleWrite('Записано байт ' & $iWrite & @CRLF)
        $startBufRd += @DesktopWidth * 4
    Next

    If ProcessExists($iPidCM) Then
        _WinAPI_CloseHandle($hProcess)
    EndIf
    ;ConsoleWrite('Время выполнения  ' & TimerDiff($hTimer) & ' ms' & @CRLF)
EndFunc   ;==>_COLORMODE_GREYSCALE_OLD2

Func _COLORMODE_GREYSCALE_OLD3($fx1, $fy1, $fx2, $fy2)
    Local $hProcess
    Local $iRead, $iWrite, $startbuf, $startBufRd
    Local $color, $R, $G, $B, $A
    Local Const $lenXBite = ($fx2 - $fx1 + 1)
    Local Const $tagSTRUCT = 'DWORD[' & $lenXBite &']'
    Local $tClrStruct = DllStructCreate($tagSTRUCT)
    Local $tBf = DllStructCreate('DWORD')

    ;Local $hTimer = TimerInit()
    If $fx1 > @DesktopWidth Or $fx2 > @DesktopWidth Or $fy1 > @DesktopHeight Or $fy2 > @DesktopHeight Then
        ConsoleWrite('Неправильные координаты' & @CRLF)
        Return
    EndIf
    If Not _IsWinCM() Then Return

    $hProcess = _WinAPI_OpenProcess($PROCESS_ALL_ACCESS, 0, $iPidCM)
    If Not $hProcess Then
        ConsoleWrite('Не удалось открыть память тестовой программы' & @CRLF)
        Return
    EndIf

    ; Читаем адрес начала буфера в указателе
    _WinAPI_ReadProcessMemory($hProcess, $iAddressCM, DllStructGetPtr($tBf), 4, $iRead)
    $startbuf = DllStructGetData($tBf, 1)
    ;ConsoleWrite('startbuf  ' & $startbuf & @CRLF)

    $startBufRd = $startbuf + ($fy1 * @DesktopWidth * 4) + ($fx1*4)
    For $y = 0 To $fy2 - $fy1
        _WinAPI_ReadProcessMemory($hProcess, $startBufRd, DllStructGetPtr($tClrStruct), $lenXBite*4, $iRead)

        For $x = 1 To $lenXBite
            $color = DllStructGetData($tClrStruct, 1, $x)
            $B = BitAND($color, 0xFF)
            $G = BitAND(BitShift($color, 8), 0xFF)
            $R = BitAND(BitShift($color, 16), 0xFF)
            ;ConsoleWrite('color  ' & $color & '   RGB  ' & _
            ;            $R & '  ' & $G & '  ' & $B & '  ' & @CRLF)
            $gray_canal = Int(0.299*$R + 0.587*$G + 0.114*$B)
            $color = $gray_canal*65536 + $gray_canal*256 + $gray_canal
            DllStructSetData($tClrStruct, 1, $color, $x)
        Next
        _WinAPI_WriteProcessMemory($hProcess, $startBufRd, DllStructGetPtr($tClrStruct), $lenXBite*4, $iWrite)
        ;ConsoleWrite('Записано байт ' & $iWrite & @CRLF)
        $startBufRd += @DesktopWidth * 4
    Next

    If ProcessExists($iPidCM) Then
        _WinAPI_CloseHandle($hProcess)
    EndIf
    ;ConsoleWrite('Время выполнения  ' & TimerDiff($hTimer) & ' ms' & @CRLF)
EndFunc   ;==>_COLORMODE_GREYSCALE_OLD3

Func _COLORMODE_GREYSCALE_OLD4($fx1, $fy1, $fx2, $fy2)
    Local $ah_Handle, $hProcess
    Local $iRead, $iWrite, $startbuf, $startBufRd
    Local $color, $R, $G, $B, $A, $lenPxl
    Local Const $DesktopWidthSize = @DesktopWidth * 4
    Local $lenXPxl = ($fx2 - $fx1 + 1)
    Local $lenXBite = $lenXPxl * 4
    Local $tagSTRUCT = 'DWORD[' & $lenXPxl &']'
    
    
    Local $tClrStruct, $pClrStruct
    Local $tBf = DllStructCreate('DWORD')

    ;Local $hTimer = TimerInit()
    If ($fx1+1) > @DesktopWidth Or ($fx2+1) > @DesktopWidth Or _
            ($fy1+1) > @DesktopHeight Or ($fy2+1) > @DesktopHeight Or _
            $fx2 < $fx1 Or $fy2 < $fy1 Then
        ConsoleWrite('Неправильные координаты' & @CRLF)
        Return
    EndIf
    If Not _IsWinCM() Then Return

    $ah_Handle = DllOpen('kernel32.dll')

    ;$hProcess = _WinAPI_OpenProcess($PROCESS_ALL_ACCESS, 0, $iPidCM)
    $hProcess = _OpenProcess($ah_Handle, $PROCESS_ALL_ACCESS, 0, $iPidCM)
    If Not $hProcess Then
        ConsoleWrite('Не удалось открыть память тестовой программы' & @CRLF)
        Return
    EndIf

    ; Читаем адрес начала буфера в указателе
    DllCall($ah_Handle, 'bool', 'ReadProcessMemory', 'handle', $hProcess, _
            'ptr', $iAddressCM, 'ptr', DllStructGetPtr($tBf), 'ulong_ptr', 4, 'ulong_ptr*', 0)
    $startbuf = DllStructGetData($tBf, 1)
    ;ConsoleWrite('startbuf  ' & $startbuf & @CRLF)

    $startBufRd = $startbuf + ($fy1 * $DesktopWidthSize) + ($fx1*4)
    If $fx1 = 0 And $fy1 = 0 And ($fx2+1) = @DesktopWidth And ($fy2+1) = @DesktopHeight Then
        $lenPxl = @DesktopWidth * @DesktopHeight
        $lenXBite = $lenPxl * 4
        $tagSTRUCT = 'DWORD[' & $lenPxl &']'
        $tClrStruct = DllStructCreate($tagSTRUCT)
        $pClrStruct = DllStructGetPtr($tClrStruct)
        DllCall($ah_Handle, 'bool', 'ReadProcessMemory', 'handle', $hProcess, _
                'ptr', $startBufRd, 'ptr', $pClrStruct, 'ulong_ptr', $lenXBite, 'ulong_ptr*', 0)
        For $x = 1 To $lenPxl
            $color = DllStructGetData($tClrStruct, 1, $x)
            $B = BitAND($color, 0xFF)
            $G = BitAND(BitShift($color, 8), 0xFF)
            $R = BitAND(BitShift($color, 16), 0xFF)
            ;ConsoleWrite('color  ' & $color & '   RGB  ' & _
            ;            $R & '  ' & $G & '  ' & $B & '  ' & @CRLF)
            $gray_canal = Int(0.299*$R + 0.587*$G + 0.114*$B)
            $color = $gray_canal*65536 + $gray_canal*256 + $gray_canal
            DllStructSetData($tClrStruct, 1, $color, $x)
        Next
        DllCall($ah_Handle, 'bool', 'WriteProcessMemory', 'handle', $hProcess, _
                'ptr', $startBufRd, 'ptr', $pClrStruct, 'ulong_ptr', $lenXBite, 'ulong_ptr*', 0)
    Else
        $tClrStruct = DllStructCreate($tagSTRUCT)
        $pClrStruct = DllStructGetPtr($tClrStruct)
        For $y = 0 To $fy2 - $fy1
            DllCall($ah_Handle, 'bool', 'ReadProcessMemory', 'handle', $hProcess, _
                    'ptr', $startBufRd, 'ptr', $pClrStruct, 'ulong_ptr', $lenXBite, 'ulong_ptr*', 0)

            For $x = 1 To $lenXPxl
                $color = DllStructGetData($tClrStruct, 1, $x)
                $B = BitAND($color, 0xFF)
                $G = BitAND(BitShift($color, 8), 0xFF)
                $R = BitAND(BitShift($color, 16), 0xFF)
                ;ConsoleWrite('color  ' & $color & '   RGB  ' & _
                ;            $R & '  ' & $G & '  ' & $B & '  ' & @CRLF)

                $gray_canal = Int(0.299*$R + 0.587*$G + 0.114*$B)
                $color = $gray_canal*65536 + $gray_canal*256 + $gray_canal
                DllStructSetData($tClrStruct, 1, $color, $x)
            Next
            DllCall($ah_Handle, 'bool', 'WriteProcessMemory', 'handle', $hProcess, _
                    'ptr', $startBufRd, 'ptr', $pClrStruct, 'ulong_ptr', $lenXBite, 'ulong_ptr*', 0)
            $startBufRd += $DesktopWidthSize
        Next
    EndIf

    If ProcessExists($iPidCM) Then
        DllCall($ah_Handle, 'bool', 'CloseHandle', 'handle', $hProcess)
    EndIf
    DllClose($ah_Handle)
    ;ConsoleWrite('Время выполнения  ' & TimerDiff($hTimer) & ' ms' & @CRLF)
EndFunc   ;==>_COLORMODE_GREYSCALE_OLD4

Func _COLORMODE_GREYSCALE($fx1, $fy1, $fx2, $fy2)
    Local $ah_Handle, $hProcess
    Local $iRead, $iWrite, $startbuf, $startBufRd, $addrRd
    Local $color, $R, $G, $B, $A
    Local Const $DesktopWidthSize = @DesktopWidth * 4
    Local $lenXPxl = ($fx2 - $fx1 + 1)
    Local $lenPxl, $lenXBite, $tagSTRUCT, $tClrStruct, $pClrStruct
    Local $tBf = DllStructCreate('DWORD')

    ;Local $hTimer = TimerInit()
    If ($fx1+1) > @DesktopWidth Or ($fx2+1) > @DesktopWidth Or _
            ($fy1+1) > @DesktopHeight Or ($fy2+1) > @DesktopHeight Or _
            $fx2 < $fx1 Or $fy2 < $fy1 Then
        ConsoleWrite('Неправильные координаты' & @CRLF)
        Return
    EndIf
    If Not _IsWinCM() Then Return

    $ah_Handle = DllOpen('kernel32.dll')

    ;$hProcess = _WinAPI_OpenProcess($PROCESS_ALL_ACCESS, 0, $iPidCM)
    $hProcess = _OpenProcess($ah_Handle, $PROCESS_ALL_ACCESS, 0, $iPidCM)
    If Not $hProcess Then
        ConsoleWrite('Не удалось открыть память тестовой программы' & @CRLF)
        Return
    EndIf

    ; Читаем адрес начала буфера в указателе
    DllCall($ah_Handle, 'bool', 'ReadProcessMemory', 'handle', $hProcess, _
            'ptr', $iAddressCM, 'ptr', DllStructGetPtr($tBf), 'ulong_ptr', 4, 'ulong_ptr*', 0)
    $startbuf = DllStructGetData($tBf, 1)
    ;ConsoleWrite('startbuf  ' & $startbuf & @CRLF)

    $startBufRd = $startbuf + ($fy1 * $DesktopWidthSize) + ($fx1*4)
    If $fx1 = 0 And $fy1 = 0 And ($fx2+1) = @DesktopWidth And ($fy2+1) = @DesktopHeight Then
        $lenPxl = @DesktopWidth * @DesktopHeight
        $lenXBite = $lenPxl * 4
        $tagSTRUCT = 'DWORD[' & $lenPxl &']'
        $tClrStruct = DllStructCreate($tagSTRUCT)
        $pClrStruct = DllStructGetPtr($tClrStruct)
        DllCall($ah_Handle, 'bool', 'ReadProcessMemory', 'handle', $hProcess, _
                'ptr', $startBufRd, 'ptr', $pClrStruct, 'ulong_ptr', $lenXBite, 'ulong_ptr*', 0)
        For $x = 1 To $lenPxl
            $color = DllStructGetData($tClrStruct, 1, $x)
            $B = BitAND($color, 0xFF)
            $G = BitAND(BitShift($color, 8), 0xFF)
            $R = BitAND(BitShift($color, 16), 0xFF)
            ;ConsoleWrite('color  ' & $color & '   RGB  ' & _
            ;            $R & '  ' & $G & '  ' & $B & '  ' & @CRLF)

            #Region    ************ Обработка ************
            $gray_canal = Int(0.299*$R + 0.587*$G + 0.114*$B)
            $color = $gray_canal*65536 + $gray_canal*256 + $gray_canal
            #EndRegion ************ Обработка ************

            DllStructSetData($tClrStruct, 1, $color, $x)
        Next
        DllCall($ah_Handle, 'bool', 'WriteProcessMemory', 'handle', $hProcess, _
                'ptr', $startBufRd, 'ptr', $pClrStruct, 'ulong_ptr', $lenXBite, 'ulong_ptr*', 0)
    Else
        $lenPxl = (($fy2 - $fy1) * @DesktopWidth) + $lenXPxl
        $lenXBite = $lenPxl * 4
        $tagSTRUCT = 'DWORD[' & $lenPxl &']'
        $tClrStruct = DllStructCreate($tagSTRUCT)
        $pClrStruct = DllStructGetPtr($tClrStruct)
        DllCall($ah_Handle, 'bool', 'ReadProcessMemory', 'handle', $hProcess, _
                'ptr', $startBufRd, 'ptr', $pClrStruct, 'ulong_ptr', $lenXBite, 'ulong_ptr*', 0)
        For $y = 0 To $fy2 - $fy1
            $yFull = $y * @DesktopWidth
            For $x = 1 To $lenXPxl
                $addrRd = $yFull + $x
                $color = DllStructGetData($tClrStruct, 1, $addrRd)
                $B = BitAND($color, 0xFF)
                $G = BitAND(BitShift($color, 8), 0xFF)
                $R = BitAND(BitShift($color, 16), 0xFF)
                ;ConsoleWrite('color  ' & $color & '   RGB  ' & _
                ;            $R & '  ' & $G & '  ' & $B & '  ' & @CRLF)

                #Region    ************ Обработка ************
                $gray_canal = Int(0.299*$R + 0.587*$G + 0.114*$B)
                $color = $gray_canal*65536 + $gray_canal*256 + $gray_canal
                #EndRegion ************ Обработка ************

                DllStructSetData($tClrStruct, 1, $color, $addrRd)
            Next
        Next
        DllCall($ah_Handle, 'bool', 'WriteProcessMemory', 'handle', $hProcess, _
                'ptr', $startBufRd, 'ptr', $pClrStruct, 'ulong_ptr', $lenXBite, 'ulong_ptr*', 0)
    EndIf

    If ProcessExists($iPidCM) Then
        DllCall($ah_Handle, 'bool', 'CloseHandle', 'handle', $hProcess)
    EndIf
    DllClose($ah_Handle)
    ;ConsoleWrite('Время выполнения  ' & TimerDiff($hTimer) & ' ms' & @CRLF)
EndFunc   ;==>_COLORMODE_GREYSCALE_5

Func _COLORMODE_DRAMCONTRAST($fx1, $fy1, $fx2, $fy2, $fmid_contr, $fk_contr)
    Local $ah_Handle, $hProcess
    Local $iRead, $iWrite, $startbuf, $startBufRd, $addrRd
    Local $color, $R, $G, $B, $A
    Local Const $DesktopWidthSize = @DesktopWidth * 4
    Local $lenXPxl = ($fx2 - $fx1 + 1)
    Local $lenPxl, $lenXBite, $tagSTRUCT, $tClrStruct, $pClrStruct
    Local $tBf = DllStructCreate('DWORD')

    ;Local $hTimer = TimerInit()
    If ($fx1+1) > @DesktopWidth Or ($fx2+1) > @DesktopWidth Or _
            ($fy1+1) > @DesktopHeight Or ($fy2+1) > @DesktopHeight Or _
            $fx2 < $fx1 Or $fy2 < $fy1 Then
        ConsoleWrite('Неправильные координаты' & @CRLF)
        Return
    EndIf
    If Not _IsWinCM() Then Return

    $ah_Handle = DllOpen('kernel32.dll')

    ;$hProcess = _WinAPI_OpenProcess($PROCESS_ALL_ACCESS, 0, $iPidCM)
    $hProcess = _OpenProcess($ah_Handle, $PROCESS_ALL_ACCESS, 0, $iPidCM)
    If Not $hProcess Then
        ConsoleWrite('Не удалось открыть память тестовой программы' & @CRLF)
        Return
    EndIf

    ConsoleWrite('(' & $fx1 & ', ' & $fy1 & ', ' & $fx2 & ', ' & $fy2 & ')   ' & _
                'mid_contr = ' & $fmid_contr & ',  k_contr = ' & $fk_contr & @CRLF)

    ; Читаем адрес начала буфера в указателе
    DllCall($ah_Handle, 'bool', 'ReadProcessMemory', 'handle', $hProcess, _
            'ptr', $iAddressCM, 'ptr', DllStructGetPtr($tBf), 'ulong_ptr', 4, 'ulong_ptr*', 0)
    $startbuf = DllStructGetData($tBf, 1)
    ;ConsoleWrite('startbuf  ' & $startbuf & @CRLF)

    $startBufRd = $startbuf + ($fy1 * $DesktopWidthSize) + ($fx1*4)
    If $fx1 = 0 And $fy1 = 0 And ($fx2+1) = @DesktopWidth And ($fy2+1) = @DesktopHeight Then
        $lenPxl = @DesktopWidth * @DesktopHeight
        $lenXBite = $lenPxl * 4
        $tagSTRUCT = 'DWORD[' & $lenPxl &']'
        $tClrStruct = DllStructCreate($tagSTRUCT)
        $pClrStruct = DllStructGetPtr($tClrStruct)
        DllCall($ah_Handle, 'bool', 'ReadProcessMemory', 'handle', $hProcess, _
                'ptr', $startBufRd, 'ptr', $pClrStruct, 'ulong_ptr', $lenXBite, 'ulong_ptr*', 0)
        For $x = 1 To $lenPxl
            $color = DllStructGetData($tClrStruct, 1, $x)
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
            $color = $R*65536 + $G*256 + $B
            #EndRegion ************ Обработка ************

            DllStructSetData($tClrStruct, 1, $color, $x)
        Next
        DllCall($ah_Handle, 'bool', 'WriteProcessMemory', 'handle', $hProcess, _
                'ptr', $startBufRd, 'ptr', $pClrStruct, 'ulong_ptr', $lenXBite, 'ulong_ptr*', 0)
    Else
        $lenPxl = (($fy2 - $fy1) * @DesktopWidth) + $lenXPxl
        $lenXBite = $lenPxl * 4
        $tagSTRUCT = 'DWORD[' & $lenPxl &']'
        $tClrStruct = DllStructCreate($tagSTRUCT)
        $pClrStruct = DllStructGetPtr($tClrStruct)
        DllCall($ah_Handle, 'bool', 'ReadProcessMemory', 'handle', $hProcess, _
                'ptr', $startBufRd, 'ptr', $pClrStruct, 'ulong_ptr', $lenXBite, 'ulong_ptr*', 0)
        For $y = 0 To $fy2 - $fy1
            $yFull = $y * @DesktopWidth
            For $x = 1 To $lenXPxl
                $addrRd = $yFull + $x
                $color = DllStructGetData($tClrStruct, 1, $addrRd)
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
                $color = $R*65536 + $G*256 + $B
                #EndRegion ************ Обработка ************

                DllStructSetData($tClrStruct, 1, $color, $addrRd)
            Next
        Next
        DllCall($ah_Handle, 'bool', 'WriteProcessMemory', 'handle', $hProcess, _
                'ptr', $startBufRd, 'ptr', $pClrStruct, 'ulong_ptr', $lenXBite, 'ulong_ptr*', 0)
    EndIf

    If ProcessExists($iPidCM) Then
        DllCall($ah_Handle, 'bool', 'CloseHandle', 'handle', $hProcess)
    EndIf
    DllClose($ah_Handle)
    ;ConsoleWrite('Время выполнения  ' & TimerDiff($hTimer) & ' ms' & @CRLF)
EndFunc   ;==>_COLORMODE_DRAMCONTRAST

Func _SendCM($wParam, $lParam)
    _SendMessage($hWndCM, $WM_CMCOMMAND, $wParam, $lParam)
    If @error Then
        MsgBox(4096, '_ToggleMonitor', '_SendMessage Error: ' & @error)
        Exit
    EndIf
EndFunc   ;==>_SendCM



Func _ToggleMonitor($hwnd, $OnOff)
    Local Const $WM_SYSCOMMAND = 274
    Local Const $SC_MONITORPOWER = 61808
    _SendMessage($hWnd, $WM_SYSCOMMAND, $SC_MONITORPOWER, $OnOff)
    If @error Then
        MsgBox(4096, '_ToggleMonitor', '_SendMessage Error: ' & @error)
        Exit
    EndIf
EndFunc   ;==>_ToggleMonitor

;~ WM_User = 0x400 (1024)
;~ Стандартные сообщения до WM_User-1.     от              0   до  0x03FF (1023)
;~ Локальные сообщения от WM_User          от  0x0400  (1024)  до  0x7FFF (32767)
;~ Глобальные сообщения                    от  0xC000 (49152)  до  0xFFFF (65535)


;ExitLoop(1)
;Binary('0x' & '4D5A00000000')

;~ $hControl = ControlGetHandle($hWnd, '', '[CLASS:Button; TEXT:OK]')
;~ ControlClick($hWnd, '', $hControl, 'main')

