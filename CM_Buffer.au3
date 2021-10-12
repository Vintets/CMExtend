#Region Header
;===================================================================================================
;
; Title:            CM_Buffer
; Filename:         CM_Buffer.au3
; Description:      Работа с буфером Clickermann
; Version:          1.0.1
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
Global $startBuf, $startBufRd


_WaitCM()
ConsoleWrite('Идентификатор PID ' & $iPidCM & @CRLF)

$startBuf = _CalculateBuffer()

$startBufRd = $startBuf + 0x0039F440 * 4
ConsoleWrite('startBufRd  ' & Hex($startBufRd, 8) & @CRLF)

_ReadLinePXLs($startBufRd, 1)
#cs
iAddressCM  00655BB8
pointer  034CFCC0
startBuf  057B0000
startBufRd  0662D100
color  FFFA0000   RGB  250  0  0
#ce

DllClose($hDLLkernel32)


Func _ReadLinePXLs($startRd, $lenXPxl)
    Local $lenXBite, $tagSTRUCT, $tClrStruct, $pClrStruct
    Local $hProcess

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

        ; #Region    ************ Обработка ************
        ; $gray_canal = Int(0.299*$R + 0.587*$G + 0.114*$B)
        ; $color = $gray_canal*65536 + $gray_canal*256 + $gray_canal
        ; #EndRegion ************ Обработка ************

        ; DllStructSetData($tClrStruct, 1, $color, $addrRd)
    Next
EndFunc   ;==>_ReadPXLs


Func _CalculateBuffer()
    Local $hProcess
    Local $pointer
    Local Const $DesktopWidthSize = @DesktopWidth * 4
    Local $lenPxl, $lenXBite, $tagSTRUCT, $tClrStruct, $pClrStruct
    Local $tBf = DllStructCreate('DWORD')
    Local $iAddressCM, $offset
    ; Local $hDLLkernel32 = DllOpen('kernel32.dll')

    $iAddressCM = 0x00655BB8
    $offset = 0x1C


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
    ConsoleWrite('pointer  ' & Hex($pointer, 8) & @CRLF)  ; 034CFCC0

    DllCall($hDLLkernel32, 'bool', 'ReadProcessMemory', 'handle', $hProcess, _
            'ptr', $pointer + $offset, 'ptr', DllStructGetPtr($tBf), 'ulong_ptr', 4, 'ulong_ptr*', 0)
    $startBuf = DllStructGetData($tBf, 1)
    ConsoleWrite('startBuf  ' & Hex($startBuf, 8) & @CRLF)  ; 057B0000
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

