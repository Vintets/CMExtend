#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=cmex.ico
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_Res_Comment=CMExtend
#AutoIt3Wrapper_Res_Fileversion=0.0.2
#AutoIt3Wrapper_Res_LegalCopyright=Vint
#AutoIt3Wrapper_Res_Language=1049
#AutoIt3Wrapper_Res_requestedExecutionLevel=None
#AutoIt3Wrapper_Res_Field=Version|0.0.2
#AutoIt3Wrapper_Res_Field=Build|2021.09.30
#AutoIt3Wrapper_Res_Field=Coded by|Vint
#AutoIt3Wrapper_Res_Field=Compile date|%longdate% %time%
#AutoIt3Wrapper_Res_Field=AutoIt Version|%AutoItVer%
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

;===============================================================================
;
; Description:      CMExtend
; Version:          0.0.2
; Requirement(s):   Autoit 3.3.14.5
; Author(s):        Vint
;
;===============================================================================

#Region    ************ Includes ************
#include <WinAPI.au3>
#include <Array.au3>
#include <WindowsConstants.au3>
#include <GUIConstants.au3>
#include <GUIConstantsEx.au3>
#EndRegion ************ Includes ************

#RequireAdmin
Opt('MustDeclareVars', 1)
Opt('TrayIconDebug', 1)
;~ Opt('WinTitleMatchMode', 2)  ; 1-начальное, 2-любая подстрока, 3-точное

Global $Available = False
Global $hWndCMM = '', $hWndCM = '', $hWndCMR = '', $iPidCM = '', $aPosCM[4], $aPosCMR[4]
Global $fileini = @ScriptDir & '\settings_cme.ini'
Global $aWindows2D[3][14], $k = 0

_CheckINI()
_ReadINIPos()
_LogPos()
_Starting()
_LogPos()


Global $hGuiDummyMain
$hGuiDummyMain = GUICreate('dummy_main', $aPosCM[2], $aPosCM[3], $aPosCM[0], $aPosCM[1]+30, BitOR($WS_POPUP, $WS_BORDER))  ;, $WS_EX_MDICHILD
;~ DllCall('user32.dll', 'hwnd', 'SetParent', 'hwnd', $hGuiDummyMain, 'hwnd', $hWndCM)
_WinAPI_SetParent($hGuiDummyMain, $hWndCM)
GUISetState(@SW_SHOW, $hGuiDummyMain)
Sleep(10000)


;~ While 1
;~     _CheckAvailable()
;~     Sleep(500)
;~ WEnd

Func _CMOn()
    $Available = True
    
EndFunc   ;==>_CMOn

Func _CMOff()
    $Available = False
    _SaveINIPos()
EndFunc   ;==>_CMOff

Func _Starting()
    _IsWinCM()
    If $Available Then
        _ReadPosCM('main')
        _ReadPosCM('editor')
    EndIf
EndFunc   ;==>_Start

Func _ReadPosCM($type)
    Local $aPos

    If $type = 'main' Then
        $aPos = WinGetPos($hWndCM)
        $aPosCM[0] = $aPos[0]
        $aPosCM[1] = $aPos[1]
        $aPosCM[2] = $aPos[2]
        $aPosCM[3] = $aPos[3]
    EndIf
    If $type = 'editor' Then
        $aPos = WinGetPos($hWndCMR)
        $aPosCMR[0] = $aPos[0]
        $aPosCMR[1] = $aPos[1]
        $aPosCMR[2] = $aPos[2]
        $aPosCMR[3] = $aPos[3]
    EndIf
EndFunc   ;==>_ReadPosCM

Func _SetPosCM($type)
;~     WinMove("title", "text", x, y , width , height)
;~     _WinAPI_MoveWindow($hWnd, 10, 10, 200, 300)
EndFunc   ;==>_SetPosCM

Func _ReadINIPos()
    Local $text

    $aPosCM[0] = IniRead($fileini, 'main_position_size', 'CM_X', '-1')
    $aPosCM[1] = IniRead($fileini, 'main_position_size', 'CM_Y', '-1')
    $aPosCM[2] = 310
    $aPosCM[3] = 197
    $aPosCMR[0] = IniRead($fileini, 'main_position_size', 'CMR_X', '-1')
    $aPosCMR[1] = IniRead($fileini, 'main_position_size', 'CMR_Y', '-1')
    $aPosCMR[2] = IniRead($fileini, 'main_position_size', 'CMR_W', '649')
    $aPosCMR[3] = IniRead($fileini, 'main_position_size', 'CMR_H', '480')
