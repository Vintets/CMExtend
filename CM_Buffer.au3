#Region Header
;===================================================================================================
;
; Title:            CM_Buffer
; Filename:         CM_Buffer.au3
; Description:      Работа с буфером Clickermann
; Version:          2.0.1
; Requirement(s):   Autoit 3.3.14.5
; Author(s):        Vint
; Date:             13.10.2021
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

Opt('MustDeclareVars', 1)

Global $repeated = False
Global $CM_name = 'Clickermann_'
Global $CM_title = '[TITLE:' & $CM_name & '; W:310; H:194]'
Global $hWndCMM = '', $hWndCM = '', $hWndCMR = '', $iPidCM = '', $versionFullCM = ''
Global Const $fileini = @ScriptDir & '\CMTools\settings_cme.ini'
Global $hDLLkernel32 = DllOpen('kernel32.dll')
Global $startBuf
Global Const $aDesk = WinGetPos('Program Manager')
Global Const $DesktopWidth = $aDesk[2], $DesktopHeight = $aDesk[3]
Global Const $xMax = $DesktopWidth - 1, $yMax = $DesktopHeight - 1


_WaitCM()
_CalculateBuffer()

; _ReadLinePXLs(0, 0, 1)  ; $startX, $startY, $lenXPxl
_FillSquare(0, 0, 'RG')
_FillSquare(260, 0, 'RB')
_FillSquare(0, 260, 'GB')
_FillSquare(260, 260, 'R')

DllClose($hDLLkernel32)


Func _ReadLinePXLs($startX, $startY, $lenXPxl)
    Local $hProcess
    Local $lenXBite, $tagSTRUCT, $tClrStruct, $pClrStruct
    Local $startBufRd = $startBuf + (($DesktopWidth * ($yMax - $startY)) * 4) + ($startX * 4)
    Local $x, $addrRd
    Local $color, $R, $G, $B, $A

    ; ConsoleWrite('startBufRd  ' & Hex($startBufRd, 8) & @CRLF)
    ; 0x0             ; последняя строка
    ; 0x0039F440 * 4  ; первая строка   ($DesktopWidth * ($DesktopHeight - 1)) * 4

    If ($startY < 0) Or ($startY > $yMax) Or ($startX < 0) Or ($startX > $xMax) Then
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

Func _FillSquare($fx1, $fy1, $colorCombination = 'RG')
    Local $hProcess
    Local $lenPxl, $lenXBite, $tagSTRUCT, $tClrStruct, $pClrStruct
    Local $yFull, $addrWrStruct
    Local $color, $R, $G, $B, $A
    Local $fx2 = $fx1 + 255, $fy2 = $fy1 + 255
    Local $lenXPxl = $fx2 - $fx1 + 1, $lenYPxl = $fy2 - $fy1 + 1
    Local $startBufRd = $startBuf + _
                (($DesktopWidth * ($yMax - $fy2)) * 4) + _
                ($fx1 * 4)

    ; ConsoleWrite('startBufRd  ' & Hex($startBufRd, 8) & @CRLF)
    ; 0x0             ; последняя строка
    ; 0x0039F440 * 4  ; первая строка   ($DesktopWidth * ($DesktopHeight - 1)) * 4

    Local $hTimer = TimerInit()
    If ($fy1 < 0) Or ($fy1 > $yMax) Or ($fx1 < 0) Or ($fx1 > $xMax) Then
        ConsoleWrite('Неправильные координаты' & @CRLF)
        Return
    EndIf

    $hProcess = _OpenProcess($hDLLkernel32, $PROCESS_ALL_ACCESS, 0, $iPidCM)
    If Not $hProcess Then
        ConsoleWrite('Не удалось открыть память тестовой программы' & @CRLF)
        Return
    EndIf

    $lenPxl = (($lenYPxl - 1) * $DesktopWidth) + $lenXPxl
    $lenXBite = $lenPxl * 4
    ; ConsoleWrite('$lenXBite ' & $lenXBite  & @CRLF)
    $tagSTRUCT = 'DWORD[' & $lenPxl &']'
    $tClrStruct = DllStructCreate($tagSTRUCT)
    $pClrStruct = DllStructGetPtr($tClrStruct)

    DllCall($hDLLkernel32, 'bool', 'ReadProcessMemory', 'handle', $hProcess, _
            'ptr', $startBufRd, 'ptr', $pClrStruct, 'ulong_ptr', $lenXBite, 'ulong_ptr*', 0)

    For $y = 0 To $lenYPxl - 1
        $yFull = $y * $DesktopWidth
        For $x = 0 To $lenXPxl - 1
            $addrWrStruct = $yFull + $x + 1
            If $colorCombination = 'RG' Then
                $color = 0xFF*0x1000000 + $x*0x10000 + (255-$y)*0x100  ; + $x*0x10000 + (255-$y)*0x100 + 0
            ElseIf $colorCombination = 'RB' Then
                $color = 0xFF*0x1000000 + $x*0x10000 + (255-$y)  ; + $x*0x10000 + 0*0x100 + (255-$y)
            ElseIf $colorCombination = 'GB' Then
                $color = 0xFF*0x1000000 + $x*0x100 + (255-$y)  ; + 0*0x10000 + $x*0x100 + (255-$y)
            ElseIf $colorCombination = 'R' Then
                $color = 0xFF*0x1000000 + $x*0x10000
            Else
                $color = 0xFF*0x1000000
            EndIf

            DllStructSetData($tClrStruct, 1, $color, $addrWrStruct)
        Next
    Next
    DllCall($hDLLkernel32, 'bool', 'WriteProcessMemory', 'handle', $hProcess, _
            'ptr', $startBufRd, 'ptr', $pClrStruct, 'ulong_ptr', $lenXBite, 'ulong_ptr*', 0)

    If ProcessExists($iPidCM) Then
        DllCall($hDLLkernel32, 'bool', 'CloseHandle', 'handle', $hProcess)
    EndIf
    ConsoleWrite('Время выполнения  ' & TimerDiff($hTimer) & ' ms' & @CRLF)
EndFunc   ;==>_FillSquare

Func _WaitCM()
    $hWndCM = WinWait($CM_title, '', 3)
    $repeated = False
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

