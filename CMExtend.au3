#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=cmex.ico
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_Res_Comment=CMExtend
#AutoIt3Wrapper_Res_Fileversion=0.0.1
#AutoIt3Wrapper_Res_LegalCopyright=Vint
#AutoIt3Wrapper_Res_requestedExecutionLevel=None
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

;===============================================================================
;
; Description:      CMExtend
; Version:          0.0.1
; Requirement(s):   Autoit 3.3.8.1
; Author(s):        Vint
;
;===============================================================================

#Region    ************ Includes ************
#include <WinAPI.au3>
#include <Array.au3>
;#include <WindowsConstants.au3>
#EndRegion ************ Includes ************

Opt('MustDeclareVars', 1)
Opt('TrayIconDebug', 1)

Global $Available = False
Global $hWndCMM = '', $hWndCM = '', $hWndCMR = '', $aPosCM[2], $aPosCMR[4]
Global $fileini = @ScriptDir & '\settings_cme.ini'
Global $aWindows2D[3][14]

_CheckINI()
_ReadINI()
_LogPos()
_Starting()
_LogPos()



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
EndFunc   ;==>_SetPosCM

Func _ReadINI()
    Local $text

    $aPosCM[0] = IniRead($fileini, 'main_position_size', 'CM_X', '-1')
    $aPosCM[1] = IniRead($fileini, 'main_position_size', 'CM_Y', '-1')
    $aPosCMR[0] = IniRead($fileini, 'main_position_size', 'CMR_X', '-1')
    $aPosCMR[1] = IniRead($fileini, 'main_position_size', 'CMR_Y', '-1')
    $aPosCMR[2] = IniRead($fileini, 'main_position_size', 'CMR_W', '649')
    $aPosCMR[3] = IniRead($fileini, 'main_position_size', 'CMR_H', '480')
;~     IniWrite($fileini, 'main_position_size', 'running', '100')
EndFunc   ;==>_ReadINI

Func _CheckINI()
    IniRenameSection($fileini, 'main_position_size', 'main_position_size')
    If Not @error Then
        MsgBox(4096, '', 'Произошла ошибка, отсутствует или повреждён файл settings_cme.ini', 2)
        FileInstall('settings_cme_default.ini', $fileini)
        Sleep(500)
    EndIf
EndFunc   ;==>_CheckINI

Func _IsWinCM()
    ;$hWndCMM = _GetWin('базовое', '[CLASS:TApplication; TITLE:Clickermann -]')
    $hWndCM = _GetWin('главное', '[TITLE:Clickermann -]')
    $hWndCMR = _GetWin('редактора', '[CLASS:TfrmEdit; TITLE:Редактор -]')
    If $hWndCM <> '' Then
        $Available = True
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
    _ArrayDisplay($aWindows2D, 'Окна', -1, 0, $s, $s, $colnames)
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
    $text = 'CM_X ' & $aPosCM[0] & '  CM_Y ' & $aPosCM[1] & @CRLF
    $text &= 'CM_X ' & $aPosCMR[0] & '  CM_Y ' & $aPosCMR[1]
    $text &= '  CMR_W ' & $aPosCMR[2] & '  CMR_H ' & $aPosCMR[3] & @CRLF
    ConsoleWrite($text)
EndFunc   ;==>_LogPos

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