;~     IniWrite($fileini, 'main_position_size', 'running', '100')
EndFunc   ;==>_ReadINIPos

Func _SaveINIPos()
    IniWrite($fileini, 'main_position_size', 'CM_X', $aPosCM[0])
    IniWrite($fileini, 'main_position_size', 'CM_Y', $aPosCM[1])
    IniWrite($fileini, 'main_position_size', 'CMR_X', $aPosCMR[0])
    IniWrite($fileini, 'main_position_size', 'CMR_Y', $aPosCMR[1])
    IniWrite($fileini, 'main_position_size', 'CMR_W', $aPosCMR[2])
    IniWrite($fileini, 'main_position_size', 'CMR_H', $aPosCMR[3])
EndFunc   ;==>_SaveINIPos

Func _CheckINI()
    IniRenameSection($fileini, 'main_position_size', 'main_position_size')
    If Not @error Then
        MsgBox(4096, '', 'Произошла ошибка, отсутствует или повреждён файл settings_cme.ini', 2)
        FileInstall('settings_cme_default.ini', $fileini)
        Sleep(500)
    EndIf
EndFunc   ;==>_CheckINI

Func _IsWinCM()
    $hWndCMM = _GetWin('базовое', '[CLASS:TApplication; TITLE:Clickermann -]')
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
    _AllWindInfo()
EndFunc   ;==>_IsWinCM

Func _GetWin($type, $data)
    Local $hWndt = WinGetHandle($data), $text
    If $hWndt <> '' Then
        $text = 'окно ' & $type & ' существует  ' & $hWndt & @CRLF
    Else
        $text = 'окно ' & $type & ' НЕ существует' & @CRLF
    EndIf
    ;ConsoleWrite($text)
    Return $hWndt
EndFunc   ;==>_GetWin

Func _AllWindInfo()
    Local $aWindows, $s = Chr(1)
    Local $colnames = '№' & $s & _
                    'Дескриптор' & $s & _
                    'Класс' & $s & _
                    'Заголовок' & $s & _
                    'X' & $s & _
                    'Y' & $s & _
                    'Ширина' & $s & _
                    'Высота' & $s & _
                    'Наличие' & $s & _
                    'Скрыт' & $s & _
                    'Доступно' & $s & _
                    'Активно' & $s & _
                    'Свёрнуто' & $s & _
                    'На весь экран' & $s & _
                    'Процесс'

    _AddWinInfo(0, $hWndCMM)
    _AddWinInfo(1, $hWndCM)
    _AddWinInfo(2, $hWndCMR)
    _ArrayDisplay($aWindows2D, 'Окна', Default, 0, $s, $s, $colnames)
    ConsoleWrite('Мы здесь' & @CRLF)
EndFunc   ;==>_AllWindInf

Func _AddWinInfo($num, $hWndt)
    Local $aPos = WinGetPos($hWndt)
    Local $iState = WinGetState($hWndt)
    Local $aStat[6][2] = [['+', '-'], _
                        ['-', '+'], _
                        ['+', '-'], _
                        ['+', '-'], _
                        ['+', '-'], _
                        ['+', '-']]

    If $hWndt = '' Then
        For $i = 0 To 13
            $aWindows2D[$num][$i] = '.'
        Next
        Return
    EndIf
    
    $aWindows2D[$num][0] = $hWndt
    $aWindows2D[$num][1] = _WinAPI_GetClassName($hWndt)
    $aWindows2D[$num][2] = WinGetTitle($hWndt)
    $aWindows2D[$num][3] = $aPos[0]
    $aWindows2D[$num][4] = $aPos[1]
    $aWindows2D[$num][5] = $aPos[2]
    $aWindows2D[$num][6] = $aPos[3]

    For $i = 0 To 5
        If BitAND($iState, 2 ^ $i) Then
            $aWindows2D[$num][7+$i] = $aStat[$i][0]
        Else
            $aWindows2D[$num][7+$i] = $aStat[$i][1]
        EndIf
    Next

    $aWindows2D[$num][13] = WinGetProcess($hWndt)
    ;$aWindows2D[$num][100] = WinGetText($hWndt)
EndFunc   ;==>_WinInfo

