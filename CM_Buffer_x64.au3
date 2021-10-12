#Region Header
;===================================================================================================
;
; Title:            CM_Buffer_x64
; Filename:         CM_Buffer_x64.au3
; Description:      Работа с буфером Clickermann
; Version:          1.0.2
; Requirement(s):   Autoit 3.3.14.5
; Author(s):        Vint
; Date:             12.10.2021
;
;===================================================================================================
#EndRegion Header

#Region    **** Includes ****
#include <WinAPI.au3>
; #include <SendMessage.au3>
; #include <Misc.au3>

; #include <WindowsConstants.au3>
#include <Constants.au3>
#EndRegion **** Includes ****

Global $repeated = False
Global $CM_name = 'Clickermann_'
Global $CM_title = '[TITLE:' & $CM_name & '; W:310; H:194]'
Global $hWndCMM = '', $hWndCM = '', $hWndCMR = '', $iPidCM = ''
Global $hDLLkernel32 = DllOpen('kernel32.dll')
Global $startBuf
Global $aDesk = WinGetPos('Program Manager'), $DesktopWidth = $aDesk[2], $DesktopHeight = $aDesk[3]


_WaitCM()
ConsoleWrite('Идентификатор PID ' & $iPidCM & @CRLF)

$startBuf = _CalculateBuffer()

_ReadLinePXLs(0, 1)  ; $startY, $lenXPxl



DllClose($hDLLkernel32)


Func _ReadLinePXLs($startY, $lenXPxl)
    Local $lenXBite, $tagSTRUCT, $tClrStruct, $pClrStruct
    Local $hProcess
    Local $startBufRd = $startBuf + (($DesktopWidth * ($DesktopHeight - 1 - $startY)) * 4)

    ; ConsoleWrite('startBufRd  ' & Hex($startBufRd, 8) & @CRLF)
    ; 0x0             ; последняя строка
    ; 0x0039F440 * 4  ; первая строка   ($DesktopWidth * ($DesktopHeight - 1)) * 4

    If ($startY > ($DesktopHeight - 1)) Or ($startY < 0) Then
        Return
    EndIf

    $hProcess = _OpenProcess($hDLLkernel32, $PROCESS_ALL_ACCESS, 0, $iPidCM)
    If Not $hProcess Then
        ConsoleWrite('Не удалось открыть память тестовой программы' & @CRLF)
        Return
    EndIf

    $lenXBite = $lenXPxl * 4
    $tagSTRUCT = 'DWORD[' & $lenXPxl &']'
    $tClrStruct = DllStructCreate($tagSTRUCT)
    $pClrStruct = DllStructGetPtr($tClrStruct)
    DllCall($hDLLkernel32, 'bool', 'ReadProcessMemory', 'handle', $hProcess, _
            'ptr', $startBufRd, 'ptr', $pClrStruct, 'ulong_ptr', $lenXBite, 'ulong_ptr*', 0)

    For $x = 1 To $lenXPxl
        $addrRd = $x
        $color = DllStructGetData($tClrStruct, 1, $addrRd)
        $B = BitAND($color, 0xFF)
        $G = BitAND(BitShift($color, 8), 0xFF)
        $R = BitAND(BitShift($color, 16), 0xFF)
        ConsoleWrite('color  ' & Hex($color, 8) & '   RGB  ' & _
                   $R & '  ' & $G & '  ' & $B & '  ' & @CRLF)
    Next
EndFunc   ;==>_ReadLinePXLs

Func _CalculateBuffer()
    Local $hProcess
    Local $pointer
    Local Const $DesktopWidthSize = @DesktopWidth * 4
    Local $lenPxl, $lenXBite, $tagSTRUCT, $tClrStruct, $pClrStruct
    Local $tBf = DllStructCreate('DWORD')
    Local $iAddressCM, $offset
    ; Local $hDLLkernel32 = DllOpen('kernel32.dll')

    $iAddressCM = 0x007CC6F0
    $offset = 0x24

    #cs
    iAddressCM  007CC6F0
    pointer  0298D730
    startBuf  05130000
    Screen 1 line  05FAD100
    color  FFFA0000   RGB  250  0  0
    #ce

    ;$hProcess = _WinAPI_OpenProcess($PROCESS_ALL_ACCESS, 0, $iPidCM)
    $hProcess = _OpenProcess($hDLLkernel32, $PROCESS_ALL_ACCESS, 0, $iPidCM)
    If Not $hProcess Then
        ConsoleWrite('Не удалось открыть память тестовой программы' & @CRLF)
        Return
    EndIf

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

    If ProcessExists($iPidCM) Then
        DllCall($hDLLkernel32, 'bool', 'CloseHandle', 'handle', $hProcess)
    EndIf
    Return $startBuf
EndFunc   ;==>_CalculateBuffer

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