Func _LogPos()
    Local $text
    $text = 'CM_X ' & $aPosCM[0] & '  CM_Y ' & $aPosCM[1]
    $text &= '  CM_W ' & $aPosCM[2] & '  CM_H ' & $aPosCM[3] & @CRLF
    $text &= 'CMR_X ' & $aPosCMR[0] & '  CMR_Y ' & $aPosCMR[1]
    $text &= '  CMR_W ' & $aPosCMR[2] & '  CMR_H ' & $aPosCMR[3] & @CRLF
    ConsoleWrite($text)
EndFunc   ;==>_LogPos


Func _Restart()
    Local $sAutoIt_File = @TempDir & "\~Au3_ScriptRestart_TempFile.au3"
    Local $sRunLine, $sScript_Content, $hFile

    $sRunLine = @ScriptFullPath
    If Not @Compiled Then $sRunLine = @AutoItExe & ' /AutoIt3ExecuteScript ""' & $sRunLine & '""'
    If $CmdLine[0] > 0 Then $sRunLine &= ' ' & $CmdLineRaw

    $sScript_Content &= '#NoTrayIcon' & @CRLF & _
            'While ProcessExists(' & @AutoItPID & ')' & @CRLF & _
            '   Sleep(10)' & @CRLF & _
            'WEnd' & @CRLF & _
            'Run("' & $sRunLine & '")' & @CRLF & _
            'FileDelete(@ScriptFullPath)' & @CRLF

    $hFile = FileOpen($sAutoIt_File, 2)
    FileWrite($hFile, $sScript_Content)
    FileClose($hFile)

    Run(@AutoItExe & ' /AutoIt3ExecuteScript "' & $sAutoIt_File & '"', @ScriptDir, @SW_HIDE)
    Sleep(1000)
    Exit
EndFunc   ;==>_restart

;~ While 1
;~     $hWnd = WinGetHandle('Спонсируемый сеанс')
;~     If $hWnd <> '' Then
;~         $hControl = ControlGetHandle($hWnd, '', '[CLASS:Button; TEXT:OK]')
;~         ControlClick($hWnd, '', $hControl, 'main')
        ;_WinAPI_PostMessage($hWnd, $WM_COMMAND, _WinAPI_MakeLong(1, 1), $hControl)
        ;MsgBox(4096, 'Сообщение', 'HWND окна: ' & $hWnd & @CRLF & 'Дескриптор элемента OK: ' & $hControl, 2)
    ;Else
        ;MsgBox(4096, 'Сообщение', 'Окно не найдено.', 2)
;~     EndIf
;~     $hWnd = ''
;~     Sleep(10000)
;~ WEnd




#CS
;~ GUIRegisterMsg(0x0232, 'WM_EXITSIZEMOVE')
;~ GUIRegisterMsg(0x0024, 'WM_GETMINMAXINFO')
;~ GUIRegisterMsg($WM_MOVE, 'WM_MOVE')
;~ GUIRegisterMsg($WM_SIZE, 'WM_SIZE')
;~ GUIRegisterMsg($WM_COMMAND, 'WM_COMMAND')


;~ _WinAPI_SetWindowsHookEx($WH_CALLWNDPROCRET, $lpfn, $hmod , $dwThreadId = 0)

Func WM_MOVE($hWnd, $Msg, $wParam, $lParam)
    #forceref $Msg, $wParam
    Local $w, $h

    $w = BitAND($lParam, 0xFFFF) ; _WinAPI_LoWord
    $h = BitShift($lParam, 16) ; _WinAPI_HiWord

    $k += 1
    ConsoleWrite('Вызов ' & $k & ' раз, w=' & $w & ', h=' & $h)

    Return $GUI_RUNDEFMSG
EndFunc

Func WM_EXITSIZEMOVE($hWnd, $MsgID, $WParam, $LParam)
    ConsoleWrite('WM_ENTERSIZEMOVE')
EndFunc

Func WM_MOUSEMOVE($hWnd, $iMsg, $wParam, $lParam)
    Switch $iMsg
        Case $WM_MOUSEMOVE
            
    EndSwitch
    Return $GUI_RUNDEFMSG
EndFunc

Func _CheckAvailable()
    $hWndCM_New = _GetWin('главное', '[TITLE:Clickermann -]')
    If $hWndCM <> '' Then
        $AvailableNew = True
    Else
        $AvailableNew = False
    EndIf
    If $Available <> $AvailableNew Then
        If $AvailableNew Then
            _CMOn()
        Else
            _CMOff()
        EndIf
    EndIf
EndFunc   ;==>_CheckAvailable
#CE

